//
//  AvatarBaseTabView.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 24.10.2026.
//

import SwiftUI
import SwiftData

// MARK: - Animation Tick Environment Key

private struct TacticalTickKey: EnvironmentKey {
    static let defaultValue: Int = 0
}

extension EnvironmentValues {
    fileprivate var tacticalTick: Int {
        get { self[TacticalTickKey.self] }
        set { self[TacticalTickKey.self] = newValue }
    }
}

// MARK: - AvatarBaseTabView

/// Standalone full-screen Cyber-Tactical / Dark Neobrutalist 2D Floor Plan & Pixel Avatar Simulation View.
/// Features a live SwiftData-driven Autonomous Life Cycle (`[ 🤖 AUTO: ON ]`), 3 Mood Personalities
/// (`HYPER-CHARGE`, `CHEAT / REWARD`, `DEPLETED`), 10-second Manual Poke Override, and modular
/// `RoomInteriorRenderer` / `AvatarSpriteRenderer` components.
struct AvatarBaseTabView: View {

    // MARK: - SwiftData Live Telemetry Queries

    @Query(sort: \Workout.date, order: .reverse) private var allWorkouts: [Workout]
    @Query(sort: \TreatLog.date, order: .reverse) private var allTreatLogs: [TreatLog]
    @Query private var gamificationStates: [UserGamificationState]

    // MARK: - Zone Definition

    enum Zone: Int, CaseIterable, Identifiable {
        case ironGym = 1
        case fuelLab = 2
        case cryoLounge = 3
        case commandDeck = 4

        var id: Int { rawValue }

        var codeTag: String {
            switch self {
            case .ironGym: return "[ ZONE 01: IRON GYM ]"
            case .fuelLab: return "[ ZONE 02: FUEL LAB ]"
            case .cryoLounge: return "[ ZONE 03: CRYO LOUNGE ]"
            case .commandDeck: return "[ ZONE 04: COMMAND DECK ]"
            }
        }

        var shortName: String {
            switch self {
            case .ironGym: return "ZONE_01 // IRON GYM"
            case .fuelLab: return "ZONE_02 // FUEL LAB"
            case .cryoLounge: return "ZONE_03 // CRYO LOUNGE"
            case .commandDeck: return "ZONE_04 // COMMAND DECK"
            }
        }

        var accentColor: Color {
            switch self {
            case .ironGym: return Color(hex: "#CCFF00")
            case .fuelLab: return Color(hex: "#FF0055")
            case .cryoLounge: return Color(hex: "#FF9900")
            case .commandDeck: return Color(hex: "#00F0FF")
            }
        }

        /// Normalized coordinates inside the 2D floor plan (0.0 ... 1.0)
        var coordinate: CGPoint {
            switch self {
            case .ironGym: return CGPoint(x: 0.25, y: 0.25)
            case .fuelLab: return CGPoint(x: 0.75, y: 0.25)
            case .cryoLounge: return CGPoint(x: 0.25, y: 0.75)
            case .commandDeck: return CGPoint(x: 0.75, y: 0.75)
            }
        }
    }

    // MARK: - Avatar Mood (Personality & Route Engine)

    enum AvatarMood: String, CaseIterable, Identifiable {
        case hyperCharge
        case cheatReward
        case depleted

        var id: String { rawValue }

        var simulatorButtonTitle: String {
            switch self {
            case .hyperCharge: return "[ ⚡ CHARGE ]"
            case .cheatReward: return "[ 🍔 CHEAT ]"
            case .depleted: return "[ 💤 REST ]"
            }
        }

        var headerBadgeText: String {
            switch self {
            case .hyperCharge: return "STATE: HYPER-CHARGE"
            case .cheatReward: return "STATE: CHEAT-REWARD"
            case .depleted: return "STATE: LOW-POWER"
            }
        }

        var accentColor: Color {
            switch self {
            case .hyperCharge: return Color(hex: "#CCFF00")
            case .cheatReward: return Color(hex: "#FF0055")
            case .depleted: return Color(hex: "#FF9900")
            }
        }

        /// Primary room the character heads to when this mood is first activated.
        var initialPreferredZone: Zone {
            switch self {
            case .hyperCharge: return .ironGym
            case .cheatReward: return .fuelLab
            case .depleted: return .cryoLounge
            }
        }

        /// Duration (in seconds) of a single walking segment (Room -> Hub or Hub -> Room).
        var walkSegmentDuration: Double {
            switch self {
            case .hyperCharge: return 0.70
            case .cheatReward: return 0.65
            case .depleted: return 1.15
            }
        }

        /// Weighted route distribution for all 4 rooms.
        func routeWeights() -> [(Zone, Double)] {
            switch self {
            case .hyperCharge:
                // 50% Iron Gym, 25% Command Deck, 15% Fuel Lab, 10% Cryo Lounge
                return [
                    (.ironGym, 0.50),
                    (.commandDeck, 0.25),
                    (.fuelLab, 0.15),
                    (.cryoLounge, 0.10)
                ]
            case .cheatReward:
                // Shuttles mostly between Fuel Lab (45%) & Cryo Lounge (35%), occasional Gym (10%) & Command (10%)
                return [
                    (.fuelLab, 0.45),
                    (.cryoLounge, 0.35),
                    (.ironGym, 0.10),
                    (.commandDeck, 0.10)
                ]
            case .depleted:
                // Mostly Cryo Lounge (45%) & Command Deck (35%), occasional Fuel Lab fridge check (15%) & Gym (5%)
                return [
                    (.cryoLounge, 0.45),
                    (.commandDeck, 0.35),
                    (.fuelLab, 0.15),
                    (.ironGym, 0.05)
                ]
            }
        }
    }

    // MARK: - Avatar Action State (Sprite Animation State)

    enum AvatarState: Equatable {
        case walking
        case hubWaiting
        case workingOut
        case preppingShake
        case activeRecovery
        case eating
        case staringAtDumbbells
        case resting
        case analyzing
        case checkingFridge
        case lowBatteryAlert
    }

    // MARK: - Context-Aware Room Behavior Profile

    struct RoomBehaviorProfile {
        let spriteState: AvatarState
        let bubbleText: String
        let cctvAction: String
        let cctvSysMsg: String
        let dwellRange: ClosedRange<Double>
    }

    /// Returns how the character behaves, what speech bubble appears, and what CCTV logs say
    /// for a given `(AvatarMood, Zone)` combination.
    private func behaviorProfile(for mood: AvatarMood, in zone: Zone) -> RoomBehaviorProfile {
        switch (mood, zone) {
        // ⚡ SCENARIO 1: HYPER-CHARGE (Disciplined Athlete across all rooms)
        case (.hyperCharge, .ironGym):
            return RoomBehaviorProfile(
                spriteState: .workingOut,
                bubbleText: "⚡",
                cctvAction: "LIFTING HEAVY // PR ATTEMPT",
                cctvSysMsg: "ATP synthesis at 140%. Barbell velocity nominal. +KCAL bank expanding.",
                dwellRange: 7.0...10.0
            )
        case (.hyperCharge, .fuelLab):
            return RoomBehaviorProfile(
                spriteState: .preppingShake,
                bubbleText: "🥤",
                cctvAction: "MIXING PROTEIN SHAKE // PREPPING MACROS",
                cctvSysMsg: "Blending 50g whey isolate & creatine. Zero cheat discipline active!",
                dwellRange: 6.0...8.5
            )
        case (.hyperCharge, .cryoLounge):
            return RoomBehaviorProfile(
                spriteState: .activeRecovery,
                bubbleText: "⚡",
                cctvAction: "ACTIVE RECOVERY & FOAM ROLLING",
                cctvSysMsg: "Myofascial release & mobility stretching. Keeping heart rate primed.",
                dwellRange: 6.0...8.0
            )
        case (.hyperCharge, .commandDeck):
            return RoomBehaviorProfile(
                spriteState: .analyzing,
                bubbleText: "💻",
                cctvAction: "ANALYZING VO2 MAX & MACRO SURPLUS",
                cctvSysMsg: "Calorie ledger in strong surplus. Metabolic engine at peak efficiency.",
                dwellRange: 6.5...9.5
            )

        // 🍔 SCENARIO 2: CHEAT / REWARD (Feasting & Gaming, avoids heavy lifting)
        case (.cheatReward, .fuelLab):
            return RoomBehaviorProfile(
                spriteState: .eating,
                bubbleText: "🍔",
                cctvAction: "CONSUMING REWARD // BURGER FEAST",
                cctvSysMsg: "Dopamine spike detected! High-glycemic cheat payload authorized.",
                dwellRange: 7.0...10.0
            )
        case (.cheatReward, .cryoLounge):
            return RoomBehaviorProfile(
                spriteState: .resting,
                bubbleText: "🎮",
                cctvAction: "COUCH GAMING & DIGESTING CHEAT",
                cctvSysMsg: "Glycogen stores overflowing. Crushing retro arcade high scores.",
                dwellRange: 7.0...10.0
            )
        case (.cheatReward, .ironGym):
            return RoomBehaviorProfile(
                spriteState: .staringAtDumbbells,
                bubbleText: "😅",
                cctvAction: "STARING AT DUMBBELLS... MAYBE TOMORROW",
                cctvSysMsg: "Calculated barbell gravity: way too heavy after burgers. Retreating soon!",
                dwellRange: 4.5...5.5
            )
        case (.cheatReward, .commandDeck):
            return RoomBehaviorProfile(
                spriteState: .analyzing,
                bubbleText: "🍔",
                cctvAction: "AUDITING CHEAT CALORIE RECEIPT",
                cctvSysMsg: "Worth every calorie. Recalculating tomorrow's workout burn target.",
                dwellRange: 6.0...8.0
            )

        // 🪫 SCENARIO 3: DEPLETED / LOW POWER (Sluggish, dozing, deficit warnings)
        case (.depleted, .cryoLounge):
            return RoomBehaviorProfile(
                spriteState: .resting,
                bubbleText: "💤",
                cctvAction: "LOW-POWER HIBERNATION // DOZING",
                cctvSysMsg: "Kinetic battery critically low. Log a workout to restore volt charge.",
                dwellRange: 7.5...10.0
            )
        case (.depleted, .commandDeck):
            return RoomBehaviorProfile(
                spriteState: .lowBatteryAlert,
                bubbleText: "🪫",
                cctvAction: "SYSTEM WARNING // CALORIE DEFICIT",
                cctvSysMsg: "ALERT: Calorie bank depleted or long inactivity! Workout required.",
                dwellRange: 7.0...9.5
            )
        case (.depleted, .fuelLab):
            return RoomBehaviorProfile(
                spriteState: .checkingFridge,
                bubbleText: "🪫",
                cctvAction: "CHECKING FRIDGE... LOCKED BY DEFICIT",
                cctvSysMsg: "Inspecting empty fridge shelves. Reward lock engaged until next workout.",
                dwellRange: 6.0...8.0
            )
        case (.depleted, .ironGym):
            return RoomBehaviorProfile(
                spriteState: .staringAtDumbbells,
                bubbleText: "🪫",
                cctvAction: "STARING AT BARBELL // LOW BATTERY",
                cctvSysMsg: "System requires kinetic spark. One workout will ignite HYPER-CHARGE.",
                dwellRange: 5.5...7.0
            )
        }
    }

    // MARK: - Constants

    private let baseBackground = Color(hex: "#0D0D0D")
    private let cardSurface = Color(hex: "#141418")
    private let centerHubPoint = CGPoint(x: 0.5, y: 0.5)

    // MARK: - State

    @State private var isSpriteSceneMode: Bool = true
    @State private var isAutoMode: Bool = true
    @State private var manualMood: AvatarMood = .hyperCharge
    @State private var isPokeOverride: Bool = false

    @State private var currentZone: Zone = .ironGym
    @State private var targetZone: Zone = .ironGym
    @State private var avatarState: AvatarState = .workingOut
    @State private var avatarPosition: CGPoint = Zone.ironGym.coordinate
    @State private var walkGeneration: Int = 0
    @State private var showCCTV: Bool = false
    @State private var hasInitializedLifeCycle: Bool = false

    // MARK: - Real SwiftData Calorie & Mood Calculations

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

    /// Computes the character's real-data mood from SwiftData:
    /// 1) If a `TreatLog` was logged within the last 24 hours (and more recently than the latest workout) -> `.cheatReward`
    /// 2) If live calorie balance < 0, or no workouts this week with <= 0 balance, or last workout > 72h ago -> `.depleted`
    /// 3) Otherwise -> `.hyperCharge`
    private var computedRealMood: AvatarMood {
        let now = Date()
        let latestTreatDate = allTreatLogs.first?.date
        let latestWorkoutDate = allWorkouts.first?.date

        if let treatDate = latestTreatDate,
           now.timeIntervalSince(treatDate) <= 24 * 3600 {
            if let workoutDate = latestWorkoutDate {
                if treatDate > workoutDate {
                    return .cheatReward
                }
            } else {
                return .cheatReward
            }
        }

        if remainingCalories < 0 {
            return .depleted
        }

        if let workoutDate = latestWorkoutDate {
            if now.timeIntervalSince(workoutDate) > 72 * 3600 && remainingCalories <= 0 {
                return .depleted
            }
        } else if remainingCalories <= 0 {
            return .depleted
        }

        return .hyperCharge
    }

    /// Currently active mood (either live SwiftData mood when `AUTO: ON`, or selected simulator mood).
    private var activeMood: AvatarMood {
        isAutoMode ? computedRealMood : manualMood
    }

    /// Active behavior profile for the current/target room and mood.
    private var currentBehavior: RoomBehaviorProfile {
        behaviorProfile(for: activeMood, in: currentZone)
    }

