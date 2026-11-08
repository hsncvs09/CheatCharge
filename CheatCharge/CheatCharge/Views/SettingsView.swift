//
//  SettingsView.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 24.09.2026.
//

import SwiftUI
import SwiftData

/// 5. Tab: Settings, HealthKit Integration, EPOC Configuration, and Data Management.
/// Redesigned to Stitch Dark Neobrutalism (Kinetic Volt).
struct SettingsView: View {

    // MARK: - Dependencies

    @Environment(\.modelContext) private var modelContext
    @Environment(HealthKitManager.self) private var healthKitManager

    @Query private var allWorkouts: [Workout]
    @Query private var allTreatLogs: [TreatLog]

    // MARK: - State

    @State private var showResetConfirmation = false
    @State private var showResetSuccess = false
    @State private var showAuthSuccess = false
    @State private var showDebugAlert = false
    @State private var debugMessage = ""

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                CyberTheme.background.ignoresSafeArea()
                NeoDotBackground()
                    .opacity(0.7)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header Bar
                    headerBar
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 12)

                    // Scrollable Content
                    ScrollView {
                        VStack(spacing: 16) {
                            // 1. Weekly Cycle
                            weeklyCycleSection

                            // 2. Afterburn Effect
                            afterburnSection

                            // 3. Apple Health
                            healthKitSection

                            // 4. Data Management
                            dataManagementSection

                            #if DEBUG
                            // 5. Developer & Test Tools
                            debugSection
                            #endif

                            // 6. App Info
                            appInfoSection
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100) // Clearance for floating tab dock
                    }
                }
            }
            .navigationBarHidden(true)
            .confirmationDialog(
                "All workouts and cheat meal logs recorded this week will be deleted. This action cannot be undone.",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset Current Week", role: .destructive) {
                    resetCurrentWeek()
                    showResetSuccess = true
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Data Reset", isPresented: $showResetSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Current week's workouts and cheat meals have been cleared.")
            }
            .alert("Apple Health Access", isPresented: $showAuthSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Authorization request dispatched. You can verify permissions in the iOS Settings app.")
            }
            .alert("Debug Simulation", isPresented: $showDebugAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(debugMessage)
            }
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            Text("SETTINGS")
                .font(.system(size: 28, weight: .black))
                .italic()
                .foregroundStyle(.white)

            Spacer()

            HStack(spacing: 5) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 11))
                Text("SYSTEM")
                    .font(.system(size: 10, weight: .black))
            }
            .foregroundStyle(Color.white.opacity(0.7))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(hex: "#18181c"))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1.5))
        }
    }

    // MARK: - 1. Weekly Cycle Section

    private var weeklyCycleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(CyberTheme.neonVolt)
                Text("WEEKLY CYCLE")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white)
                    .tracking(0.8)
            }

            Divider().overlay(Color.white.opacity(0.15))

            HStack {
                Text("Cycle Start")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.7))

                Spacer()

                Text("MONDAY 00:00")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(CyberTheme.neonVolt)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1))
            }

            Text("The week closes every Monday at 00:00. Unused credits roll over to the next week (FIFO), and the previous week is archived.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.55))
                .lineSpacing(2)
        }
        .padding(16)
        .neoBox(borderColor: .white, cornerRadius: 18)
    }

    // MARK: - 2. Afterburn Section

    private var afterburnSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(CyberTheme.neonYellow)
                Text("AFTERBURN EFFECT (EPOC)")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white)
                    .tracking(0.8)
            }

            Divider().overlay(Color.white.opacity(0.15))

            VStack(spacing: 8) {
                HStack {
                    Text("Weight & Resistance")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.8))

                    Spacer()

                    Text("1.2X (+20%)")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundStyle(CyberTheme.neonYellow)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(CyberTheme.neonYellow.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(CyberTheme.neonYellow.opacity(0.5), lineWidth: 1))
                }

                HStack {
                    Text("Cardio & Other Charges")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.8))

                    Spacer()

                    Text("1.0X (RAW)")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.2), lineWidth: 1))
                }
            }

            Text("Strength and resistance training elevates post-workout metabolism (EPOC), automatically granting a 20% bonus fuel credit.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.55))
                .lineSpacing(2)
        }
        .padding(16)
        .neoBox(borderColor: .white, cornerRadius: 18)
    }

    // MARK: - 3. Apple Health Section

    private var healthKitSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(CyberTheme.neonCoral)
                Text("APPLE HEALTH")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white)
                    .tracking(0.8)
            }

            Divider().overlay(Color.white.opacity(0.15))

            if healthKitManager.isHealthAvailable {
                HStack {
                    Text("Last Synchronization")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.8))

                    Spacer()

                    if let syncDate = healthKitManager.lastSyncDate {
                        Text(syncDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.6))
                    } else {
                        Text("NOT YET")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.4))
                    }
                }

                Button {
                    Task {
                        try? await healthKitManager.requestAuthorization()
                        showAuthSuccess = true
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12, weight: .black))
                        Text("RE-REQUEST PERMISSIONS")
                            .font(.system(size: 11, weight: .black))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(hex: "#18181c"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(CyberTheme.neonCoral, lineWidth: 1.5))
                    .foregroundStyle(CyberTheme.neonCoral)
                }
                .buttonStyle(.plain)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(CyberTheme.neonYellow)
                    Text("Apple Health is not available on this device.")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.7))
                }
            }
        }
        .padding(16)
        .neoBox(borderColor: .white, cornerRadius: 18)
    }

    // MARK: - 4. Data Management Section

    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "externaldrive.fill")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(CyberTheme.neonPurple)
                Text("DATA MANAGEMENT")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white)
                    .tracking(0.8)
            }

            Divider().overlay(Color.white.opacity(0.15))

            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 12, weight: .black))
                    Text("RESET CURRENT WEEK'S DATA")
                        .font(.system(size: 12, weight: .black))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.neoDanger)

            Text("Permanently removes all workouts and cheat meal entries logged in the current weekly cycle. Archived weeks remain safe.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.55))
                .lineSpacing(2)
        }
        .padding(16)
        .neoBox(borderColor: .white, cornerRadius: 18)
    }

    #if DEBUG
    // MARK: - 5. Developer & Test Tools

    private var debugSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "ladybug.fill")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(CyberTheme.neonYellow)
                Text("DEVELOPER TOOLS (DEBUG)")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white)
                    .tracking(0.8)
            }

            Divider().overlay(Color.white.opacity(0.15))

            VStack(spacing: 8) {
                debugButton(title: "Simulate Close Week & Rollover", icon: "arrow.forward.to.line", color: CyberTheme.neonCyan) {
                    DebugScenarioService.simulateCloseWeek(context: modelContext)
                    debugMessage = "Week closed! Archived past week, calculated FIFO rollover, and initiated new cycle."
                    showDebugAlert = true
                }

                debugButton(title: "+2 Successful Weeks (Tier Level)", icon: "trophy.fill", color: CyberTheme.neonPurple) {
                    DebugScenarioService.addSuccessfulWeeks(context: modelContext, count: 2)
                    debugMessage = "+2 successful weeks added! Inspect wristband tier progression in Achievements."
                    showDebugAlert = true
                }

                debugButton(title: "Unlock Sample Badges", icon: "star.fill", color: CyberTheme.neonYellow) {
                    DebugScenarioService.unlockSampleBadges(context: modelContext)
                    debugMessage = "Sample badges unlocked! Check the Badges tab in Achievements."
                    showDebugAlert = true
                }

                debugButton(title: "Add Strength Workout (+Afterburn)", icon: "dumbbell.fill", color: CyberTheme.neonYellow) {
                    DebugScenarioService.addStrengthWorkout(context: modelContext)
                    debugMessage = "300 kcal weight training (+20% EPOC = 360 kcal) logged to current week!"
                    showDebugAlert = true
                }

                debugButton(title: "Add Sample Treat (500 kcal Burger)", icon: "takeoutbag.and.cup.and.straw.fill", color: CyberTheme.neonCoral) {
                    DebugScenarioService.addSampleTreat(context: modelContext)
                    debugMessage = "500 kcal Burger cheat meal added to current week!"
                    showDebugAlert = true
                }

                Button(role: .destructive) {
                    DebugScenarioService.resetEverything(context: modelContext)
                    debugMessage = "Entire SwiftData database (all weeks, workouts, treats, badges & wristbands) reset."
                    showDebugAlert = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash.slash.fill")
                            .font(.system(size: 11, weight: .black))
                        Text("FACTORY RESET DATABASE")
                            .font(.system(size: 11, weight: .black))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.neoDanger)
            }

            Text("Developer shortcuts are only available in debug builds (#if DEBUG) for instantaneous testing.")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.4))
        }
        .padding(16)
        .neoBox(borderColor: CyberTheme.neonYellow, cornerRadius: 18)
    }

    private func debugButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .black))
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                Spacer()
                Text("RUN →")
                    .font(.system(size: 10, weight: .black))
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color(hex: "#18181c"))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.6), lineWidth: 1))
            .foregroundStyle(color)
        }
        .buttonStyle(.plain)
    }
    #endif

    // MARK: - 6. App Info Section

    private var appInfoSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Version")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.6))
                Spacer()
                Text(appVersion)
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
            }

            Divider().overlay(Color.white.opacity(0.15))

            HStack {
                Text("Engineering & Design")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.6))
                Spacer()
                Text("Hasan Cavusoglu")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(CyberTheme.neonVolt)
            }
        }
        .padding(14)
        .neoBox(borderColor: Color.white.opacity(0.3), cornerRadius: 16)
    }

    // MARK: - Helpers

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
    }

    private func resetCurrentWeek() {
        for workout in allWorkouts where WeekHelper.isInCurrentWeek(workout.date) {
            modelContext.delete(workout)
        }
        for log in allTreatLogs where WeekHelper.isInCurrentWeek(log.date) {
            modelContext.delete(log)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .modelContainer(for: [Workout.self, TreatItem.self, TreatLog.self, UserGamificationState.self, WeekRecord.self, BadgeRecord.self], inMemory: true)
        .environment(HealthKitManager())
        .preferredColorScheme(.dark)
}
