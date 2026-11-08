//
//  ContentView.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 24.09.2026.
//

import SwiftUI

/// App root view with Stitch Dark Neobrutalism Floating Tab Navigation Dock.
struct ContentView: View {

    enum AppTab: Int, CaseIterable, Identifiable {
        case summary = 0
        case charge = 1
        case cheat = 2
        case base = 3
        case wins = 4
        case settings = 5

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .summary: return "SUMMARY"
            case .charge: return "CHARGE"
            case .cheat: return "CHEAT"
            case .base: return "BASE"
            case .wins: return "PROGRESS"
            case .settings: return "SETTINGS"
            }
        }

        var icon: String {
            switch self {
            case .summary: return "chart.bar.fill"
            case .charge: return "flame.fill"
            case .cheat: return "fork.knife"
            case .base: return "square.split.2x2.fill"
            case .wins: return "trophy.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    @State private var selectedTab: AppTab = .summary

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Screen View Switcher
            Group {
                switch selectedTab {
                case .summary:
                    DashboardView()
                case .charge:
                    WorkoutsView()
                case .cheat:
                    TreatsView()
                case .base:
                    AvatarBaseTabView()
                case .wins:
                    AchievementsView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Stitch Neobrutalist Floating Navigation Dock
            floatingTabDock
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .preferredColorScheme(.dark)
    }

    // MARK: - Floating Neobrutalist Tab Dock

    private var floatingTabDock: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { tab in
                let isSelected = selectedTab == tab

                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.icon)
                            .font(.system(size: isSelected ? 17 : 16, weight: isSelected ? .black : .bold))

                        Text(tab.title)
                            .font(.system(size: 8.5, weight: isSelected ? .black : .heavy))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .tracking(0.4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        ZStack {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black)
                                    .offset(x: 2, y: 2)

                                RoundedRectangle(cornerRadius: 12)
                                    .fill(CyberTheme.neonVolt)

                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black, lineWidth: 1.5)
                            }
                        }
                    )
                    .foregroundStyle(isSelected ? Color.black : Color.white.opacity(0.6))
                    .offset(y: isSelected ? -2 : 0)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black)
                    .offset(x: 4, y: 4)

                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "#18181c"))

                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white, lineWidth: 2)
            }
        )
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Workout.self, TreatItem.self, TreatLog.self, UserGamificationState.self, WeekRecord.self, BadgeRecord.self], inMemory: true)
        .environment(HealthKitManager())
        .environment(BadgeUnlockCenter())
}
