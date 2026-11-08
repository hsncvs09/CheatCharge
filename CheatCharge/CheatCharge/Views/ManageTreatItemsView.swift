//
//  ManageTreatItemsView.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 24.09.2026.
//

import SwiftUI
import SwiftData

/// Neobrutalist Manage Cheat Templates Screen.
///
/// Displays existing cheat item templates with deletion and creation capabilities.
struct ManageTreatItemsView: View {

    // MARK: - Dependencies

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \TreatItem.name) private var treatItems: [TreatItem]
    @State private var showAddItem = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                NeoDotBackground()

                VStack(spacing: 0) {
                    // Top Bar
                    topBar

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            if treatItems.isEmpty {
                                emptyState
                            } else {
                                templatesList
                            }

                            Spacer(minLength: 32)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddItem) {
                AddTreatItemSheet()
            }
        }
    }

    // MARK: - 1. Top Bar

    private var topBar: some View {
        HStack {
            Button("Done") {
                dismiss()
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                NeoBoxBackground(
                    backgroundColor: CyberTheme.surface,
                    borderColor: Color.white.opacity(0.3),
                    borderWidth: 1.5,
                    cornerRadius: 10,
                    shadowColor: CyberTheme.blackBorder,
                    shadowOffset: CyberTheme.shadowOffsetSm
                )
            )

            Spacer()

            Text("TEMPLATES")
                .font(.system(size: 16, weight: .black))
                .tracking(0.8)
                .foregroundStyle(Color.white)

            Spacer()

            Button {
                showAddItem = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .black))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.neoDanger)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(CyberTheme.surfaceContainer)
        .overlay(
            Rectangle()
                .frame(height: 1.5)
                .foregroundStyle(Color.white.opacity(0.12)),
            alignment: .bottom
        )
    }

    // MARK: - 2. Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(CyberTheme.surface)
                    .frame(width: 64, height: 64)
                    .overlay(Circle().stroke(CyberTheme.cardBorder, lineWidth: 2))
                Image(systemName: "fork.knife")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(CyberTheme.neonCoral)
            }
            .padding(.top, 16)

            Text("NO TEMPLATES YET")
                .font(.system(size: 14, weight: .black))
                .tracking(0.6)
                .foregroundStyle(Color.white)

            Text("Tap the + button above to create your favorite cheat templates.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(CyberTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .neoBox(cornerRadius: 18)
    }

    // MARK: - 3. Templates List

    private var templatesList: some View {
        VStack(spacing: 10) {
            ForEach(treatItems) { item in
                templateCard(item)
            }
        }
    }

    private func templateCard(_ item: TreatItem) -> some View {
        HStack(spacing: 12) {
            // Icon Box
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "#23232a"))
                RoundedRectangle(cornerRadius: 10)
                    .stroke(CyberTheme.blackBorder, lineWidth: 1.5)
                Text(item.icon)
                    .font(.system(size: 20))
            }
            .frame(width: 44, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(CyberTheme.blackBorder)
                    .offset(x: 1.5, y: 1.5)
            )

            // Name & Category
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.white)

                Text(item.category.displayName.uppercased())
                    .font(.system(size: 9, weight: .black))
                    .tracking(0.6)
                    .foregroundStyle(CyberTheme.textMuted)
            }

            Spacer()

            // Calorie Value
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(Int(item.calories))")
                    .font(.system(size: 17, weight: .black))
                    .tracking(-0.3)
                    .foregroundStyle(CyberTheme.neonCoral)

                Text("kcal")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(CyberTheme.neonCoral.opacity(0.8))
            }
        }
        .padding(14)
        .neoBox(cornerRadius: 16)
        .contextMenu {
            Button(role: .destructive) {
                deleteItem(item)
            } label: {
                Label("Delete Template", systemImage: "trash")
            }
        }
    }

    // MARK: - Actions

    private func deleteItem(_ item: TreatItem) {
        modelContext.delete(item)
        try? modelContext.save()
    }
}

// MARK: - Preview

#Preview {
    ManageTreatItemsView()
        .modelContainer(for: [TreatItem.self, TreatLog.self], inMemory: true)
        .preferredColorScheme(.dark)
}
