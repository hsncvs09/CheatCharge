//
//  DebugScenarioService.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 03.10.2026.
//

#if DEBUG
import Foundation
import SwiftData

/// Geliştirme ve test süreçlerinde takvim ilerlemesini, rozet kazanımlarını
/// ve devir mekaniklerini anında simüle eden yardımcı servis.
@MainActor
enum DebugScenarioService {

    /// Mevcut haftaya 600 kcal koşu antrenmanı ekler ve rozetleri değerlendirir.
    static func addSampleWorkout(context: ModelContext) {
        let workout = Workout(type: "Koşu", rawCalories: 600, date: Date(), isSyncedFromHealth: false)
        context.insert(workout)
        try? context.save()
        _ = try? BadgeEvaluator.evaluate(context: context)
    }

    /// Mevcut haftaya 300 kcal Ağırlık antrenmanı (+60 kcal Afterburn = 360 kcal) ekler.
    static func addStrengthWorkout(context: ModelContext) {
        let workout = Workout(type: "Ağırlık", rawCalories: 300, date: Date(), isSyncedFromHealth: false)
        context.insert(workout)
        try? context.save()
        _ = try? BadgeEvaluator.evaluate(context: context)
    }

    /// Mevcut haftaya örnek kaçamak ekler (Burger 500 kcal).
    static func addSampleTreat(context: ModelContext) {
        let item = TreatItem(name: "Double Burger", calories: 500, icon: "🍔", category: .burger)
        context.insert(item)
        let log = TreatLog(treat: item, date: Date())
        context.insert(log)
        try? context.save()
        _ = try? BadgeEvaluator.evaluate(context: context)
    }

    /// Takvimde 1 hafta sonraya atlar ve açık haftayı kapatır:
    /// Hafta arşive eklenir, FIFO devir çalışır, seri ve bileklik seviyesi artar, yeni hafta başlar.
    static func simulateCloseWeek(context: ModelContext) {
        guard let state = try? WeekRolloverEngine.fetchOrCreateState(context: context) else { return }
        // Mevcut açık haftanın bitiminden (yani sonraki Pazartesi) 1 gün sonrasını 'now' olarak ver
        let simulatedNow = Calendar.current.date(byAdding: .day, value: 8, to: state.openWeekStart) ?? Date()
        _ = try? WeekRolloverEngine.closeElapsedWeeks(context: context, now: simulatedNow)
        _ = try? BadgeEvaluator.evaluate(context: context, now: simulatedNow)
    }

    /// Bileklik seviyesini doğrudan sonraki kademeye ilerletmek için başarılı hafta ekler (+2 hafta).
    static func addSuccessfulWeeks(context: ModelContext, count: Int = 2) {
        guard let state = try? WeekRolloverEngine.fetchOrCreateState(context: context) else { return }
        state.totalSuccessfulWeeks += count
        state.currentStreak += count
        try? context.save()
    }

    /// Birkaç farklı kategoriden popüler test rozetlerini açar.
    static func unlockSampleBadges(context: ModelContext) {
        guard let state = try? WeekRolloverEngine.fetchOrCreateState(context: context) else { return }
        let sampleKeys = ["first_charge", "iron_will", "endless_battery", "burger_boss", "yin_yang"]
        let existingKeys = Set(state.unlockedBadges.map { $0.badgeKey })

        for key in sampleKeys where !existingKeys.contains(key) {
            let record = BadgeRecord(badgeKey: key, unlockedDate: Date(), triggerNote: "Geliştirici Testi")
            record.state = state
            state.unlockedBadges.append(record)
            context.insert(record)
        }
        try? context.save()
    }

    /// Tüm veritabanını (antrenmanlar, kaçamaklar, geçmiş haftalar, seviye, rozetler) sıfırlar.
    static func resetEverything(context: ModelContext) {
        try? context.delete(model: Workout.self)
        try? context.delete(model: TreatLog.self)
        try? context.delete(model: TreatItem.self)
        try? context.delete(model: WeekRecord.self)
        try? context.delete(model: BadgeRecord.self)
        try? context.delete(model: UserGamificationState.self)
        try? context.save()
    }
}
#endif
