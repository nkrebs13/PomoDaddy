//
//  SettingsManaging.swift
//  PomoDaddy
//
//  Protocol for settings management dependency injection.
//

import Foundation

/// Protocol defining the settings management interface for dependency injection and testing.
protocol SettingsManaging: AnyObject {
    /// The current user settings.
    var settings: PomodoroSettings { get }

    /// Called when settings change. Set by AppCoordinator to sync state machine.
    var onChange: (() -> Void)? { get set }

    /// Updates the settings with new values.
    /// - Parameter newSettings: The new settings to apply.
    func update(_ newSettings: PomodoroSettings)

    /// Updates a specific setting using a closure.
    /// - Parameter transform: A closure that modifies the settings.
    func update(_ transform: (inout PomodoroSettings) -> Void)

    /// Resets all settings to defaults.
    func resetToDefaults()

    /// Updates the work duration.
    func setWorkDuration(minutes: Int)

    /// Updates the short break duration.
    func setShortBreakDuration(minutes: Int)

    /// Updates the long break duration.
    func setLongBreakDuration(minutes: Int)

    /// Updates the number of pomodoros until long break.
    func setPomodorosUntilLongBreak(count: Int)

    /// Updates the auto-start setting for both breaks and work.
    func setAutoStartNextSession(enabled: Bool)

    /// Updates the auto-start breaks setting.
    func setAutoStartBreaks(enabled: Bool)

    /// Updates the auto-start work setting.
    func setAutoStartWork(enabled: Bool)

    /// Updates the notifications setting.
    func setShowNotifications(enabled: Bool)

    /// Updates the floating window setting.
    func setShowFloatingWindow(enabled: Bool)

    /// Updates the menu bar countdown setting.
    func setShowMenuBarCountdown(enabled: Bool)

    /// Applies a preset configuration.
    func applyPreset(_ preset: SettingsPreset)
}
