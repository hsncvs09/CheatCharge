//
//  CheatChargeApp.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 24.09.2026.
//

import SwiftUI
import SwiftData

/// Uygulamanın yalnızca dikey (portrait) modda çalışmasını garanti eden delege.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        .portrait
    }
}

@main
struct CheatChargeApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @State private var healthKitManager = HealthKitManager()
    @State private var badgeUnlockCenter = BadgeUnlockCenter.shared
    @Environment(\.scenePhase) private var scenePhase

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Workout.self,
            TreatItem.self,
            TreatLog.self,
            WeekRecord.self,
            UserGamificationState.self,
            BadgeRecord.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        .environment(healthKitManager)
        .environment(badgeUnlockCenter)
        // Açılışta (initial) ve uygulama her öne geldiğinde: süresi dolan haftaları kapat.
        .onChange(of: scenePhase, initial: true) { _, phase in
            guard phase == .active else { return }
            Task {
                await WeekMaintenanceService.run(
                    context: sharedModelContainer.mainContext,
                    healthKit: healthKitManager
                )
            }
        }
    }
}
