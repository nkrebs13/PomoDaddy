import XCTest
@testable import PomoDaddy

final class DailyStatsTests: XCTestCase {
    // MARK: - Initialization Tests

    func testInitialization() {
        let date = Date()
        let stats = DailyStats(date: date)

        XCTAssertEqual(stats.completedPomodoros, 0)
        XCTAssertEqual(stats.totalFocusMinutes, 0)
        // DailyStats.init normalizes date to start of day
        XCTAssertEqual(stats.date, Calendar.current.startOfDay(for: date))
    }

    // MARK: - Record Pomodoro Tests

    func testRecordPomodoro() {
        let stats = DailyStats(date: Date())

        stats.recordPomodoro(durationMinutes: 25)

        XCTAssertEqual(stats.completedPomodoros, 1)
        XCTAssertEqual(stats.totalFocusMinutes, 25)
    }

    func testRecordMultiplePomodoros() {
        let stats = DailyStats(date: Date())

        stats.recordPomodoro(durationMinutes: 25)
        stats.recordPomodoro(durationMinutes: 25)
        stats.recordPomodoro(durationMinutes: 30)

        XCTAssertEqual(stats.completedPomodoros, 3)
        XCTAssertEqual(stats.totalFocusMinutes, 80)
    }

    // MARK: - Predicate Tests

    func testForDatePredicate() {
        let today = Calendar.current.startOfDay(for: Date())

        // Create predicate (can't fully test without SwiftData context)
        let predicate = DailyStats.forDate(today)

        // Verify it compiles and doesn't crash
        XCTAssertNotNil(predicate)
    }

    // MARK: - Calendar Day Tests

    func testCalendarDay() {
        let now = Date()
        let stats = DailyStats(date: now)

        let expectedDay = Calendar.current.startOfDay(for: now)
        XCTAssertEqual(stats.date, expectedDay)
    }

    // MARK: - Edge Cases

    func testRecordZeroDuration() {
        let stats = DailyStats(date: Date())

        stats.recordPomodoro(durationMinutes: 0)

        XCTAssertEqual(stats.completedPomodoros, 1)
        XCTAssertEqual(stats.totalFocusMinutes, 0)
    }

    func testRecordNegativeDuration() {
        let stats = DailyStats(date: Date())

        stats.recordPomodoro(durationMinutes: -25)

        // Should still record (validation happens elsewhere)
        XCTAssertEqual(stats.completedPomodoros, 1)
        XCTAssertEqual(stats.totalFocusMinutes, -25)
    }

    // MARK: - Data Accumulation Tests

    func testLargeDataAccumulation() {
        let stats = DailyStats(date: Date())

        // Simulate a very productive day
        for _ in 0 ..< 20 {
            stats.recordPomodoro(durationMinutes: 25)
        }

        XCTAssertEqual(stats.completedPomodoros, 20)
        XCTAssertEqual(stats.totalFocusMinutes, 500)
    }
}
