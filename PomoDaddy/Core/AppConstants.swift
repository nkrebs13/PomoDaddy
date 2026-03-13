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

        /// Menu popover height.
        static let height: CGFloat = 420

        /// Timer ring size (diameter).
        static let timerRingSize: CGFloat = 120
    }

    // MARK: - Menu Bar

    enum MenuBar {
        /// Icon update polling interval in seconds.
        static let iconUpdateInterval: TimeInterval = 1.0
    }

    // MARK: - Settings

    enum Settings {
        /// Settings view width.
        static let width: CGFloat = 300

        /// Settings view height.
        static let height: CGFloat = 450
    }

    // MARK: - Daily Focus

    enum DailyFocus {
        /// Daily goal in minutes (2 hours).
        static let dailyGoalMinutes = 120

        /// Maximum tomato icons to display.
        static let maxTomatoDisplay = 8
    }

    // MARK: - UserDefaults Keys

    enum UserDefaultsKeys {
        /// Key for persisted state machine state.
        static let stateMachineState = "com.pomodaddy.stateMachineState"

        /// Key for tracking whether onboarding has been shown.
        static let hasSeenOnboarding = "com.pomodaddy.hasSeenOnboarding"
    }
}
