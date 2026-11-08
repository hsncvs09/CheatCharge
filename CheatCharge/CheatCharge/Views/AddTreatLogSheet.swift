//
//  AddTreatLogSheet.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 24.09.2026.
//

import SwiftUI
import SwiftData

/// Neobrutalist Add Cheat Log Modal Sheet.
///
/// Implements Stitch "ka_amak_ekle_dark_neobrutalism":
/// - Header with Cancel button and coral-pulsing "ADD CHEAT" title.
/// - Cheat Type selector card with preview, category pill, and template chips.
/// - Spent Calorie display with "- KCAL" badge.
/// - Fuel Balance Effect estimation card with real-time balance deduction preview,
///   sufficient balance / deficit risk pills, and segmented progress indicator.
/// - Date & Time picker card constrained to current week.
/// - Sticky bottom Neobrutalist CTA: "SAVE THE CHEAT →".
struct AddTreatLogSheet: View {

    // MARK: - Dependencies

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \TreatItem.name) private var treatItems: [TreatItem]
    @Query private var allWorkouts: [Workout]
    @Query private var allTreatLogs: [TreatLog]
    @Query private var gamificationStates: [UserGamificationState]

    // MARK: - State

    @State private var selectedItem: TreatItem?
    @State private var date: Date = Date()
    @State private var showCreateTemplate = false

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

    private var currentLiveBalance: Double {
        WeekRolloverCalculator.liveBalance(
            earned: earnedCalories,
            spent: spentCalories,
            rollover: rolloverBalance
        )
    }

    private var selectedCalories: Double {
        selectedItem?.calories ?? 0
    }

    private var estimatedRemainingBalance: Double {
        currentLiveBalance - selectedCalories
    }

    private var isSufficientBalance: Bool {
        estimatedRemainingBalance >= 0
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                CyberTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Modal Header
                    modalHeader

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            // Section 1: Cheat Type
                            cheatTypeSection

                            // Section 2: Spent Calorie
                            spentCalorieSection

                            // Section 3: Estimation (Fuel Balance Effect)
                            estimationSection

                            // Section 4: Date & Time
                            dateTimeSection

                            Spacer(minLength: 24)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                    }

                    // Sticky Bottom CTA Button
                    bottomActionFooter
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                if selectedItem == nil, let first = treatItems.first {
                    selectedItem = first
                }
            }
            .sheet(isPresented: $showCreateTemplate) {
                AddTreatItemSheet()
            }
        }
    }

    // MARK: - 1. Modal Header

    private var modalHeader: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Color.white.opacity(0.7))

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(CyberTheme.neonCoral)
                    .frame(width: 8, height: 8)
                    .shadow(color: CyberTheme.neonCoral, radius: 4)

                Text("ADD CHEAT")
                    .font(.system(size: 15, weight: .black))
                    .tracking(0.6)
                    .foregroundStyle(Color.white)
            }

            Spacer()

            // Invisible placeholder for symmetry
            Text("Cancel")
                .font(.system(size: 14, weight: .semibold))
                .opacity(0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(CyberTheme.surfaceContainer)
        .overlay(
            Rectangle()
                .frame(height: 1.5)
                .foregroundStyle(Color.white.opacity(0.12)),
            alignment: .bottom
        )
    }

    // MARK: - 2. Cheat Type Section

    private var cheatTypeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("CHEAT TYPE")
                    .font(.system(size: 11, weight: .black))
                    .tracking(0.8)
                    .foregroundStyle(CyberTheme.textSecondary)

                Spacer()

                Button {
                    showCreateTemplate = true
                } label: {
                    Text("+ NEW TEMPLATE")
                        .font(.system(size: 10, weight: .black))
                        .tracking(0.5)
                        .foregroundStyle(CyberTheme.neonCoral)
                }
            }
            .padding(.horizontal, 2)

            VStack(spacing: 12) {
                if treatItems.isEmpty {
                    VStack(spacing: 8) {
                        Text("No cheat templates available yet.")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.white)
                        Button("Create First Template") {
                            showCreateTemplate = true
                        }
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(CyberTheme.neonCoral)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                } else {
                    // Selected Preview Row
                    HStack {
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(CyberTheme.neonCoral.opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(CyberTheme.neonCoral, lineWidth: 1.5)
                                    )
                                Text(selectedItem?.icon ?? "🍽️")
                                    .font(.system(size: 20))
                            }
                            .frame(width: 40, height: 40)

                            Text(selectedItem?.name ?? "Select Cheat")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color.white)
                        }

                        Spacer()

                        // Category Pill
                        if let category = selectedItem?.category {
                            Text(category.displayName.uppercased())
                                .font(.system(size: 10, weight: .black))
                                .tracking(0.5)
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(hex: "#222634"))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                                        )
                                )
                        }
                    }

                    Divider()
                        .overlay(Color.white.opacity(0.15))

                    // Cheat Items Grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                        ForEach(treatItems) { item in
                            let isSelected = selectedItem?.id == item.id
                            Button {
                                selectedItem = item
                            } label: {
                                VStack(spacing: 4) {
                                    Text(item.icon)
                                        .font(.system(size: 18))
                                    Text(item.name)
                                        .font(.system(size: 10, weight: .bold))
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .foregroundStyle(isSelected ? CyberTheme.blackBorder : Color.white)
                                .background(
                                    NeoBoxBackground(
                                        backgroundColor: isSelected ? CyberTheme.neonCoral : Color(hex: "#202430"),
                                        borderColor: isSelected ? CyberTheme.blackBorder : Color.white.opacity(0.2),
                                        borderWidth: isSelected ? 2.0 : 1.0,
                                        cornerRadius: 10,
                                        shadowColor: CyberTheme.blackBorder,
                                        shadowOffset: isSelected ? CyberTheme.shadowOffsetSm : 0
                                    )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(14)
            .neoBox(cornerRadius: 16)
        }
    }

    // MARK: - 3. Spent Calorie Section

    private var spentCalorieSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("SPENT CALORIE")
                    .font(.system(size: 11, weight: .black))
                    .tracking(0.8)
                    .foregroundStyle(CyberTheme.textSecondary)

                Spacer()

                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 9))
                    Text("CHEAT EXPENSE")
                        .font(.system(size: 10, weight: .black))
                        .tracking(0.5)
                }
                .foregroundStyle(CyberTheme.neonCoral)
            }
            .padding(.horizontal, 2)

            HStack {
                // Calorie Amount
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(selectedCalories))")
                        .font(.system(size: 34, weight: .black))
                        .tracking(-0.5)
                        .foregroundStyle(Color.white)

                    Text("kcal")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(CyberTheme.neonCoral)
                }

                Spacer()

                // - KCAL Badge
                Text("− KCAL")
                    .font(.system(size: 12, weight: .black))
                    .tracking(0.6)
                    .foregroundStyle(CyberTheme.neonCoral)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "#251720"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(CyberTheme.neonCoral, lineWidth: 1.8)
                            )
                    )
            }
            .padding(14)
            .neoBox(cornerRadius: 16)
        }
    }

    // MARK: - 4. Estimation (Fuel Balance Effect) Section

    private var estimationSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ESTIMATION")
                .font(.system(size: 11, weight: .black))
                .tracking(0.8)
                .foregroundStyle(CyberTheme.textSecondary)
                .padding(.horizontal, 2)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("FUEL BALANCE EFFECT")
                            .font(.system(size: 10, weight: .black))
                            .tracking(0.6)
                            .foregroundStyle(CyberTheme.textSecondary)

                        HStack(spacing: 6) {
                            Text("\(Int(currentLiveBalance)) kcal")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(CyberTheme.textSecondary)
                                .strikethrough(true, color: CyberTheme.textMuted)

                            Text("➔")
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(Color.white)

                            Text("\(Int(estimatedRemainingBalance)) kcal")
                                .font(.system(size: 16, weight: .black))
                                .foregroundStyle(isSufficientBalance ? CyberTheme.neonVolt : CyberTheme.neonCoral)

                            Text("left")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(CyberTheme.textSecondary)
                        }
                    }

                    Spacer()

                    // Sufficient Balance or Deficit Risk Badge
                    Text(isSufficientBalance ? "✓ SUFFICIENT BALANCE" : "⚠ DEFICIT RISK")
                        .font(.system(size: 10, weight: .black))
                        .tracking(0.5)
                        .foregroundStyle(isSufficientBalance ? CyberTheme.neonVolt : CyberTheme.neonCoral)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(isSufficientBalance ? CyberTheme.neonVolt.opacity(0.18) : CyberTheme.neonCoral.opacity(0.18))
                                .overlay(
                                    Capsule().stroke(isSufficientBalance ? CyberTheme.neonVolt : CyberTheme.neonCoral, lineWidth: 1.2)
                                )
                        )
                }

                // Balance Progress Indicator Bar
                GeometryReader { geo in
                    let totalPool = max(1.0, max(currentLiveBalance, selectedCalories))
                    let spentWidth = min(geo.size.width, geo.size.width * CGFloat(selectedCalories / totalPool))
                    let remainWidth = max(0, geo.size.width - spentWidth)

                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(CyberTheme.neonCoral)
                            .frame(width: spentWidth)

                        Rectangle()
                            .fill(isSufficientBalance ? CyberTheme.neonVolt : CyberTheme.neonCoral.opacity(0.4))
                            .frame(width: remainWidth)
                    }
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                }
                .frame(height: 8)

                // Legend
                HStack {
                    Text("● Spent: \(Int(selectedCalories)) kcal")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(CyberTheme.neonCoral)

                    Spacer()

                    Text("● Net Left: \(Int(estimatedRemainingBalance)) kcal")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(isSufficientBalance ? CyberTheme.neonVolt : CyberTheme.neonCoral)
                }
            }
            .padding(14)
            .neoBox(cornerRadius: 16)
        }
    }

    // MARK: - 5. Date & Time Section

    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("DATE & TIME")
                .font(.system(size: 11, weight: .black))
                .tracking(0.8)
                .foregroundStyle(CyberTheme.textSecondary)
                .padding(.horizontal, 2)

            VStack(spacing: 12) {
                HStack {
                    HStack(spacing: 6) {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .rotationEffect(.degrees(45))

                        Text("DATE & TIME")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.white)
                    }

                    Spacer()

                    DatePicker(
                        "",
                        selection: $date,
                        in: WeekHelper.currentWeekStart()...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                    .colorScheme(.dark)
                }

                Divider()
                    .overlay(Color.white.opacity(0.15))

                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(CyberTheme.neonCoral)

                    Text("Only cheats from the current week can be added retroactively.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(CyberTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .neoBox(cornerRadius: 16)
        }
    }

    // MARK: - 6. Bottom Action Footer

    private var bottomActionFooter: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(Color.white.opacity(0.12))

            Button {
                saveCheat()
            } label: {
                HStack(spacing: 8) {
                    Text("SAVE THE CHEAT")
                        .font(.system(size: 14, weight: .black))
                        .tracking(0.8)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .black))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(.neoDanger)
            .disabled(selectedItem == nil)
            .opacity(selectedItem != nil ? 1.0 : 0.45)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .background(CyberTheme.surfaceContainer)
    }

    // MARK: - Actions

    private func saveCheat() {
        guard let item = selectedItem else { return }
        let log = TreatLog(treat: item, date: date)
        modelContext.insert(log)
        try? modelContext.save()
        _ = try? BadgeEvaluator.evaluate(context: modelContext)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    AddTreatLogSheet()
        .modelContainer(for: [Workout.self, TreatItem.self, TreatLog.self, UserGamificationState.self, WeekRecord.self, BadgeRecord.self], inMemory: true)
        .preferredColorScheme(.dark)
}
