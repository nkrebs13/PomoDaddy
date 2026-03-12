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

