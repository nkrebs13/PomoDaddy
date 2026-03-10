//
//  AnimatedButtonStyle.swift
//  PomoDaddy
//
//  Custom button style with playful hover and press animations.
//

import SwiftUI

// MARK: - Animated Button Style

/// A custom ButtonStyle that provides playful, bouncy animations on hover and press.
///
/// Features:
/// - Scales up to 1.08x on hover with a subtle shadow
/// - Scales down to 0.95x on press for tactile feedback
/// - Uses spring animations for a lively, responsive feel
///
/// Usage:
/// ```swift
/// Button("Start Focus") {
///     // action
/// }
/// .buttonStyle(AnimatedButtonStyle())
/// ```
struct AnimatedButtonStyle: ButtonStyle {
    // MARK: - State

    @State private var isHovering = false

    // MARK: - Configuration

    /// The scale factor when hovering (default: 1.08)
    var hoverScale: CGFloat = AnimationConstants.hoverScale

    /// The scale factor when pressed (default: 0.95)
    var pressedScale: CGFloat = AnimationConstants.pressedScale

    /// The shadow color for hover state
    var shadowColor: Color = .black.opacity(AnimationConstants.hoverShadowOpacity)

    /// The shadow radius for hover state
    var shadowRadius: CGFloat = AnimationConstants.hoverShadowRadius

    // MARK: - Body

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(scaleValue(isPressed: configuration.isPressed))
            .shadow(
                color: isHovering ? shadowColor : .clear,
                radius: isHovering ? shadowRadius : 0,
                x: 0,
                y: isHovering ? 4 : 0
            )
            .animation(
                configuration.isPressed ? AnimationConstants.buttonPress : AnimationConstants.buttonHover,
                value: configuration.isPressed
            )
            .animation(AnimationConstants.buttonHover, value: isHovering)
            .onHover { hovering in
                isHovering = hovering
            }
    }

    // MARK: - Private Helpers

    /// Calculates the appropriate scale value based on interaction state.
    private func scaleValue(isPressed: Bool) -> CGFloat {
        if isPressed {
            pressedScale
        } else if isHovering {
            hoverScale
        } else {
            AnimationConstants.defaultScale
        }
    }
}

// MARK: - Button Style Extension

extension ButtonStyle where Self == AnimatedButtonStyle {
    /// A playful button style with hover and press animations.
    static var animated: AnimatedButtonStyle {
        AnimatedButtonStyle()
    }

    /// A playful button style with custom scale values.
    /// - Parameters:
    ///   - hoverScale: Scale factor when hovering (default: 1.08)
    ///   - pressedScale: Scale factor when pressed (default: 0.95)
    static func animated(
        hoverScale: CGFloat = AnimationConstants.hoverScale,
        pressedScale: CGFloat = AnimationConstants.pressedScale
    ) -> AnimatedButtonStyle {
        AnimatedButtonStyle(hoverScale: hoverScale, pressedScale: pressedScale)
    }
}

// MARK: - Preview

#Preview("Animated Button Style") {
    VStack(spacing: 20) {
        Button("Start Focus") {
            print("Focus started")
        }
        .buttonStyle(.animated)
        .padding()
        .background(Color.tomatoRed)
        .foregroundColor(.white)
        .cornerRadius(12)

        Button("Take a Break") {
            print("Break started")
        }
        .buttonStyle(.animated)
        .padding()
        .background(Color.mint)
        .foregroundColor(.white)
        .cornerRadius(12)

        Button("Custom Scale") {
            print("Custom tapped")
        }
        .buttonStyle(.animated(hoverScale: 1.15, pressedScale: 0.9))
        .padding()
        .background(Color.lavender)
        .foregroundColor(.white)
        .cornerRadius(12)
    }
    .padding(40)
}
