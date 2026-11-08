//
//  WorkoutsView.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 24.09.2026.
//

import SwiftUI
import SwiftData

/// Neobrutalist Workouts (Charges) Screen.
///
/// Implements Stitch "antrenmanlar_dark_neobrutalism":
/// - Header with "CHARGES", Apple Health sync button, and Neon Volt "+" button.
/// - Weekly Summary Banner with source pills and total burned calories.
/// - Workout item cards featuring brutalist icon frames, afterburn stickers, and category tags.
/// - Sync timestamp footer.
struct WorkoutsView: View {

    // MARK: - Dependencies

    @Environment(\.modelContext) private var modelContext
    @Environment(HealthKitManager.self) private var healthKitManager

    @Query(sort: \Workout.date, order: .reverse) private var allWorkouts: [Workout]

    @State private var showAddWorkout = false
    @State private var showSyncError = false

    // MARK: - Calculations

    private var weeklyWorkouts: [Workout] {
        allWorkouts.filter { WeekHelper.isInCurrentWeek($0.date) }
    }

    private var totalEarned: Double {
        weeklyWorkouts.reduce(0) { $0 + $1.caloriesBurned }
    }

    private var healthKitCount: Int {
        weeklyWorkouts.filter { $0.isSyncedFromHealth }.count
    }