    /// Smart Avoidance helper: true when the character is in (or heading to) Top Rooms (Zone 01 or Zone 02).
    private var isCharacterInTopRooms: Bool {
        let activeZone = (avatarState == .walking || avatarState == .hubWaiting) ? targetZone : currentZone
        return activeZone == .ironGym || activeZone == .fuelLab
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            baseBackground
                .ignoresSafeArea()

            TimelineView(.periodic(from: .now, by: 0.16)) { timeline in
                let rawTick = Int(timeline.date.timeIntervalSinceReferenceDate / 0.16)
                // Depleted mode uses a slightly slower animation cadence
                let effectiveTick = (activeMood == .depleted && avatarState == .walking)
                    ? Int(timeline.date.timeIntervalSinceReferenceDate / 0.26)
                    : rawTick
                let blinkOn = (rawTick % 4) < 2

                VStack(spacing: 8) {
                    // SECTION 1: Tactical Header (with V1 Map / V2 Sprite Scene toggle)
                    tacticalHeader(blinkOn: blinkOn)
                        .frame(height: 42)

                    if isSpriteSceneMode {
                        // V2: Centered Room Sprite Stage + Bottom Room Selector Squares
                        AvatarSpriteRoomSceneView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // SECTION 2 (V1): Full-Height 2D Interactive Floor Plan + Floating CCTV HUD Overlay
                        blueprintMapSection
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        // SECTION 3 (V1): Mode Selector / Simulator Dock ([ 🤖 AUTO ] + 3 Mood Triggers)
                        tacticalControlDock
                    }
                }
                .environment(\.tacticalTick, effectiveTick)
                .padding(.horizontal, 14)
                .padding(.top, 6)
                // Reserve space at bottom for the app's floating tab dock
                .padding(.bottom, 74)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            startOrSyncLifeCycleOnAppear()
        }
        .onChange(of: computedRealMood) { _, newMood in
            guard isAutoMode else { return }
            transitionToMood(newMood, immediateZone: newMood.initialPreferredZone)
        }
    }

    // MARK: - Autonomous Life Cycle & Poke Engine

    private func startOrSyncLifeCycleOnAppear() {
        let initialMood = activeMood
        let startZone = initialMood.initialPreferredZone

        if !hasInitializedLifeCycle {
            hasInitializedLifeCycle = true
            currentZone = startZone
            targetZone = startZone
            avatarPosition = startZone.coordinate
            let profile = behaviorProfile(for: initialMood, in: startZone)
            avatarState = profile.spriteState
            scheduleNextAutonomousMove(after: Double.random(in: profile.dwellRange))
        } else if isAutoMode && initialMood == .cheatReward && currentZone != .fuelLab {
            // In Cheat/Reward mode, immediately run to Fuel Lab upon opening the tab
            walkDirectlyToZone(.fuelLab, isManualPoke: false)
        } else {
            // Ensure autonomous timer is active
            let profile = behaviorProfile(for: initialMood, in: currentZone)
            if avatarState != .walking && avatarState != .hubWaiting {
                avatarState = profile.spriteState
                scheduleNextAutonomousMove(after: Double.random(in: profile.dwellRange))
            }
        }
    }

    /// Switches mood (via AUTO sync or manual mood button) and routes character to that mood's signature room.
    private func transitionToMood(_ mood: AvatarMood, immediateZone: Zone) {
        isPokeOverride = false
        if currentZone == immediateZone && avatarState != .walking && avatarState != .hubWaiting {
            walkGeneration += 1
            let profile = behaviorProfile(for: mood, in: currentZone)
            avatarState = profile.spriteState
            scheduleNextAutonomousMove(after: Double.random(in: profile.dwellRange))
        } else {
            walkDirectlyToZone(immediateZone, isManualPoke: false)
        }
    }

    /// Manual Poke (Override): User tapped a room on the map.
    /// Character immediately drops current task, walks via Hub (without 2s pause) to tapped room,
    /// performs action for 10 seconds, then returns to autonomous life cycle.
    func pokeZone(_ destination: Zone) {
        walkDirectlyToZone(destination, isManualPoke: true)
    }

    /// Walks via Center Hub (0.5, 0.5) to `destination` without waiting 2s at the Hub.
    private func walkDirectlyToZone(_ destination: Zone, isManualPoke: Bool) {
        walkGeneration += 1
        let activeGen = walkGeneration
        isPokeOverride = isManualPoke
        targetZone = destination

        let legDuration = isManualPoke ? 0.65 : activeMood.walkSegmentDuration

        // If already at destination coordinate, start dwell immediately
        if currentZone == destination && avatarPosition == destination.coordinate && avatarState != .walking {
            let profile = behaviorProfile(for: activeMood, in: destination)
            avatarState = profile.spriteState
            let stayDuration = isManualPoke ? 10.0 : Double.random(in: profile.dwellRange)
            scheduleNextAutonomousMove(after: stayDuration)
            return
        }

        // Stage 1: Walk to Center Hub (x: 0.5, y: 0.5)
        avatarState = .walking
        withAnimation(.linear(duration: legDuration)) {
            avatarPosition = centerHubPoint
        }

        // Stage 2: Walk from Center Hub to Target Zone coordinate
        DispatchQueue.main.asyncAfter(deadline: .now() + legDuration) {
            guard activeGen == walkGeneration else { return }

            withAnimation(.linear(duration: legDuration)) {
                avatarPosition = destination.coordinate
            }

            // Arrival: perform room action for 10s (if poked) or 6-10s (autonomous)
            DispatchQueue.main.asyncAfter(deadline: .now() + legDuration) {
                guard activeGen == walkGeneration else { return }
                currentZone = destination
                let profile = behaviorProfile(for: activeMood, in: destination)
                avatarState = profile.spriteState

                let stayDuration = isManualPoke ? 10.0 : Double.random(in: profile.dwellRange)
                scheduleNextAutonomousMove(after: stayDuration)
            }
        }
    }

