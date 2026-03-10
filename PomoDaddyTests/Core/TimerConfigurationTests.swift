import XCTest
@testable import PomoDaddy

final class TimerConfigurationTests: XCTestCase {
    var mockDefaults: MockUserDefaults!

    override func setUp() {
        super.setUp()
        mockDefaults = MockUserDefaults()
    }

    override func tearDown() {
        mockDefaults.clear()
        mockDefaults = nil
        super.tearDown()
    }

    // MARK: - Default Values Tests

    func testDefaultSettings() {
        let settings = TimerSettings()

        XCTAssertEqual(settings.workDuration, 25 * 60)
        XCTAssertEqual(settings.shortBreakDuration, 5 * 60)
        XCTAssertEqual(settings.longBreakDuration, 15 * 60)
        XCTAssertEqual(settings.pomodorosUntilLongBreak, 4)
        XCTAssertFalse(settings.autoStartBreaks)
        XCTAssertFalse(settings.autoStartWork)
        XCTAssertTrue(settings.soundEnabled)
        XCTAssertTrue(settings.notificationsEnabled)
    }

    // MARK: - Custom Settings Tests

    func testCustomSettings() {
        let settings = TimerSettings(
            workDuration: 30 * 60,
            shortBreakDuration: 10 * 60,
            longBreakDuration: 20 * 60,
            pomodorosUntilLongBreak: 3,
            autoStartBreaks: true,
            autoStartWork: true,
            soundEnabled: false,
            notificationsEnabled: false
        )

        XCTAssertEqual(settings.workDuration, 30 * 60)
        XCTAssertEqual(settings.shortBreakDuration, 10 * 60)
        XCTAssertEqual(settings.longBreakDuration, 20 * 60)
        XCTAssertEqual(settings.pomodorosUntilLongBreak, 3)
        XCTAssertTrue(settings.autoStartBreaks)
        XCTAssertTrue(settings.autoStartWork)
        XCTAssertFalse(settings.soundEnabled)
        XCTAssertFalse(settings.notificationsEnabled)
    }

    // MARK: - Validation Tests

    func testDurationValidation() {
        let settings = TimerSettings(
            workDuration: 5 * 60, // Min allowed
            shortBreakDuration: 120 * 60, // Max allowed
            longBreakDuration: 120 * 60, // Max allowed
            pomodorosUntilLongBreak: 4,
            autoStartBreaks: false,
            autoStartWork: false,
            soundEnabled: true,
            notificationsEnabled: true
        )

        XCTAssertEqual(settings.workDuration, 5 * 60)
        XCTAssertEqual(settings.shortBreakDuration, 120 * 60)
        XCTAssertEqual(settings.longBreakDuration, 120 * 60)
    }

    func testPomodorosUntilLongBreakValidation() {
        let settings1 = TimerSettings(
            workDuration: 25 * 60,
            shortBreakDuration: 5 * 60,
            longBreakDuration: 15 * 60,
            pomodorosUntilLongBreak: 1, // Min
            autoStartBreaks: false,
            autoStartWork: false,
            soundEnabled: true,
            notificationsEnabled: true
        )
        XCTAssertEqual(settings1.pomodorosUntilLongBreak, 1)

        let settings2 = TimerSettings(
            workDuration: 25 * 60,
            shortBreakDuration: 5 * 60,
            longBreakDuration: 15 * 60,
            pomodorosUntilLongBreak: 10, // Max
            autoStartBreaks: false,
            autoStartWork: false,
            soundEnabled: true,
            notificationsEnabled: true
        )
        XCTAssertEqual(settings2.pomodorosUntilLongBreak, 10)
    }

    // MARK: - Duration Query Tests

    func testDurationForIntervalType() {
        let settings = TimerSettings()

        XCTAssertEqual(settings.duration(for: .work), 25 * 60)
        XCTAssertEqual(settings.duration(for: .shortBreak), 5 * 60)
        XCTAssertEqual(settings.duration(for: .longBreak), 15 * 60)
    }
}
