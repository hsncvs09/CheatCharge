//
//  TreatsView.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 24.09.2026.
//

import SwiftUI
import SwiftData

/// Neobrutalist Cheats (Treats) Screen.
///
/// Implements Dark Neobrutalism aesthetics consistent with Charges/Workouts:
/// - Top bar with "CHEATS", template manager slider button, and Neon Coral "+" button.
/// - Weekly Summary Banner with cheat count pill and total cheated calories.
/// - Cheat item cards featuring brutalist square frames and neon coral calorie expenses.
struct TreatsView: View {

    // MARK: - Dependencies

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TreatLog.date, order: .reverse) private var allTreatLogs: [TreatLog]

    @State private var showAddLog = false
    @State private var showManageTemplates = false

    // MARK: - Calculations

    private var weeklyLogs: [TreatLog] {
        allTreatLogs.filter { WeekHelper.isInCurrentWeek($0.date) }
    }

    private var totalSpent: Double {
        weeklyLogs.compactMap { $0.treat?.calories }.reduce(0, +)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Dark Dot Grid Background
                NeoDotBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Top Header (CHEATS & Actions)
                        topHeader

                        // Weekly Summary Banner
                        weeklySummaryBanner

                        // Cheats Cards List or Empty State
                        if weeklyLogs.isEmpty {
                            emptyState
                        } else {
                            cheatsCardsList
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddLog) {
                AddTreatLogSheet()
            }
            .sheet(isPresented: $showManageTemplates) {
                ManageTreatItemsView()
            }
        }
    }

    // MARK: - 1. Top Header

    private var topHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("CHEATS")
                    .font(.system(size: 28, weight: .black))
                    .tracking(-0.5)
                    .foregroundStyle(Color.white)
            }

            Spacer()

            // Header Action Buttons
            HStack(spacing: 10) {
                // Manage Templates Button (Sliders)
                Button {
                    showManageTemplates = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.neoSecondary)

                // Add Cheat Button (Coral Plus)
                Button {
                    showAddLog = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .black))
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.neoDanger)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - 2. Weekly Summary Banner

    private var weeklySummaryBanner: some View {
        HStack(alignment: .bottom) {
            // Left: Period & Cheats Count
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text("THIS WEEK")
                        .font(.system(size: 11, weight: .black))
                        .tracking(0.8)
                        .foregroundStyle(CyberTheme.textSecondary)

                    Circle()
                        .fill(CyberTheme.neonCoral)
                        .frame(width: 6, height: 6)
                        .shadow(color: CyberTheme.neonCoral, radius: 3)
                }

                HStack(spacing: 4) {
                    Text("👆")
                        .font(.system(size: 10))
                    Text("\(weeklyLogs.count) CHEAT\(weeklyLogs.count == 1 ? "" : "S")")
                        .font(.system(size: 10, weight: .black))
                        .tracking(0.5)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .foregroundStyle(CyberTheme.neonCoral)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "#24242b"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(CyberTheme.neonCoral.opacity(0.6), lineWidth: 1.5)
                        )
                )
            }

            Spacer()

            // Right: Total Cheated Energy
            VStack(alignment: .trailing, spacing: 2) {
                Text("TOTAL CHEATED")
                    .font(.system(size: 10, weight: .black))
                    .tracking(0.8)
                    .foregroundStyle(CyberTheme.textSecondary)

                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("-\(Int(totalSpent))")
                        .font(.system(size: 22, weight: .black))
                        .tracking(-0.5)
                        .foregroundStyle(CyberTheme.neonCoral)

                    Text("KCAL")
                        .font(.system(size: 10, weight: .black))
                        .tracking(0.5)
                        .foregroundStyle(CyberTheme.neonCoral.opacity(0.8))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(CyberTheme.neonCoral.opacity(0.4), lineWidth: 1)
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
                Image(systemName: "fork.knife")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(CyberTheme.neonCoral)
            }
            .padding(.top, 12)

            Text("NO CHEATS THIS WEEK")
                .font(.system(size: 14, weight: .black))
                .tracking(0.6)
                .foregroundStyle(Color.white)

            Text("Fuel balance is completely pure! Charge up with workouts to earn your favorite treats.")
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

    // MARK: - 4. Cheats Cards List

    private var cheatsCardsList: some View {
        VStack(spacing: 12) {
            ForEach(weeklyLogs) { log in
                cheatCard(log)
            }
        }
    }

    private func cheatCard(_ log: TreatLog) -> some View {
        let calories = log.treat?.calories ?? 0
        let categoryName = log.treat?.category.displayName ?? "Cheat"

        return HStack(spacing: 12) {
            // Icon Frame (Square Neobrutalist Box)
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "#23232a"))
                RoundedRectangle(cornerRadius: 12)
                    .stroke(CyberTheme.blackBorder, lineWidth: 2)
                Text(log.treat?.icon ?? "🍽️")
                    .font(.system(size: 22))
            }
            .frame(width: 48, height: 48)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CyberTheme.blackBorder)
                    .offset(x: 2, y: 2)
            )

            // Title, Category & Date
            VStack(alignment: .leading, spacing: 4) {
                Text(log.treat?.name ?? "Unknown Cheat")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(Color.white)

                HStack(spacing: 6) {
                    Text(log.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(CyberTheme.textSecondary)

                    Text("•")
                        .font(.system(size: 10))
                        .foregroundStyle(CyberTheme.textMuted)

                    Text(categoryName.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .tracking(0.5)
                        .foregroundStyle(CyberTheme.neonCoral.opacity(0.8))
                }
            }

            Spacer()

            // Calories Spent
            VStack(alignment: .trailing, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("-\(Int(calories))")
                        .font(.system(size: 17, weight: .black))
                        .tracking(-0.3)
                        .foregroundStyle(CyberTheme.neonCoral)

                    Text("kcal")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(CyberTheme.neonCoral.opacity(0.8))
                }

                Text("EXPENSE")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(CyberTheme.textMuted)
            }
        }
        .padding(14)
        .neoBox(cornerRadius: 16)
        .contextMenu {
            Button(role: .destructive) {
                deleteLog(log)
            } label: {
                Label("Delete Cheat Log", systemImage: "trash")
            }
        }
    }

    // MARK: - Helpers

    private func deleteLog(_ log: TreatLog) {
        modelContext.delete(log)
        try? modelContext.save()
    }
}

// MARK: - Preview

#Preview {
    TreatsView()
        .modelContainer(for: [Workout.self, TreatItem.self, TreatLog.self, UserGamificationState.self, WeekRecord.self, BadgeRecord.self], inMemory: true)
        .preferredColorScheme(.dark)
}