    /// Schedules the next autonomous trip:
    /// After `delay` seconds in the current room -> walks to HUB (0.5, 0.5) -> waits 2.0s at HUB -> walks to next weighted room.
    private func scheduleNextAutonomousMove(after delay: Double) {
        let scheduledGen = walkGeneration

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard scheduledGen == walkGeneration else { return }

            // Clear poke override once the 10-second manual stay finishes
            isPokeOverride = false

            let legDuration = activeMood.walkSegmentDuration

            // Step 1: Walk out of current room to Center Hub (0.5, 0.5)
            avatarState = .walking
            withAnimation(.linear(duration: legDuration)) {
                avatarPosition = centerHubPoint
            }

            // Step 2: Arrive at Center Hub & wait 2.0 seconds while deciding next room
            DispatchQueue.main.asyncAfter(deadline: .now() + legDuration) {
                guard scheduledGen == walkGeneration else { return }
                avatarState = .hubWaiting

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    guard scheduledGen == walkGeneration else { return }

                    let nextZone = pickNextZone(for: activeMood, current: currentZone)
                    targetZone = nextZone
                    avatarState = .walking

                    // Step 3: Walk from Center Hub to the chosen room
                    withAnimation(.linear(duration: legDuration)) {
                        avatarPosition = nextZone.coordinate
                    }

                    // Step 4: Arrive at chosen room & start room-specific behavior
                    DispatchQueue.main.asyncAfter(deadline: .now() + legDuration) {
                        guard scheduledGen == walkGeneration else { return }
                        currentZone = nextZone
                        let profile = behaviorProfile(for: activeMood, in: nextZone)
                        avatarState = profile.spriteState

                        scheduleNextAutonomousMove(after: Double.random(in: profile.dwellRange))
                    }
                }
            }
        }
    }

    /// Weighted random room selector based on the current `AvatarMood`.
    /// Slightly favors picking a different room than `current` so the character visibly explores the base,
    /// while preserving the overall mood distribution.
    private func pickNextZone(for mood: AvatarMood, current: Zone) -> Zone {
        let weights = mood.routeWeights()
        // Try up to 2 rolls to encourage movement between rooms while respecting mood probabilities
        for attempt in 0..<2 {
            let roll = Double.random(in: 0...1)
            var cumulative = 0.0
            var chosen: Zone = weights.last?.0 ?? .ironGym
            for (zone, weight) in weights {
                cumulative += weight
                if roll <= cumulative {
                    chosen = zone
                    break
                }
            }
            if chosen != current || attempt == 1 {
                return chosen
            }
        }
        return mood.initialPreferredZone
    }

    // MARK: - Header & Speech Bubble Dynamic Texts

    private var activeSpeechBubbleText: String {
        switch avatarState {
        case .walking:
            return isPokeOverride ? "❗" : ">>"
        case .hubWaiting:
            return "•••"
        default:
            return currentBehavior.bubbleText
        }
    }

    private var activeCCTVActionText: String {
        switch avatarState {
        case .walking:
            return isPokeOverride ? "MANUAL POKE // ROUTING TO \(targetZone.shortName)" : "RELOCATING VIA CENTER HUB"
        case .hubWaiting:
            return "HUB [0.5, 0.5] // SCANNING NEXT SECTOR"
        default:
            return isPokeOverride ? "[POKE 10S] \(currentBehavior.cctvAction)" : currentBehavior.cctvAction
        }
    }

    private var activeCCTVSystemMessage: String {
        switch avatarState {
        case .walking:
            return isPokeOverride
                ? "User override received! Proceeding to \(targetZone.shortName) for 10s task."
                : "Autonomous routing through Center Hub [0.5, 0.5]. Collision avoidance active."
        case .hubWaiting:
            return "Pausing 2.0s at Center Hub. Decision engine evaluating \(activeMood.headerBadgeText) telemetry..."
        default:
            return currentBehavior.cctvSysMsg
        }
    }

    // MARK: - SECTION 1: Tactical Header

    private func tacticalHeader(blinkOn: Bool) -> some View {
        let badgeAccent = isPokeOverride ? Color(hex: "#00F0FF") : activeMood.accentColor
        let badgeLabel = isPokeOverride ? "OVERRIDE: POKE [10S]" : activeMood.headerBadgeText

        return HStack(spacing: 8) {
            // Left: Blinking green REC dot + [ BASE_OPS // LIVE_FEED ]
            HStack(spacing: 7) {
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color(hex: "#CCFF00"))
                        .frame(width: 8, height: 8)
                        .opacity(blinkOn ? 1.0 : 0.18)

                    Text("REC")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(Color(hex: "#CCFF00"))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.black)
                .overlay(
                    Rectangle()
                        .stroke(Color(hex: "#CCFF00").opacity(0.7), lineWidth: 1.5)
                )

                Text("[ BASE_OPS // LIVE_FEED ]")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer(minLength: 4)

            // Mode Switcher: Toggle between V2 Sprite Scene and V1 Tactical Map
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                    isSpriteSceneMode.toggle()
                }
            } label: {
                Text(isSpriteSceneMode ? "[ 🗺️ V1 MAP ]" : "[ 🎬 V2 SCENE ]")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundStyle(Color(hex: "#00F0FF"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 5)
                    .background(
                        ZStack {
                            Rectangle()
                                .fill(Color.black)
                                .offset(x: 2, y: 2)
                            Rectangle()
                                .fill(Color(hex: "#16161C"))
                            Rectangle()
                                .stroke(Color(hex: "#00F0FF"), lineWidth: 1.5)
                        }
                    )
            }
            .buttonStyle(TacticalPressButtonStyle())

            // Right: Active Mood / Override State Tag
            Text(badgeLabel)
                .font(.system(size: 9.5, weight: .black, design: .monospaced))
                .foregroundStyle(Color.black)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    ZStack {
                        Rectangle()
                            .fill(Color.black)
                            .offset(x: 2, y: 2)
                        Rectangle()
                            .fill(badgeAccent)
                        Rectangle()
                            .stroke(Color.black, lineWidth: 2)
                    }
                )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            TacticalHardBox(
                fillColor: cardSurface,
                borderColor: Color.white,
                borderWidth: 2.5,
                shadowColor: Color.black,
                shadowOffset: 4
            )
        )
    }

    // MARK: - SECTION 2: 2D Interactive Floor Plan (Blueprint + Floating CCTV HUD)

    private var blueprintMapSection: some View {
        GeometryReader { geo in
            let mapWidth = geo.size.width
            let mapHeight = geo.size.height

            ZStack {
                // Outer Blueprint Container with Subtle Dot-Matrix Grid
                TacticalHardBox(
                    fillColor: Color(hex: "#0E0F14"),
                    borderColor: Color.white,
                    borderWidth: 3,
                    shadowColor: Color.black,
                    shadowOffset: 5
                )

                BlueprintDotMatrixGrid()
                    .clipShape(Rectangle())
                    .padding(3)

                // Crosshair corridor pathways connecting Center Hub to each room doorway
                CorridorFloorOverlay()
                    .padding(10)

                // 2x2 Spacious Rooms Grid filling the vertical canvas
                VStack(spacing: 14) {
                    HStack(spacing: 14) {
                        zoneRoomView(zone: .ironGym)
                        zoneRoomView(zone: .fuelLab)
                    }
                    HStack(spacing: 14) {
                        zoneRoomView(zone: .cryoLounge)
                        zoneRoomView(zone: .commandDeck)
                    }
                }
                .padding(10)

                // Center Hub (x: 0.5, y: 0.5) Tactical Junction
                centerHubBadge
                    .position(x: mapWidth * 0.5, y: mapHeight * 0.5)

                // 16x16 Pixel Avatar + Speech Bubble Overlay (Tappable to toggle CCTV HUD)
                avatarMapEntity
                    .position(
                        x: mapWidth * avatarPosition.x,
                        y: mapHeight * avatarPosition.y
                    )

                // Floating Smart-Avoidance CCTV HUD Overlay
                // If character is in Top Rooms (Zone 01 / Zone 02) -> aligns to .bottom
                // If character is in Bottom Rooms (Zone 03 / Zone 04) -> aligns to .top
                if showCCTV {
                    floatingCCTVInspectorCard
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: isCharacterInTopRooms ? .bottom : .top
                        )
                        .transition(
                            .scale(scale: 0.92)
                            .combined(with: .opacity)
                        )
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: showCCTV)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isCharacterInTopRooms)
        }
    }

    // MARK: - Individual Zone Room Card with Doorway Gap

    private func zoneRoomView(zone: Zone) -> some View {
        let isTargeted = (targetZone == zone)

        return ZStack(alignment: .topLeading) {
            // Hard Offset Shadow (45 degree unblurred)
            RoomWallShape(zone: zone, closedFullRect: true)
                .fill(Color.black)
                .offset(x: 4, y: 4)

            // Modular 3/4 RPG Room Interior Renderer (Top Wall + Textured Flooring + Grounded Furniture)
            RoomInteriorRenderer(zone: zone)
                .clipShape(RoomWallShape(zone: zone, closedFullRect: true))

            // Thick Perimeter Border with Doorway Opening facing Center Hub (0.5, 0.5)
            RoomWallShape(zone: zone, closedFullRect: false)
                .stroke(
                    zone.accentColor,
                    style: StrokeStyle(
                        lineWidth: isTargeted ? 3.2 : 2.2,
                        lineCap: .square,
                        lineJoin: .miter
                    )
                )

            // Doorway Threshold Markers on the inner corner
            DoorwayThresholdIndicator(zone: zone, color: zone.accentColor)

            // Coordinate Readout at Outer Bottom Corner
            VStack {
                Spacer()
                HStack {
                    if zone == .fuelLab || zone == .commandDeck {
                        Spacer()
                    }
                    Text(String(format: "X:%.2f Y:%.2f", zone.coordinate.x, zone.coordinate.y))
                        .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(zone.accentColor.opacity(0.85))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1.5)
                        .background(Color.black.opacity(0.8))
                    if zone == .ironGym || zone == .cryoLounge {
                        Spacer()
                    }
                }
            }
            .padding(5)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if currentZone == zone && avatarState != .walking && avatarState != .hubWaiting {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    showCCTV.toggle()
                }
            } else {
                pokeZone(zone)
            }
        }
    }

    // MARK: - Center Hub Badge

    private var centerHubBadge: some View {
        let isAtHub = (avatarState == .walking || avatarState == .hubWaiting)
        return ZStack {
            Rectangle()
                .fill(Color.black)
                .frame(width: 52, height: 52)
                .offset(x: 3, y: 3)

            Rectangle()
                .fill(Color(hex: "#14141A"))
                .frame(width: 52, height: 52)

            Rectangle()
                .stroke(
                    isAtHub ? targetZone.accentColor : Color.white.opacity(0.65),
                    style: StrokeStyle(lineWidth: 2, dash: [5, 3])
                )
                .frame(width: 52, height: 52)

            VStack(spacing: 1) {
                Text("HUB")
                    .font(.system(size: 8.5, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.85))
                Text("0.5,0.5")
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.5))
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Avatar Entity on Map (Modular AvatarSpriteRenderer + Speech Bubble)

    private var avatarMapEntity: some View {
        let bubbleAccent = (avatarState == .hubWaiting)
            ? activeMood.accentColor
            : targetZone.accentColor

        return VStack(spacing: 2) {
            // Pixel Speech Bubble above head
            HStack(spacing: 2) {
                Text(activeSpeechBubbleText)
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.black)
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                ZStack {
                    Rectangle()
                        .fill(Color.black)
                        .offset(x: 2, y: 2)
                    Rectangle()
                        .fill(bubbleAccent)
                    Rectangle()
                        .stroke(Color.black, lineWidth: 1.5)
                }
            )

            // Modular Character Renderer
            AvatarSpriteRenderer(
                state: avatarState,
                isWalking: avatarState == .walking
            )
            .frame(width: 44, height: 44)
        }
        .padding(6)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                showCCTV.toggle()
            }
        }
    }

    // MARK: - Floating CCTV Zoom Inspector HUD Card

    private var floatingCCTVInspectorCard: some View {
        let activeZone = (avatarState == .walking || avatarState == .hubWaiting) ? targetZone : currentZone
        let accent = activeZone.accentColor

        return VStack(spacing: 0) {
            // CCTV Header Strip + Brutalist [ X ] Close Button
            HStack(spacing: 6) {
                HStack(spacing: 5) {
                    Rectangle()
                        .fill(accent)
                        .frame(width: 7, height: 7)
                    Text("CCTV ZOOM INSPECTOR // CAM_0\(activeZone.rawValue) [3X]")
                        .font(.system(size: 9.5, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Spacer(minLength: 4)

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        showCCTV = false
                    }
                } label: {
                    Text("[ X ]")
                        .font(.system(size: 9.5, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(
                            ZStack {
                                Rectangle()
                                    .fill(accent)
                                Rectangle()
                                    .stroke(Color.black, lineWidth: 1.5)
                            }
                        )
                }
                .buttonStyle(TacticalPressButtonStyle())
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.black)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.white.opacity(0.35))
                    .frame(height: 1.5)
            }

            // CCTV Content: Left 3x Zoomed Pixel Feed | Right Terminal Logs
            HStack(spacing: 10) {
                // Left: 3x Zoomed Live Modular Avatar Viewport
                ZStack {
                    Rectangle()
                        .fill(Color(hex: "#090A0F"))

                    CCTVReticleOverlay(accentColor: accent)

                    // 3x Zoomed Modular Character Renderer
                    AvatarSpriteRenderer(
                        state: avatarState,
                        isWalking: avatarState == .walking
                    )
                    .frame(width: 96, height: 96)

                    CCTVScanlines()
                }
                .frame(width: 108, height: 108)
                .overlay(
                    Rectangle()
                        .stroke(accent, lineWidth: 2)
                )
                .background(
                    Rectangle()
                        .fill(Color.black)
                        .offset(x: 3, y: 3)
                )

                // Right: Terminal / Log Readout
                VStack(alignment: .leading, spacing: 5) {
                    terminalLogLine(
                        label: "LOC:",
                        value: avatarState == .hubWaiting
                            ? "CENTER HUB [0.5, 0.5]"
                            : (avatarState == .walking ? "HUB -> \(targetZone.shortName)" : currentZone.shortName),
                        valueColor: accent
                    )

                    terminalLogLine(
                        label: "ACT:",
                        value: activeCCTVActionText,
                        valueColor: Color.white
                    )

                    Divider()
                        .overlay(Color.white.opacity(0.2))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("SYS_MSG:")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.55))

                        Text(activeCCTVSystemMessage)
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color(hex: "#D4D4DC"))
                            .lineLimit(3)
                            .minimumScaleFactor(0.8)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(8)
        }
        .background(
            TacticalHardBox(
                fillColor: cardSurface.opacity(0.97),
                borderColor: accent,
                borderWidth: 2.5,
                shadowColor: Color.black,
                shadowOffset: 5
            )
        )
    }

    // MARK: - SECTION 3: Mode Selector / Simulator Dock ([ 🤖 AUTO ] + 3 Mood Triggers)

    private var tacticalControlDock: some View {
        let autoAccent = Color(hex: "#00F0FF")

        return HStack(spacing: 6) {
            // 1. Primary Real-Data Autonomous Toggle Button: [ 🤖 AUTO: ON / OFF ]
            Button {
                isAutoMode = true
                let realMood = computedRealMood
                transitionToMood(realMood, immediateZone: realMood.initialPreferredZone)
            } label: {
                Text(isAutoMode ? "[ 🤖 AUTO: ON ]" : "[ 🤖 AUTO: OFF ]")
                    .font(.system(size: 9.5, weight: .black, design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .foregroundStyle(isAutoMode ? Color.black : autoAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        TacticalHardBox(
                            fillColor: isAutoMode ? autoAccent : Color(hex: "#16161C"),
                            borderColor: isAutoMode ? Color.black : autoAccent.opacity(0.85),
                            borderWidth: 1.8,
                            shadowColor: Color.black,
                            shadowOffset: 2
                        )
                    )
            }
            .buttonStyle(TacticalPressButtonStyle())

            // 2. Manual Mood Simulator Triggers: [ ⚡ CHARGE ], [ 🍔 CHEAT ], [ 💤 REST ]
            ForEach(AvatarMood.allCases) { mood in
                let isSelectedManual = (!isAutoMode && manualMood == mood)

                Button {
                    isAutoMode = false
                    manualMood = mood
                    transitionToMood(mood, immediateZone: mood.initialPreferredZone)
                } label: {
                    Text(mood.simulatorButtonTitle)
                        .font(.system(size: 9.5, weight: .black, design: .monospaced))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .foregroundStyle(isSelectedManual ? Color.black : mood.accentColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            TacticalHardBox(
                                fillColor: isSelectedManual ? mood.accentColor : Color(hex: "#16161C"),
                                borderColor: isSelectedManual ? Color.black : mood.accentColor.opacity(0.85),
                                borderWidth: 1.8,
                                shadowColor: Color.black,
                                shadowOffset: 2
                            )
                        )
                }
                .buttonStyle(TacticalPressButtonStyle())
            }
        }
        .padding(5)
        .background(
            TacticalHardBox(
                fillColor: Color(hex: "#121216"),
                borderColor: Color.white.opacity(0.85),
                borderWidth: 2,
                shadowColor: Color.black,
                shadowOffset: 3
            )
        )
    }

    private func terminalLogLine(label: String, value: String, valueColor: Color) -> some View {
        HStack(alignment: .top, spacing: 5) {
            Text(label)
                .font(.system(size: 9.5, weight: .black, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.55))
                .frame(width: 32, alignment: .leading)

            Text(value)
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }
}

// MARK: - 1. MODULAR SUBCOMPONENT: RoomInteriorRenderer

/// Standalone modular renderer for each Zone's 3/4 RPG interior (Top Wall + Textured Flooring + Grounded Furniture).
/// To replace procedural pixel art with a PNG tileset later, simply replace the body with:
/// `Image("room_\(zone.id)").resizable().interpolation(.none)`
struct RoomInteriorRenderer: View {
    let zone: AvatarBaseTabView.Zone

    @Environment(\.tacticalTick) private var tick

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                // Layer 1 & 2 & 3 rendered on a crisp pixel-aligned Canvas
                Canvas { context, size in
                    let wallHeight = round(size.height * 0.21)

                    // 1) FLOORING LAYER (Full coverage below top wall, zero empty black space)
                    drawFlooring(context: &context, size: size, wallHeight: wallHeight)

                    // 2) TOP WALL LAYER (Top 21% strip + vertical paneling + baseboard ledge + floor shadow)
                    drawTopWall(context: &context, size: size, wallHeight: wallHeight)

                    // 3) 3/4 RPG GROUNDED FURNITURE LAYER (Anchored to back wall & floor with drop shadows)
                    drawGroundedFurniture(context: &context, size: size, wallHeight: wallHeight, tick: tick)
                }

                // Neon Wall Sign mounted directly on the Top Wall
                neonWallSign
                    .padding(.leading, 7)
                    .padding(.top, 5)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Neon Sign on Top Wall

    private var neonWallSign: some View {
        HStack(spacing: 4) {
            Rectangle()
                .fill(Color.black)
                .frame(width: 3, height: 3)
            Text(zone.codeTag)
                .font(.system(size: 8.5, weight: .black, design: .monospaced))
                .foregroundStyle(Color.black)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Rectangle()
                .fill(Color.black)
                .frame(width: 3, height: 3)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2.5)
        .background(
            ZStack {
                Rectangle()
                    .fill(Color.black)
                    .offset(x: 2, y: 2)
                Rectangle()
                    .fill(zone.accentColor)
                Rectangle()
                    .stroke(Color.black, lineWidth: 1.5)
            }
        )
    }

    // MARK: - Layer 1: Zone-Specific Flooring

    private func drawFlooring(context: inout GraphicsContext, size: CGSize, wallHeight: CGFloat) {
        let floorRect = CGRect(x: 0, y: wallHeight, width: size.width, height: size.height - wallHeight)

        switch zone {
        case .ironGym:
            // Dark anthracite rubber gym tiles
            context.fill(Path(floorRect), with: .color(Color(hex: "#181A22")))
            let tileSize: CGFloat = 18
            var y = wallHeight
            var row = 0
            while y < size.height {
                var x: CGFloat = 0
                var col = 0
                while x < size.width {
                    let isAlt = (row + col) % 2 == 0
                    let cell = CGRect(x: x, y: y, width: tileSize, height: tileSize)
                    context.fill(
                        Path(cell),
                        with: .color(isAlt ? Color(hex: "#191C24") : Color(hex: "#15171E"))
                    )
                    // Tile seam
                    context.stroke(Path(cell), with: .color(Color(hex: "#0F1015")), lineWidth: 1)
                    // Rubber speckle pixel
                    let speck = CGRect(x: x + 4, y: y + 5, width: 2, height: 2)
                    context.fill(Path(speck), with: .color(Color.white.opacity(0.04)))
                    x += tileSize
                    col += 1
                }
                y += tileSize
                row += 1
            }

            // Center Neon-Green Bordered Workout Mat
            let matRect = CGRect(
                x: round(size.width * 0.16),
                y: round(wallHeight + (size.height - wallHeight) * 0.20),
                width: round(size.width * 0.68),
                height: round((size.height - wallHeight) * 0.62)
            )
            // Mat floor shadow
            context.fill(
                Path(matRect.offsetBy(dx: 2, dy: 2)),
                with: .color(Color.black.opacity(0.6))
            )
            context.fill(Path(matRect), with: .color(Color(hex: "#111319")))
            context.stroke(Path(matRect), with: .color(Color(hex: "#CCFF00").opacity(0.85)), lineWidth: 2)
            context.stroke(
                Path(matRect.insetBy(dx: 4, dy: 4)),
                with: .color(Color(hex: "#CCFF00").opacity(0.25)),
                style: StrokeStyle(lineWidth: 1, dash: [4, 3])
            )

        case .fuelLab:
            // Dark gray / carbon checkerboard kitchen tiles
            let tileSize: CGFloat = 16
            var y = wallHeight
            var row = 0
            while y < size.height {
                var x: CGFloat = 0
                var col = 0
                while x < size.width {
                    let isDark = (row + col) % 2 == 0
                    let cell = CGRect(x: x, y: y, width: tileSize, height: tileSize)
                    context.fill(
                        Path(cell),
                        with: .color(isDark ? Color(hex: "#13141A") : Color(hex: "#21232E"))
                    )
                    if !isDark {
                        let glint = CGRect(x: x + 1, y: y + 1, width: tileSize - 2, height: 1.5)
                        context.fill(Path(glint), with: .color(Color.white.opacity(0.06)))
                    }
                    context.stroke(Path(cell), with: .color(Color(hex: "#0D0E12")), lineWidth: 0.8)
                    x += tileSize
                    col += 1
                }
                y += tileSize
                row += 1
            }

        case .cryoLounge:
            // Warm dark walnut vertical RPG wood planks (matching the reference image's plank architecture)
            context.fill(Path(floorRect), with: .color(Color(hex: "#1F1917")))
            let plankW: CGFloat = 12
            var x: CGFloat = 0
            var col = 0
            while x < size.width {
                let plankTone = (col % 3 == 0)
                    ? Color(hex: "#241D1A")
                    : (col % 2 == 0 ? Color(hex: "#1E1816") : Color(hex: "#221B18"))
                let colRect = CGRect(x: x, y: wallHeight, width: plankW, height: size.height - wallHeight)
                context.fill(Path(colRect), with: .color(plankTone))

                // Vertical seam line
                let vSeam = CGRect(x: x, y: wallHeight, width: 1, height: size.height - wallHeight)
                context.fill(Path(vSeam), with: .color(Color(hex: "#120E0D")))

                // Staggered horizontal plank joints
                let jointStep: CGFloat = 26
                var jointY = wallHeight + CGFloat((col * 11) % 22) + 8
                while jointY < size.height {
                    let hSeam = CGRect(x: x, y: jointY, width: plankW, height: 1.2)
                    context.fill(Path(hSeam), with: .color(Color(hex: "#120E0D")))
                    jointY += jointStep
                }
                x += plankW
                col += 1
            }

            // Center Pixel Lounge Rug
            let rugRect = CGRect(
                x: round(size.width * 0.16),
                y: round(wallHeight + (size.height - wallHeight) * 0.24),
                width: round(size.width * 0.66),
                height: round((size.height - wallHeight) * 0.56)
            )
            context.fill(Path(rugRect.offsetBy(dx: 2, dy: 2)), with: .color(Color.black.opacity(0.5)))
            context.fill(Path(rugRect), with: .color(Color(hex: "#291E24")))
            context.stroke(Path(rugRect), with: .color(Color(hex: "#FF9900").opacity(0.85)), lineWidth: 2)
            context.stroke(Path(rugRect.insetBy(dx: 4, dy: 4)), with: .color(Color(hex: "#FF9900").opacity(0.35)), lineWidth: 1)

        case .commandDeck:
            // Dark metallic server-room raised grid flooring
            context.fill(Path(floorRect), with: .color(Color(hex: "#12161E")))
            let tileSize: CGFloat = 18
            var y = wallHeight
            while y < size.height {
                var x: CGFloat = 0
                while x < size.width {
                    let cell = CGRect(x: x, y: y, width: tileSize, height: tileSize)
                    context.fill(Path(cell.insetBy(dx: 0.8, dy: 0.8)), with: .color(Color(hex: "#161B25")))
                    context.stroke(Path(cell), with: .color(Color(hex: "#0B0E14")), lineWidth: 1)

                    // Corner rivets
                    let r1 = CGRect(x: x + 2, y: y + 2, width: 1.5, height: 1.5)
                    let r2 = CGRect(x: x + tileSize - 3.5, y: y + 2, width: 1.5, height: 1.5)
                    context.fill(Path(r1), with: .color(Color(hex: "#2B3548")))
                    context.fill(Path(r2), with: .color(Color(hex: "#2B3548")))
                    x += tileSize
                }
                y += tileSize
            }

            // Glowing Neon Cyan Sub-Floor Cable Conduits from Back Server Wall to Center Desk
            let cyanGlow = Color(hex: "#00F0FF")
            var cablePath = Path()
            let leftBusX = round(size.width * 0.34)
            let rightBusX = round(size.width * 0.66)
            let midY = round(wallHeight + (size.height - wallHeight) * 0.55)

            cablePath.move(to: CGPoint(x: leftBusX, y: wallHeight))
            cablePath.addLine(to: CGPoint(x: leftBusX, y: midY))
            cablePath.addLine(to: CGPoint(x: size.width * 0.5, y: midY))

            cablePath.move(to: CGPoint(x: rightBusX, y: wallHeight))
            cablePath.addLine(to: CGPoint(x: rightBusX, y: midY))
            cablePath.addLine(to: CGPoint(x: size.width * 0.5, y: midY))

            context.stroke(cablePath, with: .color(cyanGlow.opacity(0.25)), lineWidth: 4)
            context.stroke(cablePath, with: .color(cyanGlow.opacity(0.8)), lineWidth: 1.5)
        }
    }

    // MARK: - Layer 2: 3/4 Perspective Top Wall & Baseboard Shadow

    private func drawTopWall(context: inout GraphicsContext, size: CGSize, wallHeight: CGFloat) {
        let wallRect = CGRect(x: 0, y: 0, width: size.width, height: wallHeight)

        // Base wall tone
        context.fill(Path(wallRect), with: .color(Color(hex: "#212430")))

        // Top ceiling crown trim
        let crownRect = CGRect(x: 0, y: 0, width: size.width, height: 4)
        context.fill(Path(crownRect), with: .color(Color(hex: "#13151C")))

        // Vertical architectural wall panel seams
        let panelSpacing: CGFloat = 24
        var px: CGFloat = panelSpacing
        while px < size.width {
            let seam = CGRect(x: px, y: 4, width: 1, height: wallHeight - 8)
            context.fill(Path(seam), with: .color(Color.black.opacity(0.35)))
            px += panelSpacing
        }

        // Accent neon strip along upper wall
        let neonStrip = CGRect(x: 0, y: wallHeight - 7, width: size.width, height: 1.5)
        context.fill(Path(neonStrip), with: .color(zone.accentColor.opacity(0.45)))

        // 3D Baseboard ledge at the bottom of the top wall
        let baseboard = CGRect(x: 0, y: wallHeight - 5, width: size.width, height: 5)
        context.fill(Path(baseboard), with: .color(Color(hex: "#14161E")))
        let wallBottomLine = CGRect(x: 0, y: wallHeight - 1.5, width: size.width, height: 1.5)
        context.fill(Path(wallBottomLine), with: .color(Color.black))

        // Deep floor drop shadow immediately below the wall (gives 3/4 RPG room depth)
        let wallShadow = CGRect(x: 0, y: wallHeight, width: size.width, height: 7)
        context.fill(Path(wallShadow), with: .color(Color.black.opacity(0.48)))
    }

    // MARK: - Layer 3: Grounded 3/4 RPG Room Furniture

    private func drawGroundedFurniture(
        context: inout GraphicsContext,
        size: CGSize,
        wallHeight: CGFloat,
        tick: Int
    ) {
        switch zone {
        case .ironGym:
            drawGymInterior(context: &context, size: size, wallHeight: wallHeight)
        case .fuelLab:
            drawFuelLabInterior(context: &context, size: size, wallHeight: wallHeight)
        case .cryoLounge:
            drawCryoLoungeInterior(context: &context, size: size, wallHeight: wallHeight, tick: tick)
        case .commandDeck:
            drawCommandDeckInterior(context: &context, size: size, wallHeight: wallHeight, tick: tick)
        }
    }

    // MARK: - Zone 01: Iron Gym Grounded Furniture

    private func drawGymInterior(context: inout GraphicsContext, size: CGSize, wallHeight: CGFloat) {
        let w = size.width
        let h = size.height

        // 1. Back-Wall Gym Mirror (mounted on top wall, right-center)
        let mirrorRect = CGRect(
            x: round(w * 0.42),
            y: round(wallHeight * 0.18),
            width: round(w * 0.26),
            height: round(wallHeight * 0.72)
        )
        context.fill(Path(mirrorRect), with: .color(Color(hex: "#1A2B3C")))
        context.stroke(Path(mirrorRect), with: .color(Color(hex: "#CCFF00")), lineWidth: 1.5)
        // Diagonal reflection glints
        var glint = Path()
        glint.move(to: CGPoint(x: mirrorRect.minX + 5, y: mirrorRect.maxY - 3))
        glint.addLine(to: CGPoint(x: mirrorRect.minX + 13, y: mirrorRect.minY + 3))
        glint.move(to: CGPoint(x: mirrorRect.minX + 11, y: mirrorRect.maxY - 3))
        glint.addLine(to: CGPoint(x: mirrorRect.minX + 19, y: mirrorRect.minY + 3))
        context.stroke(glint, with: .color(Color.white.opacity(0.5)), lineWidth: 1.5)

        // 2. Dumbbell Rack (flush against the right side of the back wall)
        let rackW = min(54, max(38, w * 0.28))
        let rackH = min(30, max(22, h * 0.14))
        let rackOrigin = CGPoint(x: round(w * 0.70), y: round(wallHeight - rackH * 0.42))
        drawGroundedSprite(
            context: &context,
            matrix: FurnitureSprites.gymDumbbellRack,
            origin: rackOrigin,
            size: CGSize(width: rackW, height: rackH),
            shadowInsetY: 3
        )

        // 3. 3/4 Bench Press Station (grounded on the workout mat)
        let benchSize = min(62, max(44, min(w, h) * 0.31))
        let benchOrigin = CGPoint(
            x: round(w * 0.54),
            y: round(wallHeight + (h - wallHeight) * 0.22)
        )
        drawGroundedSprite(
            context: &context,
            matrix: FurnitureSprites.gymBenchPress3D,
            origin: benchOrigin,
            size: CGSize(width: benchSize, height: benchSize),
            shadowInsetY: 5
        )

        // 4. 3/4 Treadmill (grounded on bottom-left gym floor)
        let treadSize = min(58, max(42, min(w, h) * 0.29))
        let treadOrigin = CGPoint(
            x: round(w * 0.12),
            y: round(wallHeight + (h - wallHeight) * 0.42)
        )
        drawGroundedSprite(
            context: &context,
            matrix: FurnitureSprites.gymTreadmill3D,
            origin: treadOrigin,
            size: CGSize(width: treadSize, height: treadSize),
            shadowInsetY: 4
        )
    }

    // MARK: - Zone 02: Fuel Lab Grounded Furniture

    private func drawFuelLabInterior(context: inout GraphicsContext, size: CGSize, wallHeight: CGFloat) {
        let w = size.width
        let h = size.height

        // 1. Overhead Range Hood (Davlumbaz) on the Top Wall
        let hoodRect = CGRect(
            x: round(w * 0.46),
            y: 2,
            width: round(w * 0.22),
            height: round(wallHeight * 0.58)
        )
        context.fill(Path(hoodRect), with: .color(Color(hex: "#383C4C")))
        context.stroke(Path(hoodRect), with: .color(Color.black), lineWidth: 1.5)
        let hoodVent = CGRect(x: hoodRect.minX + 3, y: hoodRect.maxY - 4, width: hoodRect.width - 6, height: 3)
        context.fill(Path(hoodVent), with: .color(Color(hex: "#FF0055")))

        // 2. Wall-to-Wall Kitchen Counter & Stove (flush against the back wall)
        let counterW = round(w * 0.62)
        let counterH = min(36, max(24, h * 0.16))
        let counterOrigin = CGPoint(x: round(w * 0.08), y: round(wallHeight - counterH * 0.35))
        drawGroundedSprite(
            context: &context,
            matrix: FurnitureSprites.fuelBackWallCounter,
            origin: counterOrigin,
            size: CGSize(width: counterW, height: counterH),
            shadowInsetY: 3
        )

        // 3. Tall Cyber Refrigerator (right side against back wall)
        let fridgeW = min(36, max(26, w * 0.20))
        let fridgeH = min(48, max(34, h * 0.22))
        let fridgeOrigin = CGPoint(x: round(w * 0.72), y: round(wallHeight - fridgeH * 0.52))
        drawGroundedSprite(
            context: &context,
            matrix: FurnitureSprites.fuelCyberFridge,
            origin: fridgeOrigin,
            size: CGSize(width: fridgeW, height: fridgeH),
            shadowInsetY: 4
        )

        // 4. Center 3/4 Dining Table + Bar Stools with Burger & Drink ON THE TABLE
        let tableW = min(78, max(54, w * 0.46))
        let tableH = min(56, max(40, h * 0.27))
        let tableOrigin = CGPoint(
            x: round((w - tableW) * 0.52),
            y: round(wallHeight + (h - wallHeight) * 0.36)
        )
        drawGroundedSprite(
            context: &context,
            matrix: FurnitureSprites.fuelDiningTableWithBurgerAndDrink,
            origin: tableOrigin,
            size: CGSize(width: tableW, height: tableH),
            shadowInsetY: 5
        )
    }

    // MARK: - Zone 03: Cryo Lounge Grounded Furniture

    private func drawCryoLoungeInterior(
        context: inout GraphicsContext,
        size: CGSize,
        wallHeight: CGFloat,
        tick: Int
    ) {
        let w = size.width
        let h = size.height

        // 1. Tall Retro Arcade Cabinet (against back wall, right side)
        let arcadeW = min(42, max(30, w * 0.23))
        let arcadeH = min(52, max(36, h * 0.24))
        let arcadeOrigin = CGPoint(x: round(w * 0.66), y: round(wallHeight - arcadeH * 0.45))
        drawGroundedSprite(
            context: &context,
            matrix: FurnitureSprites.loungeArcadeCabinet(blink: tick % 2 == 0),
            origin: arcadeOrigin,
            size: CGSize(width: arcadeW, height: arcadeH),
            shadowInsetY: 4
        )

        // 2. Corner Potted Plant (left corner near back wall, just like the reference image)
        let plantSize = min(36, max(26, min(w, h) * 0.18))
        let plantOrigin = CGPoint(x: round(w * 0.07), y: round(wallHeight + 2))
        drawGroundedSprite(
            context: &context,
            matrix: FurnitureSprites.loungePottedPlant,
            origin: plantOrigin,
            size: CGSize(width: plantSize, height: plantSize),
            shadowInsetY: 3
        )

        // 3. Center Wide 3/4 L-Sofa + Coffee Table (seated on the lounge rug)
        let sofaW = min(76, max(52, w * 0.46))
        let sofaH = min(50, max(36, h * 0.24))
        let sofaOrigin = CGPoint(
            x: round(w * 0.20),
            y: round(wallHeight + (h - wallHeight) * 0.24)
        )
        drawGroundedSprite(
            context: &context,
            matrix: FurnitureSprites.loungeLSofa3D,
            origin: sofaOrigin,
            size: CGSize(width: sofaW, height: sofaH),
            shadowInsetY: 5
        )

        // 4. TV Media Unit facing the L-Sofa (lower center)
        let tvUnitW = min(68, max(48, w * 0.42))
        let tvUnitH = min(40, max(28, h * 0.19))
        let tvOrigin = CGPoint(
            x: round(w * 0.24),
            y: round(wallHeight + (h - wallHeight) * 0.62)
        )
        drawGroundedSprite(
            context: &context,
            matrix: FurnitureSprites.loungeTVUnit3D,
            origin: tvOrigin,
            size: CGSize(width: tvUnitW, height: tvUnitH),
            shadowInsetY: 4
        )
    }

    // MARK: - Zone 04: Command Deck Grounded Furniture

    private func drawCommandDeckInterior(
        context: inout GraphicsContext,
        size: CGSize,
        wallHeight: CGFloat,
        tick: Int
    ) {
        let w = size.width
        let h = size.height

        // 1. Back-Wall Server Rack Cabinets (flush against the top wall)
        let rackW = min(44, max(32, w * 0.25))
        let rackH = min(48, max(34, h * 0.22))
        let leftRackOrigin = CGPoint(x: round(w * 0.16), y: round(wallHeight - rackH * 0.46))
        let rightRackOrigin = CGPoint(x: round(w * 0.56), y: round(wallHeight - rackH * 0.46))

        drawGroundedSprite(
            context: &context,
            matrix: PixelArtCatalog.commandServerRack(blink: tick % 2 == 0),
            origin: leftRackOrigin,
            size: CGSize(width: rackW, height: rackH),
            shadowInsetY: 4
        )
        drawGroundedSprite(
            context: &context,
            matrix: PixelArtCatalog.commandServerRack(blink: tick % 2 != 0),
            origin: rightRackOrigin,
            size: CGSize(width: rackW, height: rackH),
            shadowInsetY: 4
        )

        // 2. Center Wide 3/4 Command Desk with 3 Monitors & Gaming Chair
        let deskW = min(84, max(58, w * 0.50))
        let deskH = min(62, max(44, h * 0.30))
        let deskOrigin = CGPoint(
            x: round((w - deskW) * 0.52),
            y: round(wallHeight + (h - wallHeight) * 0.34)
        )
        drawGroundedSprite(
            context: &context,
            matrix: FurnitureSprites.commandTripleMonitorDeskAndChair,
            origin: deskOrigin,
            size: CGSize(width: deskW, height: deskH),
            shadowInsetY: 5
        )
    }

    // MARK: - Grounded Sprite Helper (Draws Floor Shadow + Pixel Matrix)

    private func drawGroundedSprite(
        context: inout GraphicsContext,
        matrix: [[Int]],
        origin: CGPoint,
        size: CGSize,
        shadowInsetY: CGFloat
    ) {
        let rowCount = matrix.count
        guard rowCount > 0 else { return }
        let colCount = matrix[0].count
        guard colCount > 0 else { return }

        // Grounded dark pixel shadow underneath the furniture base
        let shadowRect = CGRect(
            x: origin.x + 3,
            y: origin.y + size.height - shadowInsetY,
            width: size.width - 2,
            height: shadowInsetY + 3
        )
        context.fill(Path(shadowRect), with: .color(Color.black.opacity(0.62)))

        let pixelW = size.width / CGFloat(colCount)
        let pixelH = size.height / CGFloat(rowCount)

        for r in 0..<rowCount {
            let row = matrix[r]
            for c in 0..<min(colCount, row.count) {
                let code = row[c]
                guard code != 0, let color = PixelArtCatalog.palette[code] else { continue }

                let rect = CGRect(
                    x: origin.x + CGFloat(c) * pixelW,
                    y: origin.y + CGFloat(r) * pixelH,
                    width: ceil(pixelW + 0.25),
                    height: ceil(pixelH + 0.25)
                )
                context.fill(Path(rect), with: .color(color))
            }
        }
    }
}

// MARK: - 2. MODULAR SUBCOMPONENT: AvatarSpriteRenderer

/// Standalone modular renderer for the 16x16 character sprite.
/// To replace procedural pixel art with PNG sprites later, simply replace the body with:
/// `Image(spriteAssetName).resizable().interpolation(.none)`
struct AvatarSpriteRenderer: View {
    let state: AvatarBaseTabView.AvatarState
    let isWalking: Bool

    @Environment(\.tacticalTick) private var tick

    var body: some View {
        let effectiveState: AvatarBaseTabView.AvatarState = isWalking ? .walking : state
        let matrix = PixelArtCatalog.avatarFrame(state: effectiveState, tick: tick)

        ZStack(alignment: .bottom) {
            // Grounded pixel foot shadow
            Ellipse()
                .fill(Color.black.opacity(0.68))
                .frame(width: 28, height: 8)
                .offset(y: 2)

            // 16x16 Crisp Pixel Matrix Character
            PixelMatrixView(
                matrix: matrix,
                palette: PixelArtCatalog.palette
            )
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Tactical Neobrutalist Structural Views & Shapes

/// Sharp-cornered Neobrutalist container with unblurred 45-degree hard drop shadow.
private struct TacticalHardBox: View {
    var fillColor: Color
    var borderColor: Color
    var borderWidth: CGFloat = 2.5
    var shadowColor: Color = .black
    var shadowOffset: CGFloat = 4

    var body: some View {
        ZStack {
            Rectangle()
                .fill(shadowColor)
                .offset(x: shadowOffset, y: shadowOffset)

            Rectangle()
                .fill(fillColor)

            Rectangle()
                .stroke(borderColor, lineWidth: borderWidth)
        }
    }
}

/// Tactile press button style for simulation triggers.
private struct TacticalPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(
                x: configuration.isPressed ? 2 : 0,
                y: configuration.isPressed ? 2 : 0
            )
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Subtle dot-matrix grid for the floor plan background.
private struct BlueprintDotMatrixGrid: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 14
            let dotSize: CGFloat = 1.6
            let dotColor = Color.white.opacity(0.11)

            var x: CGFloat = spacing / 2
            while x < size.width {
                var y: CGFloat = spacing / 2
                while y < size.height {
                    let rect = CGRect(
                        x: x - dotSize / 2,
                        y: y - dotSize / 2,
                        width: dotSize,
                        height: dotSize
                    )
                    context.fill(Path(rect), with: .color(dotColor))
                    y += spacing
                }
                x += spacing
            }
        }
        .allowsHitTesting(false)
    }
}

/// Draws tactical floor guide lines connecting the Center Hub (0.5, 0.5) to the 4 zone centers.
private struct CorridorFloorOverlay: View {
    var body: some View {
        Canvas { context, size in
            let midX = size.width * 0.5
            let midY = size.height * 0.5

            // Vertical & horizontal central corridor channels
            let hChannel = CGRect(x: 0, y: midY - 7, width: size.width, height: 14)
            let vChannel = CGRect(x: midX - 7, y: 0, width: 14, height: size.height)

            context.fill(Path(hChannel), with: .color(Color.white.opacity(0.03)))
            context.fill(Path(vChannel), with: .color(Color.white.opacity(0.03)))

            // Subtle waypoint guide tracks from Center Hub (0.5, 0.5) to each room center
            var guidePath = Path()
            let targets = [
                CGPoint(x: size.width * 0.25, y: size.height * 0.25),
                CGPoint(x: size.width * 0.75, y: size.height * 0.25),
                CGPoint(x: size.width * 0.25, y: size.height * 0.75),
                CGPoint(x: size.width * 0.75, y: size.height * 0.75)
            ]
            for pt in targets {
                guidePath.move(to: CGPoint(x: midX, y: midY))
                guidePath.addLine(to: CGPoint(x: pt.x, y: pt.y))
            }
            context.stroke(
                guidePath,
                with: .color(Color.white.opacity(0.12)),
                style: StrokeStyle(lineWidth: 1.2, dash: [3, 4])
            )
        }
        .allowsHitTesting(false)
    }
}

/// Draws a room perimeter with a doorway opening on the corner facing the Center Hub (0.5, 0.5).
private struct RoomWallShape: Shape {
    var zone: AvatarBaseTabView.Zone
    var closedFullRect: Bool

    func path(in rect: CGRect) -> Path {
        if closedFullRect {
            return Path(rect)
        }

        let doorGap: CGFloat = min(rect.width, rect.height) * 0.24
        var path = Path()

        switch zone {
        case .ironGym:
            path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - doorGap))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX - doorGap, y: rect.maxY))

        case .fuelLab:
            path.move(to: CGPoint(x: rect.minX + doorGap, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - doorGap))

        case .cryoLounge:
            path.move(to: CGPoint(x: rect.maxX - doorGap, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + doorGap))

        case .commandDeck:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY + doorGap))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX + doorGap, y: rect.minY))
        }

        return path
    }
}

