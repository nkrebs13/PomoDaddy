//
//  ColorPalette.swift
//  PomoDaddy
//
//  Color palette and gradients for the PomoDaddy app.
//

import SwiftUI

// MARK: - Hex Color Initializer

extension Color {
    /// Initialize a Color from a hex string.
    /// - Parameter hex: A hex color string (e.g., "FF6B6B" or "#FF6B6B")
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

// MARK: - App Color Palette

extension Color {
    // MARK: Primary Colors

    /// Primary focus mode color - vibrant tomato red
    static let tomatoRed = Color(hex: "FF6B6B")

    /// Hover state color - warm coral
    static let coral = Color(hex: "FF8E72")

    /// Short break color - refreshing mint
    static let mint = Color(hex: "4ECDC4")

    /// Long break color - calming lavender
    static let lavender = Color(hex: "A78BFA")

    /// Celebration color - bright sunny yellow
    static let sunnyYellow = Color(hex: "F6E05E")

    /// Informational color - calm sky blue
    static let skyBlue = Color(hex: "63B3ED")

    /// Streak celebration color - energetic hot pink
    static let hotPink = Color(hex: "ED64A6")

    /// Completed state color - satisfying forest green
    static let forestGreen = Color(hex: "38A169")
}

// MARK: - Gradients

extension LinearGradient {
    /// Gradient for focus mode - tomatoRed to coral
    static let focusGradient = LinearGradient(
        colors: [.tomatoRed, .coral],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Gradient for break mode - mint to skyBlue
    static let breakGradient = LinearGradient(
        colors: [.mint, .skyBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Gradient for celebrations - sunnyYellow to hotPink to lavender
    static let celebrationGradient = LinearGradient(
        colors: [.sunnyYellow, .hotPink, .lavender],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Convenience Gradients as AnyGradient

extension Gradient {
    /// Focus mode gradient colors
    static let focus = Gradient(colors: [.tomatoRed, .coral])

    /// Break mode gradient colors
    static let breakMode = Gradient(colors: [.mint, .skyBlue])

    /// Celebration gradient colors
    static let celebration = Gradient(colors: [.sunnyYellow, .hotPink, .lavender])
}
