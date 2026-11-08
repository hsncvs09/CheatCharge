//
//  HealthKitManager.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 24.09.2026.
//

import Foundation
import HealthKit
import SwiftData

// MARK: - HealthKitManager

/// HealthKit ile iletişimi yöneten servis katmanı.
/// Yalnızca okuma (read) yetkisi kullanır; veri yazılmaz.
/// `@Observable` ile tüm view'lara environment üzerinden sağlanır.
@Observable
final class HealthKitManager {

    // MARK: - Durum

    /// Senkronizasyon devam ediyor mu?
    var isSyncing = false
    /// Son senkronizasyon sonuç mesajı (başarı veya hata)
    var lastSyncMessage: String?
    /// Son başarılı senkronizasyon tarihi (UserDefaults'ta saklanır)
    var lastSyncDate: Date? = UserDefaults.standard.object(forKey: "cheatcharge.lastSyncDate") as? Date
    /// Bu cihazda HealthKit kullanılabilir mi?
    var isHealthAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    // MARK: - Özel

    private let healthStore = HKHealthStore()
    private let workoutType = HKObjectType.workoutType()

    // MARK: - Yetkilendirme

    /// HealthKit okuma iznini kullanıcıdan ister.
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        try await healthStore.requestAuthorization(toShare: [], read: [workoutType])
    }

    // MARK: - Senkronizasyon

    /// Bu haftaki HealthKit antrenmanlarını çekip SwiftData'ya aktarır.
    /// Akıllı Eşleştirme (Smart Matching):
    /// - Yalnızca UUID'ye değil, başlangıç saatine (±3 dakika tolerans) göre de kontrol eder.
    /// - Garmin vb. kaynakların antrenmanı güncelleyip yeni UUID üretmesi durumunda mükerrer kayıt açmaz, mevcut kaydı günceller.
    /// - Varsa önceki senkronizasyonlardan kalma çift kayıtları otomatik temizler.
    /// - İşlem sonunda `context.save()` çağrılarak veritabanına kalıcı olarak yazılır.
    /// - Parameter startDate: Eşitlemenin başlangıcı. Verilmezse içinde bulunulan haftanın başı.
    ///   Hafta kapanışından önce, kapanacak haftaların başı verilir.
    @MainActor
    func syncWorkouts(into context: ModelContext, from startDate: Date? = nil) async {
        guard HKHealthStore.isHealthDataAvailable() else {
            lastSyncMessage = "Bu cihazda HealthKit desteklenmiyor."
            return
        }

        isSyncing = true
        lastSyncMessage = nil
        defer { isSyncing = false }

        do {
            // 1. Yetki iste
            try await requestAuthorization()

            // 2. Belirtilen tarihten (varsayılan: bu haftanın başı) itibaren antrenmanları çek
            let weekStart = startDate ?? WeekHelper.currentWeekStart()
            let hkWorkouts = try await fetchHKWorkouts(from: weekStart)

            // 3. Mevcut antrenmanları veritabanından al
            var existingWorkouts = try context.fetch(FetchDescriptor<Workout>())

            // 4. Önceden oluşmuş mükerrer (duplicate) kayıtları otomatik temizle
            var toDelete = Set<UUID>()
            let healthWorkouts = existingWorkouts
                .filter { $0.isSyncedFromHealth }
                .sorted(by: { $0.date < $1.date })

            for i in 0..<healthWorkouts.count {
                let current = healthWorkouts[i]
                guard !toDelete.contains(current.id) else { continue }

                for j in (i + 1)..<healthWorkouts.count {
                    let next = healthWorkouts[j]
                    guard !toDelete.contains(next.id) else { continue }

                    // 3 dakika (180 saniye) içinde başlamışsa aynı Garmin antrenmanıdır
                    if abs(next.date.timeIntervalSince(current.date)) < 180 {
                        // Kalorisi daha yüksek veya güncel olanı koru, diğerini sil
                        // (karşılaştırma ham kalori üzerinden; afterburn çarpanı sonucu etkilemesin)
                        if next.rawCalories >= current.rawCalories {
                            toDelete.insert(current.id)
                            context.delete(current)
                            break
                        } else {
                            toDelete.insert(next.id)
                            context.delete(next)
                        }
                    } else {
                        break
                    }
                }
            }

            if !toDelete.isEmpty {
                existingWorkouts.removeAll { toDelete.contains($0.id) }
            }

            // 5. Yeni gelen HealthKit kayıtlarını akıllı eşleştir ve ekle/güncelle
            var newCount = 0
            var updatedCount = 0

            for hkWorkout in hkWorkouts {
                let uuidString = hkWorkout.uuid.uuidString
                // HealthKit'ten gelen değer HAM kaloridir; afterburn Workout modelinde uygulanır.
                let calories = hkWorkout.activeEnergyCalories
                guard calories > 0 else { continue }

                let turkishType = hkWorkout.workoutActivityType.turkishName

                // Akıllı eşleşme kontrolü:
                // a) UUID birebir eşleşiyor mu? VEYA
                // b) Sağlık kaydı olup başlangıç saati 3 dakika (180 saniye) içinde mi?
                if let match = existingWorkouts.first(where: { w in
                    w.isSyncedFromHealth && (w.sourceID == uuidString || abs(w.date.timeIntervalSince(hkWorkout.startDate)) < 180)
                }) {
                    var modified = false

                    // Ham kalori değiştiyse güncelle (Garmin sunucu hesaplaması sonrası güncelleme).
                    // caloriesBurned, afterburn çarpanıyla otomatik yeniden hesaplanır.
                    if abs(match.rawCalories - calories) > 0.5 {
                        match.updateRawCalories(calories)
                        modified = true
                    }
                    // UUID güncellendiyse güncelle
                    if match.sourceID != uuidString {
                        match.sourceID = uuidString
                        modified = true
                    }
                    // Tür ismi daha spesifik hale geldiyse güncelle (çarpan da yeniden hesaplanır)
                    if match.type != turkishType && match.type == "Antrenman" {
                        match.updateType(turkishType)
                        modified = true
                    }

                    if modified {
                        updatedCount += 1
                    }
                } else {
                    // Tamamen yeni bir antrenman (afterburn türe göre otomatik belirlenir)
                    let newWorkout = Workout(
                        type: turkishType,
                        rawCalories: calories,
                        date: hkWorkout.startDate,
                        isSyncedFromHealth: true,
                        sourceID: uuidString
                    )
                    context.insert(newWorkout)
                    existingWorkouts.append(newWorkout)
                    newCount += 1
                }
            }

            // 6. Değişiklikleri diske / veritabanına mühürle (Kalıcı Kayıt)
            try context.save()

            // 6.1. Yeni gelen veya güncellenen antrenmanlar sonrası rozetleri değerlendir
            if newCount > 0 || updatedCount > 0 {
                _ = try? BadgeEvaluator.evaluate(context: context)
            }

            // 7. Son senkronizasyon tarihini kaydet
            let now = Date()
            lastSyncDate = now
            UserDefaults.standard.set(now, forKey: "cheatcharge.lastSyncDate")

            // 8. Kullanıcıya net durum mesajı ver
            if newCount > 0 && updatedCount > 0 {
                lastSyncMessage = "✅ \(newCount) yeni eklendi, \(updatedCount) antrenman güncellendi."
            } else if newCount > 0 {
                lastSyncMessage = "✅ \(newCount) yeni antrenman aktarıldı."
            } else if updatedCount > 0 {
                lastSyncMessage = "✅ \(updatedCount) antrenman kalorisi güncellendi."
            } else if !toDelete.isEmpty {
                lastSyncMessage = "✅ Çift kayıtlar temizlendi, veriler güncel."
            } else {
                lastSyncMessage = "Tüm veriler güncel."
            }

        } catch HealthKitError.notAvailable {
            lastSyncMessage = "❌ HealthKit bu cihazda kullanılamıyor."
        } catch {
            lastSyncMessage = "❌ Hata: \(error.localizedDescription)"
        }
    }

    // MARK: - Özel: HK Sorgulama

    private func fetchHKWorkouts(from startDate: Date) async throws -> [HKWorkout] {
        try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(
                withStart: startDate,
                end: Date(),
                options: .strictStartDate
            )
            let sortDescriptor = NSSortDescriptor(
                key: HKSampleSortIdentifierStartDate,
                ascending: false
            )
            let query = HKSampleQuery(
                sampleType: HKWorkoutType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (samples as? [HKWorkout]) ?? [])
                }
            }
            healthStore.execute(query)
        }
    }
}

