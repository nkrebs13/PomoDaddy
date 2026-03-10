//
//  TimerConfiguration.swift
//  PomoDaddy
//
//  Timer configuration constants and user settings.
//

import Foundation
import os.log

// MARK: - Default Configuration Constants

/// Default timer configuration constants.
enum TimerConfiguration {
    /// Default work session duration: 25 minutes.
    static let defaultWorkDuration: TimeInterval = 25 * 60

    /// Default short break duration: 5 minutes.
    static let defaultShortBreakDuration: TimeInterval = 5 * 60

    /// Default long break duration: 15 minutes.
    static let defaultLongBreakDuration: TimeInterval = 15 * 60

    /// Number of pomodoros to complete before a long break.
    static let defaultPomodorosUntilLongBreak = 4

    /// Minimum allowed duration for any interval: 1 minute.
    static let minimumDuration: TimeInterval = 1 * 60

    /// Maximum allowed duration for any interval: 120 minutes.
    static let maximumDuration: TimeInterval = 120 * 60
}

// MARK: - Timer Settings

/// User-configurable timer settings.
struct TimerSettings: Codable, Equatable {
    /// Duration of work sessions in seconds.
    var workDuration: TimeInterval

    /// Duration of short breaks in seconds.
    var shortBreakDuration: TimeInterval

    /// Duration of long breaks in seconds.
    var longBreakDuration: TimeInterval

    /// Number of pomodoros to complete before a long break.
    var pomodorosUntilLongBreak: Int

    /// Whether to automatically start breaks after work sessions.
    var autoStartBreaks: Bool

    /// Whether to automatically start work sessions after breaks.
    var autoStartWork: Bool

    /// Whether to play sound notifications.
    var soundEnabled: Bool

    /// Whether to show system notifications.
    var notificationsEnabled: Bool

    /// Creates settings with default values.
    init() {
        workDuration = TimerConfiguration.defaultWorkDuration
        shortBreakDuration = TimerConfiguration.defaultShortBreakDuration
        longBreakDuration = TimerConfiguration.defaultLongBreakDuration
        pomodorosUntilLongBreak = TimerConfiguration.defaultPomodorosUntilLongBreak
        autoStartBreaks = false
        autoStartWork = false
        soundEnabled = true
        notificationsEnabled = true
    }

    /// Creates settings with custom values.
    init(
        workDuration: TimeInterval,
        shortBreakDuration: TimeInterval,
        longBreakDuration: TimeInterval,
        pomodorosUntilLongBreak: Int,
        autoStartBreaks: Bool = false,
        autoStartWork: Bool = false,
        soundEnabled: Bool = true,
        notificationsEnabled: Bool = true
    ) {
        self.workDuration = workDuration
        self.shortBreakDuration = shortBreakDuration
        self.longBreakDuration = longBreakDuration
        self.pomodorosUntilLongBreak = pomodorosUntilLongBreak
        self.autoStartBreaks = autoStartBreaks
        self.autoStartWork = autoStartWork
        self.soundEnabled = soundEnabled
        self.notificationsEnabled = notificationsEnabled
    }

    /// Returns the duration for a given interval type based on current settings.
    func duration(for intervalType: IntervalType) -> TimeInterval {
        switch intervalType {
        case .work:
            workDuration
        case .shortBreak:
            shortBreakDuration
        case .longBreak:
            longBreakDuration
        }
    }

    /// Validates and clamps all duration values to acceptable ranges.
    mutating func validate() {
        workDuration = workDuration.clamped(
            to: TimerConfiguration.minimumDuration ... TimerConfiguration.maximumDuration
        )
        shortBreakDuration = shortBreakDuration.clamped(
            to: TimerConfiguration.minimumDuration ... TimerConfiguration.maximumDuration
        )
        longBreakDuration = longBreakDuration.clamped(
            to: TimerConfiguration.minimumDuration ... TimerConfiguration.maximumDuration
        )
        pomodorosUntilLongBreak = max(1, min(10, pomodorosUntilLongBreak))
    }
}

// MARK: - TimeInterval Extension

extension TimeInterval {
    /// Clamps the value to the specified range.
    func clamped(to range: ClosedRange<TimeInterval>) -> TimeInterval {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - UserDefaults Keys

extension TimerSettings {
    /// Key used for storing settings in UserDefaults.
    static let userDefaultsKey = "com.pomodaddy.timerSettings"

    /// Saves the settings to UserDefaults.
    func save() {
        do {
            let encoded = try JSONEncoder().encode(self)
            UserDefaults.standard.set(encoded, forKey: Self.userDefaultsKey)
        } catch {
            Logger.logError(error, context: "Failed to save timer settings", log: Logger.persistence)
        }
    }

    /// Loads settings from UserDefaults, or returns default settings if none exist.
    static func load() -> TimerSettings {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return TimerSettings()
        }

        do {
            return try JSONDecoder().decode(TimerSettings.self, from: data)
        } catch {
            Logger.logError(error, context: "Failed to decode timer settings", log: Logger.persistence)
            return TimerSettings()
        }
    }
}
