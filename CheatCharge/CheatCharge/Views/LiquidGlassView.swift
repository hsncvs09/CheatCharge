//
//  LiquidGlassView.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 03.10.2026.
//

import SwiftUI

/// Neobrutalist Fuel Tank (Tumbler) Component.
///
/// Implements Dark Neobrutalism (Kinetic Volt) aesthetics:
/// - Heavy structural white borders and solid black offset drop shadows.
/// - Left-edge measurement hash marks.
/// - Angled pop multiplier sticker (-6° rotation).
/// - Dynamic liquid physics with wave motion, secondary foam layer, black crest outline,
///   diagonal stripe texture, and rising energy bubbles.
/// - Gyroscope tilt reactivity using MotionManager.
/// - Central value sticker ("500 KCAL AVAILABLE").
struct LiquidGlassView: View {

    // MARK: - Properties

    var remainingCalories: Double

    // MARK: - Motion & State

    @State private var motionManager = MotionManager()
    @Environment(\.scenePhase) private var scenePhase

    // Tank Dimensions
    private let tankWidth: CGFloat = 208
    private let tankHeight: CGFloat = 224

    // MARK: - Computed Metrics

    private var metrics: LiquidCupMetrics {
        LiquidGlassCalculator.compute(remainingCalories: remainingCalories)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .topLeading) {
                // Main Neobrutalist Fuel Tank Container
                tankContainer
                    .frame(width: tankWidth, height: tankHeight)

                // Angled Multiplier / Deficit Pop Tag (-6 deg)
                statusBadge
                    .rotationEffect(.degrees(-6))
                    .offset(x: -8, y: -10)
                    .zIndex(20)
            }

