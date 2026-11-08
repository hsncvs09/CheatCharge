//
//  WeekRolloverEngine.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 03.10.2026.
//

import Foundation
import SwiftData

/// Süresi dolan haftaları kapatır: arşivler (`WeekRecord`), devri (rollover) hesaplar,
/// kalıcı seviyeyi (`totalSuccessfulWeeks`) ve bağımsız seriyi (`currentStreak`) günceller.
///
/// Güvenceler:
/// - **Eksik haftalar sırayla kapanır:** Uygulama haftalarca açılmazsa her hafta ayrı ayrı
///   değerlendirilir; devir tek haftalık olduğu için pasif haftalarda bakiye sıfırlanır.
/// - **Atomik:** Hafta kaydı, seviye/seri/devir ve `openWeekStart` ilerlemesi tek `save()` ile
///   yazılır. Hata olursa `rollback` yapılır ve aynı hafta bir sonraki çalışmada temiz durumdan
///   yeniden denenir. Bu yüzden aynı haftaya iki kez kayıt açılamaz.
@MainActor
enum WeekRolloverEngine {

    /// Kapatılması gereken (süresi dolmuş) hafta var mı?
    static func hasElapsedWeek(state: UserGamificationState, now: Date = Date()) -> Bool {
        WeekHelper.weekEnd(startingAt: state.openWeekStart) <= now
    }

    /// Süresi dolan tüm haftaları kapatır ve oluşturulan arşiv kayıtlarını döndürür.
    @discardableResult
    static func closeElapsedWeeks(context: ModelContext, now: Date = Date()) throws -> [WeekRecord] {
        let state = try fetchOrCreateState(context: context)
        var closed: [WeekRecord] = []

        // Güvenlik sınırı: ≈ 40 yıllık haftalık döngü.
        var iterations = 0
        while hasElapsedWeek(state: state, now: now), iterations < 2_100 {
            iterations += 1
            let start = state.openWeekStart
            let end = WeekHelper.weekEnd(startingAt: start)

            do {
                let record = try closeWeek(start: start, end: end, state: state, context: context)
                state.openWeekStart = end
                try context.save()
                closed.append(record)
            } catch {
                context.rollback()
                throw error
            }
        }
        return closed
    }

    // MARK: - Tek Hafta

    private static func closeWeek(
        start: Date,
        end: Date,
        state: UserGamificationState,
        context: ModelContext
    ) throws -> WeekRecord {
        let workouts = try context.fetch(FetchDescriptor<Workout>(
            predicate: #Predicate { $0.date >= start && $0.date < end }
        ))
        let logs = try context.fetch(FetchDescriptor<TreatLog>(
            predicate: #Predicate { $0.date >= start && $0.date < end }
        ))

        let earned = workouts.reduce(0) { $0 + $1.caloriesBurned }
        let spent = logs.compactMap { $0.treat?.calories }.reduce(0, +)

        let result = WeekRolloverCalculator.close(
            earned: earned,
            spent: spent,
            rollover: state.currentRolloverBalance
        )

        // Seviye kalıcıdır (asla düşmez); seri ise başarısızlıkta sıfırlanır.
        if result.isSuccessful {
            state.totalSuccessfulWeeks += 1
            state.currentStreak += 1
        } else {
            state.currentStreak = 0
        }
        state.currentRolloverBalance = result.carriedForward

        let record = WeekRecord(
            weekStartDate: start,
            weekEndDate: end,
            earnedCalories: earned,
            spentCalories: spent,
            rolloverReceived: result.rolloverReceived,
            rolloverRemaining: result.rolloverExpired,
            rolloverCarriedForward: result.carriedForward,
            isSuccessful: result.isSuccessful
        )
        context.insert(record)
        return record
    }

    // MARK: - Durum

    static func fetchOrCreateState(context: ModelContext) throws -> UserGamificationState {
        if let existing = try context.fetch(FetchDescriptor<UserGamificationState>()).first {
            return existing
        }
        let state = UserGamificationState()
        context.insert(state)
        return state
    }
}
