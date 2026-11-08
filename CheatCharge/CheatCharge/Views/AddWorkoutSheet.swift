//
//  AddWorkoutSheet.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 24.09.2026.
//

import SwiftUI
import SwiftData

/// Neobrutalist Add Workout (Add Charge) Modal Sheet.
///
/// Implements Stitch "antrenman_ekle_dark_neobrutalism":
/// - Header with Cancel button and green-pulsing "ADD CHARGE" title.
/// - Workout type selection card with dropdown menu and 4 quick chips (Run, Weight, Bicycle, Swim).
/// - Burned calorie card with large numerical input and "🔥 KCAL" active fuel badge.
/// - Dynamic Afterburn (+20%) calculation preview for resistance/weight training.
/// - Date & Time card constrained to current week.
/// - Sticky bottom Neobrutalist CTA: "SAVE THE WORKOUT →".
struct AddWorkoutSheet: View {

    // MARK: - Dependencies

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var selectedType: String = "Run"
    @State private var caloriesText: String = ""
    @State private var date: Date = Date()

    private let primaryWorkoutTypes = ["Run", "Weight", "Bicycle", "Swim"]
    private let allWorkoutTypes = [
        "Run", "Weight", "Bicycle", "Swim", "HIIT", "Yoga", "Walk", "Rowing", "Elliptical", "Other"
    ]

    // MARK: - Calculations

    private var rawCalories: Double? {
        guard let cal = Double(caloriesText.replacingOccurrences(of: ",", with: ".")), cal > 0 else { return nil }
        return cal
    }

    private var isValid: Bool { rawCalories != nil }

    private var multiplier: Double { Workout.multiplier(forType: selectedType) }

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
                            // Section 1: Workout Type
                            workoutTypeSection

                            // Section 2: Burned Calorie
                            burnedCalorieSection

                            // Section 3: Date & Time
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
                    .fill(CyberTheme.neonVolt)
                    .frame(width: 8, height: 8)
                    .shadow(color: CyberTheme.neonVolt, radius: 4)

                Text("ADD CHARGE")
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

    // MARK: - 2. Workout Type Section

    private var workoutTypeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("WORKOUT TYPE")
                .font(.system(size: 11, weight: .black))
                .tracking(0.8)
                .foregroundStyle(CyberTheme.textSecondary)
                .padding(.horizontal, 2)

            VStack(spacing: 12) {
                // Top Row: Active Workout Name + Dropdown Picker
                HStack {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(CyberTheme.neonVolt.opacity(0.12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(CyberTheme.neonVolt.opacity(0.4), lineWidth: 1)
                                )
                            Text(workoutEmoji(for: selectedType))
                                .font(.system(size: 18))
                        }
                        .frame(width: 36, height: 36)

                        Text(workoutDisplayName(for: selectedType))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.white)
                    }

                    Spacer()

                    // Menu Picker Pill
                    Menu {
                        ForEach(allWorkoutTypes, id: \.self) { type in
                            Button {
                                selectedType = type
                            } label: {
                                HStack {
                                    Text("\(workoutEmoji(for: type)) \(type)")
                                    if selectedType == type {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedType)
                                .font(.system(size: 12, weight: .bold))
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(CyberTheme.neonVolt)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(hex: "#24242b"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                                )
                        )
                    }
                }

                Divider()
                    .overlay(Color.white.opacity(0.15))

                // Quick Select Chips (Run, Weight, Bicycle, Swim)
                HStack(spacing: 8) {
                    ForEach(primaryWorkoutTypes, id: \.self) { type in
                        let isSelected = selectedType == type
                        Button {
                            selectedType = type
                        } label: {
                            VStack(spacing: 3) {
                                Text(workoutEmoji(for: type))
                                    .font(.system(size: 16))
                                Text(type)
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .foregroundStyle(isSelected ? CyberTheme.blackBorder : Color.white)
                            .background(
                                NeoBoxBackground(
                                    backgroundColor: isSelected ? CyberTheme.neonVolt : Color(hex: "#24242b"),
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
            .padding(14)
            .neoBox(cornerRadius: 16)
        }
    }

    // MARK: - 3. Burned Calorie Section

    private var burnedCalorieSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("BURNED CALORIE")
                    .font(.system(size: 11, weight: .black))
                    .tracking(0.8)
                    .foregroundStyle(CyberTheme.textSecondary)

                Spacer()

                HStack(spacing: 3) {
                    Text("🔥")
                        .font(.system(size: 10))
                    Text("ACTIVE FUEL")
                        .font(.system(size: 10, weight: .black))
                        .tracking(0.5)
                        .foregroundStyle(CyberTheme.neonOrange)
                }
            }
            .padding(.horizontal, 2)

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // Numerical Input
                    TextField("0", text: $caloriesText)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 34, weight: .black))
                        .tracking(-0.5)
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)

                    // KCAL Badge
                    HStack(spacing: 4) {
                        Text("🔥")
                            .font(.system(size: 12))
                        Text("KCAL")
                            .font(.system(size: 13, weight: .black))
                            .tracking(0.6)
                            .foregroundStyle(CyberTheme.neonOrange)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(CyberTheme.neonOrange.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(CyberTheme.neonOrange, lineWidth: 1.8)
                            )
                    )
                }