    private var manualCount: Int {
        weeklyWorkouts.filter { !$0.isSyncedFromHealth }.count
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Dark Dot Grid Background
                NeoDotBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Top Header (CHARGES & Actions)
                        topHeader

                        // Weekly Summary Banner
                        weeklySummaryBanner

                        // Workout Cards or Empty State
                        if weeklyWorkouts.isEmpty {
                            emptyState
                        } else {
                            workoutCardsList
                        }

                        // Last Synced Footer
                        syncFooter

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
            .alert("Sync Issue", isPresented: $showSyncError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(healthKitManager.lastSyncMessage ?? "Unknown error.")
            }
            .onChange(of: healthKitManager.lastSyncMessage) { _, newValue in
                if let msg = newValue, msg.hasPrefix("❌") {
                    showSyncError = true
                }
            }
        }
    }

    // MARK: - 1. Top Header

    private var topHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("CHARGES")
                    .font(.system(size: 28, weight: .black))
                    .tracking(-0.5)
                    .foregroundStyle(Color.white)
            }

            Spacer()

            // Header Action Buttons
            HStack(spacing: 10) {
                // Apple Health Sync Button (Heart)
                if healthKitManager.isHealthAvailable {
                    Button {
                        Task {
                            await healthKitManager.syncWorkouts(into: modelContext)
                        }
                    } label: {
                        ZStack {
                            if healthKitManager.isSyncing {
                                ProgressView()
                                    .tint(.red)
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(Color.red)
                            }
                        }
                        .frame(width: 40, height: 40)
                    }
                    .buttonStyle(.neoSecondary)
                    .disabled(healthKitManager.isSyncing)
                }

                // Add Workout Button (Volt Plus)
                Button {
                    showAddWorkout = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .black))
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.neoPrimary)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - 2. Weekly Summary Banner

    private var weeklySummaryBanner: some View {
        HStack(alignment: .bottom) {
            // Left: Period & Source Tags
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text("THIS WEEK")
                        .font(.system(size: 11, weight: .black))
                        .tracking(0.8)
                        .foregroundStyle(CyberTheme.textSecondary)

                    Circle()
                        .fill(CyberTheme.neonVolt)
                        .frame(width: 6, height: 6)
                        .shadow(color: CyberTheme.neonVolt, radius: 3)
                }

                HStack(spacing: 6) {
                    if manualCount > 0 {
                        HStack(spacing: 4) {
                            Text("👆")
                                .font(.system(size: 10))
                            Text("\(manualCount) MANUAL")
                                .font(.system(size: 10, weight: .black))
                                .tracking(0.5)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundStyle(CyberTheme.neonVolt)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "#24242b"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(CyberTheme.neonVolt.opacity(0.6), lineWidth: 1.5)
                                )
                        )
                    }

                    if healthKitCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(.red)
                            Text("\(healthKitCount) HEALTH")
                                .font(.system(size: 10, weight: .black))
                                .tracking(0.5)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundStyle(Color.white)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "#24242b"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.red.opacity(0.6), lineWidth: 1.5)
                                )
                        )
                    }

                    if manualCount == 0 && healthKitCount == 0 {
                        Text("0 WORKOUTS")
                            .font(.system(size: 10, weight: .black))
                            .tracking(0.5)
                            .foregroundStyle(CyberTheme.textMuted)
                    }
                }
            }

            Spacer()

            // Right: Total Burned Energy
            VStack(alignment: .trailing, spacing: 2) {
                Text("TOTAL BURNED")
                    .font(.system(size: 10, weight: .black))
                    .tracking(0.8)
                    .foregroundStyle(CyberTheme.textSecondary)

                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(Int(totalEarned))")
                        .font(.system(size: 22, weight: .black))
                        .tracking(-0.5)
                        .foregroundStyle(CyberTheme.neonYellow)

                    Text("KCAL")
                        .font(.system(size: 10, weight: .black))
                        .tracking(0.5)
                        .foregroundStyle(CyberTheme.neonYellow.opacity(0.8))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(CyberTheme.neonYellow.opacity(0.4), lineWidth: 1)
                        )
                )
            }
        }
        .padding(16)
        .neoBox(cornerRadius: 16)
    }

    // MARK: - 3. Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(CyberTheme.surface)
                    .frame(width: 64, height: 64)
                    .overlay(Circle().stroke(CyberTheme.cardBorder, lineWidth: 2))
                Image(systemName: "figure.run")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(CyberTheme.neonVolt)
            }
            .padding(.top, 12)

            Text("NO CHARGES THIS WEEK")
                .font(.system(size: 14, weight: .black))
                .tracking(0.6)
                .foregroundStyle(Color.white)

            Text("Tap + to add a workout manually or tap the heart to sync from Apple Health.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(CyberTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .neoBox(cornerRadius: 18)
    }

    // MARK: - 4. Workout Cards List

    private var workoutCardsList: some View {
        VStack(spacing: 12) {
            ForEach(weeklyWorkouts) { workout in
                workoutCard(workout)
            }
        }
    }

    private func workoutCard(_ workout: Workout) -> some View {
        let meta = workoutMetadata(for: workout.type)

        return HStack(spacing: 12) {
            // Icon Frame (Square Neobrutalist Box)
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "#23232a"))
                RoundedRectangle(cornerRadius: 12)
                    .stroke(CyberTheme.blackBorder, lineWidth: 2)
                Text(meta.emoji)
                    .font(.system(size: 22))
            }
            .frame(width: 48, height: 48)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CyberTheme.blackBorder)
                    .offset(x: 2, y: 2)
            )

            // Title & Date
            VStack(alignment: .leading, spacing: 3) {
                Text(meta.title)
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                HStack(spacing: 5) {
                    Text(workout.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(CyberTheme.textSecondary)
                        .lineLimit(1)

                    if workout.isSyncedFromHealth {
                        HStack(spacing: 3) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(.red)
                            Text("HEALTH")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(CyberTheme.textMuted)
                        }
                        .lineLimit(1)
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
            }

            Spacer(minLength: 4)

            // Afterburn Badge (2-line centered badge in front of calories)
            if workout.afterburnBonus > 0 {
                VStack(spacing: 1.5) {
                    Text("+\(Int(workout.afterburnBonus)) KCAL")
                        .font(.system(size: 8.5, weight: .black, design: .monospaced))
                    Text("AFTERBURN 🔥")
                        .font(.system(size: 7.5, weight: .black))
                }
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 6)
                .padding(.vertical, 3.5)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(CyberTheme.blackBorder)
                            .offset(x: 1.5, y: 1.5)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(CyberTheme.neonOrange)

                        RoundedRectangle(cornerRadius: 6)
                            .stroke(CyberTheme.blackBorder, lineWidth: 1)
                    }
                )
                .fixedSize(horizontal: true, vertical: false)
            }

            // Calories & Category Tag
            VStack(alignment: .trailing, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(Int(workout.caloriesBurned))")
                        .font(.system(size: 17, weight: .black))
                        .tracking(-0.3)
                        .foregroundStyle(CyberTheme.neonYellow)
                        .lineLimit(1)

                    Text("kcal")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(CyberTheme.neonYellow.opacity(0.8))
                        .lineLimit(1)
                }
                .fixedSize(horizontal: true, vertical: false)

                Text(meta.category.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(CyberTheme.textMuted)
                    .lineLimit(1)
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .padding(14)
        .neoBox(cornerRadius: 16)
        .contextMenu {
            Button(role: .destructive) {
                deleteWorkout(workout)
            } label: {
                Label("Delete Workout", systemImage: "trash")
            }
        }
    }

    // MARK: - 5. Sync Footer

    private var syncFooter: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(CyberTheme.textMuted)

            if let syncDate = healthKitManager.lastSyncDate {
                Text("Last Synced: \(syncDate.formatted(date: .abbreviated, time: .shortened))")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(CyberTheme.textMuted)
            } else if let message = healthKitManager.lastSyncMessage, !message.hasPrefix("❌") {
                Text(message)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(CyberTheme.textMuted)
            } else {
                Text("Ready to sync with Apple Health")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(CyberTheme.textMuted)
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Helpers

    private func deleteWorkout(_ workout: Workout) {
        modelContext.delete(workout)
        try? modelContext.save()
    }

    private func workoutMetadata(for type: String) -> (emoji: String, title: String, category: String) {
        switch type {
        case "Koşu", "Run":
            return ("🏃", "Run", "CARDIO")
        case "Ağırlık", "Weight":
            return ("🏋️", "Weight", "STRENGTH")
        case "Bisiklet", "Bicycle", "Cycling":
            return ("🚴", "Bicycle", "ENDURANCE")
        case "Yüzme", "Swim", "Swimming":
            return ("🏊", "Swim", "CARDIO")
        case "HIIT":
            return ("⚡️", "HIIT", "INTERVAL")
        case "Yoga":
            return ("🧘", "Yoga", "FLEXIBILITY")
        case "Yürüyüş", "Walk", "Walking":
            return ("🚶", "Walk", "CARDIO")
        case "Kürek", "Rowing":
            return ("🚣", "Rowing", "ENDURANCE")
        case "Eliptik", "Elliptical":
            return ("🔄", "Elliptical", "CARDIO")
        default:
            return ("💪", type, "FITNESS")
        }
    }
}

// MARK: - Preview

#Preview {
    WorkoutsView()
        .modelContainer(for: [Workout.self, TreatItem.self, TreatLog.self, UserGamificationState.self, WeekRecord.self, BadgeRecord.self], inMemory: true)
        .environment(HealthKitManager())
        .preferredColorScheme(.dark)
}
