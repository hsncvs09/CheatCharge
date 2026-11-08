//
//  AddTreatItemSheet.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 24.09.2026.
//

import SwiftUI
import SwiftData

/// Neobrutalist New Cheat Template Modal Sheet.
///
/// Implements Stitch "add_cheat_template_dark_neobrutalism":
/// - Header with Cancel button and coral-pulsing "NEW TEMPLATE" title.
/// - Category selector with dropdown menu and dual chevrons indicator.
/// - 6-column emoji picker grid with active neon coral highlight.
/// - Cheat Name text field ("e.g. Homemade Smash Burger").
/// - Calorie Value input with "kcal" badge.
/// - Full-width high-impact Neobrutalist button: "SAVE CHEAT TEMPLATE →".
struct AddTreatItemSheet: View {

    // MARK: - Dependencies

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var name: String = ""
    @State private var caloriesText: String = "600"
    @State private var selectedEmoji: String = "🍽️"
    @State private var selectedCategory: TreatCategory = .other

    private let emojiOptions = [
        "🍔", "🍕", "🍗", "🍟", "🌯", "🍿",
        "🍺", "🍷", "🥃", "💧", "🍸", "🥤",
        "🍩", "🍰", "🍦", "🍫", "🤤", "🍽️"
    ]

    // MARK: - Calculations

    private var isValid: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let cal = Double(caloriesText), cal > 0 else { return false }
        return true
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
                            // Section 1: Category
                            categorySection

                            // Section 2: Icon Picker
                            iconPickerSection

                            // Section 3: Cheat Name
                            cheatNameSection

                            // Section 4: Calorie Value
                            calorieValueSection

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
                    .fill(CyberTheme.neonCoral)
                    .frame(width: 8, height: 8)
                    .shadow(color: CyberTheme.neonCoral, radius: 4)

                Text("NEW TEMPLATE")
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

    // MARK: - 2. Category Section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CATEGORY")
                .font(.system(size: 11, weight: .black))
                .tracking(0.8)
                .foregroundStyle(CyberTheme.textSecondary)
                .padding(.horizontal, 2)

            Menu {
                ForEach(TreatCategory.allCases) { category in
                    Button {
                        selectedCategory = category
                        selectedEmoji = category.defaultIcon
                    } label: {
                        HStack {
                            Text("\(category.defaultIcon) \(category.displayName)")
                            if selectedCategory == category {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text("CATEGORY")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(CyberTheme.textSecondary)

                    Spacer()

                    HStack(spacing: 6) {
                        HStack(spacing: 5) {
                            Text(selectedCategory.defaultIcon)
                                .font(.system(size: 14))
                            Text(selectedCategory.displayName)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "#222634"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                                )
                        )

                        // Dual Chevrons Box
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(CyberTheme.neonCoral)
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(CyberTheme.blackBorder, lineWidth: 1.5)
                            Text("⇅")
                                .font(.system(size: 13, weight: .black))
                                .foregroundStyle(Color.white)
                        }
                        .frame(width: 28, height: 28)
                    }
                }
                .padding(14)
                .neoBox(cornerRadius: 16)
            }
        }
    }

    // MARK: - 3. Icon Picker Section

    private var iconPickerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SELECT ICON")
                .font(.system(size: 11, weight: .black))
                .tracking(0.8)
                .foregroundStyle(CyberTheme.textSecondary)
                .padding(.horizontal, 2)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                ForEach(emojiOptions, id: \.self) { emoji in
                    let isSelected = selectedEmoji == emoji
                    Button {
                        selectedEmoji = emoji
                    } label: {
                        Text(emoji)
                            .font(.system(size: 20))
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isSelected ? CyberTheme.neonCoral.opacity(0.25) : Color(hex: "#202430"))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(isSelected ? CyberTheme.neonCoral : Color.white.opacity(0.12), lineWidth: isSelected ? 2 : 1)
                                    )
                                    .scaleEffect(isSelected ? 1.05 : 1.0)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .neoBox(cornerRadius: 16)
        }
    }

    // MARK: - 4. Cheat Name Section

    private var cheatNameSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CHEAT NAME")
                .font(.system(size: 11, weight: .black))
                .tracking(0.8)
                .foregroundStyle(CyberTheme.textSecondary)
                .padding(.horizontal, 2)

            HStack {
                TextField("e.g. Homemade Smash Burger", text: $name)
                    .autocorrectionDisabled()
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.white)
            }
            .padding(14)
            .neoBox(cornerRadius: 16)
        }
    }

    // MARK: - 5. Calorie Value Section

    private var calorieValueSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("CALORIE VALUE")
                    .font(.system(size: 11, weight: .black))
                    .tracking(0.8)
                    .foregroundStyle(CyberTheme.textSecondary)

                Spacer()

                Text("ESTIMATED ENERGY")
                    .font(.system(size: 10, weight: .black))
                    .tracking(0.5)
                    .foregroundStyle(CyberTheme.textMuted)
            }
            .padding(.horizontal, 2)

            HStack {
                TextField("600", text: $caloriesText)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(Color.white)

                Spacer()

                Text("KCAL")
                    .font(.system(size: 12, weight: .black))
                    .tracking(0.6)
                    .foregroundStyle(CyberTheme.neonVolt)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                            )
                    )
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
                saveTemplate()
            } label: {
                HStack(spacing: 8) {
                    Text("SAVE CHEAT TEMPLATE")
                        .font(.system(size: 14, weight: .black))
                        .tracking(0.8)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .black))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(.neoDanger)
            .disabled(!isValid)
            .opacity(isValid ? 1.0 : 0.45)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .background(CyberTheme.surfaceContainer)
    }

    // MARK: - Actions

    private func saveTemplate() {
        guard let cal = Double(caloriesText), cal > 0 else { return }
        let item = TreatItem(
            name: name.trimmingCharacters(in: .whitespaces),
            calories: cal,
            icon: selectedEmoji,
            category: selectedCategory
        )
        modelContext.insert(item)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    AddTreatItemSheet()
        .modelContainer(for: TreatItem.self, inMemory: true)
        .preferredColorScheme(.dark)
}
