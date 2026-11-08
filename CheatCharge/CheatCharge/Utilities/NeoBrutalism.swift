//
//  NeoBrutalism.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 15.10.2026.
//

import SwiftUI

// MARK: - Neobrutalism Box Background & Modifier

/// Neobrutalist container with high contrast borders and solid hard offset shadows.
struct NeoBoxBackground: View {
    var backgroundColor: Color = CyberTheme.surface
    var borderColor: Color = CyberTheme.cardBorder
    var borderWidth: CGFloat = CyberTheme.borderWidth
    var cornerRadius: CGFloat = 16
    var shadowColor: Color = CyberTheme.blackBorder
    var shadowOffset: CGFloat = CyberTheme.shadowOffset

    var body: some View {
        ZStack {
            // Hard Drop Shadow (no blur)
            if shadowOffset > 0 {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(shadowColor)
                    .offset(x: shadowOffset, y: shadowOffset)
            }

            // Surface Fill
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(backgroundColor)

            // Structural Border
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(borderColor, lineWidth: borderWidth)
        }
    }
}

struct NeoBoxModifier: ViewModifier {
    var backgroundColor: Color = CyberTheme.surface
    var borderColor: Color = CyberTheme.cardBorder
    var borderWidth: CGFloat = CyberTheme.borderWidth
    var cornerRadius: CGFloat = 16
    var shadowColor: Color = CyberTheme.blackBorder
    var shadowOffset: CGFloat = CyberTheme.shadowOffset

    func body(content: Content) -> some View {
        content
            .background(
                NeoBoxBackground(
                    backgroundColor: backgroundColor,
                    borderColor: borderColor,
                    borderWidth: borderWidth,
                    cornerRadius: cornerRadius,
                    shadowColor: shadowColor,
                    shadowOffset: shadowOffset
                )
            )
    }
}

extension View {
    /// Applies Neobrutalist container styling with border and hard shadow.
    func neoBox(
        backgroundColor: Color = CyberTheme.surface,
        borderColor: Color = CyberTheme.cardBorder,
        borderWidth: CGFloat = CyberTheme.borderWidth,
        cornerRadius: CGFloat = 16,
        shadowColor: Color = CyberTheme.blackBorder,
        shadowOffset: CGFloat = CyberTheme.shadowOffset
    ) -> some View {
        modifier(
            NeoBoxModifier(
                backgroundColor: backgroundColor,
                borderColor: borderColor,
                borderWidth: borderWidth,
                cornerRadius: cornerRadius,
                shadowColor: shadowColor,
                shadowOffset: shadowOffset
            )
        )
    }

    /// Smaller Neobrutalist box styling (e.g. for badges, chips, pills)
    func neoBoxSm(
        backgroundColor: Color = CyberTheme.surface,
        borderColor: Color = CyberTheme.cardBorder,
        borderWidth: CGFloat = CyberTheme.borderWidthSm,
        cornerRadius: CGFloat = 10,
        shadowColor: Color = CyberTheme.blackBorder,
        shadowOffset: CGFloat = CyberTheme.shadowOffsetSm
    ) -> some View {
        modifier(
            NeoBoxModifier(
                backgroundColor: backgroundColor,
                borderColor: borderColor,
                borderWidth: borderWidth,
                cornerRadius: cornerRadius,
                shadowColor: shadowColor,
                shadowOffset: shadowOffset
            )
        )
    }

    /// Accent Neobrutalist box (black border for neon backgrounds)
    func neoBoxAccent(
        backgroundColor: Color = CyberTheme.neonVolt,
        borderColor: Color = CyberTheme.blackBorder,
        borderWidth: CGFloat = CyberTheme.borderWidth,
        cornerRadius: CGFloat = 14,
        shadowColor: Color = CyberTheme.blackBorder,
        shadowOffset: CGFloat = CyberTheme.shadowOffset
    ) -> some View {
        modifier(
            NeoBoxModifier(
                backgroundColor: backgroundColor,
                borderColor: borderColor,
                borderWidth: borderWidth,
                cornerRadius: cornerRadius,
                shadowColor: shadowColor,
                shadowOffset: shadowOffset
            )
        )
    }
}

// MARK: - Neobrutalism Interactive Button Style

/// Button style that translates down-right on press, giving tactile arcade tactile feel.
struct NeoInteractiveButtonStyle: ButtonStyle {
    var backgroundColor: Color = CyberTheme.neonVolt
    var foregroundColor: Color = CyberTheme.blackBorder
    var borderColor: Color = CyberTheme.blackBorder
    var borderWidth: CGFloat = CyberTheme.borderWidth
    var cornerRadius: CGFloat = 14
    var shadowOffset: CGFloat = CyberTheme.shadowOffset

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        let currentOffset: CGFloat = isPressed ? 2.0 : 0.0
        let currentShadow: CGFloat = isPressed ? max(0, shadowOffset - 2.0) : shadowOffset

        configuration.label
            .font(.system(size: 14, weight: .black))
            .textCase(.uppercase)
            .foregroundStyle(foregroundColor)
            .background(
                NeoBoxBackground(
                    backgroundColor: backgroundColor,
                    borderColor: borderColor,
                    borderWidth: borderWidth,
                    cornerRadius: cornerRadius,
                    shadowColor: CyberTheme.blackBorder,
                    shadowOffset: currentShadow
                )
            )
            .offset(x: currentOffset, y: currentOffset)
            .animation(.easeOut(duration: 0.12), value: isPressed)
    }
}

