//
//  SettingsManager.swift
//  PomoDaddy
//
//  Observable settings manager that persists to UserDefaults.
//

import Foundation
import SwiftUI

/// Manages user settings with persistence to UserDefaults.
@Observable
final class SettingsManager {
    // MARK: - Constants

    private enum Keys {
        static let settings = "com.pomodaddy.settings"
    }

    // MARK: - Properties

    /// The current user settings.
    private(set) var settings: PomodoroSettings {
        didSet {
            if settings != oldValue {
                save()
                onChange?()
            }
        }
    }

    /// Called when settings change. Set by AppCoordinator to sync state machine.
    var onChange: (() -> Void)?

    /// The UserDefaults instance to use for persistence.
    private let defaults: UserDefaults

    /// JSON encoder for serialization.
    private let encoder = JSONEncoder()

    /// JSON decoder for deserialization.
    private let decoder = JSONDecoder()

    // MARK: - Initialization

    /// Creates a new settings manager.
    /// - Parameter defaults: The UserDefaults instance to use (defaults to standard).
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        settings = PomodoroSettings.default
        load()
    }

    // MARK: - Public Methods

    /// Updates the settings with new values.
    /// - Parameter newSettings: The new settings to apply.
    func update(_ newSettings: PomodoroSettings) {
        settings = newSettings.validated
    }

    /// Updates a specific setting using a closure.
    /// - Parameter transform: A closure that modifies the settings.
    func update(_ transform: (inout PomodoroSettings) -> Void) {
        var modified = settings
        transform(&modified)
        settings = modified.validated
    }

    /// Resets all settings to defaults.
    func resetToDefaults() {
        settings = PomodoroSettings.default
    }

    // MARK: - Individual Setting Updates

    /// Updates the work duration.
    /// - Parameter minutes: New work duration in minutes.
    func setWorkDuration(minutes: Int) {
        update { $0.workDurationMinutes = minutes }
    }

    /// Updates the short break duration.
    /// - Parameter minutes: New short break duration in minutes.
    func setShortBreakDuration(minutes: Int) {
        update { $0.shortBreakDurationMinutes = minutes }
    }

    /// Updates the long break duration.
    /// - Parameter minutes: New long break duration in minutes.
    func setLongBreakDuration(minutes: Int) {
        update { $0.longBreakDurationMinutes = minutes }
    }

    /// Updates the number of pomodoros until long break.
    /// - Parameter count: New pomodoro count.
    func setPomodorosUntilLongBreak(count: Int) {
        update { $0.pomodorosUntilLongBreak = count }
    }

    /// Updates the auto-start setting for both breaks and work.
    /// - Parameter enabled: Whether auto-start is enabled for both.
    func setAutoStartNextSession(enabled: Bool) {
        update { $0.autoStartNextSession = enabled }
    }

    /// Updates the auto-start breaks setting.
    /// - Parameter enabled: Whether breaks should auto-start after work sessions.
    func setAutoStartBreaks(enabled: Bool) {
        update { $0.autoStartBreaks = enabled }
    }

    /// Updates the auto-start work setting.
    /// - Parameter enabled: Whether work sessions should auto-start after breaks.
    func setAutoStartWork(enabled: Bool) {
        update { $0.autoStartWork = enabled }
    }

    /// Updates the notifications setting.
    /// - Parameter enabled: Whether notifications are enabled.
    func setShowNotifications(enabled: Bool) {
        update { $0.showNotifications = enabled }
    }

    /// Updates the floating window setting.
    /// - Parameter enabled: Whether floating window is shown.
    func setShowFloatingWindow(enabled: Bool) {
        update { $0.showFloatingWindow = enabled }
    }

    /// Updates the menu bar countdown setting.
    /// - Parameter enabled: Whether menu bar countdown is shown.
    func setShowMenuBarCountdown(enabled: Bool) {
        update { $0.showMenuBarCountdown = enabled }
    }

    // MARK: - Preset Application

    /// Applies a preset configuration.
    /// - Parameter preset: The preset to apply.
    func applyPreset(_ preset: SettingsPreset) {
        switch preset {
        case .classic:
            update(PomodoroSettings.classic)
        case .extendedFocus:
            update(PomodoroSettings.extendedFocus)
        case .quickSprints:
            update(PomodoroSettings.quickSprints)
        }
    }

    // MARK: - Private Methods

    /// Loads settings from UserDefaults.
    private func load() {
        guard let data = defaults.data(forKey: Keys.settings) else {
            settings = PomodoroSettings.default
            return
        }

        do {
            settings = try decoder.decode(PomodoroSettings.self, from: data)
        } catch {
            Logger.logError(error, context: "Failed to decode settings, using defaults", log: Logger.persistence)
            settings = PomodoroSettings.default
        }
    }

    /// Saves settings to UserDefaults.
    private func save() {
        do {
            let data = try encoder.encode(settings)
            defaults.set(data, forKey: Keys.settings)
        } catch {
            Logger.logError(error, context: "Failed to encode settings", log: Logger.persistence)
        }
    }
}

// MARK: - Settings Presets

/// Available preset configurations.
enum SettingsPreset: String, CaseIterable, Identifiable {
    case classic = "Classic"
    case extendedFocus = "Extended Focus"
    case quickSprints = "Quick Sprints"

    var id: String {
        rawValue
    }

    var description: String {
        switch self {
        case .classic:
            "25 min work, 5 min break"
        case .extendedFocus:
            "50 min work, 10 min break"
        case .quickSprints:
            "15 min work, 3 min break"
        }
    }
}

// MARK: - Preview Support

extension SettingsManager {
    /// Creates a settings manager for previews with default settings.
    static var preview: SettingsManager {
        SettingsManager(defaults: UserDefaults(suiteName: "preview") ?? .standard)
    }
}
