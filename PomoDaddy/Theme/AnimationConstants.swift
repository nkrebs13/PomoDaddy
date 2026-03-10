//
//  AnimationConstants.swift
//  PomoDaddy
//
//  Reusable animation constants for consistent app-wide animations.
//

import SwiftUI

// MARK: - Animation Constants

/// Centralized animation constants for consistent, playful animations throughout the app.
enum AnimationConstants {
    // MARK: Button Animations

    /// Spring animation for button hover states - bouncy and responsive
    static let buttonHover: Animation = .spring(response: 0.3, dampingFraction: 0.6)

    /// Spring animation for button press states - quick and snappy
    static let buttonPress: Animation = .spring(response: 0.2, dampingFraction: 0.5)

    // MARK: Transition Animations

    /// Spring animation for mode transitions (focus/break) - smooth and deliberate
    static let modeTransition: Animation = .spring(response: 0.5, dampingFraction: 0.7)

    /// Ease-out animation for timer tick updates - subtle and non-distracting
    static let timerTick: Animation = .easeOut(duration: 0.15)

    /// Ease-out animation for popover appearance - smooth entry
    static let popoverAppear: Animation = .easeOut(duration: 0.25)

    // MARK: Celebration Animations

    /// Duration for confetti celebration animation in seconds
    static let confettiDuration: Double = 2.5

    // MARK: Scale Values

    /// Scale factor for hover state
    static let hoverScale: CGFloat = 1.08

    /// Scale factor for pressed state
    static let pressedScale: CGFloat = 0.95

    /// Default scale (no transformation)
    static let defaultScale: CGFloat = 1.0

    // MARK: Shadow Values

    /// Shadow radius for hover state
    static let hoverShadowRadius: CGFloat = 8

    /// Shadow opacity for hover state
    static let hoverShadowOpacity: Double = 0.15
}

// MARK: - Animation Extensions

extension Animation {
    /// Convenience accessor for button hover animation
    static var buttonHover: Animation {
        AnimationConstants.buttonHover
    }

    /// Convenience accessor for button press animation
    static var buttonPress: Animation {
        AnimationConstants.buttonPress
    }

    /// Convenience accessor for mode transition animation
    static var modeTransition: Animation {
        AnimationConstants.modeTransition
    }

    /// Convenience accessor for timer tick animation
    static var timerTick: Animation {
        AnimationConstants.timerTick
    }

    /// Convenience accessor for popover appear animation
    static var popoverAppear: Animation {
        AnimationConstants.popoverAppear
    }
}
