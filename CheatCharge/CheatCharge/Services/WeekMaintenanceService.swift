//
//  WeekMaintenanceService.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 03.10.2026.
//

import Foundation
import SwiftData

/// Uygulama açılışında / öne geldiğinde çalışan bakım akışı:
/// 1. Gamification durumunu hazırlar (ilk açılışta oluşturur).
/// 2. Süresi dolan hafta varsa, kapatmadan ÖNCE HealthKit'i o haftanın başından itibaren eşitler
///    (Pazar gecesi yapılan antrenman Pazartesi sabahı kaçmasın).
/// 3. `WeekRolloverEngine` ile eksik haftaları kapatır.
@MainActor
enum WeekMaintenanceService {

    /// Aynı anda iki akışın çalışıp aynı haftayı iki kez kapatmasını önler.
    private static var isRunning = false

    static func run(context: ModelContext, healthKit: HealthKitManager) async {
        guard !isRunning else { return }
        isRunning = true
        defer { isRunning = false }

        // 1. Hazırlık
        guard let state = try? WeekRolloverEngine.fetchOrCreateState(context: context) else { return }
        try? context.save()

        // 2. Kapatılacak hafta yoksa çık.
        guard WeekRolloverEngine.hasElapsedWeek(state: state) else { return }

        // 3. En iyi çaba HealthKit eşitlemesi. Kullanıcı daha önce eşitleme yapmadıysa
        //    (izin vermediyse) beklenmedik bir izin penceresi çıkmasın diye atlanır.
        if healthKit.isHealthAvailable, healthKit.lastSyncDate != nil {
            await healthKit.syncWorkouts(into: context, from: state.openWeekStart)
        }

        // 4. Eksik haftaları kapat.
        do {
            try WeekRolloverEngine.closeElapsedWeeks(context: context)
        } catch {
            print("WeekRolloverEngine hatası: \(error)")
        }
    }
}
