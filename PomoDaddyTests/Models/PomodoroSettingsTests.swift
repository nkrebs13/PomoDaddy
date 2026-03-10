import XCTest
@testable import PomoDaddy

final class PomodoroSettingsTests: XCTestCase {
    // MARK: - Default Settings Tests

    func testDefaultSettings() {
        let settings = PomodoroSettings.default

        XCTAssertEqual(settings.workDurationMinutes, 25)
        XCTAssertEqual(settings.shortBreakDurationMinutes, 5)
        XCTAssertEqual(settings.longBreakDurationMinutes, 15)
        XCTAssertEqual(settings.pomodorosUntilLongBreak, 4)
        XCTAssertFalse(settings.autoStartBreaks)
        XCTAssertFalse(settings.autoStartWork)
        XCTAssertTrue(settings.showNotifications)
        XCTAssertTrue(settings.showFloatingWindow)
        XCTAssertTrue(settings.showMenuBarCountdown)
    }

    // MARK: - Preset Tests

    func testClassicPreset() {
        let settings = PomodoroSettings.classic

        XCTAssertEqual(settings.workDurationMinutes, 25)
        XCTAssertEqual(settings.shortBreakDurationMinutes, 5)
        XCTAssertEqual(settings.longBreakDurationMinutes, 15)
        XCTAssertEqual(settings.pomodorosUntilLongBreak, 4)
    }

    func testExtendedFocusPreset() {
        let settings = PomodoroSettings.extendedFocus

        XCTAssertEqual(settings.workDurationMinutes, 50)
        XCTAssertEqual(settings.shortBreakDurationMinutes, 10)
        XCTAssertEqual(settings.longBreakDurationMinutes, 30)
        XCTAssertEqual(settings.pomodorosUntilLongBreak, 4)
    }

    func testQuickSprintsPreset() {
        let settings = PomodoroSettings.quickSprints

        XCTAssertEqual(settings.workDurationMinutes, 15)
        XCTAssertEqual(settings.shortBreakDurationMinutes, 3)
        XCTAssertEqual(settings.longBreakDurationMinutes, 10)
        XCTAssertEqual(settings.pomodorosUntilLongBreak, 4)
    }

    // MARK: - Duration Conversion Tests

    func testWorkDuration() {
        let settings = PomodoroSettings(
            workDurationMinutes: 30,
            shortBreakDurationMinutes: 5,
            longBreakDurationMinutes: 15,
            pomodorosUntilLongBreak: 4,
            autoStartBreaks: false,
            autoStartWork: false,
            showNotifications: true,
            showFloatingWindow: true,
            showMenuBarCountdown: true
        )

        XCTAssertEqual(settings.workDuration, 30 * 60)
    }

    func testShortBreakDuration() {
        let settings = PomodoroSettings(
            workDurationMinutes: 25,
            shortBreakDurationMinutes: 8,
            longBreakDurationMinutes: 15,
            pomodorosUntilLongBreak: 4,
            autoStartBreaks: false,
            autoStartWork: false,
            showNotifications: true,
            showFloatingWindow: true,
            showMenuBarCountdown: true
        )

        XCTAssertEqual(settings.shortBreakDuration, 8 * 60)
    }

    func testLongBreakDuration() {
        let settings = PomodoroSettings(
            workDurationMinutes: 25,
            shortBreakDurationMinutes: 5,
            longBreakDurationMinutes: 20,
            pomodorosUntilLongBreak: 4,
            autoStartBreaks: false,
            autoStartWork: false,
            showNotifications: true,
            showFloatingWindow: true,
            showMenuBarCountdown: true
        )

        XCTAssertEqual(settings.longBreakDuration, 20 * 60)
    }

    // MARK: - Validation Tests

    func testValidatedSettings() {
        var settings = PomodoroSettings(
            workDurationMinutes: 200, // Above max
            shortBreakDurationMinutes: 0, // Below min
            longBreakDurationMinutes: -5, // Below min
            pomodorosUntilLongBreak: 15, // Above max
            autoStartBreaks: false,
            autoStartWork: false,
            showNotifications: true,
            showFloatingWindow: true,
            showMenuBarCountdown: true
        )

        let validated = settings.validated

        // Should clamp to valid ranges
        XCTAssertLessThanOrEqual(validated.workDurationMinutes, 120)
        XCTAssertGreaterThanOrEqual(validated.workDurationMinutes, 1)
        XCTAssertGreaterThanOrEqual(validated.shortBreakDurationMinutes, 1)
        XCTAssertGreaterThanOrEqual(validated.longBreakDurationMinutes, 1)
        XCTAssertLessThanOrEqual(validated.pomodorosUntilLongBreak, 10)
        XCTAssertGreaterThanOrEqual(validated.pomodorosUntilLongBreak, 1)
    }

