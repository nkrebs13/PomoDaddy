import XCTest
@testable import PomoDaddy

final class SettingsManagerTests: XCTestCase {
    var settingsManager: SettingsManager!
    var mockDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        // Use a separate suite for testing
        mockDefaults = UserDefaults(suiteName: "com.pomodaddy.tests")!
        mockDefaults.removePersistentDomain(forName: "com.pomodaddy.tests")
        settingsManager = SettingsManager(defaults: mockDefaults)
    }

    override func tearDown() {
        mockDefaults.removePersistentDomain(forName: "com.pomodaddy.tests")
        settingsManager = nil
        mockDefaults = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialSettings() {
        // Should load defaults on first init
        XCTAssertEqual(settingsManager.settings.workDurationMinutes, 25)
        XCTAssertEqual(settingsManager.settings.shortBreakDurationMinutes, 5)
        XCTAssertEqual(settingsManager.settings.longBreakDurationMinutes, 15)
        XCTAssertEqual(settingsManager.settings.pomodorosUntilLongBreak, 4)
        XCTAssertFalse(settingsManager.settings.autoStartBreaks)
        XCTAssertFalse(settingsManager.settings.autoStartWork)
        XCTAssertTrue(settingsManager.settings.showNotifications)
    }

    // MARK: - Update Tests

    func testUpdateSettings() {
        let newSettings = PomodoroSettings(
            workDurationMinutes: 50,
            shortBreakDurationMinutes: 10,
            longBreakDurationMinutes: 20,
            pomodorosUntilLongBreak: 3,
            autoStartBreaks: true,
            autoStartWork: true,
            showNotifications: false,
            showFloatingWindow: false,
            showMenuBarCountdown: false
        )

        settingsManager.update(newSettings)

        XCTAssertEqual(settingsManager.settings.workDurationMinutes, 50)
        XCTAssertEqual(settingsManager.settings.shortBreakDurationMinutes, 10)
        XCTAssertEqual(settingsManager.settings.longBreakDurationMinutes, 20)
        XCTAssertEqual(settingsManager.settings.pomodorosUntilLongBreak, 3)
        XCTAssertTrue(settingsManager.settings.autoStartBreaks)
        XCTAssertTrue(settingsManager.settings.autoStartWork)
        XCTAssertFalse(settingsManager.settings.showNotifications)
    }

    func testUpdateWithClosure() {
        settingsManager.update { settings in
            settings.workDurationMinutes = 45
            settings.autoStartBreaks = true
            settings.autoStartWork = true
        }

        XCTAssertEqual(settingsManager.settings.workDurationMinutes, 45)
        XCTAssertTrue(settingsManager.settings.autoStartBreaks)
        XCTAssertTrue(settingsManager.settings.autoStartWork)
    }

    // MARK: - Individual Setting Updates

    func testSetWorkDuration() {
        settingsManager.setWorkDuration(minutes: 30)
        XCTAssertEqual(settingsManager.settings.workDurationMinutes, 30)
    }

    func testSetShortBreakDuration() {
        settingsManager.setShortBreakDuration(minutes: 10)
        XCTAssertEqual(settingsManager.settings.shortBreakDurationMinutes, 10)
    }

    func testSetLongBreakDuration() {
        settingsManager.setLongBreakDuration(minutes: 25)
        XCTAssertEqual(settingsManager.settings.longBreakDurationMinutes, 25)
    }

    func testSetPomodorosUntilLongBreak() {
        settingsManager.setPomodorosUntilLongBreak(count: 6)
        XCTAssertEqual(settingsManager.settings.pomodorosUntilLongBreak, 6)
    }

    func testSetAutoStartNextSession() {
        settingsManager.setAutoStartNextSession(enabled: true)
        XCTAssertTrue(settingsManager.settings.autoStartBreaks)
        XCTAssertTrue(settingsManager.settings.autoStartWork)

        settingsManager.setAutoStartNextSession(enabled: false)
        XCTAssertFalse(settingsManager.settings.autoStartBreaks)
        XCTAssertFalse(settingsManager.settings.autoStartWork)
    }

    func testSetShowNotifications() {
        settingsManager.setShowNotifications(enabled: false)
        XCTAssertFalse(settingsManager.settings.showNotifications)

        settingsManager.setShowNotifications(enabled: true)
        XCTAssertTrue(settingsManager.settings.showNotifications)
    }

    func testSetShowFloatingWindow() {
        settingsManager.setShowFloatingWindow(enabled: false)
        XCTAssertFalse(settingsManager.settings.showFloatingWindow)

        settingsManager.setShowFloatingWindow(enabled: true)
        XCTAssertTrue(settingsManager.settings.showFloatingWindow)
    }

    func testSetShowMenuBarCountdown() {
        settingsManager.setShowMenuBarCountdown(enabled: false)
        XCTAssertFalse(settingsManager.settings.showMenuBarCountdown)

        settingsManager.setShowMenuBarCountdown(enabled: true)
        XCTAssertTrue(settingsManager.settings.showMenuBarCountdown)
    }

    // MARK: - Persistence Tests

    func testSettingsPersistence() {
        // Update settings
        settingsManager.setWorkDuration(minutes: 40)
        settingsManager.setAutoStartNextSession(enabled: true)

        // Create a new settings manager (simulating app restart)
        let newManager = SettingsManager(defaults: mockDefaults)

        // Should load persisted settings
        XCTAssertEqual(newManager.settings.workDurationMinutes, 40)
        XCTAssertTrue(newManager.settings.autoStartBreaks)
        XCTAssertTrue(newManager.settings.autoStartWork)
    }

    func testSettingsAutomaticallySaveOnChange() {
        settingsManager.update { settings in
            settings.workDurationMinutes = 35
        }

        // Verify it was saved
        let data = mockDefaults.data(forKey: "com.pomodaddy.settings")
        XCTAssertNotNil(data)
    }

    // MARK: - Reset Tests

    func testResetToDefaults() {
        // Change settings
        settingsManager.setWorkDuration(minutes: 50)
        settingsManager.setAutoStartNextSession(enabled: true)
        settingsManager.setPomodorosUntilLongBreak(count: 6)

        // Reset
        settingsManager.resetToDefaults()

        // Should be back to defaults
        XCTAssertEqual(settingsManager.settings.workDurationMinutes, 25)
        XCTAssertEqual(settingsManager.settings.shortBreakDurationMinutes, 5)
        XCTAssertEqual(settingsManager.settings.longBreakDurationMinutes, 15)
        XCTAssertEqual(settingsManager.settings.pomodorosUntilLongBreak, 4)
        XCTAssertFalse(settingsManager.settings.autoStartBreaks)
        XCTAssertFalse(settingsManager.settings.autoStartWork)
    }

    // MARK: - Preset Tests

    func testApplyClassicPreset() {
        settingsManager.applyPreset(.classic)

        XCTAssertEqual(settingsManager.settings.workDurationMinutes, 25)
        XCTAssertEqual(settingsManager.settings.shortBreakDurationMinutes, 5)
        XCTAssertEqual(settingsManager.settings.longBreakDurationMinutes, 15)
        XCTAssertEqual(settingsManager.settings.pomodorosUntilLongBreak, 4)
    }

    func testApplyExtendedFocusPreset() {
        settingsManager.applyPreset(.extendedFocus)

        XCTAssertEqual(settingsManager.settings.workDurationMinutes, 50)
        XCTAssertEqual(settingsManager.settings.shortBreakDurationMinutes, 10)
        XCTAssertEqual(settingsManager.settings.longBreakDurationMinutes, 30)
        XCTAssertEqual(settingsManager.settings.pomodorosUntilLongBreak, 4)
    }

    func testApplyQuickSprintsPreset() {
        settingsManager.applyPreset(.quickSprints)

        XCTAssertEqual(settingsManager.settings.workDurationMinutes, 15)
        XCTAssertEqual(settingsManager.settings.shortBreakDurationMinutes, 3)
        XCTAssertEqual(settingsManager.settings.longBreakDurationMinutes, 10)
        XCTAssertEqual(settingsManager.settings.pomodorosUntilLongBreak, 4)
    }

    // MARK: - Validation Tests

    func testValidationClampsValues() {
        // Try to set invalid values
        let invalidSettings = PomodoroSettings(
            workDurationMinutes: 200, // Above max
            shortBreakDurationMinutes: 0, // Below min
            longBreakDurationMinutes: 150, // Above max
            pomodorosUntilLongBreak: 15, // Above max
            autoStartBreaks: false,
            autoStartWork: false,
            showNotifications: true,
            showFloatingWindow: true,
            showMenuBarCountdown: true
        )

        settingsManager.update(invalidSettings)

        // Should be clamped to valid ranges
        XCTAssertLessThanOrEqual(settingsManager.settings.workDurationMinutes, 120)
        XCTAssertGreaterThanOrEqual(settingsManager.settings.shortBreakDurationMinutes, 1)
        XCTAssertLessThanOrEqual(settingsManager.settings.longBreakDurationMinutes, 120)
        XCTAssertLessThanOrEqual(settingsManager.settings.pomodorosUntilLongBreak, 10)
    }

    // MARK: - Error Handling Tests

    func testLoadingCorruptedData() {
        // Write invalid data
        let invalidData = Data("invalid json".utf8)
        mockDefaults.set(invalidData, forKey: "com.pomodaddy.settings")

        // Should fall back to defaults without crashing
        let manager = SettingsManager(defaults: mockDefaults)
        XCTAssertEqual(manager.settings.workDurationMinutes, 25)
    }

    // MARK: - Thread Safety Tests

    func testConcurrentUpdates() {
        let expectation = expectation(description: "concurrent updates")
        expectation.expectedFulfillmentCount = 10

        DispatchQueue.concurrentPerform(iterations: 10) { index in
            settingsManager.setWorkDuration(minutes: 20 + index)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)

        // Should not crash and should have some value
        XCTAssertGreaterThanOrEqual(settingsManager.settings.workDurationMinutes, 20)
        XCTAssertLessThanOrEqual(settingsManager.settings.workDurationMinutes, 30)
    }
}
