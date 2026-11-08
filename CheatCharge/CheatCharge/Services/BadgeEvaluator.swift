//
//  BadgeEvaluator.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 03.10.2026.
//

import Foundation
import SwiftData

/// Veritabanındaki tüm antrenman ve kaçamak verilerini değerlendirerek
/// rozet kazanım durumunu güncelleyen servis.
///
/// `BadgeRules` saf hesaplama motorunu kullanır. Zaten kazanılmış rozetleri
/// atlar (idempotent çalışır). Yeni kazanılan rozetleri `UserGamificationState`'e
/// kaydeder ve `BadgeUnlockCenter` kuyruğuna ekler.
@MainActor
enum BadgeEvaluator {

    /// Tüm geçmiş verileri analiz eder, yeni kazanılan rozetleri kaydeder ve döndürür.
    ///
    /// - Parameters:
    ///   - context: SwiftData model bağlamı
    ///   - now: Değerlendirme anı (varsayılan: `Date()`)
    ///   - unlockCenter: Bildirim kuyruğu (varsayılan: `BadgeUnlockCenter.shared`)
    /// - Returns: Bu değerlendirmede yeni kazanılan `BadgeRecord` listesi
    @discardableResult
    static func evaluate(
        context: ModelContext,
        now: Date = Date(),
        unlockCenter: BadgeUnlockCenter? = nil
    ) throws -> [BadgeRecord] {
        let targetUnlockCenter = unlockCenter ?? BadgeUnlockCenter.shared
        let state = try WeekRolloverEngine.fetchOrCreateState(context: context)

        // Mevcut kazanılmış rozet anahtarlarını topla
        let existingKeys = Set(state.unlockedBadges.map { $0.badgeKey })

        // Eğer tüm rozetler zaten kazanılmışsa işlemi erken sonlandır
        if existingKeys.count >= BadgeCatalog.all.count {
            return []
        }

        // 1. Tüm antrenmanları çek ve snapshot'a dönüştür
        let workoutDesc = FetchDescriptor<Workout>()
        let workouts = try context.fetch(workoutDesc)
        let workoutSnapshots = workouts.map {
            WorkoutSnapshot(
                date: $0.date,
                calories: $0.caloriesBurned,
                type: $0.type
            )
        }

        // 2. Tüm kaçamak kayıtlarını çek ve snapshot'a dönüştür
        let treatDesc = FetchDescriptor<TreatLog>()
        let treatLogs = try context.fetch(treatDesc)
        let treatSnapshots: [TreatSnapshot] = treatLogs.compactMap { log in
            guard let treat = log.treat else { return nil }
            return TreatSnapshot(
                date: log.date,
                calories: treat.calories,
                category: treat.category
            )
        }

        // 3. Değerlendirme girdisini hazırla
        let input = BadgeEvaluationInput(
            workouts: workoutSnapshots,
            treats: treatSnapshots,
            currentRollover: state.currentRolloverBalance,
            openWeekStart: state.openWeekStart,
            calendar: WeekHelper.calendar
        )

        // 4. Saf kuralları çalıştır
        let unlockedKeys = BadgeRules.evaluate(input: input)

        // 5. Yalnızca yeni açılanları filtrele
        let newlyUnlockedKeys = unlockedKeys.subtracting(existingKeys)
        guard !newlyUnlockedKeys.isEmpty else {
            return []
        }

        // 6. Yeni kayıtları oluştur ve state'e ekle
        var newRecords: [BadgeRecord] = []
        for key in newlyUnlockedKeys.sorted() {
            let definition = BadgeCatalog.definition(for: key)
            let record = BadgeRecord(
                badgeKey: key,
                unlockedDate: now,
                triggerNote: definition?.title
            )
            record.state = state
            state.unlockedBadges.append(record)
            context.insert(record)
            newRecords.append(record)
        }

        // 7. Veritabanına mühürle
        try context.save()

        // 8. Bildirim kuyruğuna ekle
        let definitions = newRecords.compactMap { BadgeCatalog.definition(for: $0.badgeKey) }
        targetUnlockCenter.enqueue(definitions)

        return newRecords
    }
}
