//
//  PomodoroSettings.swift
//  PomoDaddy
//
//  Codable settings struct for user preferences, stored in UserDefaults.
//

import Foundation

/// User-configurable settings for the pomodoro timer.
struct PomodoroSettings: Codable, Equatable {
    // MARK: - Timer Duration Settings

    /// Duration of a focus/work session in minutes.
    var workDurationMinutes: Int

    /// Duration of a short break in minutes.
    var shortBreakDurationMinutes: Int

    /// Duration of a long break in minutes.
    var longBreakDurationMinutes: Int

    /// Number of pomodoros before a long break is triggered.
    var pomodorosUntilLongBreak: Int

    // MARK: - Behavior Settings

    /// Whether to automatically start the next session (break or work).
    var autoStartNextSession: Bool

    /// Whether to show system notifications.
    var showNotifications: Bool

    // MARK: - UI Settings

    /// Whether to show the floating timer window.
    var showFloatingWindow: Bool

    /// Whether to show the countdown in the menu bar.
    var showMenuBarCountdown: Bool

    // MARK: - Default Values

    /// Default settings following the classic Pomodoro Technique.
    static let `default` = PomodoroSettings(
        workDurationMinutes: 25,
        shortBreakDurationMinutes: 5,
        longBreakDurationMinutes: 15,
        pomodorosUntilLongBreak: 4,
        autoStartNextSession: false,
        showNotifications: true,
        showFloatingWindow: true,
        showMenuBarCountdown: true
    )

    // MARK: - Computed Properties

    /// Work duration as TimeInterval (seconds).
    var workDuration: TimeInterval {
        TimeInterval(workDurationMinutes * 60)
    }

    /// Short break duration as TimeInterval (seconds).
    var shortBreakDuration: TimeInterval {
        TimeInterval(shortBreakDurationMinutes * 60)
    }

    /// Long break duration as TimeInterval (seconds).
    var longBreakDuration: TimeInterval {
        TimeInterval(longBreakDurationMinutes * 60)
    }

    // MARK: - Validation

    /// Validates the settings and returns corrected values if needed.
    var validated: PomodoroSettings {
        var corrected = self

        // Ensure positive durations
        corrected.workDurationMinutes = max(1, workDurationMinutes)
        corrected.shortBreakDurationMinutes = max(1, shortBreakDurationMinutes)
        corrected.longBreakDurationMinutes = max(1, longBreakDurationMinutes)

        // Ensure reasonable limits
        corrected.workDurationMinutes = min(120, corrected.workDurationMinutes)
        corrected.shortBreakDurationMinutes = min(60, corrected.shortBreakDurationMinutes)
        corrected.longBreakDurationMinutes = min(60, corrected.longBreakDurationMinutes)

        // Ensure at least 1 pomodoro before long break
        corrected.pomodorosUntilLongBreak = max(1, min(10, pomodorosUntilLongBreak))

        return corrected
    }

    /// Whether the current settings match the defaults.
    var isDefault: Bool {
        self == PomodoroSettings.default
    }
}

// MARK: - Preset Configurations

extension PomodoroSettings {
    /// Classic 25/5/15 Pomodoro Technique settings.
    static let classic = PomodoroSettings.default

    /// Extended focus: 50 minute work sessions.
    static let extendedFocus = PomodoroSettings(
        workDurationMinutes: 50,
        shortBreakDurationMinutes: 10,
        longBreakDurationMinutes: 30,
        pomodorosUntilLongBreak: 4,
        autoStartNextSession: false,
        showNotifications: true,
        showFloatingWindow: true,
        showMenuBarCountdown: true
    )

    /// Quick sprints: 15 minute work sessions.
    static let quickSprints = PomodoroSettings(
        workDurationMinutes: 15,
        shortBreakDurationMinutes: 3,
        longBreakDurationMinutes: 10,
        pomodorosUntilLongBreak: 4,
        autoStartNextSession: true,
        showNotifications: true,
        showFloatingWindow: true,
        showMenuBarCountdown: true
    )
}

// MARK: - Description

extension PomodoroSettings: CustomStringConvertible {
    var description: String {
        """
        PomodoroSettings(
            work: \(workDurationMinutes)m,
            shortBreak: \(shortBreakDurationMinutes)m,
            longBreak: \(longBreakDurationMinutes)m,
            cycleLength: \(pomodorosUntilLongBreak)
        )
        """
    }
}
