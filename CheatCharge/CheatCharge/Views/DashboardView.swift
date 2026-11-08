//
//  DashboardView.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 24.09.2026.
//

import SwiftUI
import SwiftData

/// Neobrutalist Today Dashboard (Summary Screen).
///
/// Implements Stitch "today_dashboard_dark_neobrutalism":
/// - Header with Cheat & Charge brand mark and HealthKit Sync status pill.
/// - Top sticker badges: User Tier ("ROOKIE"), Streak ("14D STREAK"), and Date Period ("12 OCT - 18 OCT").
/// - Neobrutalist Fuel Tank (Tumbler) with liquid physics and central available kcal sticker.
/// - Bento Quick Stats Grid: TOTAL CHARGED and TOTAL CHEATED.
/// - Dual Action Buttons: "CHARGE WORKOUT" and "LOG CHEAT MEAL".
struct DashboardView: View {

    // MARK: - Dependencies

    @Environment(\.modelContext) private var modelContext
    @Environment(HealthKitManager.self) private var healthKitManager

    @Query private var allWorkouts: [Workout]
    @Query private var allTreatLogs: [TreatLog]
    @Query private var gamificationStates: [UserGamificationState]

    // MARK: - State

    @State private var showAddWorkout = false
    @State private var showAddTreat = false

    // MARK: - Calculations

    private var weeklyWorkouts: [Workout] {
        allWorkouts.filter { WeekHelper.isInCurrentWeek($0.date) }
    }

    private var weeklyTreatLogs: [TreatLog] {
        allTreatLogs.filter { WeekHelper.isInCurrentWeek($0.date) }
    }

    private var earnedCalories: Double {
        weeklyWorkouts.reduce(0) { $0 + $1.caloriesBurned }
    }

    private var spentCalories: Double {
        weeklyTreatLogs.compactMap { $0.treat?.calories }.reduce(0, +)
    }

    private var rolloverBalance: Double {
        gamificationStates.first?.currentRolloverBalance ?? 0
    }

    private var remainingCalories: Double {
        WeekRolloverCalculator.liveBalance(
            earned: earnedCalories,
            spent: spentCalories,
            rollover: rolloverBalance
        )
    }

    private var currentStreak: Int {
        gamificationStates.first?.currentStreak ?? 0
    }

