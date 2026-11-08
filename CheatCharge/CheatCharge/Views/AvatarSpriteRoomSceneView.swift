//
//  AvatarSpriteRoomSceneView.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 01.11.2026.
//

import SwiftUI

/// V2 Sprite-based Room Scene View for the Base tab.
/// Displays the active room's pixel-art background centered on screen, runs the chained
/// sprite animation (door opening -> walking in from doorway -> door closing -> dumbbell curls in center),
/// and provides square room selector thumbnails underneath.
struct AvatarSpriteRoomSceneView: View {

    // MARK: - Room Definition

    enum SpriteRoom: Int, CaseIterable, Identifiable {
        case ironGym = 1
        case fuelLab = 2
        case cryoLounge = 3
        case commandDeck = 4

        var id: Int { rawValue }

        var codeNumber: String {
            String(format: "0%d", rawValue)
        }

        var shortTitle: String {
            switch self {
            case .ironGym: return "IRON GYM"
            case .fuelLab: return "FUEL LAB"
            case .cryoLounge: return "CRYO LOUNGE"
            case .commandDeck: return "CMD DECK"
            }
        }

        var headerTitle: String {
            switch self {
            case .ironGym: return "[ ZONE 01 // IRON GYM ]"
            case .fuelLab: return "[ ZONE 02 // FUEL LAB ]"
            case .cryoLounge: return "[ ZONE 03 // CRYO LOUNGE ]"
            case .commandDeck: return "[ ZONE 04 // COMMAND DECK ]"
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

        var systemIcon: String {
            switch self {
            case .ironGym: return "dumbbell.fill"
            case .fuelLab: return "flame.fill"
            case .cryoLounge: return "bed.double.fill"
            case .commandDeck: return "terminal.fill"
            }
        }

        var isSpriteReady: Bool {
            self == .ironGym
        }
    }

    // MARK: - Animation Phase State Machine

    enum GymAnimationPhase: Equatable {
        case doorClosedInitial
        case doorOpeningHalf
        case doorOpenFull
        case walkingToCenter
        case liftingDumbbells

        var statusTag: String {
            switch self {
            case .doorClosedInitial:
                return "DOOR CLOSED // STANDBY"
            case .doorOpeningHalf:
                return "DOOR OPENING [50%]"
            case .doorOpenFull:
                return "DOOR OPEN // ENTRY"
            case .walkingToCenter:
                return "ENTERING ROOM // WALK"
            case .liftingDumbbells:
                return "ACTIVE // DUMBBELL CURL"
            }
        }

        var speechBubble: String {
            switch self {
            case .doorClosedInitial, .doorOpeningHalf:
                return "..."
            case .doorOpenFull:
                return "⚡"
            case .walkingToCenter:
                return ">>"
            case .liftingDumbbells:
                return "💪⚡"
            }
        }
    }

    // MARK: - Door Background Frame

    enum DoorFrame: Int {
        case closed = 1     // gym_bg_1
        case halfOpen = 2   // gym_bg_2
        case fullyOpen = 3  // gym_bg_3

        var assetName: String {
            "gym_bg_\(rawValue)"
        }
    }

    // MARK: - State

    @State private var selectedRoom: SpriteRoom = .ironGym
    @State private var phase: GymAnimationPhase = .doorClosedInitial
    @State private var doorFrame: DoorFrame = .closed

    /// Normalized character center position within the 1376x768 room canvas (0.0 ... 1.0)
    @State private var characterNormalizedPos: CGPoint = CGPoint(x: 0.90, y: 0.50)
    @State private var characterDepthScale: CGFloat = 0.86
    @State private var characterOpacity: Double = 0.0
    @State private var isFacingLeft: Bool = true

    /// Incrementing generation token to cancel any in-flight DispatchQueue timers on replay/room switch
    @State private var sequenceGeneration: Int = 0

    // MARK: - Constants

    private let doorwayPoint = CGPoint(x: 0.90, y: 0.50)
    private let centerMatPoint = CGPoint(x: 0.47, y: 0.55)
    private let roomAspectRatio: CGFloat = 1376.0 / 768.0
    private let spriteAspectRatio: CGFloat = 67.0 / 137.0

    // MARK: - Body

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.10)) { timeline in
            let tick = Int(timeline.date.timeIntervalSinceReferenceDate / 0.10)

            VStack(spacing: 12) {
                // 1. Top Scene Status & Replay Bar
                sceneControlStrip

                Spacer(minLength: 0)

                // 2. Centered Main Room Stage (1376:768 Aspect Ratio)
                centerRoomStage(tick: tick)

                Spacer(minLength: 0)

                // 3. Bottom Room Selector Thumbnail Squares
                roomThumbnailsSection
            }
        }
        .onAppear {
            startGymEntranceSequence()
        }
    }

    // MARK: - 1. Scene Control Strip

    private var sceneControlStrip: some View {
        let accent = selectedRoom.accentColor

        return HStack(spacing: 8) {
            // Room Name & Phase Status
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedRoom.headerTitle)
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(accent)
                    .lineLimit(1)

                Text(selectedRoom.isSpriteReady ? phase.statusTag : "ASSET PACK PENDING // STANDBY")
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.75))
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            // Replay Button (active when Iron Gym is selected)
            if selectedRoom == .ironGym {
                Button {
                    startGymEntranceSequence()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 10, weight: .black))
                        Text("REPLAY")
                            .font(.system(size: 9.5, weight: .black, design: .monospaced))
                    }
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        ZStack {
                            Rectangle()
                                .fill(Color.black)
                                .offset(x: 2, y: 2)
                            Rectangle()
                                .fill(accent)
                            Rectangle()
                                .stroke(Color.black, lineWidth: 1.8)
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            ZStack {
                Rectangle()
                    .fill(Color.black)
                    .offset(x: 4, y: 4)
                Rectangle()
                    .fill(Color(hex: "#141418"))
                Rectangle()
                    .stroke(Color.white.opacity(0.85), lineWidth: 2)
            }
        )
    }

    // MARK: - 2. Center Room Stage

    private func centerRoomStage(tick: Int) -> some View {
        let accent = selectedRoom.accentColor

        return VStack(spacing: 0) {
            // Top Tactical Frame Header
            HStack(spacing: 6) {
                Circle()
                    .fill(accent)
                    .frame(width: 7, height: 7)

                Text("CAM_0\(selectedRoom.rawValue) // \(selectedRoom.shortTitle) LIVE VIEWPORT")
                    .font(.system(size: 9.5, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.9))

                Spacer()

                Text(selectedRoom == .ironGym ? "DOOR: \(doorFrameLabel)" : "OFFLINE")
                    .font(.system(size: 8.5, weight: .black, design: .monospaced))
                    .foregroundStyle(accent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.black)
                    .overlay(Rectangle().stroke(accent.opacity(0.6), lineWidth: 1))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(hex: "#101014"))
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.white.opacity(0.25))
                    .frame(height: 1.5)
            }

            // 1376x768 Aspect-Fit Room Canvas
            GeometryReader { geo in
                let stageW = geo.size.width
                let stageH = geo.size.height

                ZStack {
                    if selectedRoom == .ironGym {
                        ironGymInteractiveStage(stageW: stageW, stageH: stageH, tick: tick)
                    } else {
                        placeholderRoomStage(room: selectedRoom)
                    }

                    // Corner Tactical HUD Reticles
                    StageCornerBrackets(color: accent.opacity(0.75))
                        .padding(6)
                        .allowsHitTesting(false)
                }
                .frame(width: stageW, height: stageH)
                .clipped()
            }
            .aspectRatio(roomAspectRatio, contentMode: .fit)
        }
        .background(
            ZStack {
                Rectangle()
                    .fill(Color.black)
                    .offset(x: 5, y: 5)
                Rectangle()
                    .fill(Color(hex: "#0D0E12"))
            }
        )
        .overlay(
            Rectangle()
                .stroke(accent, lineWidth: 2.5)
        )
    }

    // MARK: - Iron Gym Animated Sprite Stage

    private func ironGymInteractiveStage(stageW: CGFloat, stageH: CGFloat, tick: Int) -> some View {
        let charBaseHeight = stageH * 0.52
        let charBaseWidth = charBaseHeight * spriteAspectRatio
        let currentSpriteName = activeSpriteAssetName(for: tick)

        return ZStack {
            // Layer 1: Room Background (gym_bg_1 / gym_bg_2 / gym_bg_3)
            Image(doorFrame.assetName)
                .interpolation(.none)
                .resizable()
                .scaledToFill()
                .frame(width: stageW, height: stageH)
                .clipped()

            // Layer 2: Character Floor Shadow on the Gym Mat / Floor
            if characterOpacity > 0.05 {
                Ellipse()
                    .fill(Color.black.opacity(0.45))
                    .frame(
                        width: charBaseWidth * 0.78 * characterDepthScale,
                        height: charBaseHeight * 0.09 * characterDepthScale
                    )
                    .position(
                        x: stageW * characterNormalizedPos.x,
                        y: stageH * characterNormalizedPos.y + (charBaseHeight * 0.47 * characterDepthScale)
                    )
                    .opacity(characterOpacity)
            }

            // Layer 3: Animated Character Sprite (Walk Cycle or Dumbbell Curl)
            VStack(spacing: 2) {
                // Tactical Mini Status Bubble above head
                Text(phase.speechBubble)
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(
                        ZStack {
                            Rectangle()
                                .fill(Color.black)
                                .offset(x: 1.5, y: 1.5)
                            Rectangle()
                                .fill(Color(hex: "#CCFF00"))
                            Rectangle()
                                .stroke(Color.black, lineWidth: 1.2)
                        }
                    )

                Image(currentSpriteName)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: charBaseWidth, height: charBaseHeight)
                    // Walk sprites face right by default; flip horizontally when walking left from the right doorway
                    .scaleEffect(x: isFacingLeft ? -1.0 : 1.0, y: 1.0)
            }
            .scaleEffect(characterDepthScale)
            .opacity(characterOpacity)
            .position(
                x: stageW * characterNormalizedPos.x,
                y: stageH * characterNormalizedPos.y
            )
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Tapping the stage replays the entrance animation
            startGymEntranceSequence()
        }
    }

    // MARK: - Placeholder Stage for Other Rooms

    private func placeholderRoomStage(room: SpriteRoom) -> some View {
        let accent = room.accentColor

        return ZStack {
            Color(hex: "#0B0C10")

            // Subtle Grid Pattern
            NeoDotBackground()
                .opacity(0.6)

            VStack(spacing: 10) {
                ZStack {
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: 48, height: 48)
                        .offset(x: 3, y: 3)

                    Rectangle()
                        .fill(Color(hex: "#16161D"))
                        .frame(width: 48, height: 48)

                    Rectangle()
                        .stroke(accent, lineWidth: 2)
                        .frame(width: 48, height: 48)

                    Image(systemName: room.systemIcon)
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(accent)
                }

                Text("ZONE \(room.codeNumber) // \(room.shortTitle)")
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.white)

                Text("Bu odanın piksel arka plan ve sprite animasyonları eklendiğinde burada aktif olacak.")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                        selectedRoom = .ironGym
                    }
                    startGymEntranceSequence()
                } label: {
                    Text("[ RETURN TO IRON GYM ]")
                        .font(.system(size: 9.5, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            ZStack {
                                Rectangle()
                                    .fill(Color.black)
                                    .offset(x: 2, y: 2)
                                Rectangle()
                                    .fill(Color(hex: "#CCFF00"))
                                Rectangle()
                                    .stroke(Color.black, lineWidth: 1.5)
                            }
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
    }

    // MARK: - 3. Bottom Room Selector Thumbnail Squares

    private var roomThumbnailsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("BASE SECTORS // SELECT ROOM")
                    .font(.system(size: 9.5, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.7))

                Spacer()

                Text("TAP GYM TO REPLAY")
                    .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: "#CCFF00").opacity(0.85))
            }

            HStack(spacing: 10) {
                ForEach(SpriteRoom.allCases) { room in
                    roomThumbnailSquare(for: room)
                }
            }
        }
    }

    private func roomThumbnailSquare(for room: SpriteRoom) -> some View {
        let isSelected = (selectedRoom == room)
        let accent = room.accentColor

        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                selectedRoom = room
            }
            if room == .ironGym {
                startGymEntranceSequence()
            } else {
                // Cancel active gym sequence timers while inspecting another room
                sequenceGeneration += 1
            }
        } label: {
            GeometryReader { geo in
                let side = geo.size.width

                ZStack(alignment: .bottom) {
                    // Thumbnail Background Content
                    if room == .ironGym {
                        Image("gym_bg_1")
                            .interpolation(.none)
                            .resizable()
                            .scaledToFill()
                            .frame(width: side, height: side)
                            .clipped()
                            .overlay(
                                Color.black.opacity(isSelected ? 0.08 : 0.35)
                            )
                    } else {
                        ZStack {
                            Color(hex: "#121318")

                            VStack(spacing: 4) {
                                Image(systemName: room.systemIcon)
                                    .font(.system(size: 18, weight: .black))
                                    .foregroundStyle(isSelected ? accent : accent.opacity(0.55))

                                Text("SOON")
                                    .font(.system(size: 7.5, weight: .black, design: .monospaced))
                                    .foregroundStyle(Color.white.opacity(0.45))
                            }
                            .offset(y: -8)
                        }
                        .frame(width: side, height: side)
                    }

                    // Top-Right Badge (LIVE vs SOON)
                    VStack {
                        HStack {
                            Spacer()
                            Text(room.isSpriteReady ? "LIVE" : "SOON")
                                .font(.system(size: 7, weight: .black, design: .monospaced))
                                .foregroundStyle(room.isSpriteReady ? Color.black : Color.white.opacity(0.8))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1.5)
                                .background(room.isSpriteReady ? accent : Color.black.opacity(0.85))
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.black, lineWidth: 1)
                                )
                        }
                        Spacer()
                    }
                    .padding(4)

                    // Bottom Label Strip
                    HStack(spacing: 2) {
                        Text(room.codeNumber)
                            .font(.system(size: 8, weight: .black, design: .monospaced))
                            .foregroundStyle(accent)

                        Text(room.shortTitle)
                            .font(.system(size: 7.5, weight: .black, design: .monospaced))
                            .foregroundStyle(Color.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 3)
                    .background(Color.black.opacity(0.88))
                }
                .frame(width: side, height: side)
                .background(
                    Rectangle()
                        .fill(Color.black)
                        .offset(x: 3, y: 3)
                )
                .overlay(
                    Rectangle()
                        .stroke(
                            isSelected ? accent : Color.white.opacity(0.35),
                            lineWidth: isSelected ? 2.5 : 1.5
                        )
                )
                .offset(y: isSelected ? -3 : 0)
            }
            .aspectRatio(1.0, contentMode: .fit)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sprite Frame Calculation & Entrance Chained Sequence

    private var doorFrameLabel: String {
        switch doorFrame {
        case .closed: return "CLOSED"
        case .halfOpen: return "50% OPEN"
        case .fullyOpen: return "OPEN"
        }
    }

    /// Selects the active PNG sprite frame based on the current animation phase and TimelineView tick.
    private func activeSpriteAssetName(for tick: Int) -> String {
        switch phase {
        case .doorClosedInitial, .doorOpeningHalf, .doorOpenFull:
            return "avatar_walk_0"
        case .walkingToCenter:
            let frameIndex = abs(tick) % 8
            return "avatar_walk_\(frameIndex)"
        case .liftingDumbbells:
            // Slightly more deliberate cadence for heavy dumbbell curls
            let curlFrameIndex = (abs(tick) / 1) % 8
            return "avatar_curl_\(curlFrameIndex)"
        }
    }

    /// Runs the full entrance & workout animation sequence:
    /// 1) Door closed (`gym_bg_1`) -> half open (`gym_bg_2`) -> fully open (`gym_bg_3`)
    /// 2) Character appears in doorway and walks left to the center exercise mat (`avatar_walk_0..7`)
    /// 3) Door closes behind the character (`gym_bg_3` -> `gym_bg_2` -> `gym_bg_1`)
    /// 4) Character performs dumbbell curls in the center of the room (`avatar_curl_0..7`)
    private func startGymEntranceSequence() {
        sequenceGeneration += 1
        let activeGen = sequenceGeneration

        // Reset to initial state: Door closed, character hidden at right doorway
        phase = .doorClosedInitial
        doorFrame = .closed
        characterNormalizedPos = doorwayPoint
        characterDepthScale = 0.86
        characterOpacity = 0.0
        isFacingLeft = true

        // Step 1 (t = 0.45s): Door opens halfway (gym-1 -> gym-2)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            guard activeGen == sequenceGeneration else { return }
            phase = .doorOpeningHalf
            doorFrame = .halfOpen
        }

        // Step 2 (t = 0.80s): Door opens completely (gym-2 -> gym-3) & character appears at doorway
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.80) {
            guard activeGen == sequenceGeneration else { return }
            phase = .doorOpenFull
            doorFrame = .fullyOpen
            withAnimation(.easeOut(duration: 0.18)) {
                characterOpacity = 1.0
            }
        }

        // Step 3 (t = 1.05s): Character starts walking from right doorway to center gym mat
        let walkStartDelay = 1.05
        let walkDuration = 1.85

        DispatchQueue.main.asyncAfter(deadline: .now() + walkStartDelay) {
            guard activeGen == sequenceGeneration else { return }
            phase = .walkingToCenter
            isFacingLeft = true

            withAnimation(.linear(duration: walkDuration)) {
                characterNormalizedPos = centerMatPoint
                characterDepthScale = 1.0
            }
        }

        // Step 4a (t = 1.95s): Door starts closing behind character (gym-3 -> gym-2)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.95) {
            guard activeGen == sequenceGeneration else { return }
            doorFrame = .halfOpen
        }

        // Step 4b (t = 2.30s): Door fully closed behind character (gym-2 -> gym-1)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.30) {
            guard activeGen == sequenceGeneration else { return }
            doorFrame = .closed
        }

        // Step 5 (t = 2.90s): Character arrives at center mat and starts Dumbbell Curl loop
        DispatchQueue.main.asyncAfter(deadline: .now() + walkStartDelay + walkDuration) {
            guard activeGen == sequenceGeneration else { return }
            isFacingLeft = false
            phase = .liftingDumbbells
        }
    }
}

// MARK: - Stage Corner HUD Brackets

private struct StageCornerBrackets: View {
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let len: CGFloat = 12

            Path { path in
                // Top-Left
                path.move(to: CGPoint(x: 0, y: len))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: len, y: 0))

                // Top-Right
                path.move(to: CGPoint(x: w - len, y: 0))
                path.addLine(to: CGPoint(x: w, y: 0))
                path.addLine(to: CGPoint(x: w, y: len))

                // Bottom-Left
                path.move(to: CGPoint(x: 0, y: h - len))
                path.addLine(to: CGPoint(x: 0, y: h))
                path.addLine(to: CGPoint(x: len, y: h))

                // Bottom-Right
                path.move(to: CGPoint(x: w - len, y: h))
                path.addLine(to: CGPoint(x: w, y: h))
                path.addLine(to: CGPoint(x: w, y: h - len))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .square))
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "#0D0D0D").ignoresSafeArea()
        AvatarSpriteRoomSceneView()
            .padding(.horizontal, 14)
            .padding(.vertical, 20)
    }
    .preferredColorScheme(.dark)
}