            // Subtitle Footnote
            subtitleFootnote
        }
        .onAppear {
            motionManager.start()
        }
        .onDisappear {
            motionManager.stop()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                motionManager.start()
            } else {
                motionManager.stop()
            }
        }
    }

    // MARK: - Neobrutalist Tank Frame

    private var tankContainer: some View {
        ZStack {
            // 1. Tank Background Container (White border + 4px black shadow)
            NeoBoxBackground(
                backgroundColor: CyberTheme.surface,
                borderColor: CyberTheme.cardBorder,
                borderWidth: CyberTheme.borderWidth,
                cornerRadius: 18,
                shadowColor: CyberTheme.blackBorder,
                shadowOffset: CyberTheme.shadowOffsetLg
            )

            // 2. Inner Fluid Vessel (Dark recessed cavity with black border)
            ZStack {
                // Cavity background
                RoundedRectangle(cornerRadius: 13)
                    .fill(CyberTheme.glassInterior)

                // Animated Fluid Waves (Canvas)
                TimelineView(.animation) { timeline in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    Canvas { context, size in
                        drawFluid(context: context, size: size, time: time)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 13))

                // Left-edge Measurement Hash Marks
                hashMarks
                    .padding(.leading, 8)
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                // Inner Cavity Border (Black 2px)
                RoundedRectangle(cornerRadius: 13)
                    .stroke(CyberTheme.blackBorder, lineWidth: 2)

                // Central Floating Value Sticker
                centerValueSticker
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 12)
            }
            .padding(8) // Padding inside outer tank frame
        }
    }

    // MARK: - Measurement Hash Marks

    private var hashMarks: some View {
        VStack(alignment: .leading, spacing: 6) {
            Rectangle().frame(width: 12, height: 2)
            Rectangle().frame(width: 8, height: 2)
            Rectangle().frame(width: 12, height: 2)
            Rectangle().frame(width: 8, height: 2)
            Rectangle().frame(width: 12, height: 2)
        }
        .foregroundStyle(Color.white.opacity(0.45))
        .allowsHitTesting(false)
    }

    // MARK: - Fluid Drawing (Canvas)

    private func drawFluid(context: GraphicsContext, size: CGSize, time: Double) {
        if metrics.isDeficit {
            // Deficit state: Red glowing pulse
            let pulse = (sin(time * 3.5) + 1.0) / 2.0
            let glowRect = CGRect(x: 0, y: size.height * 0.35, width: size.width, height: size.height * 0.65)
            context.fill(
                Path(glowRect),
                with: .radialGradient(
                    Gradient(colors: [CyberTheme.neonCoral.opacity(0.35 + pulse * 0.2), .clear]),
                    center: CGPoint(x: size.width / 2, y: size.height * 0.75),
                    startRadius: 5,
                    endRadius: size.width * 0.75
                )
            )
            return
        }

        guard metrics.fillRatio > 0 else { return }

        // Fluid fill level: 0.08 to 0.92
        let clampedRatio = max(0.08, min(0.92, metrics.fillRatio))
        let baseLevelY = size.height * (1.0 - clampedRatio)

        // Gyroscope or simulation tilt
        let tiltAngle: Double
        if motionManager.isMotionAvailable {
            let rawTilt = -motionManager.roll * 1.3
            tiltAngle = max(-0.95, min(0.95, rawTilt))
        } else {
            tiltAngle = sin(time * 0.9) * 0.09
        }

        // Layer 1: Secondary Background Foam / Fluid (Neon Yellow)
        let backWavePath = createWavePath(
            size: size,
            baseY: baseLevelY + 4,
            amplitude: 4.5,
            wavelength: size.width * 0.85,
            phase: time * 1.1 + 1.6,
            tilt: tiltAngle * 0.85
        )
        context.fill(
            backWavePath,
            with: .color(CyberTheme.neonYellow.opacity(0.92))
        )

        // Layer 2: Main Vivid Neon Volt Fluid Body
        let frontWavePath = createWavePath(
            size: size,
            baseY: baseLevelY,
            amplitude: 6.0,
            wavelength: size.width * 0.75,
            phase: time * 1.4,
            tilt: tiltAngle
        )
        context.fill(
            frontWavePath,
            with: .linearGradient(
                Gradient(colors: [
                    CyberTheme.neonVolt,
                    CyberTheme.neonGreenDark
                ]),
                startPoint: CGPoint(x: size.width / 2, y: baseLevelY),
                endPoint: CGPoint(x: size.width / 2, y: size.height)
            )
        )

        // Layer 3: Hard Neobrutalist Black Dynamic Crest Line (3.5px stroke)
        let crestPath = createCrestLine(
            size: size,
            baseY: baseLevelY,
            amplitude: 6.0,
            wavelength: size.width * 0.75,
            phase: time * 1.4,
            tilt: tiltAngle
        )
        context.stroke(
            crestPath,
            with: .color(CyberTheme.blackBorder),
            lineWidth: 3.5
        )

        // Layer 4: Dark Diagonal Stripe Grid Texture Overlay
        drawDiagonalStripes(context: context, size: size, baseY: baseLevelY)

        // Layer 5: Rising Floating Energy Bubbles
        for i in 0..<4 {
            let offset = Double(i) * 40.0
            let cycle = (time * 30.0 + offset).truncatingRemainder(dividingBy: Double(size.height * clampedRatio))
            let bubbleY = size.height - cycle
            let bubbleX = size.width * (0.24 + Double(i) * 0.18) + sin(time * 3.5 + Double(i)) * 6.0
            let bubbleRadius = (i % 2 == 0) ? 2.5 : 3.5
            let bubbleColor = (i == 1) ? CyberTheme.neonYellow : Color.white

            let bubbleRect = CGRect(
                x: bubbleX - bubbleRadius,
                y: bubbleY - bubbleRadius,
                width: bubbleRadius * 2,
                height: bubbleRadius * 2
            )
            context.fill(
                Path(ellipseIn: bubbleRect),
                with: .color(bubbleColor.opacity(0.85))
            )
        }
    }

    // MARK: - Diagonal Stripe Texture

    private func drawDiagonalStripes(context: GraphicsContext, size: CGSize, baseY: CGFloat) {
        var localContext = context
        let stripeSpacing: CGFloat = 10.0
        let lineWidth: CGFloat = 1.8
        let stripeColor = Color.black.opacity(0.25)

        var path = Path()
        var x = -size.height
        while x < size.width + size.height {
            path.move(to: CGPoint(x: x, y: size.height))
            path.addLine(to: CGPoint(x: x + size.height, y: 0))
            x += stripeSpacing
        }

        // Clip stripes within fluid area
        var clipPath = Path()
        clipPath.addRect(CGRect(x: 0, y: baseY, width: size.width, height: size.height - baseY))
        localContext.clip(to: clipPath)
        localContext.stroke(path, with: .color(stripeColor), lineWidth: lineWidth)
    }

    // MARK: - Wave Geometry Helpers

    private func createWavePath(
        size: CGSize,
        baseY: CGFloat,
        amplitude: CGFloat,
        wavelength: CGFloat,
        phase: Double,
        tilt: Double
    ) -> Path {
        var path = Path()
        let step: CGFloat = 4.0
        let midX = size.width / 2.0
        let tanTilt = CGFloat(tan(tilt))

        let startTilt = (0 - midX) * tanTilt
        let startWave = amplitude * CGFloat(sin(phase))
        path.move(to: CGPoint(x: 0, y: baseY + startTilt + startWave))

        for x in stride(from: step, through: size.width, by: step) {
            let tiltOffset = (x - midX) * tanTilt
            let waveOffset = amplitude * CGFloat(sin((Double(x) / Double(wavelength)) * 2.0 * .pi + phase))
            let y = baseY + tiltOffset + waveOffset
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: size.width, y: size.height + 40))
        path.addLine(to: CGPoint(x: 0, y: size.height + 40))
        path.closeSubpath()
        return path
    }

    private func createCrestLine(
        size: CGSize,
        baseY: CGFloat,
        amplitude: CGFloat,
        wavelength: CGFloat,
        phase: Double,
        tilt: Double
    ) -> Path {
        var path = Path()
        let step: CGFloat = 4.0
        let midX = size.width / 2.0
        let tanTilt = CGFloat(tan(tilt))

        let startTilt = (0 - midX) * tanTilt
        let startWave = amplitude * CGFloat(sin(phase))
        path.move(to: CGPoint(x: 0, y: baseY + startTilt + startWave))

        for x in stride(from: step, through: size.width, by: step) {
            let tiltOffset = (x - midX) * tanTilt
            let waveOffset = amplitude * CGFloat(sin((Double(x) / Double(wavelength)) * 2.0 * .pi + phase))
            let y = baseY + tiltOffset + waveOffset
            path.addLine(to: CGPoint(x: x, y: y))
        }
        return path
    }

    // MARK: - Central Value Sticker

    private var centerValueSticker: some View {
        VStack(spacing: 2) {
            Text(remainingCalories >= 0
                 ? "\(Int(remainingCalories))"
                 : "\(Int(remainingCalories))")
                .font(.system(size: 30, weight: .black))
                .tracking(-0.5)
                .foregroundStyle(Color.white)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.25), value: remainingCalories)

            Text(metrics.isDeficit ? "KCAL DEFICIT" : "KCAL AVAILABLE")
                .font(.system(size: 10, weight: .black))
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundStyle(metrics.isDeficit ? CyberTheme.neonCoral : CyberTheme.neonVolt)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            NeoBoxBackground(
                backgroundColor: Color(hex: "#0d0e11"),
                borderColor: CyberTheme.cardBorder,
                borderWidth: CyberTheme.borderWidthSm,
                cornerRadius: 10,
                shadowColor: CyberTheme.blackBorder,
                shadowOffset: CyberTheme.shadowOffset
            )
        )
    }

    // MARK: - Multiplier / Status Pop Badge (-6 deg)

    @ViewBuilder
    private var statusBadge: some View {
        if let multiplierText = metrics.multiplierText {
            // e.g. 2X Multiplier Pop Tag
            HStack(spacing: 3) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 11, weight: .black))
                Text(multiplierText.uppercased())
                    .font(.system(size: 11, weight: .black))
                    .tracking(0.5)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(CyberTheme.blackBorder)
            .background(
                NeoBoxBackground(
                    backgroundColor: CyberTheme.neonYellow,
                    borderColor: CyberTheme.blackBorder,
                    borderWidth: CyberTheme.borderWidthSm,
                    cornerRadius: 6,
                    shadowColor: CyberTheme.blackBorder,
                    shadowOffset: CyberTheme.shadowOffsetSm
                )
            )
        } else if metrics.isDeficit {
            // DEFICIT Pop Tag
            HStack(spacing: 3) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10, weight: .black))
                Text("DEFICIT")
                    .font(.system(size: 10, weight: .black))
                    .tracking(0.5)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(CyberTheme.blackBorder)
            .background(
                NeoBoxBackground(
                    backgroundColor: CyberTheme.neonCoral,
                    borderColor: CyberTheme.blackBorder,
                    borderWidth: CyberTheme.borderWidthSm,
                    cornerRadius: 6,
                    shadowColor: CyberTheme.blackBorder,
                    shadowOffset: CyberTheme.shadowOffsetSm
                )
            )
        }
    }

    // MARK: - Subtitle Footnote

    private var subtitleFootnote: some View {
        Group {
            if metrics.isDeficit {
                Text("Budget deficit • Complete workouts to rebalance")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(CyberTheme.neonCoral)
            } else if metrics.hasMultiplier {
                Text("\(metrics.fullCups) glasses in stock • Current \(Int(metrics.currentCupCalories)) / 210 kcal")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(CyberTheme.textSecondary)
            } else if remainingCalories > 0 {
                Text("Current glass • \(Int(metrics.currentCupCalories)) / 210 kcal")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(CyberTheme.textSecondary)
            } else {
                Text("1 glass = 210 kcal • Add workout to charge")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(CyberTheme.textMuted)
            }
        }
        .tracking(0.3)
        .multilineTextAlignment(.center)
    }
}

// MARK: - Previews

#Preview("Tumbler - 500 kcal (2x)") {
    ZStack {
        NeoDotBackground()
        LiquidGlassView(remainingCalories: 500)
    }
}

#Preview("Tumbler - Deficit (-120 kcal)") {
    ZStack {
        NeoDotBackground()
        LiquidGlassView(remainingCalories: -120)
    }
}
