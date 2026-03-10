import XCTest
@testable import PomoDaddy

final class UserStreakTests: XCTestCase {
    // MARK: - Initialization Tests

    func testInitialization() {
        let streak = UserStreak()

        XCTAssertEqual(streak.currentStreakDays, 0)
        XCTAssertEqual(streak.longestStreakDays, 0)
        XCTAssertNil(streak.lastActiveDate)
    }

    // MARK: - Record Activity Tests

    func testRecordFirstActivity() {
        let streak = UserStreak()
        let today = Date()

        streak.recordActivity(on: today)

        XCTAssertEqual(streak.currentStreakDays, 1)
        XCTAssertEqual(streak.longestStreakDays, 1)
        XCTAssertNotNil(streak.lastActiveDate)
    }

    func testRecordConsecutiveDays() throws {
        let streak = UserStreak()
        let calendar = Calendar.current

        let today = calendar.startOfDay(for: Date())
        let yesterday = try XCTUnwrap(calendar.date(byAdding: .day, value: -1, to: today))

        // Record yesterday
        streak.recordActivity(on: yesterday)
        XCTAssertEqual(streak.currentStreakDays, 1)

        // Record today (consecutive)
        streak.recordActivity(on: today)
        XCTAssertEqual(streak.currentStreakDays, 2)
        XCTAssertEqual(streak.longestStreakDays, 2)
    }

    func testRecordSameDay() {
        let streak = UserStreak()
        let today = Date()

        streak.recordActivity(on: today)
        XCTAssertEqual(streak.currentStreakDays, 1)

        // Record same day again
        streak.recordActivity(on: today)

        // Streak should not increase
        XCTAssertEqual(streak.currentStreakDays, 1)
        XCTAssertEqual(streak.longestStreakDays, 1)
    }

    func testRecordAfterBreak() throws {
        let streak = UserStreak()
        let calendar = Calendar.current

        let today = calendar.startOfDay(for: Date())
        let threeDaysAgo = try XCTUnwrap(calendar.date(byAdding: .day, value: -3, to: today))

        // Record activity 3 days ago
        streak.recordActivity(on: threeDaysAgo)
        XCTAssertEqual(streak.currentStreakDays, 1)
        XCTAssertEqual(streak.longestStreakDays, 1)

        // Record today (broke streak)
        streak.recordActivity(on: today)

        // Current streak should reset
        XCTAssertEqual(streak.currentStreakDays, 1)
        // Longest should remain
        XCTAssertEqual(streak.longestStreakDays, 1)
    }