                // Afterburn Bonus Calculation (if Weight/Ağırlık)
                if multiplier > 1.0 {
                    Divider()
                        .overlay(Color.white.opacity(0.15))

                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(CyberTheme.neonOrange)

                        if let raw = rawCalories {
                            let bonus = raw * (multiplier - 1.0)
                            Text("\(Int(raw)) kcal + \(Int(bonus)) kcal Afterburn 🔥 = \(Int(raw + bonus)) kcal total")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(CyberTheme.neonOrange)
                        } else {
                            Text("+20% Afterburn (EPOC) automatically applied for resistance workouts.")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(CyberTheme.neonOrange)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(14)
            .neoBox(cornerRadius: 16)
        }
    }

    // MARK: - 4. Date & Time Section

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
                        .foregroundStyle(CyberTheme.neonVolt)

                    Text("Only workouts from the current week can be added retroactively.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(CyberTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .neoBox(cornerRadius: 16)
        }
    }

    // MARK: - 5. Bottom Action Footer

    private var bottomActionFooter: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(Color.white.opacity(0.12))

            Button {
                saveWorkout()
            } label: {
                HStack(spacing: 8) {
                    Text("SAVE THE WORKOUT")
                        .font(.system(size: 14, weight: .black))
                        .tracking(0.8)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .black))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(.neoPrimary)
            .disabled(!isValid)
            .opacity(isValid ? 1.0 : 0.45)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .background(CyberTheme.surfaceContainer)
    }

    // MARK: - Actions

    private func saveWorkout() {
        guard let raw = rawCalories else { return }
        let workout = Workout(
            type: selectedType,
            rawCalories: raw,
            date: date,
            isSyncedFromHealth: false
        )
        modelContext.insert(workout)
        try? modelContext.save()
        _ = try? BadgeEvaluator.evaluate(context: modelContext)
        dismiss()
    }

    private func workoutEmoji(for type: String) -> String {
        switch type {
        case "Run", "Koşu": return "🏃"
        case "Weight", "Ağırlık": return "🏋️"
        case "Bicycle", "Bisiklet": return "🚴"
        case "Swim", "Yüzme": return "🏊"
        case "HIIT": return "⚡️"
        case "Yoga": return "🧘"
        case "Walk", "Yürüyüş": return "🚶"
        case "Rowing", "Kürek": return "🚣"
        case "Elliptical", "Eliptik": return "🔄"
        default: return "💪"
        }
    }

    private func workoutDisplayName(for type: String) -> String {
        switch type {
        case "Run", "Koşu": return "Outdoor Running"
        case "Weight", "Ağırlık": return "Weight Training"
        case "Bicycle", "Bisiklet": return "Cycling"
        case "Swim", "Yüzme": return "Swimming"
        case "HIIT": return "HIIT Interval"
        case "Yoga": return "Yoga & Mobility"
        case "Walk", "Yürüyüş": return "Brisk Walk"
        case "Rowing", "Kürek": return "Rowing"
        case "Elliptical", "Eliptik": return "Elliptical"
        default: return type
        }
    }
}

// MARK: - Preview

#Preview {
    AddWorkoutSheet()
        .modelContainer(for: [Workout.self, TreatItem.self, TreatLog.self, UserGamificationState.self, WeekRecord.self, BadgeRecord.self], inMemory: true)
        .preferredColorScheme(.dark)
}
