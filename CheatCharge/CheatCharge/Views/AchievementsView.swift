//
//  AchievementsView.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 03.10.2026.
//

import SwiftUI
import SwiftData

/// 4. Tab: Achievements, Cumulative Wristband Journey, Badge Gallery, and Weekly History Archive.
/// Redesigned to Stitch Dark Neobrutalism (Kinetic Volt).
struct AchievementsView: View {

    // MARK: - Dependencies

    @Environment(\.modelContext) private var modelContext
    @Query private var gamificationStates: [UserGamificationState]
    @Query(sort: \WeekRecord.weekStartDate, order: .reverse) private var pastWeeks: [WeekRecord]
    @Query(sort: \Workout.date, order: .reverse) private var allWorkouts: [Workout]
    @Query private var allTreatLogs: [TreatLog]

    // MARK: - State

    enum WeekRowStatus {
        case successful
        case unsuccessful
        case upcoming
    }

    enum SectionTab: String, CaseIterable, Identifiable {
        case wristband = "WRISTBANDS"
        case badges = "BADGES"
        case archive = "HISTORY"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .wristband: return "trophy.fill"
            case .badges: return "sparkles"
            case .archive: return "calendar"
            }
        }
    }

    @State private var selectedTab: SectionTab = .wristband
    @State private var selectedBadgeCategory: BadgeCategory? = nil
    @State private var selectedBadgeForDetail: BadgeDefinition? = nil

    // MARK: - Computed Properties

    private var state: UserGamificationState? {
        gamificationStates.first
    }

    private var successfulWeeks: Int {
        state?.totalSuccessfulWeeks ?? 0
    }

    private var currentStreak: Int {
        state?.currentStreak ?? 0
    }

    private var currentTier: WristbandTier {
        WristbandTier.current(for: successfulWeeks)
    }

    private var unlockedBadgeMap: [String: BadgeRecord] {
        guard let badges = state?.unlockedBadges else { return [:] }
        return Dictionary(uniqueKeysWithValues: badges.map { ($0.badgeKey, $0) })
    }

    private var unlockedCount: Int {
        unlockedBadgeMap.count
    }

    private var totalBadgeCount: Int {
        BadgeCatalog.all.count
    }

    private var filteredBadges: [BadgeDefinition] {
        if let cat = selectedBadgeCategory {
            return BadgeCatalog.all.filter { $0.category == cat }
        }
        return BadgeCatalog.all
    }

    private var archivedSuccessfulCount: Int {
        pastWeeks.filter { $0.isSuccessful }.count
    }

    private var successRateString: String {
        guard !pastWeeks.isEmpty else { return "0%" }
        let rate = Int((Double(archivedSuccessfulCount) / Double(pastWeeks.count)) * 100.0)
        return "\(rate)%"
    }

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

                    // Brutalist Segmented Navigation Tabs
                    tabPicker
                        .padding(.horizontal, 16)
                        .padding(.bottom, 14)

                    // Tab Content
                    ScrollView {
                        VStack(spacing: 16) {
                            switch selectedTab {
                            case .wristband:
                                wristbandSection
                            case .badges:
                                badgeSection
                            case .archive:
                                archiveSection
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100) // Clearance for floating tab dock
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedBadgeForDetail) { badge in
                badgeDetailSheet(badge)
            }
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            Text("PROGRESS")
                .font(.system(size: 28, weight: .black, design: .default))
                .italic()
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer()

            // Small Rank Badge
            HStack(spacing: 5) {
                Circle()
                    .fill(currentTier.color)
                    .frame(width: 8, height: 8)
                Text(currentTier.englishTitle.uppercased())
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(hex: "#18181c"))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1.5))
        }
    }

    // MARK: - 1. Segmented Brutalist Tabs

    private var tabPicker: some View {
        HStack(spacing: 4) {
            ForEach(SectionTab.allCases) { tab in
                let isSelected = selectedTab == tab
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 12, weight: .bold))

                        Text(tab.rawValue)
                            .font(.system(size: 11, weight: isSelected ? .black : .bold))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 4)
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
                    .foregroundStyle(isSelected ? Color.black : Color.white.opacity(0.65))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "#1A1A1A"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white, lineWidth: 2)
                )
        )
    }

    // MARK: - 2. Wristband Tab

    private var wristbandSection: some View {
        VStack(spacing: 16) {
            // A. Active Tier Hero Card
            currentTierHeroCard

            // B. Next Milestone Card
            if let nextTier = currentTier.nextTier {
                nextTierProgressCard(nextTier)
            } else {
                maxTierAchievedCard
            }

            // C. 7-Tier Journey Ladder
            allTiersRoadmap
        }
    }

    private var currentTierHeroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(CyberTheme.neonVolt)
                            .frame(width: 6, height: 6)
                        Text("ACTIVE WRISTBAND LEVEL")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(CyberTheme.neonVolt)
                            .tracking(1.2)
                    }

                    Text(currentTier.englishTitle)
                        .font(.system(size: 24, weight: .black))
                        .foregroundStyle(.white)

                    Text(currentTier.englishSubtitle)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.6))
                        .textCase(.uppercase)
                }

                Spacer()

                // Brutalist Concentric Wristband Graphic
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 4)
                        .frame(width: 60, height: 60)

                    Circle()
                        .stroke(
                            currentTier.color.opacity(0.8),
                            style: StrokeStyle(lineWidth: 2, dash: [4, 4])
                        )
                        .frame(width: 50, height: 50)

                    Circle()
                        .fill(currentTier.color)
                        .frame(width: 32, height: 32)
                        .shadow(color: currentTier.glowColor, radius: 8)

                    Circle()
                        .fill(Color(hex: "#0a0a0c"))
                        .frame(width: 14, height: 14)
                }
            }

            Divider()
                .overlay(Color.white.opacity(0.15))

            // Metrics Row
            HStack(spacing: 12) {
                // Metric 1: Success Weeks
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(successfulWeeks)")
                        .font(.system(size: 24, weight: .black, design: .monospaced))
                        .foregroundStyle(.white)
                    Text(successfulWeeks == 1 ? "SUCCESS WEEK" : "SUCCESS WEEKS")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(Color.white.opacity(0.55))
                        .lineLimit(1)
                }

                Divider()
                    .frame(height: 28)
                    .overlay(Color.white.opacity(0.2))

                // Metric 2: Active Streak
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("🔥")
                            .font(.system(size: 16))
                        Text("\(currentStreak)")
                            .font(.system(size: 24, weight: .black, design: .monospaced))
                            .foregroundStyle(.white)
                    }
                    Text("ACTIVE STREAK")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(Color.white.opacity(0.55))
                        .lineLimit(1)
                }

                Spacer(minLength: 6)

                // Status Badge: Permanent
                HStack(spacing: 5) {
                    Circle()
                        .fill(CyberTheme.neonCyan)
                        .frame(width: 5, height: 5)
                    Text("PERMANENT")
                        .font(.system(size: 9.5, weight: .black))
                        .foregroundStyle(CyberTheme.neonCyan)
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(CyberTheme.neonCyan.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(CyberTheme.neonCyan.opacity(0.4), lineWidth: 1.2)
                )
                .fixedSize(horizontal: true, vertical: false)
            }
        }
        .padding(16)
        .neoBox(borderColor: .white, cornerRadius: 20)
    }

    private func nextTierProgressCard(_ nextTier: WristbandTier) -> some View {
        let progress = WristbandTier.progressToNext(for: successfulWeeks)
        let remaining = WristbandTier.weeksRemaining(for: successfulWeeks)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Text("↑")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.black)
                        .frame(width: 24, height: 24)
                        .background(CyberTheme.neonVolt)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 1.5))
                        .shadow(color: .black, radius: 0, x: 2, y: 2)

                    Text("NEXT GOAL: \(nextTier.englishTitle.uppercased())")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.white)
                }

                Spacer()

                Text("\(remaining) WEEK\(remaining == 1 ? "" : "S") LEFT")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(CyberTheme.neonVolt)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(CyberTheme.neonVolt.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(CyberTheme.neonVolt.opacity(0.4), lineWidth: 1))
            }

            // Brutalist Progress Bar
            VStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(hex: "#0a0a0c"))
                            .frame(height: 12)
                            .overlay(Capsule().stroke(Color.white, lineWidth: 2))

                        Capsule()
                            .fill(CyberTheme.neonVolt)
                            .frame(width: max(12, geo.size.width * CGFloat(progress)), height: 10)
                            .padding(.leading, 1)
                            .shadow(color: CyberTheme.neonVolt.opacity(0.8), radius: 4)
                    }
                }
                .frame(height: 12)

                HStack {
                    Text("\(currentTier.requiredWeeks) WEEKS (\(currentTier.englishSubtitle.components(separatedBy: " / ").first?.uppercased() ?? ""))")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.5))

                    Spacer()

                    Text("\(nextTier.requiredWeeks) WEEKS (\(nextTier.englishSubtitle.components(separatedBy: " / ").first?.uppercased() ?? ""))")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.7))
                }
            }
        }
        .padding(16)
        .neoBox(borderColor: .white, cornerRadius: 20)
    }

    private var maxTierAchievedCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "crown.fill")
                .font(.title)
                .foregroundStyle(CyberTheme.neonYellow)

            VStack(alignment: .leading, spacing: 2) {
                Text("CROWN PEAK: UNBEATABLE!")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.white)
                Text("All wristband milestones achieved. You vs. You!")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .neoBox(borderColor: CyberTheme.neonYellow, cornerRadius: 20)
    }

    private var allTiersRoadmap: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("WRISTBAND JOURNEY")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .tracking(1.0)

                Spacer()

                Text("PROGRESSION LADDER")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(Color.white.opacity(0.4))
            }
            .padding(.horizontal, 4)

            VStack(spacing: 8) {
                ForEach(WristbandTier.allCases) { tier in
                    roadmapRow(for: tier)
                }
            }
        }
    }

    private func roadmapRow(for tier: WristbandTier) -> some View {
        let isUnlocked = successfulWeeks >= tier.requiredWeeks
        let isCurrent = tier == currentTier

        return HStack(spacing: 12) {
            // Ring Graphic Token
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "#121215"))
                    .frame(width: 40, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isCurrent ? Color.white : (isUnlocked ? tier.color.opacity(0.6) : Color.white.opacity(0.2)), lineWidth: 1.5)
                    )

                if isUnlocked {
                    Circle()
                        .stroke(tier.color, lineWidth: 2)
                        .frame(width: 20, height: 20)
                    Circle()
                        .fill(tier.color)
                        .frame(width: 8, height: 8)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.3))
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(tier.englishTitle)
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(isUnlocked ? .white : Color.white.opacity(0.45))

                    if isCurrent {
                        Text("CURRENT")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(CyberTheme.neonVolt)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.black, lineWidth: 1))
                    }
                }

                Text(tier.englishSubtitle)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(isUnlocked ? Color.white.opacity(0.6) : Color.white.opacity(0.3))
            }

            Spacer()

            // Target Weeks
            Text("\(tier.requiredWeeks) WEEKS")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(isUnlocked ? .white : Color.white.opacity(0.35))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            ZStack {
                if isCurrent {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.black)
                        .offset(x: 2.5, y: 2.5)
                }

                RoundedRectangle(cornerRadius: 14)
                    .fill(isCurrent ? Color(hex: "#18181c") : Color(hex: "#121215"))

                RoundedRectangle(cornerRadius: 14)
                    .stroke(isCurrent ? Color.white : Color.white.opacity(0.2), lineWidth: isCurrent ? 2 : 1)
            }
        )
    }

    // MARK: - 3. Badges Tab

    private var badgeSection: some View {
        VStack(spacing: 14) {
            // Filter Pills
            categoryFilterPills

            // Stats Summary Row
            HStack {
                Text("\(totalBadgeCount) TOTAL ACHIEVEMENTS")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .tracking(0.8)

                Spacer()

                HStack(spacing: 5) {
                    Circle()
                        .fill(CyberTheme.neonVolt)
                        .frame(width: 6, height: 6)
                    Text("UNLOCKED: \(unlockedCount) / \(totalBadgeCount)")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundStyle(CyberTheme.neonVolt)
                }
            }
            .padding(.horizontal, 2)

            // 2-Column Badge Grid
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(filteredBadges) { badge in
                    let record = unlockedBadgeMap[badge.key]
                    badgeCard(badge: badge, record: record)
                        .onTapGesture {
                            selectedBadgeForDetail = badge
                        }
                }
            }
        }
    }

    private var categoryFilterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All
                filterPill(title: "ALL", category: nil, count: totalBadgeCount)

                // Categories
                ForEach(BadgeCategory.allCases) { cat in
                    let count = BadgeCatalog.all.filter { $0.category == cat }.count
                    filterPill(title: cat.displayName.uppercased(), category: cat, count: count)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func filterPill(title: String, category: BadgeCategory?, count: Int) -> some View {
        let isSelected = selectedBadgeCategory == category
        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                selectedBadgeCategory = category
            }
        } label: {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 11, weight: .black))
                Text("(\(count))")
                    .font(.system(size: 10, weight: .bold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(Color.black)
                            .offset(x: 2, y: 2)
                    }

                    Capsule()
                        .fill(isSelected ? CyberTheme.neonVolt : Color(hex: "#18181c"))

                    Capsule()
                        .stroke(isSelected ? Color.white : Color.white.opacity(0.4), lineWidth: 2)
                }
            )
            .foregroundStyle(isSelected ? Color.black : Color.white.opacity(0.75))
        }
        .buttonStyle(.plain)
    }

    private func badgeCard(badge: BadgeDefinition, record: BadgeRecord?) -> some View {
        let isUnlocked = record != nil
        let isHiddenSecret = badge.isSecret && !isUnlocked

        return VStack(spacing: 10) {
            // Icon
            ZStack {
                Circle()
                    .fill(isUnlocked ? categoryColor(badge.category).opacity(0.2) : Color.black.opacity(0.4))
                    .frame(width: 58, height: 58)
                    .overlay(
                        Circle()
                            .stroke(isUnlocked ? categoryColor(badge.category) : Color.white.opacity(0.2), lineWidth: 2)
                    )
                    .shadow(color: isUnlocked ? categoryColor(badge.category).opacity(0.5) : .clear, radius: 4)

                Image(systemName: isHiddenSecret ? "questionmark" : badgeIcon(badge))
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(isUnlocked ? categoryColor(badge.category) : Color.white.opacity(0.25))
            }
            .padding(.top, 4)

            // Title
            Text(isHiddenSecret ? "SECRET BADGE" : badge.englishTitle.uppercased())
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(isUnlocked ? .white : Color.white.opacity(0.45))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 32)

            // Status Row
            if isUnlocked {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .black))
                    Text("UNLOCKED")
                        .font(.system(size: 10, weight: .black))
                }
                .foregroundStyle(CyberTheme.neonVolt)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9))
                    Text(badge.category.displayName.uppercased())
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundStyle(Color.white.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 10)
        .background(
            ZStack {
                if isUnlocked {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.black)
                        .offset(x: 3, y: 3)
                }

                RoundedRectangle(cornerRadius: 18)
                    .fill(isUnlocked ? Color(hex: "#18181c") : Color(hex: "#121215"))

                RoundedRectangle(cornerRadius: 18)
                    .stroke(isUnlocked ? Color.white : Color.white.opacity(0.3), lineWidth: 2)
            }
        )
    }

    private func categoryColor(_ category: BadgeCategory) -> Color {
        switch category {
        case .charge: return CyberTheme.neonYellow
        case .cheat: return CyberTheme.neonPurple
        case .secret: return CyberTheme.neonCyan
        }
    }

    private func badgeIcon(_ badge: BadgeDefinition) -> String {
        switch badge.category {
        case .charge: return "bolt.fill"
        case .cheat: return "flame.fill"
        case .secret: return "sparkles"
        }
    }

    // MARK: - Badge Detail Sheet

    private func badgeDetailSheet(_ badge: BadgeDefinition) -> some View {
        let record = unlockedBadgeMap[badge.key]
        let isUnlocked = record != nil
        let isHiddenSecret = badge.isSecret && !isUnlocked

        return ZStack {
            CyberTheme.background.ignoresSafeArea()
            NeoDotBackground()
                .opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Dismiss Bar
                HStack {
                    Spacer()
                    Button("CLOSE") {
                        selectedBadgeForDetail = nil
                    }
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(CyberTheme.neonVolt)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.black, lineWidth: 1.5))
                }
                .padding(.top, 16)
                .padding(.horizontal, 20)

                Spacer(minLength: 8)

                // Large Glowing Icon
                ZStack {
                    Circle()
                        .fill(isUnlocked ? categoryColor(badge.category).opacity(0.2) : Color.black.opacity(0.5))
                        .frame(width: 88, height: 88)
                        .overlay(
                            Circle()
                                .stroke(isUnlocked ? categoryColor(badge.category) : Color.white.opacity(0.3), lineWidth: 3)
                        )
                        .shadow(color: isUnlocked ? categoryColor(badge.category).opacity(0.6) : .clear, radius: 10)

                    Image(systemName: isHiddenSecret ? "questionmark" : badgeIcon(badge))
                        .font(.system(size: 38, weight: .black))
                        .foregroundStyle(isUnlocked ? categoryColor(badge.category) : Color.white.opacity(0.4))
                }

                // Title & Category
                VStack(spacing: 6) {
                    Text(isHiddenSecret ? "SECRET ACHIEVEMENT" : badge.englishTitle.uppercased())
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(.white)

                    Text(badge.category.displayName.uppercased())
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(categoryColor(badge.category))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(categoryColor(badge.category).opacity(0.18))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(categoryColor(badge.category).opacity(0.5), lineWidth: 1))
                }

                // Detail Box
                VStack(spacing: 12) {
                    Text(isHiddenSecret
                         ? "Unlock this secret badge by fulfilling a hidden gameplay condition."
                         : badge.englishDetail)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)

                    Divider().overlay(Color.white.opacity(0.2))

                    if let record = record {
                        VStack(spacing: 4) {
                            HStack(spacing: 5) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("UNLOCKED ON: \(formatEnglishDate(record.unlockedDate))")
                            }
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(CyberTheme.neonVolt)

                            if let note = record.triggerNote, !note.isEmpty, note != badge.title && note != badge.detail {
                                Text(note)
                                    .font(.caption2)
                                    .foregroundStyle(Color.white.opacity(0.6))
                            }
                        }
                    } else {
                        HStack(spacing: 5) {
                            Image(systemName: "lock.fill")
                            Text("LOCKED ACHIEVEMENT")
                        }
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(Color.white.opacity(0.5))
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity)
                .neoBox(borderColor: .white, cornerRadius: 18)
                .padding(.horizontal, 20)

                Spacer()
            }
        }
        .presentationDetents([.height(420), .medium])
        .presentationDragIndicator(.visible)
    }

    private func formatEnglishDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "d MMM yyyy, HH:mm"
        return f.string(from: date).uppercased()
    }

    // MARK: - 4. History Tab

    private var archiveSection: some View {
        VStack(spacing: 14) {
            // Overview Bento Header
            archiveStatsHeader

            // Current Month Workout & Weekly Status Calendar Box
            monthlyCalendarCard

            // Past Week Cards
            if pastWeeks.isEmpty {
                emptyArchiveView
            } else {
                ForEach(pastWeeks) { week in
                    weekRecordCard(week)
                }
            }
        }
    }

    // MARK: - Monthly Calendar Card

    private var currentMonthTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "MMMM yyyy"
        return f.string(from: Date()).uppercased()
    }

    private var workoutDayStarts: Set<Date> {
        let cal = WeekHelper.calendar
        return Set(allWorkouts.map { cal.startOfDay(for: $0.date) })
    }

    private var currentMonthWorkoutDaysCount: Int {
        let cal = WeekHelper.calendar
        let monthStart = WeekHelper.monthStart()
        return workoutDayStarts.filter { cal.isDate($0, equalTo: monthStart, toGranularity: .month) }.count
    }

    private var monthlyCalendarCard: some View {
        let cal = WeekHelper.calendar
        let now = Date()
        let monthStart = WeekHelper.monthStart(containing: now)
        let weekRows = WeekHelper.monthWeekRows(for: now)
        let weekdayHeaders = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]

        return VStack(spacing: 12) {
            // Header Row: Month Title & Active Workout Days Count
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(CyberTheme.neonVolt)

                    Text(currentMonthTitle)
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(.white)
                        .tracking(0.6)
                }

                Spacer()

                HStack(spacing: 5) {
                    Circle()
                        .fill(CyberTheme.neonVolt)
                        .frame(width: 6, height: 6)
                    Text("\(currentMonthWorkoutDaysCount) \(currentMonthWorkoutDaysCount == 1 ? "WORKOUT DAY" : "WORKOUT DAYS")")
                        .font(.system(size: 9.5, weight: .black))
                        .foregroundStyle(CyberTheme.neonVolt)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(CyberTheme.neonVolt.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(CyberTheme.neonVolt.opacity(0.4), lineWidth: 1)
                )
            }

            Divider()
                .overlay(Color.white.opacity(0.15))

            // Weekday Headers + End-of-Week Status Column Header
            HStack(spacing: 6) {
                ForEach(weekdayHeaders, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                }

                // Vertical Separator Spacer
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 2)

                Text("WK")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(CyberTheme.neonCyan.opacity(0.85))
                    .frame(width: 32)
            }

            // Week Rows (Mon-Sun + End of Week Status Indicator)
            VStack(spacing: 6) {
                ForEach(weekRows) { row in
                    HStack(spacing: 6) {
                        ForEach(row.days, id: \.self) { day in
                            let dayStart = cal.startOfDay(for: day)
                            let isInMonth = cal.isDate(day, equalTo: monthStart, toGranularity: .month)
                            let isToday = cal.isDate(day, inSameDayAs: now)
                            let hasWorkout = workoutDayStarts.contains(dayStart)

                            calendarDayCell(
                                day: day,
                                isInMonth: isInMonth,
                                isToday: isToday,
                                hasWorkout: hasWorkout
                            )
                        }

                        // Subtle divider between week days and week status indicator
                        Rectangle()
                            .fill(Color.white.opacity(0.14))
                            .frame(width: 1.5, height: 24)
                            .padding(.horizontal, 0.25)

                        weekStatusBadge(status: weekRowStatus(for: row, now: now))
                    }
                }
            }

            Divider()
                .overlay(Color.white.opacity(0.12))

            // Compact Legend Footer
            HStack(spacing: 14) {
                HStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(CyberTheme.neonVolt)
                        .frame(width: 10, height: 10)
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.black, lineWidth: 1))
                    Text("WORKOUT")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(Color.white.opacity(0.65))
                }

                HStack(spacing: 5) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(CyberTheme.neonGreen)
                    Text("SUCCESS WEEK")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(Color.white.opacity(0.65))
                }

                HStack(spacing: 5) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(CyberTheme.neonCoral)
                    Text("FAILED WEEK")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(Color.white.opacity(0.65))
                }

                Spacer(minLength: 0)
            }
        }
        .padding(14)
        .neoBox(borderColor: .white, cornerRadius: 18)
    }

    private func calendarDayCell(
        day: Date,
        isInMonth: Bool,
        isToday: Bool,
        hasWorkout: Bool
    ) -> some View {
        let dayNumber = WeekHelper.calendar.component(.day, from: day)

        return ZStack {
            if hasWorkout {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black)
                    .offset(x: 1.5, y: 1.5)
            }

            RoundedRectangle(cornerRadius: 8)
                .fill(hasWorkout ? CyberTheme.neonVolt : Color(hex: "#121215"))

            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isToday
                        ? (hasWorkout ? Color.white : CyberTheme.neonCyan)
                        : (hasWorkout ? Color.black : Color.white.opacity(0.18)),
                    lineWidth: isToday ? 2.0 : 1.2
                )

            Text("\(dayNumber)")
                .font(.system(size: 12, weight: hasWorkout || isToday ? .black : .bold, design: .monospaced))
                .foregroundStyle(hasWorkout ? Color.black : (isToday ? CyberTheme.neonCyan : Color.white))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 32)
        .opacity(isInMonth ? 1.0 : 0.25)
    }

    private func weekStatusBadge(status: WeekRowStatus) -> some View {
        ZStack {
            switch status {
            case .successful:
                RoundedRectangle(cornerRadius: 8)
                    .fill(CyberTheme.neonGreen.opacity(0.16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(CyberTheme.neonGreen, lineWidth: 1.5)
                    )
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(CyberTheme.neonGreen)

            case .unsuccessful:
                RoundedRectangle(cornerRadius: 8)
                    .fill(CyberTheme.neonCoral.opacity(0.16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(CyberTheme.neonCoral, lineWidth: 1.5)
                    )
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(CyberTheme.neonCoral)

            case .upcoming:
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "#121215"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                Image(systemName: "minus")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(Color.white.opacity(0.35))
            }
        }
        .frame(width: 32, height: 32)
    }

    private func weekRowStatus(for row: CalendarWeekRow, now: Date) -> WeekRowStatus {
        let cal = WeekHelper.calendar
        let currentWeekStart = WeekHelper.currentWeekStart(now: now)

        // Future week in the current month
        if row.weekStart > currentWeekStart {
            return .upcoming
        }

        // Ongoing current week: evaluate using live balance
        if cal.isDate(row.weekStart, inSameDayAs: currentWeekStart) {
            let earned = allWorkouts
                .filter { $0.date >= row.weekStart && $0.date < row.weekEnd }
                .reduce(0.0) { $0 + $1.caloriesBurned }
            let spent = allTreatLogs
                .filter { $0.date >= row.weekStart && $0.date < row.weekEnd }
                .compactMap { $0.treat?.calories }
                .reduce(0.0, +)
            let rollover = state?.currentRolloverBalance ?? 0
            let result = WeekRolloverCalculator.close(earned: earned, spent: spent, rollover: rollover)
            return result.isSuccessful ? .successful : .unsuccessful
        }

        // Past week: check archived WeekRecord first
        if let archived = pastWeeks.first(where: { cal.isDate($0.weekStartDate, inSameDayAs: row.weekStart) }) {
            return archived.isSuccessful ? .successful : .unsuccessful
        }

        // Past week without WeekRecord (e.g. before app install): evaluate from workouts/logs
        let earned = allWorkouts
            .filter { $0.date >= row.weekStart && $0.date < row.weekEnd }
            .reduce(0.0) { $0 + $1.caloriesBurned }
        let spent = allTreatLogs
            .filter { $0.date >= row.weekStart && $0.date < row.weekEnd }
            .compactMap { $0.treat?.calories }
            .reduce(0.0, +)
        let result = WeekRolloverCalculator.close(earned: earned, spent: spent, rollover: 0)
        return result.isSuccessful ? .successful : .unsuccessful
    }

    private var archiveStatsHeader: some View {
        HStack(spacing: 10) {
            archiveStatCard(
                title: "ARCHIVED",
                value: "\(pastWeeks.count)",
                unit: "WEEKS",
                valueColor: CyberTheme.neonCyan
            )
            archiveStatCard(
                title: "SUCCESSFUL",
                value: "\(archivedSuccessfulCount)",
                unit: "WEEKS",
                valueColor: CyberTheme.neonGreen
            )
            archiveStatCard(
                title: "RATE",
                value: successRateString,
                unit: "RATIO",
                valueColor: CyberTheme.neonVolt
            )
        }
    }

    private func archiveStatCard(title: String, value: String, unit: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(Color.white.opacity(0.55))
                .tracking(1.0)

            Text(value)
                .font(.system(size: 26, weight: .black, design: .monospaced))
                .foregroundStyle(valueColor)

            Text(unit)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .neoBox(borderColor: .white, cornerRadius: 16)
    }

    private var emptyArchiveView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40))
                .foregroundStyle(CyberTheme.neonCyan.opacity(0.7))
                .padding(.top, 12)

            Text("NO ARCHIVED WEEKS YET")
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(.white)

            Text("The weekly cycle closes every Monday at 00:00. Past balance and rollover history will be archived here.")
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .neoBox(borderColor: .white, cornerRadius: 18)
    }

    private func weekRecordCard(_ week: WeekRecord) -> some View {
        VStack(spacing: 12) {
            // Header Row: Date Range and Status Pill
            HStack {
                Text(weekDateRangeString(start: week.weekStartDate, end: week.weekEndDate))
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(.white)

                Spacer()

                if week.isSuccessful {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .black))
                        Text("SUCCESSFUL")
                            .font(.system(size: 9, weight: .black))
                    }
                    .foregroundStyle(CyberTheme.neonGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(CyberTheme.neonGreen.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(CyberTheme.neonGreen, lineWidth: 1))
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .black))
                        Text("UNCOMPLETED")
                            .font(.system(size: 9, weight: .black))
                    }
                    .foregroundStyle(CyberTheme.neonCoral)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(CyberTheme.neonCoral.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(CyberTheme.neonCoral, lineWidth: 1))
                }
            }

            Divider().overlay(Color.white.opacity(0.15))

            // 3-Column Bento Stat Breakdown
            HStack(spacing: 8) {
                // Earned
                VStack(spacing: 2) {
                    Text("EARNED")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(Color.white.opacity(0.5))
                    Text("+\(Int(week.earnedCalories)) kcal")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundStyle(CyberTheme.neonYellow)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.15), lineWidth: 1))

                // Spent
                VStack(spacing: 2) {
                    Text("SPENT")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(Color.white.opacity(0.5))
                    Text("-\(Int(week.spentCalories)) kcal")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundStyle(CyberTheme.neonPurple)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.15), lineWidth: 1))

                // Net Balance
                VStack(spacing: 2) {
                    Text("NET BALANCE")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(Color.white.opacity(0.5))
                    Text(week.netBalance >= 0 ? "+\(Int(week.netBalance)) kcal" : "\(Int(week.netBalance)) kcal")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundStyle(week.netBalance >= 0 ? CyberTheme.neonGreen : CyberTheme.neonCoral)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(week.netBalance >= 0 ? CyberTheme.neonGreen.opacity(0.4) : CyberTheme.neonCoral.opacity(0.4), lineWidth: 1)
                )
            }

            // Rollover Banner
            if week.rolloverCarriedForward > 0 {
                HStack(spacing: 6) {
                    Text("➔")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(.black)
                        .frame(width: 16, height: 16)
                        .background(CyberTheme.neonCyan)
                        .clipShape(Circle())

                    Text("Rolled over +\(Int(week.rolloverCarriedForward)) kcal to next week")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(CyberTheme.neonCyan)

                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(CyberTheme.neonCyan.opacity(0.6), lineWidth: 1))
            } else if week.rolloverRemaining > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "flame")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.5))

                    Text("\(Int(week.rolloverRemaining)) kcal unused rollover expired")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.5))

                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
            }
        }
        .padding(14)
        .neoBox(borderColor: .white, cornerRadius: 18)
    }

    private func weekDateRangeString(start: Date, end: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "d MMM"
        let startStr = f.string(from: start).uppercased()
        let displayEnd = Calendar.current.date(byAdding: .day, value: -1, to: end) ?? end
        let endStr = f.string(from: displayEnd).uppercased()
        return "\(startStr) – \(endStr)"
    }
}

// MARK: - Previews

#Preview {
    AchievementsView()
        .modelContainer(for: [Workout.self, TreatItem.self, TreatLog.self, UserGamificationState.self, WeekRecord.self, BadgeRecord.self], inMemory: true)
        .preferredColorScheme(.dark)
}