    private var currentTier: WristbandTier {
        WristbandTier.current(for: gamificationStates.first?.totalSuccessfulWeeks ?? 0)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Dark Dot Grid Background
                NeoDotBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Top App Bar
                        topAppBar

                        // Top Badges & Date Range
                        topBadgesSection

                        // Central Fuel Tank / Tumbler
                        LiquidGlassView(remainingCalories: remainingCalories)
                            .padding(.top, 2)

                        // Rollover Balance Tag (if applicable)
                        if rolloverBalance > 0 {
                            rolloverBanner
                        }

                        // Bento Quick Stats Grid (2 Cards)
                        bentoStatsGrid

                        // Action Buttons (2 Primary CTAs)
                        actionButtonsGrid

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddWorkout) {
                AddWorkoutSheet()
            }
            .sheet(isPresented: $showAddTreat) {
                AddTreatLogSheet()
            }
        }
    }

    // MARK: - 1. Top App Bar

    private var topAppBar: some View {
        HStack {
            // Brand Logo & Title
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(CyberTheme.neonVolt)
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(CyberTheme.blackBorder, lineWidth: 2)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(CyberTheme.blackBorder)
                }
                .frame(width: 32, height: 32)
                .offset(x: -1, y: -1)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(CyberTheme.blackBorder)
                        .offset(x: 1.5, y: 1.5)
                )

                Text("CHEAT & CHARGE")
                    .font(.system(size: 18, weight: .black))
                    .tracking(-0.3)
                    .foregroundStyle(Color.white)
            }

            Spacer()

            // HealthKit Sync Status Pill
            Button {
                Task {
                    await healthKitManager.syncWorkouts(into: modelContext)
                }
            } label: {
                HStack(spacing: 6) {
                    Circle()
                        .fill(CyberTheme.neonVolt)
                        .frame(width: 8, height: 8)
                        .shadow(color: CyberTheme.neonVolt, radius: 4)

                    if healthKitManager.isSyncing {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.7)
                    } else {
                        Text("HEALTHKIT SYNC")
                            .font(.system(size: 10, weight: .black))
                            .tracking(0.5)
                            .textCase(.uppercase)
                            .foregroundStyle(Color.white)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(CyberTheme.surface)
                        .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1.2))
                )
            }
            .disabled(healthKitManager.isSyncing || !healthKitManager.isHealthAvailable)
        }
        .padding(.vertical, 6)
    }

    // MARK: - 2. Top Badges & Date Range

    private var topBadgesSection: some View {
        VStack(spacing: 10) {
            HStack {
                // User Wristband Tier Badge
                HStack(spacing: 5) {
                    Image(systemName: currentTier.icon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(CyberTheme.neonYellow)
                    Text(currentTier.subtitle.uppercased())
                        .font(.system(size: 11, weight: .black))
                        .tracking(0.6)
                        .foregroundStyle(Color.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .neoBoxSm(backgroundColor: CyberTheme.surface, cornerRadius: 8)

                Spacer()

                // Active Streak Badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(CyberTheme.blackBorder)
                        .frame(width: 7, height: 7)
                    Text("\(currentStreak)D STREAK")
                        .font(.system(size: 11, weight: .black))
                        .tracking(0.6)
                        .textCase(.uppercase)
                        .foregroundStyle(CyberTheme.blackBorder)
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 5)
                .background(
                    NeoBoxBackground(
                        backgroundColor: CyberTheme.neonVolt,
                        borderColor: CyberTheme.blackBorder,
                        borderWidth: CyberTheme.borderWidthSm,
                        cornerRadius: 8,
                        shadowColor: CyberTheme.blackBorder,
                        shadowOffset: CyberTheme.shadowOffsetSm
                    )
                )
            }

            // Date Period Tag
            Text(WeekHelper.weekRangeString)
                .font(.system(size: 11, weight: .bold))
                .tracking(1.0)
                .textCase(.uppercase)
                .foregroundStyle(Color.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    NeoBoxBackground(
                        backgroundColor: CyberTheme.surface,
                        borderColor: Color.white.opacity(0.6),
                        borderWidth: CyberTheme.borderWidthSm,
                        cornerRadius: 6,
                        shadowColor: CyberTheme.blackBorder,
                        shadowOffset: CyberTheme.shadowOffsetSm
                    )
                )
        }
    }

    // MARK: - 3. Rollover Banner

    private var rolloverBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.uturn.right.circle.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(CyberTheme.neonCyan)

            Text("ROLLED OVER: +\(Int(rolloverBalance)) KCAL FROM LAST WEEK")
                .font(.system(size: 10, weight: .black))
                .tracking(0.6)
                .foregroundStyle(Color.white)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .neoBoxSm(
            backgroundColor: CyberTheme.surface,
            borderColor: CyberTheme.neonCyan,
            cornerRadius: 10
        )
    }

    // MARK: - 4. Bento Stats Grid

    private var bentoStatsGrid: some View {
        HStack(spacing: 12) {
            // Card 1: TOTAL CHARGED
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("TOTAL CHARGED")
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(0.6)
                        .textCase(.uppercase)
                        .foregroundStyle(CyberTheme.textSecondary)

                    Spacer()

                    // Bolt icon in neon volt box
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(CyberTheme.neonVolt)
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(CyberTheme.blackBorder, lineWidth: 1.5)
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(CyberTheme.blackBorder)
                    }
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(CyberTheme.blackBorder)
                            .offset(x: 1.5, y: 1.5)
                    )
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("+\(Int(earnedCalories))")
                        .font(.system(size: 24, weight: .black))
                        .tracking(-0.5)
                        .foregroundStyle(CyberTheme.neonVolt)

                    Text("KCAL")
                        .font(.system(size: 10, weight: .black))
                        .tracking(0.5)
                        .foregroundStyle(Color.white)
                }

                Divider()
                    .overlay(Color.white.opacity(0.2))

                HStack {
                    Text("\(weeklyWorkouts.count) CHARGE\(weeklyWorkouts.count == 1 ? "" : "S")")
                        .font(.system(size: 10, weight: .black))
                        .tracking(0.6)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.white)

                    Spacer()

                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(CyberTheme.neonVolt)
                }
            }
            .padding(14)
            .neoBox(cornerRadius: 16)

            // Card 2: TOTAL CHEATED
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("TOTAL CHEATED")
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(0.6)
                        .textCase(.uppercase)
                        .foregroundStyle(CyberTheme.textSecondary)

                    Spacer()

                    // Burger / Dining icon in neon coral box
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(CyberTheme.neonCoral)
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(CyberTheme.blackBorder, lineWidth: 1.5)
                        Image(systemName: "fork.knife")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(CyberTheme.blackBorder)
                    }
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(CyberTheme.blackBorder)
                            .offset(x: 1.5, y: 1.5)
                    )
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("-\(Int(spentCalories))")
                        .font(.system(size: 24, weight: .black))
                        .tracking(-0.5)
                        .foregroundStyle(CyberTheme.neonCoral)

                    Text("KCAL")
                        .font(.system(size: 10, weight: .black))
                        .tracking(0.5)
                        .foregroundStyle(Color.white)
                }

                Divider()
                    .overlay(Color.white.opacity(0.2))

                HStack {
                    Text("\(weeklyTreatLogs.count) CHEAT\(weeklyTreatLogs.count == 1 ? "" : "S")")
                        .font(.system(size: 10, weight: .black))
                        .tracking(0.6)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.white)

                    Spacer()

                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(CyberTheme.neonCoral)
                }
            }
            .padding(14)
            .neoBox(cornerRadius: 16)
        }
    }

    // MARK: - 5. Action Buttons Grid

    private var actionButtonsGrid: some View {
        HStack(spacing: 12) {
            // Charge Workout CTA
            Button {
                showAddWorkout = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 14, weight: .black))
                    Text("Charge Workout")
                        .font(.system(size: 12, weight: .black))
                        .textCase(.uppercase)
                        .tracking(0.4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.neoPrimary)

            // Log Cheat Meal CTA
            Button {
                showAddTreat = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(CyberTheme.neonCoral)
                    Text("Log Cheat Meal")
                        .font(.system(size: 12, weight: .black))
                        .textCase(.uppercase)
                        .tracking(0.4)
                        .foregroundStyle(Color.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.neoSecondary)
        }
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .modelContainer(for: [Workout.self, TreatItem.self, TreatLog.self, UserGamificationState.self, WeekRecord.self, BadgeRecord.self], inMemory: true)
        .environment(HealthKitManager())
        .preferredColorScheme(.dark)
}