/// Renders threshold jamb ticks at the doorway opening facing the Center Hub.
private struct DoorwayThresholdIndicator: View {
    var zone: AvatarBaseTabView.Zone
    var color: Color

    var body: some View {
        Canvas { context, size in
            let doorGap: CGFloat = min(size.width, size.height) * 0.24
            var threshold = Path()

            switch zone {
            case .ironGym:
                threshold.move(to: CGPoint(x: size.width - doorGap, y: size.height))
                threshold.addLine(to: CGPoint(x: size.width, y: size.height - doorGap))
            case .fuelLab:
                threshold.move(to: CGPoint(x: doorGap, y: size.height))
                threshold.addLine(to: CGPoint(x: 0, y: size.height - doorGap))
            case .cryoLounge:
                threshold.move(to: CGPoint(x: size.width - doorGap, y: 0))
                threshold.addLine(to: CGPoint(x: size.width, y: doorGap))
            case .commandDeck:
                threshold.move(to: CGPoint(x: doorGap, y: 0))
                threshold.addLine(to: CGPoint(x: 0, y: doorGap))
            }

            context.stroke(
                threshold,
                with: .color(color.opacity(0.55)),
                style: StrokeStyle(lineWidth: 2, dash: [3, 3])
            )
        }
        .allowsHitTesting(false)
    }
}

