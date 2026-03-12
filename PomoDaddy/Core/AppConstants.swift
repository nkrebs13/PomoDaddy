//
//  AppConstants.swift
//  PomoDaddy
//
//  Centralized constants for the application.
//

import CoreGraphics
import Foundation

/// Centralized application constants to avoid magic numbers and hardcoded strings.
enum AppConstants {
    // MARK: - Confetti Animation

    enum Confetti {
        /// Confetti animation duration in seconds.
        static let duration: TimeInterval = 3.0

        /// Confetti animation duration in nanoseconds (for Task.sleep).
        static let durationNanoseconds: UInt64 = 3_000_000_000
    }

    // MARK: - Floating Window

    enum FloatingWindow {
        /// Default floating window width.
        static let defaultWidth: CGFloat = 280

        /// Default floating window height.
        static let defaultHeight: CGFloat = 320

        /// Compact floating window width.
        static let compactWidth: CGFloat = 180

        /// Compact floating window height.
        static let compactHeight: CGFloat = 180

        /// Frame autosave name for position persistence.
        static let frameAutosaveName = "com.pomodaddy.floatingWindow"
    }

    // MARK: - Menu Popover

    enum MenuPopover {
        /// Menu popover width.
        static let width: CGFloat = 300

        /// Timer ring size (diameter).
        static let timerRingSize: CGFloat = 120
    }

    // MARK: - Menu Bar

    enum MenuBar {
        /// Icon update polling interval in seconds.
        static let iconUpdateInterval: TimeInterval = 1.0
    }

    // MARK: - UserDefaults Keys

    enum UserDefaultsKeys {
        /// Key for persisted state machine state.
        static let stateMachineState = "com.pomodaddy.stateMachineState"
    }
}
