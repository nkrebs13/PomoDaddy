//
//  PomodoroSettings.swift
//  PomoDaddy
//
//  Codable settings struct for user preferences, stored in UserDefaults.
//

import Foundation

/// User-configurable settings for the pomodoro timer.
internal struct PomodoroSettings: Codable, Equatable {
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

    /// Whether to automatically start breaks after work sessions complete.
    var autoStartBreaks: Bool

    /// Whether to automatically start work sessions after breaks complete.
    var autoStartWork: Bool

    /// Whether to show system notifications.
    var showNotifications: Bool

    // MARK: - UI Settings

    /// Whether to show the floating timer window.
    var showFloatingWindow: Bool

    /// Whether to show the countdown in the menu bar.
    var showMenuBarCountdown: Bool

    // MARK: - Default Values

    /// Default settings following the classic Pomodoro Technique.
    static let `default`: PomodoroSettings = PomodoroSettings(
        workDurationMinutes: 25,
        shortBreakDurationMinutes: 5,
        longBreakDurationMinutes: 15,
        pomodorosUntilLongBreak: 4,
        autoStartBreaks: false,
        autoStartWork: false,
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

    /// Whether to automatically start the next session (break or work).
    /// This computed property provides backward compatibility and convenience.
    /// Setting this property sets both autoStartBreaks and autoStartWork to the same value.
    var autoStartNextSession: Bool {
        get { autoStartBreaks && autoStartWork }
        set {
            autoStartBreaks = newValue
            autoStartWork = newValue
        }
    }

    // MARK: - Validation

    /// Validates the settings and returns corrected values if needed.
    var validated: PomodoroSettings {
        var corrected: PomodoroSettings = self

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
    static let classic: PomodoroSettings = PomodoroSettings.default

    /// Extended focus: 50 minute work sessions.
    static let extendedFocus: PomodoroSettings = PomodoroSettings(
        workDurationMinutes: 50,
        shortBreakDurationMinutes: 10,
        longBreakDurationMinutes: 30,
        pomodorosUntilLongBreak: 4,
        autoStartBreaks: false,
        autoStartWork: false,
        showNotifications: true,
        showFloatingWindow: true,
        showMenuBarCountdown: true
    )

    /// Quick sprints: 15 minute work sessions.
    static let quickSprints: PomodoroSettings = PomodoroSettings(
        workDurationMinutes: 15,
        shortBreakDurationMinutes: 3,
        longBreakDurationMinutes: 10,
        pomodorosUntilLongBreak: 4,
        autoStartBreaks: true,
        autoStartWork: true,
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