/// Reticle and grid inside the 3x CCTV Zoom Inspector viewport.
private struct CCTVReticleOverlay: View {
    var accentColor: Color

    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 16
            var grid = Path()
            var x: CGFloat = step
            while x < size.width {
                grid.move(to: CGPoint(x: x, y: 0))
                grid.addLine(to: CGPoint(x: x, y: size.height))
                x += step
            }
            var y: CGFloat = step
            while y < size.height {
                grid.move(to: CGPoint(x: 0, y: y))
                grid.addLine(to: CGPoint(x: size.width, y: y))
                y += step
            }
            context.stroke(grid, with: .color(accentColor.opacity(0.1)), lineWidth: 1)

            // Corner brackets
            let inset: CGFloat = 6
            let len: CGFloat = 10
            var brackets = Path()
            brackets.move(to: CGPoint(x: inset, y: inset + len))
            brackets.addLine(to: CGPoint(x: inset, y: inset))
            brackets.addLine(to: CGPoint(x: inset + len, y: inset))

            brackets.move(to: CGPoint(x: size.width - inset - len, y: inset))
            brackets.addLine(to: CGPoint(x: size.width - inset, y: inset))
            brackets.addLine(to: CGPoint(x: size.width - inset, y: inset + len))

            brackets.move(to: CGPoint(x: inset, y: size.height - inset - len))
            brackets.addLine(to: CGPoint(x: inset, y: size.height - inset))
            brackets.addLine(to: CGPoint(x: inset + len, y: size.height - inset))

            brackets.move(to: CGPoint(x: size.width - inset - len, y: size.height - inset))
            brackets.addLine(to: CGPoint(x: size.width - inset, y: size.height - inset))
            brackets.addLine(to: CGPoint(x: size.width - inset, y: size.height - inset - len))

            context.stroke(brackets, with: .color(accentColor.opacity(0.75)), lineWidth: 1.5)
        }
        .allowsHitTesting(false)
    }
}

