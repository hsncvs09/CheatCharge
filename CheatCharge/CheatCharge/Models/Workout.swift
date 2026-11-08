//
//  Workout.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 24.09.2026.
//

import Foundation
import SwiftData

/// Kullanıcının yaptığı antrenmanları temsil eder.
/// Hem manuel giriş hem de HealthKit senkronizasyonunu destekler.
///
/// v2: Direnç antrenmanlarında Afterburn (1.2x) uygulanır.
/// - `rawCalories`: HealthKit'ten veya elle girilen ham kalori
/// - `afterburnMultiplier`: Direnç antrenmanı ise 1.2, değilse 1.0
/// - `caloriesBurned`: `rawCalories * afterburnMultiplier` (bütçeye yansıyan değer)
@Model
final class Workout {

    // MARK: - Afterburn Kuralı

    /// Direnç antrenmanları için sabit çarpan.
    static let afterburnFactor: Double = 1.2

    /// Antrenman türüne göre uygulanacak çarpanı döndürür.
    /// HealthKit'te `.traditionalStrengthTraining`, `.functionalStrengthTraining`
    /// ve `.coreTraining` zaten "Ağırlık" adına çevrildiği için manuel ve
    /// HealthKit kayıtları aynı kuralla çalışır.
    static func multiplier(forType type: String) -> Double {
        (type == "Ağırlık" || type == "Weight") ? afterburnFactor : 1.0
    }

    // MARK: - Alanlar

    var id: UUID
    /// Antrenman türü (Koşu, Ağırlık, Bisiklet vb.)
    var type: String
    /// Ham kalori (afterburn öncesi). Varsayılan değer, v1 → v2
    /// hafif (lightweight) migration'ın çalışması için gereklidir.
    var rawCalories: Double = 0
    /// Afterburn çarpanı (1.0 veya 1.2).
    var afterburnMultiplier: Double = 1.0
    /// Bütçeye yansıyan kalori: `rawCalories * afterburnMultiplier`
    var caloriesBurned: Double
    /// Antrenmanın yapıldığı tarih
    var date: Date
    /// HealthKit'ten senkronize edildi mi?
    var isSyncedFromHealth: Bool
    /// HealthKit'ten gelen kayıtlarda tekrar senkronizasyonu önlemek için
    /// saklanan HKWorkout UUID dizesi. Manuel kayıtlarda nil olur.
    var sourceID: String?

    // MARK: - Türetilmiş Değerler

    /// Afterburn'den gelen ek kalori (örn. 300 kcal → +60 kcal).
    var afterburnBonus: Double {
        max(0, caloriesBurned - rawCalories)
    }

    /// Bu antrenmana afterburn uygulanıyor mu?
    var hasAfterburn: Bool {
        afterburnMultiplier > 1.0
    }

    // MARK: - Init

    /// - Parameter afterburnMultiplier: Verilmezse `type`'a göre otomatik belirlenir.
    init(
        id: UUID = UUID(),
        type: String,
        rawCalories: Double,
        date: Date = Date(),
        isSyncedFromHealth: Bool = false,
        sourceID: String? = nil,
        afterburnMultiplier: Double? = nil
    ) {
        let multiplier = afterburnMultiplier ?? Workout.multiplier(forType: type)
        self.id = id
        self.type = type
        self.rawCalories = rawCalories
        self.afterburnMultiplier = multiplier
        self.caloriesBurned = rawCalories * multiplier
        self.date = date
        self.isSyncedFromHealth = isSyncedFromHealth
        self.sourceID = sourceID
    }

    // MARK: - Güncelleme Yardımcıları

    /// Ham kaloriyi günceller ve bütçeye yansıyan değeri yeniden hesaplar.
    func updateRawCalories(_ newValue: Double) {
        rawCalories = newValue
        caloriesBurned = newValue * afterburnMultiplier
    }

    /// Türü günceller; çarpanı ve bütçeye yansıyan kaloriyi yeniden hesaplar.
    func updateType(_ newType: String) {
        type = newType
        afterburnMultiplier = Workout.multiplier(forType: newType)
        caloriesBurned = rawCalories * afterburnMultiplier
    }
}