// MARK: - Hata Tipleri

enum HealthKitError: LocalizedError {
    case notAvailable

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit bu cihazda kullanılamıyor."
        }
    }
}

// MARK: - HKWorkoutActivityType → Türkçe İsim

extension HKWorkoutActivityType {
    /// HKWorkoutActivityType değerini Türkçe antrenman adına çevirir.
    var turkishName: String {
        switch self {
        case .running:                                          return "Koşu"
        case .walking:                                         return "Yürüyüş"
        case .cycling:                                         return "Bisiklet"
        case .swimming:                                        return "Yüzme"
        case .traditionalStrengthTraining,
             .functionalStrengthTraining,
             .coreTraining:                                    return "Ağırlık"
        case .highIntensityIntervalTraining:                   return "HIIT"
        case .yoga:                                            return "Yoga"
        case .rowing:                                          return "Kürek"
        case .elliptical:                                      return "Eliptik"
        case .stairClimbing:                                   return "Merdiven"
        case .soccer, .basketball, .tennis, .volleyball:       return "Takım Sporu"
        case .hiking:                                          return "Yürüyüş (Doğa)"
        case .crossTraining:                                   return "Çapraz Antrenman"
        default:                                               return "Antrenman"
        }
    }
}

// MARK: - HKWorkout → Kalori Okuma (Modern API)

extension HKWorkout {
    /// Modern `statistics(for:)` API'sini kullanan kalori okuma yardımcısı.
    var activeEnergyCalories: Double {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
              let stats = statistics(for: energyType),
              let sumQuantity = stats.sumQuantity() else {
            return 0
        }
        return sumQuantity.doubleValue(for: .kilocalorie())
    }
}