    func testValidationClampsToMinimum() {
        var settings = PomodoroSettings(
            workDurationMinutes: 0,
            shortBreakDurationMinutes: 0,
            longBreakDurationMinutes: 0,
            pomodorosUntilLongBreak: 0,
            autoStartBreaks: false,
            autoStartWork: false,
            showNotifications: true,
            showFloatingWindow: true,
            showMenuBarCountdown: true
        )

        let validated = settings.validated

        XCTAssertGreaterThanOrEqual(validated.workDurationMinutes, 1)
        XCTAssertGreaterThanOrEqual(validated.shortBreakDurationMinutes, 1)
        XCTAssertGreaterThanOrEqual(validated.longBreakDurationMinutes, 1)
        XCTAssertGreaterThanOrEqual(validated.pomodorosUntilLongBreak, 1)
    }

    func testValidationClampsToMaximum() {
        var settings = PomodoroSettings(
            workDurationMinutes: 999,
            shortBreakDurationMinutes: 999,
            longBreakDurationMinutes: 999,
            pomodorosUntilLongBreak: 999,
            autoStartBreaks: false,
            autoStartWork: false,
            showNotifications: true,
            showFloatingWindow: true,
            showMenuBarCountdown: true
        )

        let validated = settings.validated

        XCTAssertLessThanOrEqual(validated.workDurationMinutes, 120)
        XCTAssertLessThanOrEqual(validated.shortBreakDurationMinutes, 120)
        XCTAssertLessThanOrEqual(validated.longBreakDurationMinutes, 120)
        XCTAssertLessThanOrEqual(validated.pomodorosUntilLongBreak, 10)
    }

    // MARK: - Codable Tests

    func testEncodeDecode() throws {
        let original = PomodoroSettings(
            workDurationMinutes: 30,
            shortBreakDurationMinutes: 7,
            longBreakDurationMinutes: 18,
            pomodorosUntilLongBreak: 3,
            autoStartBreaks: true,
            autoStartWork: true,
            showNotifications: false,
            showFloatingWindow: false,
            showMenuBarCountdown: false
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PomodoroSettings.self, from: data)

        XCTAssertEqual(decoded.workDurationMinutes, original.workDurationMinutes)
        XCTAssertEqual(decoded.shortBreakDurationMinutes, original.shortBreakDurationMinutes)
        XCTAssertEqual(decoded.longBreakDurationMinutes, original.longBreakDurationMinutes)
        XCTAssertEqual(decoded.pomodorosUntilLongBreak, original.pomodorosUntilLongBreak)
        XCTAssertEqual(decoded.autoStartBreaks, original.autoStartBreaks)
        XCTAssertEqual(decoded.autoStartWork, original.autoStartWork)
        XCTAssertEqual(decoded.showNotifications, original.showNotifications)
        XCTAssertEqual(decoded.showFloatingWindow, original.showFloatingWindow)
        XCTAssertEqual(decoded.showMenuBarCountdown, original.showMenuBarCountdown)
    }

    // MARK: - Equatable Tests

    func testEquality() {
        let settings1 = PomodoroSettings.default
        let settings2 = PomodoroSettings.default

        XCTAssertEqual(settings1, settings2)
    }

    func testInequality() {
        let settings1 = PomodoroSettings.default
        var settings2 = PomodoroSettings.default
        settings2.workDurationMinutes = 30

        XCTAssertNotEqual(settings1, settings2)
    }

    // MARK: - Backward Compatibility Tests

    func testAutoStartNextSessionComputedProperty() {
        var settings = PomodoroSettings.default

        // Test setting via computed property sets both
        settings.autoStartNextSession = true
        XCTAssertTrue(settings.autoStartBreaks)
        XCTAssertTrue(settings.autoStartWork)
        XCTAssertTrue(settings.autoStartNextSession)

        // Test unsetting via computed property unsets both
        settings.autoStartNextSession = false
        XCTAssertFalse(settings.autoStartBreaks)
        XCTAssertFalse(settings.autoStartWork)
        XCTAssertFalse(settings.autoStartNextSession)

        // Test edge case: split preferences (one true, one false)
        settings.autoStartBreaks = true
        settings.autoStartWork = false
        XCTAssertFalse(settings.autoStartNextSession) // Returns false when split (uses &&)

        // Test edge case: opposite split
        settings.autoStartBreaks = false
        settings.autoStartWork = true
        XCTAssertFalse(settings.autoStartNextSession) // Returns false when split (uses &&)
    }
}
