//
//  CyberTheme.swift
//  CheatCharge
//
//  Created by Hasan Cavusoglu on 03.10.2026.
//

import SwiftUI

/// CheatCharge Dark Neobrutalism (Kinetic Volt) Palette & Design Constants.
enum CyberTheme {

    // MARK: - Neobrutalism Brand Accents

    /// Neon Volt (#CCFF00) - Primary athletic energy, active buttons, positive charge
    static let neonVolt = Color(hex: "#ccff00")

    /// Neon Yellow (#FFE600) - Multipliers (2X), streak badges, secondary tags
    static let neonYellow = Color(hex: "#ffe600")

    /// Neon Coral / Red (#FF4D6D) - Cheats, spent calories, deficit alerts
    static let neonCoral = Color(hex: "#ff4d6d")

    /// Electric Cyan (#00E5FF) - Rollover balance & archive accents
    static let neonCyan = Color(hex: "#00e5ff")

    /// Neon Orange (#FF9500) - Calorie burn & afterburn bonus
    static let neonOrange = Color(hex: "#ff9500")

    /// Neon Purple (#BF5AF2) - Dessert & specialty cheats
    static let neonPurple = Color(hex: "#bf5af2")

    // MARK: - Backward-Compatible Aliases

    /// Aliased to neonVolt (#CCFF00)
    static var neonGreen: Color { neonVolt }

    /// Light wave highlight for tumbler fluid (#E5FF80)
    static let neonGreenLight = Color(hex: "#e5ff80")

    /// Deep wave shadow for tumbler fluid (#8FD400)
    static let neonGreenDark = Color(hex: "#8fd400")

    /// Aliased to neonCoral (#FF4D6D)
    static var neonRed: Color { neonCoral }

    /// Dark container for deficit warnings
    static let neonRedDark = Color(hex: "#2a0e10")

    // MARK: - Surfaces & Backgrounds (Dark Neobrutalism)

    /// Main canvas background (#121214)
    static let background = Color(hex: "#121214")

    /// Primary card & module container surface (#1E1E26)
    static let surface = Color(hex: "#1e1e26")

    /// Secondary card surface (#18181C)
    static let surfaceContainer = Color(hex: "#18181c")

    /// Higher elevation surface (#272730)
    static let surfaceHigh = Color(hex: "#272730")

    /// Lowest dark surface (#0E0E10)
    static let surfaceLowest = Color(hex: "#0e0e10")

    /// Aliased to surface (#1E1E26)
    static var cardBackground: Color { surface }

    /// Tumbler interior fill
    static let glassInterior = Color(hex: "#111115")

    // MARK: - Borders & Shadows

    /// Crisp white border for dark containers
    static let cardBorder = Color.white

    /// Pitch black border for neon-filled elements
    static let blackBorder = Color.black

    /// Standard border thickness for Neobrutalist cards (2.5px)
    static let borderWidth: CGFloat = 2.5

    /// Small border thickness (2.0px)
    static let borderWidthSm: CGFloat = 2.0

    /// Large border thickness (3.0px)
    static let borderWidthLg: CGFloat = 3.0

    /// Default hard drop shadow offset (3.5px)
    static let shadowOffset: CGFloat = 3.5

    /// Small hard drop shadow offset (2.0px)
    static let shadowOffsetSm: CGFloat = 2.0

    /// Large hard drop shadow offset (4.5px)
    static let shadowOffsetLg: CGFloat = 4.5

    // MARK: - Typography Colors

    /// Primary bright white text (#FFFFFF)
    static let textPrimary = Color.white

    /// Secondary muted metadata (#A6A6B3)
    static let textSecondary = Color(hex: "#a6a6b3")

    /// Tertiary inactive text (#71717A)
    static let textMuted = Color(hex: "#71717a")
}

// MARK: - Color Hex Initializer Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