extension ButtonStyle where Self == NeoInteractiveButtonStyle {
    static var neoPrimary: NeoInteractiveButtonStyle {
        NeoInteractiveButtonStyle(
            backgroundColor: CyberTheme.neonVolt,
            foregroundColor: CyberTheme.blackBorder,
            borderColor: CyberTheme.blackBorder,
            borderWidth: CyberTheme.borderWidth,
            cornerRadius: 14,
            shadowOffset: CyberTheme.shadowOffset
        )
    }

    static var neoSecondary: NeoInteractiveButtonStyle {
        NeoInteractiveButtonStyle(
            backgroundColor: CyberTheme.surface,
            foregroundColor: CyberTheme.textPrimary,
            borderColor: CyberTheme.cardBorder,
            borderWidth: CyberTheme.borderWidth,
            cornerRadius: 14,
            shadowOffset: CyberTheme.shadowOffset
        )
    }

    static var neoDanger: NeoInteractiveButtonStyle {
        NeoInteractiveButtonStyle(
            backgroundColor: CyberTheme.neonCoral,
            foregroundColor: CyberTheme.blackBorder,
            borderColor: CyberTheme.blackBorder,
            borderWidth: CyberTheme.borderWidth,
            cornerRadius: 14,
            shadowOffset: CyberTheme.shadowOffset
        )
    }
}

// MARK: - Dark Dot Grid Canvas Background

/// Canvas background rendering subtle dot grid (16px spacing) over #121214.
struct NeoDotBackground: View {
    var body: some View {
        ZStack {
            CyberTheme.background
                .ignoresSafeArea()

            Canvas { context, size in
                let spacing: CGFloat = 16.0
                let dotRadius: CGFloat = 1.0
                let dotColor = Color.white.opacity(0.12)

                var x: CGFloat = spacing / 2
                while x < size.width {
                    var y: CGFloat = spacing / 2
                    while y < size.height {
                        let rect = CGRect(
                            x: x - dotRadius,
                            y: y - dotRadius,
                            width: dotRadius * 2,
                            height: dotRadius * 2
                        )
                        context.fill(Path(ellipseIn: rect), with: .color(dotColor))
                        y += spacing
                    }
                    x += spacing
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Neobrutalist Badge Component

/// Small sticker badge with solid fill, border, and hard drop shadow.
struct NeoBadge: View {
    var text: String
    var icon: String? = nil
    var backgroundColor: Color = CyberTheme.neonVolt
    var foregroundColor: Color = CyberTheme.blackBorder
    var borderColor: Color = CyberTheme.blackBorder
    var cornerRadius: CGFloat = 8

    var body: some View {
        HStack(spacing: 5) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .black))
            }
            Text(text)
                .font(.system(size: 11, weight: .black))
                .tracking(0.6)
                .textCase(.uppercase)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4.5)
        .foregroundStyle(foregroundColor)
        .background(
            NeoBoxBackground(
                backgroundColor: backgroundColor,
                borderColor: borderColor,
                borderWidth: CyberTheme.borderWidthSm,
                cornerRadius: cornerRadius,
                shadowColor: CyberTheme.blackBorder,
                shadowOffset: CyberTheme.shadowOffsetSm
            )
        )
    }
}

// MARK: - Neobrutalist Typography Presets

extension View {
    func neoHeadline() -> some View {
        self.font(.system(size: 20, weight: .heavy))
            .tracking(0.3)
    }

    func neoDisplay() -> some View {
        self.font(.system(size: 32, weight: .black))
            .tracking(-0.5)
    }

    func neoLabel() -> some View {
        self.font(.system(size: 11, weight: .bold))
            .tracking(0.8)
            .textCase(.uppercase)
    }
}

// MARK: - Previews

#Preview("Neobrutalism Components") {
    ZStack {
        NeoDotBackground()

        VStack(spacing: 20) {
            HStack(spacing: 12) {
                NeoBadge(text: "ROOKIE", icon: "military_tech", backgroundColor: CyberTheme.surface, foregroundColor: .white, borderColor: .white)
                NeoBadge(text: "14D STREAK", icon: "flame.fill", backgroundColor: CyberTheme.neonVolt, foregroundColor: .black, borderColor: .black)
                NeoBadge(text: "2X", icon: "bolt.fill", backgroundColor: CyberTheme.neonYellow, foregroundColor: .black, borderColor: .black)
            }

            VStack(spacing: 8) {
                Text("TOTAL CHARGED")
                    .neoLabel()
                    .foregroundStyle(CyberTheme.textSecondary)
                Text("+2,100 KCAL")
                    .neoDisplay()
                    .foregroundStyle(CyberTheme.neonVolt)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .neoBox()

            HStack(spacing: 12) {
                Button("Charge Workout") {}
                    .buttonStyle(.neoPrimary)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)

                Button("Log Cheat Meal") {}
                    .buttonStyle(.neoSecondary)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
    }
}