    func testLongestStreakTracking() throws {
        let streak = UserStreak()
        let calendar = Calendar.current

        // Build up a streak by recording backwards in time
        let today = calendar.startOfDay(for: Date())

        // Record 5 consecutive days
        for dayOffset in 0 ..< 5 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                continue
            }
            streak.recordActivity(on: date)
        }

        XCTAssertEqual(streak.currentStreakDays, 5)
        XCTAssertEqual(streak.longestStreakDays, 5)

        // Break the streak by recording a date 7 days ago
        if let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) {
            streak.recordActivity(on: weekAgo)
        }

        // Build shorter streak of 3 days
        for dayOffset in 0 ..< 3 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else {
                continue
            }
            streak.recordActivity(on: date)
        }

        XCTAssertEqual(streak.currentStreakDays, 3)
        // Longest should still be 5
        XCTAssertEqual(streak.longestStreakDays, 5)
    }

    // MARK: - Edge Cases

    func testFutureDate() throws {
        let streak = UserStreak()
        let tomorrow = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 1, to: Date()))

        streak.recordActivity(on: tomorrow)

        // Should still work (app handles future dates)
        XCTAssertGreaterThan(streak.currentStreakDays, 0)
    }

    func testDistantPastDate() {
        let streak = UserStreak()
        let longAgo = Date(timeIntervalSince1970: 0) // 1970

        streak.recordActivity(on: longAgo)

        XCTAssertEqual(streak.currentStreakDays, 1)
        XCTAssertEqual(streak.longestStreakDays, 1)
    }

    // MARK: - Validation Tests

    func testValidateStreakBroken() throws {
        let streak = UserStreak()
        let calendar = Calendar.current

        // Set last active date to 3 days ago
        let threeDaysAgo = try XCTUnwrap(calendar.date(byAdding: .day, value: -3, to: Date()))
        streak.recordActivity(on: threeDaysAgo)
        streak.recordActivity(on: threeDaysAgo) // Ensure it's set
        XCTAssertEqual(streak.currentStreakDays, 1)

        // Manually set streak higher to test validation
        streak.currentStreakDays = 5

        // Call validate - should reset streak
        streak.validateStreak()

        XCTAssertEqual(streak.currentStreakDays, 0)
    }

    func testValidateStreakActive() {
        let streak = UserStreak()

        // Record today
        streak.recordActivity(on: Date())
        let currentBefore = streak.currentStreakDays

        // Validate - should not reset
        streak.validateStreak()

        XCTAssertEqual(streak.currentStreakDays, currentBefore)
    }

    // MARK: - Reset Tests

    func testReset() {
        let streak = UserStreak()

        // Build a streak
        streak.recordActivity(on: Date())
        streak.recordActivity(on: Date())

        XCTAssertGreaterThan(streak.currentStreakDays, 0)

        // Reset
        streak.reset()

        XCTAssertEqual(streak.currentStreakDays, 0)
        XCTAssertEqual(streak.longestStreakDays, 0)
        XCTAssertNil(streak.lastActiveDate)
    }

    // MARK: - Computed Properties Tests

    func testIsActiveToday() {
        let streak = UserStreak()

        XCTAssertFalse(streak.isActiveToday)

        streak.recordActivity(on: Date())

        XCTAssertTrue(streak.isActiveToday)
    }

    func testIsStreakActive() throws {
        let calendar = Calendar.current
        let streak = UserStreak()

        // No activity - not active
        XCTAssertFalse(streak.isStreakActive)

        // Active today - is active
        streak.recordActivity(on: Date())
        XCTAssertTrue(streak.isStreakActive)

        // Active yesterday - still active
        let yesterday = try XCTUnwrap(calendar.date(byAdding: .day, value: -1, to: Date()))
        let yesterdayStreak = UserStreak()
        yesterdayStreak.recordActivity(on: yesterday)
        XCTAssertTrue(yesterdayStreak.isStreakActive)
    }

    func testDaysSinceLastActivity() throws {
        let calendar = Calendar.current
        let streak = UserStreak()

        // No activity
        XCTAssertEqual(streak.daysSinceLastActivity, -1)

        // Active today
        streak.recordActivity(on: Date())
        XCTAssertEqual(streak.daysSinceLastActivity, 0)

        // Active 3 days ago
        let threeDaysAgo = try XCTUnwrap(calendar.date(byAdding: .day, value: -3, to: Date()))
        let oldStreak = UserStreak()
        oldStreak.recordActivity(on: threeDaysAgo)
        XCTAssertEqual(oldStreak.daysSinceLastActivity, 3)
    }

    // MARK: - Realistic Usage Tests

    func testWeekLongStreak() {
        let streak = UserStreak()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Record 7 consecutive days
        for dayOffset in 0 ..< 7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                continue
            }
            streak.recordActivity(on: date)
        }

        XCTAssertEqual(streak.currentStreakDays, 7)
        XCTAssertEqual(streak.longestStreakDays, 7)
    }

    func testMultipleActivitiesPerDay() {
        let streak = UserStreak()
        let today = Date()

        // Record multiple activities on the same day
        streak.recordActivity(on: today)
        streak.recordActivity(on: today)
        streak.recordActivity(on: today)

        // Should only count as one day
        XCTAssertEqual(streak.currentStreakDays, 1)
    }
}