/// Subtle horizontal scanlines for the CCTV monitor.
private struct CCTVScanlines: View {
    var body: some View {
        Canvas { context, size in
            var y: CGFloat = 0
            while y < size.height {
                let rect = CGRect(x: 0, y: y, width: size.width, height: 1)
                context.fill(Path(rect), with: .color(Color.black.opacity(0.28)))
                y += 3
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - 2D Pixel Matrix Canvas Renderer

/// Renders any 2D integer matrix (`[[Int]]`) as crisp, unblurred 8-bit/16-bit pixel art using SwiftUI `Canvas`.
private struct PixelMatrixView: View {
    let matrix: [[Int]]
    let palette: [Int: Color]

    var body: some View {
        Canvas { context, size in
            let rowCount = matrix.count
            guard rowCount > 0 else { return }
            let colCount = matrix[0].count
            guard colCount > 0 else { return }

            let pixelW = size.width / CGFloat(colCount)
            let pixelH = size.height / CGFloat(rowCount)

            for r in 0..<rowCount {
                let row = matrix[r]
                for c in 0..<min(colCount, row.count) {
                    let code = row[c]
                    guard code != 0, let color = palette[code] else { continue }

                    let rect = CGRect(
                        x: CGFloat(c) * pixelW,
                        y: CGFloat(r) * pixelH,
                        width: ceil(pixelW + 0.25),
                        height: ceil(pixelH + 0.25)
                    )
                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - 3/4 RPG Furniture Pixel Matrices

private enum FurnitureSprites {

    /// Zone 01: Back-wall Dumbbell & Weight Rack (12x20)
    static let gymDumbbellRack: [[Int]] = [
        [0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0],
        [1,3,6,6,3,3,6,6,3,3,9,9,3,3,6,6,3,3,1,0],
        [1,2,1,1,2,2,1,1,2,2,1,1,2,2,1,1,2,2,1,0],
        [1,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,1,0],
        [1,2,8,8,2,2,8,8,2,2,7,7,2,2,6,6,2,2,1,0],
        [1,2,8,8,2,2,8,8,2,2,7,7,2,2,6,6,2,2,1,0],
        [1,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,1,0],
        [1,2,3,3,2,2,3,3,2,2,3,3,2,2,3,3,2,2,1,0],
        [1,2,3,3,2,2,3,3,2,2,3,3,2,2,3,3,2,2,1,0],
        [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0],
        [0,1,3,1,0,0,0,0,0,0,0,0,0,0,0,0,1,3,1,0],
        [0,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,0]
    ]

    /// Zone 01: 3/4 Perspective Bench Press Station with Uprights, Barbell & Bench Legs (16x16)
    static let gymBenchPress3D: [[Int]] = [
        [0,0,1,6,1,0,0,0,0,0,0,1,6,1,0,0],
        [0,1,6,4,6,1,3,3,3,3,1,6,4,6,1,0],
        [0,1,6,6,6,3,4,4,4,4,3,6,6,6,1,0],
        [0,0,1,6,1,1,3,1,1,3,1,1,6,1,0,0],
        [0,0,0,0,0,1,3,1,1,3,1,0,0,0,0,0],
        [0,0,0,0,1,2,2,2,2,2,2,1,0,0,0,0],
        [0,0,0,0,1,2,6,6,6,6,2,1,0,0,0,0],
        [0,0,0,0,1,2,2,2,2,2,2,1,0,0,0,0],
        [0,0,0,0,1,1,2,6,6,2,1,1,0,0,0,0],
        [0,0,0,0,0,1,2,6,6,2,1,0,0,0,0,0],
        [0,0,0,0,0,1,2,6,6,2,1,0,0,0,0,0],
        [0,0,0,0,0,1,2,2,2,2,1,0,0,0,0,0],
        [0,0,0,0,1,3,3,1,1,3,3,1,0,0,0,0],
        [0,0,0,0,1,3,1,0,0,1,3,1,0,0,0,0],
        [0,0,0,0,1,1,1,0,0,1,1,1,0,0,0,0],
        [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    ]

    /// Zone 01: 3/4 Perspective Treadmill with Console & Running Deck (16x16)
    static let gymTreadmill3D: [[Int]] = [
        [0,0,0,0,0,0,0,0,0,1,1,1,1,1,0,0],
        [0,0,0,0,0,0,0,0,1,2,6,4,6,2,1,0],
        [0,0,0,0,0,0,0,0,1,2,2,6,2,2,1,0],
        [0,0,0,0,0,0,0,0,0,1,3,1,3,1,0,0],
        [0,0,0,0,0,0,0,0,1,3,1,0,1,3,1,0],
        [0,0,0,0,0,0,0,1,3,1,0,0,1,3,1,0],
        [0,0,0,0,0,0,0,1,3,1,0,1,3,1,0,0],
        [0,0,0,0,0,0,1,3,1,0,0,1,3,1,0,0],
        [0,0,1,1,1,1,1,3,1,1,1,1,3,1,0,0],
        [0,1,6,6,6,6,6,6,6,6,6,6,6,1,0,0],
        [1,2,2,3,2,2,3,2,2,3,2,2,3,2,1,0],
        [1,2,3,2,2,3,2,2,3,2,2,3,2,2,1,0],
        [1,6,6,6,6,6,6,6,6,6,6,6,6,6,1,0],
        [1,3,3,3,3,3,3,3,3,3,3,3,3,3,1,0],
        [0,1,1,1,0,0,0,0,0,0,0,1,1,1,0,0],
        [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    ]

    /// Zone 02: Wall-to-Wall Kitchen Counter with Sink & Induction Stove (12x24)
    static let fuelBackWallCounter: [[Int]] = [
        [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
        [1,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,1],
        [1,4,4,9,9,9,9,4,4,4,4,1,10,1,4,1,10,1,4,4,8,8,4,1],
        [1,4,4,9,4,9,9,4,4,4,4,1,1,1,4,1,1,1,4,4,8,8,4,1],
        [1,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,1],
        [1,2,2,2,2,2,2,1,2,2,2,2,2,2,2,2,1,2,2,2,2,2,2,1],
        [1,2,3,3,3,2,2,1,2,7,7,7,7,7,7,2,1,2,2,3,3,3,2,1],
        [1,2,2,2,2,2,2,1,2,2,4,4,4,4,2,2,1,2,2,2,2,2,2,1],
        [1,2,2,2,2,4,2,1,2,2,2,2,2,2,2,2,1,2,4,2,2,2,2,1],
        [1,2,2,2,2,2,2,1,2,2,2,2,2,2,2,2,1,2,2,2,2,2,2,1],
        [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
        [0,1,1,1,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,1,1,1,0]
    ]

    /// Zone 02: Tall 3/4 Cyber Refrigerator (16x12)
    static let fuelCyberFridge: [[Int]] = [
        [0,1,1,1,1,1,1,1,1,1,1,0],
        [1,3,4,4,4,4,4,4,4,4,3,1],
        [1,2,3,3,3,3,3,3,3,3,2,1],
        [1,2,3,9,9,3,3,7,7,3,2,1],
        [1,2,3,9,4,3,3,3,3,4,2,1],
        [1,2,3,3,3,3,3,3,3,4,2,1],
        [1,1,1,1,1,1,1,1,1,1,1,1],
        [1,2,3,3,3,3,3,3,3,4,2,1],
        [1,2,3,3,3,3,3,3,3,4,2,1],
        [1,2,3,3,3,3,3,3,3,4,2,1],
        [1,2,3,3,3,3,3,3,3,3,2,1],
        [1,2,3,7,7,7,7,7,7,3,2,1],
        [1,2,2,2,2,2,2,2,2,2,2,1],
        [1,1,1,1,1,1,1,1,1,1,1,1],
        [0,1,2,1,0,0,0,0,1,2,1,0],
        [0,1,1,1,0,0,0,0,1,1,1,0]
    ]

    /// Zone 02: 3/4 Dining Table + Bar Stools with Burger & Drink ON THE TABLE (16x22)
    static let fuelDiningTableWithBurgerAndDrink: [[Int]] = [
        [0,0,0,0,0,0,0,1,1,1,1,0,0,0,0,4,4,0,0,0,0,0],
        [0,0,0,0,0,0,1,8,8,4,8,1,0,0,1,9,9,1,0,0,0,0],
        [0,0,0,0,0,0,1,6,6,6,6,1,0,0,1,7,9,1,0,0,0,0],
        [0,0,0,0,0,0,1,7,10,7,7,1,0,0,1,7,7,1,0,0,0,0],
        [0,0,0,0,1,1,1,8,8,8,8,1,1,1,1,4,4,1,0,0,0,0],
        [0,0,0,1,2,7,7,4,4,4,4,4,7,7,7,7,7,2,1,0,0,0],
        [1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1],
        [1,7,7,1,3,3,3,3,3,3,3,3,3,3,3,3,3,3,1,7,7,1],
        [1,2,2,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,2,2,1],
        [0,1,3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,3,1,0],
        [0,1,3,1,1,3,2,1,0,0,0,0,0,0,1,2,3,1,1,3,1,0],
        [0,1,3,1,1,3,2,1,0,0,0,0,0,0,1,2,3,1,1,3,1,0],
        [0,1,3,1,1,3,2,1,0,0,0,0,0,0,1,2,3,1,1,3,1,0],
        [1,3,3,3,1,3,2,1,0,0,0,0,0,0,1,2,3,1,3,3,3,1],
        [0,1,1,1,1,1,1,1,0,0,0,0,0,0,1,1,1,1,1,1,1,0],
        [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    ]

    /// Zone 03: Tall 3/4 Retro Arcade Cabinet (16x12)
    static func loungeArcadeCabinet(blink: Bool) -> [[Int]] {
        let s = blink ? 9 : 6
        return [
            [0,0,1,1,1,1,1,1,1,1,0,0],
            [0,1,8,8,4,8,8,4,8,8,1,0],
            [0,1,2,1,1,1,1,1,1,2,1,0],
            [0,1,8,1,2,9,9,2,1,8,1,0],
            [0,1,8,1,9,s,4,9,1,8,1,0],
            [0,1,8,1,2,9,9,2,1,8,1,0],
            [0,1,2,1,1,1,1,1,1,2,1,0],
            [1,8,8,10,3,6,7,3,8,8,8,1],
            [1,1,1,1,1,1,1,1,1,1,1,1],
            [0,1,2,2,2,2,2,2,2,2,1,0],
            [0,1,2,8,1,8,8,1,8,2,1,0],
            [0,1,2,2,1,10,10,1,2,2,1,0],
            [0,1,2,2,2,2,2,2,2,2,1,0],
            [0,1,8,8,8,8,8,8,8,8,1,0],
            [0,1,1,1,1,1,1,1,1,1,1,0],
            [0,0,1,3,1,0,0,1,3,1,0,0]
        ]
    }

    /// Zone 03: Corner Potted Plant (14x12, inspired by the reference office image)
    static let loungePottedPlant: [[Int]] = [
        [0,0,0,0,1,6,6,1,0,0,0,0],
        [0,0,1,6,6,4,6,6,1,0,0,0],
        [0,1,6,6,1,6,6,1,6,6,1,0],
        [1,6,4,6,6,6,6,6,4,6,6,1],
        [1,6,6,1,6,6,6,1,6,6,1,0],
        [0,1,1,6,6,6,6,6,1,1,0,0],
        [0,0,1,6,1,6,6,1,6,1,0,0],
        [0,0,0,1,1,3,3,1,1,0,0,0],
        [0,0,1,8,8,8,8,8,8,1,0,0],
        [0,0,1,1,8,8,8,8,1,1,0,0],
        [0,0,0,1,8,8,8,8,1,0,0,0],
        [0,0,0,1,8,2,2,8,1,0,0,0],
        [0,0,0,0,1,1,1,1,0,0,0,0],
        [0,0,0,0,0,0,0,0,0,0,0,0]
    ]

    /// Zone 03: Wide 3/4 L-Shaped Sofa + Coffee Table (14x22)
    static let loungeLSofa3D: [[Int]] = [
        [0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0],
        [1,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,1],
        [1,8,2,2,2,2,1,2,2,2,2,2,1,2,2,2,2,2,2,8,8,1],
        [1,8,2,8,8,2,1,2,2,8,8,2,1,2,2,2,8,8,2,8,8,1],
        [1,8,2,2,2,2,1,2,2,2,2,2,1,2,2,2,2,2,2,8,8,1],
        [1,8,3,3,3,3,3,3,3,3,3,3,3,3,3,2,2,2,2,8,8,1],
        [1,2,2,2,2,2,2,2,2,2,2,2,2,2,1,2,2,2,2,8,8,1],
        [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,3,3,3,8,8,1],
        [0,1,3,1,0,0,0,0,0,0,0,1,3,1,1,2,2,2,2,2,2,1],
        [0,0,0,0,0,1,1,1,1,1,1,0,0,0,1,1,1,1,1,1,1,1],
        [0,0,0,0,1,3,3,9,4,3,3,1,0,0,0,1,3,1,0,1,3,1],
        [0,0,0,0,1,2,2,2,2,2,2,1,0,0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,1,3,1,1,3,1,0,0,0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    ]

    /// Zone 03: 3/4 TV Media Console Unit (12x20)
    static let loungeTVUnit3D: [[Int]] = [
        [0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0],
        [0,0,0,1,2,9,9,9,8,8,4,9,9,9,9,2,1,0,0,0],
        [0,0,0,1,2,9,8,8,4,8,8,9,9,4,9,2,1,0,0,0],
        [0,0,0,1,2,9,9,9,9,9,9,9,9,9,9,2,1,0,0,0],
        [0,0,0,1,1,1,1,1,3,3,3,3,1,1,1,1,1,0,0,0],
        [0,0,0,0,0,0,0,1,3,3,3,3,1,0,0,0,0,0,0,0],
        [0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0],
        [1,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,1],
        [1,2,2,3,3,2,1,2,9,9,6,2,1,2,3,3,2,2,2,1],
        [1,2,2,2,2,2,1,2,2,2,2,2,1,2,2,2,2,2,2,1],
        [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
        [0,1,3,1,0,0,0,0,0,0,0,0,0,0,0,0,1,3,1,0]
    ]

    /// Zone 04: 3/4 Triple-Monitor Command Desk + Operator Gaming Chair (16x22)
    static let commandTripleMonitorDeskAndChair: [[Int]] = [
        [0,0,1,1,1,1,1,0,1,1,1,1,1,1,0,1,1,1,1,1,0,0],
        [0,1,2,9,9,4,2,1,2,9,4,9,9,2,1,2,9,4,9,2,1,0],
        [0,1,2,9,6,9,2,1,2,9,6,6,9,2,1,2,9,9,6,2,1,0],
        [0,1,2,9,9,9,2,1,2,9,9,9,9,2,1,2,6,9,9,2,1,0],
        [0,0,1,1,3,1,1,0,1,1,3,3,1,1,0,1,1,3,1,1,0,0],
        [0,0,0,1,3,1,0,0,0,1,3,3,1,0,0,0,1,3,1,0,0,0],
        [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
        [1,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,1],
        [1,2,2,2,3,4,3,4,3,4,3,2,2,9,2,2,8,8,2,2,2,1],
        [1,2,2,2,2,2,2,1,1,1,1,1,1,2,2,2,2,2,2,2,2,1],
        [1,3,3,3,3,3,1,9,2,2,2,2,9,1,3,3,3,3,3,3,3,1],
        [0,1,2,3,1,0,1,9,2,9,9,2,9,1,0,0,0,1,3,2,1,0],
        [0,1,2,3,1,0,1,2,2,2,2,2,2,1,0,0,0,1,3,2,1,0],
        [0,1,2,3,1,0,0,1,3,3,3,3,1,0,0,0,0,1,3,2,1,0],
        [0,1,1,1,1,0,0,1,1,3,3,1,1,0,0,0,0,1,1,1,1,0],
        [0,0,0,0,0,0,0,1,1,0,0,1,1,0,0,0,0,0,0,0,0,0]
    ]
}

// MARK: - Pixel Art Sprite Catalog (16x16 Matrices)

private enum PixelArtCatalog {

    /// Color Palette for 2D Pixel Matrices:
    /// 0 = Transparent
    /// 1 = Pitch Black (#08080A)
    /// 2 = Dark Tactical Armor / Chassis (#242632)
    /// 3 = Steel / Mid Metallic Gray (#565B70)
    /// 4 = Pure White Highlight (#F8FAFC)
    /// 5 = Skin / Warm Visor Tone (#FFB888)
    /// 6 = Neon Green (#CCFF00 - Iron Gym)
    /// 7 = Neon Pink (#FF0055 - Fuel Lab)
    /// 8 = Warm Amber (#FF9900 - Cryo Lounge)
    /// 9 = Neon Cyan (#00F0FF - Command Deck)
    /// 10 = Alert Red (#FF2A2A)
    static let palette: [Int: Color] = [
        1: Color(hex: "#08080A"),
        2: Color(hex: "#242632"),
        3: Color(hex: "#565B70"),
        4: Color(hex: "#F8FAFC"),
        5: Color(hex: "#FFB888"),
        6: Color(hex: "#CCFF00"),
        7: Color(hex: "#FF0055"),
        8: Color(hex: "#FF9900"),
        9: Color(hex: "#00F0FF"),
        10: Color(hex: "#FF2A2A")
    ]

    // MARK: - Dynamic Avatar Frame Selector (16x16)

    static func avatarFrame(state: AvatarBaseTabView.AvatarState, tick: Int) -> [[Int]] {
        switch state {
        case .walking:
            return (tick % 2 == 0) ? avatarWalkFrameA : avatarWalkFrameB
        case .hubWaiting:
            return (tick % 2 == 0) ? avatarHubWaitFrame1 : avatarHubWaitFrame2
        case .workingOut:
            let f = tick % 3
            if f == 0 { return avatarGymFrame1 }
            if f == 1 { return avatarGymFrame2 }
            return avatarGymFrame3
        case .preppingShake:
            return (tick % 2 == 0) ? avatarShakeFrame1 : avatarShakeFrame2
        case .activeRecovery:
            return (tick % 2 == 0) ? avatarGymFrame1 : avatarRestFrame1
        case .eating:
            let f = tick % 3
            if f == 0 { return avatarEatFrame1 }
            if f == 1 { return avatarEatFrame2 }
            return avatarEatFrame3
        case .staringAtDumbbells:
            return (tick % 2 == 0) ? avatarStareDumbbellsFrame1 : avatarStareDumbbellsFrame2
        case .resting:
            let f = tick % 3
            if f == 0 { return avatarRestFrame1 }
            if f == 1 { return avatarRestFrame2 }
            return avatarRestFrame3
        case .analyzing:
            let f = tick % 3
            if f == 0 { return avatarCommandFrame1 }
            if f == 1 { return avatarCommandFrame2 }
            return avatarCommandFrame3
        case .checkingFridge, .lowBatteryAlert:
            return (tick % 2 == 0) ? avatarLowBatteryFrame1 : avatarLowBatteryFrame2
        }
    }

    // MARK: - 16x16 Hub Waiting / Decision Frames

    static let avatarHubWaitFrame1: [[Int]] = [
        [0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0],
        [0,0,0,0,1,2,2,2,2,2,2,1,0,0,0,0],
        [0,0,0,1,2,2,9,9,9,9,2,2,1,0,0,0],
        [0,0,0,1,2,4,9,9,9,9,9,2,1,0,0,0],
        [0,0,0,1,2,5,5,5,5,5,5,2,1,0,0,0],
        [0,0,0,0,1,1,5,5,5,5,1,1,0,0,0,0],
        [0,0,0,1,2,2,1,1,1,1,2,2,1,0,0,0],
        [0,0,1,5,2,2,2,9,9,2,2,2,5,1,0,0],
        [0,0,0,1,2,2,2,9,9,2,2,2,1,0,0,0],
        [0,0,0,0,1,1,2,2,2,2,1,1,0,0,0,0],
        [0,0,0,0,0,1,3,3,3,3,1,0,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,1,6,6,6,1,1,6,6,6,1,0,0,0],
        [0,0,0,1,1,1,1,0,0,1,1,1,1,0,0,0]
    ]

    static let avatarHubWaitFrame2: [[Int]] = [
        [0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0],
        [0,0,0,0,1,2,2,2,2,2,2,1,0,0,0,0],
        [0,0,0,1,2,2,9,9,9,9,2,2,1,0,0,0],
        [0,0,0,1,2,9,9,9,9,9,4,2,1,0,0,0],
        [0,0,0,1,2,5,5,5,5,5,5,2,1,0,0,0],
        [0,0,0,0,1,1,5,5,5,5,1,1,0,0,0,0],
        [0,0,0,1,2,2,1,1,1,1,2,2,1,0,0,0],
        [0,0,1,5,2,2,2,6,6,2,2,2,5,1,0,0],
        [0,0,0,1,2,2,2,6,6,2,2,2,1,0,0,0],
        [0,0,0,0,1,1,2,2,2,2,1,1,0,0,0,0],
        [0,0,0,0,0,1,3,3,3,3,1,0,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,1,6,6,6,1,1,6,6,6,1,0,0,0],
        [0,0,0,1,1,1,1,0,0,1,1,1,1,0,0,0]
    ]

    // MARK: - 16x16 Protein Shake Prep Frames (Hyper-Charge in Fuel Lab)

    static let avatarShakeFrame1: [[Int]] = [
        [0,0,0,0,0,1,1,1,1,1,1,0,0,6,6,0],
        [0,0,0,0,1,2,2,2,2,2,2,1,0,9,4,0],
        [0,0,0,1,2,2,6,6,6,6,2,2,1,9,9,0],
        [0,0,0,1,2,6,6,4,6,6,6,2,1,5,5,0],
        [0,0,0,1,2,5,5,5,5,5,5,2,1,2,1,0],
        [0,0,0,0,1,1,5,5,5,5,1,1,2,2,1,0],
        [0,0,0,1,2,2,1,1,1,1,2,2,1,1,0,0],
        [0,0,1,5,2,2,2,6,6,2,2,2,1,0,0,0],
        [0,0,1,5,1,2,2,6,6,2,2,1,0,0,0,0],
        [0,0,0,1,0,1,2,2,2,2,1,0,0,0,0,0],
        [0,0,0,0,0,1,3,3,3,3,1,0,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,1,6,6,6,1,1,6,6,6,1,0,0,0],
        [0,0,0,1,1,1,1,0,0,1,1,1,1,0,0,0]
    ]

    static let avatarShakeFrame2: [[Int]] = [
        [0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0],
        [0,0,0,0,1,2,2,2,2,2,2,1,0,0,0,0],
        [0,0,0,1,2,2,6,6,6,6,2,2,1,0,0,0],
        [0,0,0,1,2,6,6,4,6,6,6,2,1,6,6,0],
        [0,0,0,1,2,5,5,5,5,5,5,2,1,9,4,0],
        [0,0,0,0,1,1,5,5,5,5,1,1,1,9,9,0],
        [0,0,0,1,2,2,1,1,1,1,2,2,5,5,1,0],
        [0,0,1,5,2,2,2,6,6,2,2,2,2,1,0,0],
        [0,0,1,5,1,2,2,6,6,2,2,1,0,0,0,0],
        [0,0,0,1,0,1,2,2,2,2,1,0,0,0,0,0],
        [0,0,0,0,0,1,3,3,3,3,1,0,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,1,6,6,6,1,1,6,6,6,1,0,0,0],
        [0,0,0,1,1,1,1,0,0,1,1,1,1,0,0,0]
    ]

    // MARK: - 16x16 Staring at Dumbbells ("Maybe Tomorrow") Frames

    static let avatarStareDumbbellsFrame1: [[Int]] = [
        [0,0,0,0,0,1,1,1,1,1,1,0,0,9,0,0],
        [0,0,0,0,1,2,2,2,2,2,2,1,9,4,9,0],
        [0,0,0,1,2,2,7,7,7,7,2,2,1,9,0,0],
        [0,0,0,1,2,8,8,8,8,4,8,2,1,0,0,0],
        [0,0,0,1,2,5,5,5,5,5,5,2,1,0,0,0],
        [0,0,0,0,1,1,5,5,5,5,1,1,0,0,0,0],
        [0,0,1,2,2,2,1,1,1,1,2,2,2,1,0,0],
        [0,1,2,1,2,2,2,7,7,2,2,2,1,2,1,0],
        [0,1,5,1,1,2,2,7,7,2,2,1,1,5,1,0],
        [0,0,1,0,0,1,2,2,2,2,1,0,0,1,0,0],
        [0,0,0,0,0,1,3,3,3,3,1,0,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,1,7,7,7,1,1,7,7,7,1,0,0,0],
        [0,0,0,1,1,1,1,0,0,1,1,1,1,0,0,0]
    ]

    static let avatarStareDumbbellsFrame2: [[Int]] = [
        [0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0],
        [0,0,0,0,1,2,2,2,2,2,2,1,0,9,0,0],
        [0,0,0,1,2,2,7,7,7,7,2,2,9,4,9,0],
        [0,0,0,1,2,4,8,8,8,8,8,2,1,9,0,0],
        [0,0,0,1,2,5,5,5,5,5,5,2,1,0,0,0],
        [0,0,0,0,1,1,5,5,5,5,1,1,0,0,0,0],
        [0,0,1,2,2,2,1,1,1,1,2,2,2,1,0,0],
        [0,1,2,1,2,2,2,7,7,2,2,2,1,2,1,0],
        [0,1,5,1,1,2,2,7,7,2,2,1,1,5,1,0],
        [0,0,1,0,0,1,2,2,2,2,1,0,0,1,0,0],
        [0,0,0,0,0,1,3,3,3,3,1,0,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,1,7,7,7,1,1,7,7,7,1,0,0,0],
        [0,0,0,1,1,1,1,0,0,1,1,1,1,0,0,0]
    ]

    // MARK: - 16x16 Depleted / Low Battery Frames

    static let avatarLowBatteryFrame1: [[Int]] = [
        [0,0,10,0,0,0,0,0,0,0,0,0,0,10,0,0],
        [0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0],
        [0,0,0,0,1,2,2,2,2,2,2,1,0,0,0,0],
        [0,0,0,1,2,2,10,10,10,10,2,2,1,0,0,0],
        [0,0,0,1,2,8,8,10,10,8,8,2,1,0,0,0],
        [0,0,0,1,2,5,5,5,5,5,5,2,1,0,0,0],
        [0,0,0,0,1,1,5,5,5,5,1,1,0,0,0,0],
        [0,0,0,1,2,2,1,1,1,1,2,2,1,0,0,0],
        [0,0,0,1,5,2,2,8,8,2,2,5,1,0,0,0],
        [0,0,0,0,1,2,2,8,8,2,2,1,0,0,0,0],
        [0,0,0,0,0,1,3,3,3,3,1,0,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,1,8,8,8,1,1,8,8,8,1,0,0,0],
        [0,0,0,1,1,1,1,0,0,1,1,1,1,0,0,0]
    ]

    static let avatarLowBatteryFrame2: [[Int]] = [
        [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0],
        [0,0,0,0,1,2,2,2,2,2,2,1,0,0,0,0],
        [0,0,0,1,2,2,8,8,8,8,2,2,1,0,0,0],
        [0,0,0,1,2,3,3,10,10,3,3,2,1,0,0,0],
        [0,0,0,1,2,5,5,5,5,5,5,2,1,0,0,0],
        [0,0,0,0,1,1,5,5,5,5,1,1,0,0,0,0],
        [0,0,0,1,2,2,1,1,1,1,2,2,1,0,0,0],
        [0,0,0,1,5,2,2,10,10,2,2,5,1,0,0,0],
        [0,0,0,0,1,2,2,8,8,2,2,1,0,0,0,0],
        [0,0,0,0,0,1,3,3,3,3,1,0,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,1,8,8,8,1,1,8,8,8,1,0,0,0],
        [0,0,0,1,1,1,1,0,0,1,1,1,1,0,0,0]
    ]

    // MARK: - 16x16 Avatar Walking Frames

    static let avatarWalkFrameA: [[Int]] = [
        [0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0],
        [0,0,0,0,1,2,2,2,2,2,2,1,0,0,0,0],
        [0,0,0,1,2,2,6,6,6,6,2,2,1,0,0,0],
        [0,0,0,1,2,9,9,4,9,9,9,2,1,0,0,0],
        [0,0,0,1,2,5,5,5,5,5,5,2,1,0,0,0],
        [0,0,0,0,1,1,5,5,5,5,1,1,0,0,0,0],
        [0,0,0,1,2,2,1,1,1,1,2,2,1,0,0,0],
        [0,0,1,5,2,2,2,6,6,2,2,2,3,1,0,0],
        [0,0,1,5,1,2,2,6,6,2,2,1,5,1,0,0],
        [0,0,0,1,0,1,2,2,2,2,1,0,1,0,0,0],
        [0,0,0,0,0,1,3,3,3,3,1,0,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,1,2,2,1,0,0,1,2,2,1,0,0,0],
        [0,0,1,6,6,1,0,0,0,0,1,2,2,1,0,0],
        [0,0,1,1,1,0,0,0,0,0,1,6,6,1,0,0],
        [0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0]
    ]

    static let avatarWalkFrameB: [[Int]] = [
        [0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0],
        [0,0,0,0,1,2,2,2,2,2,2,1,0,0,0,0],
        [0,0,0,1,2,2,6,6,6,6,2,2,1,0,0,0],
        [0,0,0,1,2,9,9,9,4,9,9,2,1,0,0,0],
        [0,0,0,1,2,5,5,5,5,5,5,2,1,0,0,0],
        [0,0,0,0,1,1,5,5,5,5,1,1,0,0,0,0],
        [0,0,0,1,2,2,1,1,1,1,2,2,1,0,0,0],
        [0,0,1,3,2,2,2,6,6,2,2,2,5,1,0,0],
        [0,0,1,5,1,2,2,6,6,2,2,1,5,1,0,0],
        [0,0,0,1,0,1,2,2,2,2,1,0,1,0,0,0],
        [0,0,0,0,0,1,3,3,3,3,1,0,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,1,2,2,1,0,0,1,2,2,1,0,0,0],
        [0,0,1,2,2,1,0,0,0,0,1,6,6,1,0,0],
        [0,0,1,6,6,1,0,0,0,0,0,1,1,1,0,0],
        [0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0]
    ]

    // MARK: - 16x16 Iron Gym Action Frames (Lifting Heavy Barbell)

    static let avatarGymFrame1: [[Int]] = [
        [0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0],
        [0,0,0,0,1,2,2,2,2,2,2,1,0,0,0,0],
        [0,0,0,1,2,2,6,6,6,6,2,2,1,0,0,0],
        [0,0,0,1,2,6,6,4,6,6,6,2,1,0,0,0],
        [0,0,0,1,2,5,5,5,5,5,5,2,1,0,0,0],
        [0,1,6,1,0,1,5,5,5,5,1,0,1,6,1,0],
        [1,6,6,6,1,3,3,3,3,3,3,1,6,6,6,1],
        [1,6,4,6,3,5,2,6,6,2,5,3,6,4,6,1],
        [0,1,6,1,0,1,2,6,6,2,1,0,1,6,1,0],
        [0,0,0,0,0,1,2,2,2,2,1,0,0,0,0,0],
        [0,0,0,0,0,1,3,3,3,3,1,0,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,1,6,6,6,1,1,6,6,6,1,0,0,0],
        [0,0,0,1,1,1,1,0,0,1,1,1,1,0,0,0]
    ]

    static let avatarGymFrame2: [[Int]] = [
        [0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0],
        [0,1,6,1,1,2,2,2,2,2,2,1,1,6,1,0],
        [1,6,6,6,1,3,3,3,3,3,3,1,6,6,6,1],
        [1,6,4,6,3,9,9,4,9,9,9,3,6,4,6,1],
        [0,1,6,1,5,5,5,5,5,5,5,5,1,6,1,0],
        [0,0,0,1,5,1,5,5,5,5,1,5,1,0,0,0],
        [0,0,0,0,1,2,1,1,1,1,2,1,0,0,0,0],
        [0,0,0,0,1,2,2,6,6,2,2,1,0,0,0,0],
        [0,0,0,0,0,1,2,6,6,2,1,0,0,0,0,0],
        [0,0,0,0,0,1,2,2,2,2,1,0,0,0,0,0],
        [0,0,0,0,0,1,3,3,3,3,1,0,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,1,6,6,6,1,1,6,6,6,1,0,0,0],
        [0,0,0,1,1,1,1,0,0,1,1,1,1,0,0,0]
    ]

    static let avatarGymFrame3: [[Int]] = [
        [0,1,6,1,0,0,0,0,0,0,0,0,1,6,1,0],
        [1,6,6,6,1,3,3,4,4,3,3,1,6,6,6,1],
        [1,6,4,6,1,5,1,1,1,1,5,1,6,4,6,1],
        [0,1,6,1,1,5,2,6,6,2,5,1,1,6,1,0],
        [0,0,0,0,1,2,6,4,4,6,2,1,0,0,0,0],
        [0,0,0,0,1,2,5,5,5,5,2,1,0,0,0,0],
        [0,0,0,0,0,1,1,5,5,1,1,0,0,0,0,0],
        [0,0,6,0,0,1,2,6,6,2,1,0,0,6,0,0],
        [0,0,0,0,0,1,2,6,6,2,1,0,0,0,0,0],
        [0,0,0,0,0,1,2,2,2,2,1,0,0,0,0,0],
        [0,0,0,0,0,1,3,3,3,3,1,0,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,1,6,6,6,1,1,6,6,6,1,0,0,0],
        [0,0,0,1,1,1,1,0,0,1,1,1,1,0,0,0]
    ]

    // MARK: - 16x16 Fuel Lab Action Frames (Eating Neon Burger)

    static let avatarEatFrame1: [[Int]] = [
        [0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0],
        [0,0,0,0,1,2,2,2,2,2,2,1,0,0,0,0],
        [0,0,0,1,2,2,7,7,7,7,2,2,1,0,0,0],
        [0,0,0,1,2,9,9,4,9,9,9,2,1,0,0,0],
        [0,0,0,1,2,5,5,5,5,5,5,2,1,8,8,0],
        [0,0,0,0,1,1,5,5,5,5,1,1,8,8,8,8],
        [0,0,0,1,2,2,1,1,1,1,2,1,6,6,6,6],
        [0,0,1,5,2,2,2,7,7,2,2,1,7,7,10,7],
        [0,0,1,5,1,2,2,7,7,2,2,5,8,8,8,8],
        [0,0,0,1,0,1,2,2,2,2,1,1,1,1,1,0],
        [0,0,0,0,0,1,3,3,3,3,1,0,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,1,7,7,7,1,1,7,7,7,1,0,0,0],
        [0,0,0,1,1,1,1,0,0,1,1,1,1,0,0,0]
    ]

    static let avatarEatFrame2: [[Int]] = [
        [0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0],
        [0,0,0,0,1,2,2,2,2,2,2,1,0,0,0,0],
        [0,0,0,1,2,2,7,7,7,7,2,2,1,0,0,0],
        [0,0,0,1,2,9,9,4,9,9,9,2,1,0,0,0],
        [0,0,0,1,2,5,5,5,1,1,8,8,8,0,0,0],
        [0,0,0,0,1,1,5,5,1,6,6,6,6,0,0,0],
        [0,0,0,1,2,2,1,1,1,7,7,10,7,0,0,0],
        [0,0,1,5,2,2,2,7,7,8,8,8,8,0,0,0],
        [0,0,1,5,1,2,2,7,7,2,5,5,1,0,0,0],
        [0,0,0,1,0,1,2,2,2,2,1,1,0,0,0,0],
        [0,0,0,0,0,1,3,3,3,3,1,0,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,1,7,7,7,1,1,7,7,7,1,0,0,0],
        [0,0,0,1,1,1,1,0,0,1,1,1,1,0,0,0]
    ]

    static let avatarEatFrame3: [[Int]] = [
        [0,7,0,0,0,1,1,1,1,1,1,0,0,7,0,0],
        [7,4,7,0,1,2,2,2,2,2,2,1,0,0,0,0],
        [0,7,0,1,2,2,7,7,7,7,2,2,1,0,0,0],
        [0,0,0,1,2,6,6,4,6,6,6,2,1,0,0,0],
        [0,0,0,1,2,5,5,5,5,5,5,2,1,0,0,0],
        [0,0,0,0,1,1,5,4,4,5,1,1,8,8,0,0],
        [0,0,0,1,2,2,1,1,1,1,2,1,6,6,0,0],
        [0,0,1,5,2,2,2,7,7,2,2,5,8,8,0,0],
        [0,0,1,5,1,2,2,7,7,2,2,1,1,0,0,0],
        [0,0,0,1,0,1,2,2,2,2,1,0,0,0,0,0],
        [0,0,0,0,0,1,3,3,3,3,1,0,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,1,7,7,7,1,1,7,7,7,1,0,0,0],
        [0,0,0,1,1,1,1,0,0,1,1,1,1,0,0,0]
    ]

    // MARK: - 16x16 Cryo Lounge Action Frames (Lounge Relaxation & Zzz)

    static let avatarRestFrame1: [[Int]] = [
        [0,0,0,0,0,1,1,1,1,1,1,0,0,8,8,0],
        [0,0,0,0,1,2,2,2,2,2,2,1,0,0,8,0],
        [0,0,0,1,2,2,8,8,8,8,2,2,1,8,8,0],
        [0,0,0,1,2,9,9,9,9,9,9,2,1,0,0,0],
        [0,0,0,1,2,5,5,5,5,5,5,2,1,0,0,0],
        [0,0,0,0,1,1,5,5,5,5,1,1,0,0,0,0],
        [0,0,0,1,2,2,1,1,1,1,2,2,1,0,0,0],
        [0,0,0,1,2,5,3,8,9,3,5,2,1,0,0,0],
        [0,0,0,0,1,5,3,3,3,3,5,1,0,0,0,0],
        [0,0,0,0,0,1,2,2,2,2,1,0,0,0,0,0],
        [0,0,0,0,1,3,3,3,3,3,3,1,0,0,0,0],
        [0,0,0,1,2,2,2,1,1,2,2,2,1,0,0,0],
        [0,0,0,1,8,8,1,0,0,1,8,8,1,0,0,0],
        [0,0,0,1,1,1,0,0,0,0,1,1,1,0,0,0],
        [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    ]

    static let avatarRestFrame2: [[Int]] = [
        [0,0,0,0,0,1,1,1,1,1,1,0,8,8,8,0],
        [0,0,0,0,1,2,2,2,2,2,2,1,0,8,0,0],
        [0,0,0,1,2,2,8,8,8,8,2,2,8,8,8,0],
        [0,0,0,1,2,3,3,3,3,3,3,2,1,0,0,0],
        [0,0,0,1,2,5,5,5,5,5,5,2,1,0,0,0],
        [0,0,0,0,1,1,5,5,5,5,1,1,0,0,0,0],
        [0,0,0,1,2,2,1,1,1,1,2,2,1,0,0,0],
        [0,0,0,1,2,5,3,4,6,3,5,2,1,0,0,0],
        [0,0,0,0,1,5,3,3,3,3,5,1,0,0,0,0],
        [0,0,0,0,0,1,2,2,2,2,1,0,0,0,0,0],
        [0,0,0,0,1,3,3,3,3,3,3,1,0,0,0,0],
        [0,0,0,1,2,2,2,1,1,2,2,2,1,0,0,0],
        [0,0,0,1,8,8,1,0,0,1,8,8,1,0,0,0],
        [0,0,0,1,1,1,0,0,0,0,1,1,1,0,0,0],
        [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    ]

    static let avatarRestFrame3: [[Int]] = [
        [0,8,8,0,0,0,0,0,0,0,0,0,0,4,4,0],
        [0,0,8,0,0,1,1,1,1,1,1,0,0,0,4,0],
        [0,8,8,0,1,2,2,2,2,2,2,1,0,4,4,0],
        [0,0,0,1,2,2,8,8,8,8,2,2,1,0,0,0],
        [0,0,0,1,2,3,3,3,3,3,3,2,1,0,0,0],
        [0,0,0,1,2,5,5,5,5,5,5,2,1,0,0,0],
        [0,0,0,1,2,2,1,1,1,1,2,2,1,0,0,0],
        [0,0,0,1,2,5,3,8,8,3,5,2,1,0,0,0],
        [0,0,0,0,1,5,3,3,3,3,5,1,0,0,0,0],
        [0,0,0,0,0,1,2,2,2,2,1,0,0,0,0,0],
        [0,0,0,0,1,3,3,3,3,3,3,1,0,0,0,0],
        [0,0,0,1,2,2,2,1,1,2,2,2,1,0,0,0],
        [0,0,0,1,8,8,1,0,0,1,8,8,1,0,0,0],
        [0,0,0,1,1,1,0,0,0,0,1,1,1,0,0,0],
        [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    ]

    // MARK: - 16x16 Command Deck Action Frames (Holo-Keyboard & Telemetry)

    static let avatarCommandFrame1: [[Int]] = [
        [0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0],
        [0,0,0,0,1,2,2,2,2,2,2,1,0,0,0,0],
        [0,0,0,1,2,2,9,9,9,9,2,2,1,0,0,0],
        [0,0,0,1,2,9,4,9,9,4,9,2,1,0,0,0],
        [0,0,0,1,2,5,5,5,5,5,5,2,1,0,0,0],
        [0,0,0,0,1,1,5,5,5,5,1,1,0,0,0,0],
        [0,0,0,1,2,2,1,1,1,1,2,2,1,0,0,0],
        [0,0,1,5,2,2,2,9,9,2,2,2,2,1,0,0],
        [0,0,1,5,5,2,2,9,9,2,2,5,5,1,0,0],
        [0,1,9,9,9,9,9,9,9,9,9,9,9,9,1,0],
        [0,1,2,4,9,2,9,4,9,2,9,4,2,2,1,0],
        [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,1,9,9,9,1,1,9,9,9,1,0,0,0],
        [0,0,0,1,1,1,1,0,0,1,1,1,1,0,0,0]
    ]

    static let avatarCommandFrame2: [[Int]] = [
        [0,9,0,0,0,1,1,1,1,1,1,0,0,0,6,0],
        [0,0,0,0,1,2,2,2,2,2,2,1,0,0,0,0],
        [0,0,0,1,2,2,9,9,9,9,2,2,1,0,0,0],
        [0,0,0,1,2,9,9,4,9,9,4,2,1,0,0,0],
        [0,0,0,1,2,5,5,5,5,5,5,2,1,0,0,0],
        [0,0,0,0,1,1,5,5,5,5,1,1,0,0,0,0],
        [0,0,0,1,2,2,1,1,1,1,2,2,1,0,0,0],
        [0,0,1,2,2,2,2,9,9,2,2,2,5,1,0,0],
        [0,0,1,5,5,2,2,9,9,2,2,5,5,1,0,0],
        [0,1,9,9,9,9,9,9,9,9,9,9,9,9,1,0],
        [0,1,2,9,4,2,4,9,2,9,4,9,2,2,1,0],
        [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,1,9,9,9,1,1,9,9,9,1,0,0,0],
        [0,0,0,1,1,1,1,0,0,1,1,1,1,0,0,0]
    ]

    static let avatarCommandFrame3: [[Int]] = [
        [0,0,6,0,0,1,1,1,1,1,1,0,0,9,0,0],
        [0,0,0,0,1,2,2,2,2,2,2,1,0,0,0,0],
        [0,0,0,1,2,2,9,9,9,9,2,2,1,0,0,0],
        [0,0,0,1,2,4,4,9,9,4,4,2,1,0,0,0],
        [0,0,0,1,2,5,5,5,5,5,5,2,1,0,0,0],
        [0,0,0,0,1,1,5,5,5,5,1,1,0,0,0,0],
        [0,0,0,1,2,2,1,1,1,1,2,2,1,0,0,0],
        [0,0,1,5,2,2,2,6,6,2,2,2,5,1,0,0],
        [0,0,1,5,5,2,2,6,6,2,2,5,5,1,0,0],
        [0,1,6,9,6,9,6,9,6,9,6,9,6,9,1,0],
        [0,1,2,4,4,2,4,4,2,4,4,2,4,2,1,0],
        [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
        [0,0,0,1,9,9,9,1,1,9,9,9,1,0,0,0],
        [0,0,0,1,1,1,1,0,0,1,1,1,1,0,0,0]
    ]

    /// Server Rack Cabinet with Blinking LEDs (16x16)
    static func commandServerRack(blink: Bool) -> [[Int]] {
        let a = blink ? 6 : 9
        let b = blink ? 9 : 10
        return [
            [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0],
            [0,0,1,2,9,9,9,9,9,9,9,9,2,1,0,0],
            [0,0,1,2,2,2,2,2,2,2,2,2,2,1,0,0],
            [0,0,1,2,3,3,3,3,3,3,a,b,2,1,0,0],
            [0,0,1,2,1,1,1,1,1,1,1,1,2,1,0,0],
            [0,0,1,2,3,3,3,3,3,3,b,a,2,1,0,0],
            [0,0,1,2,1,1,1,1,1,1,1,1,2,1,0,0],
            [0,0,1,2,3,3,3,3,3,3,a,a,2,1,0,0],
            [0,0,1,2,1,1,1,1,1,1,1,1,2,1,0,0],
            [0,0,1,2,3,3,3,3,3,3,b,6,2,1,0,0],
            [0,0,1,2,1,1,1,1,1,1,1,1,2,1,0,0],
            [0,0,1,2,3,3,3,3,3,3,9,a,2,1,0,0],
            [0,0,1,2,2,2,2,2,2,2,2,2,2,1,0,0],
            [0,0,1,9,9,9,9,9,9,9,9,9,9,1,0,0],
            [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0],
            [0,0,0,1,3,1,0,0,0,0,1,3,1,0,0,0]
        ]
    }
}

// MARK: - Preview

#Preview("Avatar Base Tab") {
    AvatarBaseTabView()
        .modelContainer(
            for: [Workout.self, TreatItem.self, TreatLog.self, UserGamificationState.self, WeekRecord.self, BadgeRecord.self],
            inMemory: true
        )
}
