//
//  MockSettingsManager.swift
//  PomoDaddyTests
//
//  Mock settings manager for testing (no UserDefaults).
//

import Foundation
@testable import PomoDaddy

/// Mock settings manager that stores settings in memory.
@Observable
@MainActor
final class MockSettingsManager: SettingsManaging {
    // MARK: - Protocol Properties

    private(set) var settings: PomodoroSettings = .default
    var onChange: (() -> Void)?

    // MARK: - Call Tracking

    private(set) var updateCallCount = 0
    private(set) var resetToDefaultsCallCount = 0
    private(set) var applyPresetCallCount = 0
    private(set) var lastAppliedPreset: SettingsPreset?

    // MARK: - Protocol Methods

    func update(_ newSettings: PomodoroSettings) {
        updateCallCount += 1
        settings = newSettings.validated
        onChange?()
    }

    func update(_ transform: (inout PomodoroSettings) -> Void) {
        updateCallCount += 1
        var modified = settings
        transform(&modified)
        settings = modified.validated
        onChange?()
    }

    func resetToDefaults() {
        resetToDefaultsCallCount += 1
        settings = .default
        onChange?()
    }

    func setWorkDuration(minutes: Int) {
        update { $0.workDurationMinutes = minutes }
    }

    func setShortBreakDuration(minutes: Int) {
        update { $0.shortBreakDurationMinutes = minutes }
    }

    func setLongBreakDuration(minutes: Int) {
        update { $0.longBreakDurationMinutes = minutes }
    }

    func setPomodorosUntilLongBreak(count: Int) {
        update { $0.pomodorosUntilLongBreak = count }
    }

    func setAutoStartNextSession(enabled: Bool) {
        update { $0.autoStartNextSession = enabled }
    }

    func setAutoStartBreaks(enabled: Bool) {
        update { $0.autoStartBreaks = enabled }
    }

    func setAutoStartWork(enabled: Bool) {
        update { $0.autoStartWork = enabled }
    }

    func setShowNotifications(enabled: Bool) {
        update { $0.showNotifications = enabled }
    }

    func setShowFloatingWindow(enabled: Bool) {
        update { $0.showFloatingWindow = enabled }
    }

    func setShowMenuBarCountdown(enabled: Bool) {
        update { $0.showMenuBarCountdown = enabled }
    }

    func applyPreset(_ preset: SettingsPreset) {
        applyPresetCallCount += 1
        lastAppliedPreset = preset
        switch preset {
        case .classic:
            update(PomodoroSettings.classic)
        case .extendedFocus:
            update(PomodoroSettings.extendedFocus)
        case .quickSprints:
            update(PomodoroSettings.quickSprints)
        }
    }
}
