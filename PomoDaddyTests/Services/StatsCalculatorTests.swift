import SwiftData
import XCTest
@testable import PomoDaddy

@MainActor
final class StatsCalculatorTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var calculator: StatsCalculator!

    override func setUp() async throws {
        try await super.setUp()

        container = TestHelpers.createTestContainer()
        context = container.mainContext
        calculator = StatsCalculator(modelContext: context)
    }

    override func tearDown() async throws {
        calculator = nil
        context = nil
        container = nil
        try await super.tearDown()
    }

    // MARK: - Today Stats Tests

    func testTodayStatsWithNoData() throws {
        let stats = try calculator.todayStats()
        XCTAssertNil(stats)
    }

    func testTodayStatsWithData() throws {
        // Create stats for today
        let today = Calendar.current.startOfDay(for: Date())
        let dailyStats = DailyStats(date: today)
        dailyStats.recordPomodoro(durationMinutes: 25)
        context.insert(dailyStats)
        try context.save()

        let stats = try calculator.todayStats()
        XCTAssertNotNil(stats)
        XCTAssertEqual(stats?.completedPomodoros, 1)
        XCTAssertEqual(stats?.totalFocusMinutes, 25)
    }

    // MARK: - Focus Minutes Tests

    func testTodayFocusMinutesWithNoData() throws {
        let minutes = try calculator.todayFocusMinutes()
        XCTAssertEqual(minutes, 0)
    }

    func testTodayFocusMinutesWithData() throws {
        let today = Calendar.current.startOfDay(for: Date())
        let dailyStats = DailyStats(date: today)
        dailyStats.recordPomodoro(durationMinutes: 25)
        dailyStats.recordPomodoro(durationMinutes: 25)
        context.insert(dailyStats)
        try context.save()

        let minutes = try calculator.todayFocusMinutes()
        XCTAssertEqual(minutes, 50)
    }

    // MARK: - Weekly Trend Tests

    func testWeeklyTrendWithNoData() throws {
        let trend = try calculator.weeklyTrend()
        // Should return empty array if no data
        XCTAssertEqual(trend.count, 0)
    }

    func testWeeklyTrendWithData() throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Create stats for today and yesterday
        let todayStats = DailyStats(date: today)
        todayStats.recordPomodoro(durationMinutes: 25)
        context.insert(todayStats)

        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
            let yesterdayStats = DailyStats(date: yesterday)
            yesterdayStats.recordPomodoro(durationMinutes: 30)
            context.insert(yesterdayStats)
        }

        try context.save()

        let trend = try calculator.weeklyTrend()

        // Should have data for 2 days
        XCTAssertEqual(trend.count, 2)

        // Verify stats are correct
        let nonZeroDays = trend.filter { $0.totalFocusMinutes > 0 }
        XCTAssertEqual(nonZeroDays.count, 2)
    }

    // MARK: - Streak Tests

    func testCurrentStreakWithNoData() throws {
        let streak = try calculator.currentStreak()
        XCTAssertNil(streak)
    }

    func testCurrentStreakWithData() throws {
        let streak = UserStreak()
        streak.recordActivity(on: Date())
        context.insert(streak)
        try context.save()

        let retrieved = try calculator.currentStreak()
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.currentStreakDays, 1)
    }

    // MARK: - Weekly Summary Tests

    func testWeeklySummaryWithNoData() throws {
        let summary = try calculator.weeklySummary()

        XCTAssertEqual(summary.totalPomodoros, 0)
        XCTAssertEqual(summary.totalFocusMinutes, 0)
        XCTAssertEqual(summary.activeDays, 0)
        XCTAssertEqual(summary.averageMinutesPerDay, 0.0)
        XCTAssertEqual(summary.averagePomodorosPerDay, 0.0)
    }

    func testWeeklySummaryWithData() throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Create varied data
        let todayStats = DailyStats(date: today)
        todayStats.recordPomodoro(durationMinutes: 25)
        todayStats.recordPomodoro(durationMinutes: 25)
        context.insert(todayStats)

        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
            let yesterdayStats = DailyStats(date: yesterday)
            yesterdayStats.recordPomodoro(durationMinutes: 30)
            yesterdayStats.recordPomodoro(durationMinutes: 30)
            yesterdayStats.recordPomodoro(durationMinutes: 30)
            context.insert(yesterdayStats)
        }

        try context.save()

        let summary = try calculator.weeklySummary()

        XCTAssertGreaterThan(summary.totalPomodoros, 0)
        XCTAssertGreaterThan(summary.totalFocusMinutes, 0)
        XCTAssertGreaterThan(summary.activeDays, 0)
        XCTAssertGreaterThan(summary.averageMinutesPerDay, 0)
        XCTAssertGreaterThan(summary.averagePomodorosPerDay, 0)
    }

    // MARK: - Integration Tests

    func testMultipleDaysTracking() throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Create stats for multiple days
        for dayOffset in 0 ..< 5 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                continue
            }

            let stats = DailyStats(date: date)
            stats.recordPomodoro(durationMinutes: 25)
            context.insert(stats)
        }

        try context.save()

        let trend = try calculator.weeklyTrend()
        XCTAssertEqual(trend.count, 5)

        let nonZeroDays = trend.filter { $0.totalFocusMinutes > 0 }
        XCTAssertEqual(nonZeroDays.count, 5)
    }

    // MARK: - Error Handling Tests

    func testHandlesCorruptedData() throws {
        // This test verifies the calculator doesn't crash with unusual data
        let stats = DailyStats(date: Date())
        stats.recordPomodoro(durationMinutes: -100) // Negative value
        context.insert(stats)
        try context.save()

        // Should not crash
        _ = try calculator.todayStats()
        _ = try calculator.weeklyTrend()
    }

    // MARK: - Edge Case Tests

    func testTodayCompletedPomodorosReturnsZeroWithNoData() throws {
        let count = try calculator.todayCompletedPomodoros()
        XCTAssertEqual(count, 0)
    }

    func testStatsForSpecificDateReturnsNilWhenNoData() throws {
        let yesterday = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -1, to: Date()))
        let stats = try calculator.stats(for: yesterday)
        XCTAssertNil(stats)
    }

    func testStatsForSpecificDateReturnsCorrectData() throws {
        let yesterday = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -1, to: Date()))
        let yesterdayStart = Calendar.current.startOfDay(for: yesterday)
        let dailyStats = DailyStats(date: yesterdayStart)
        dailyStats.recordPomodoro(durationMinutes: 25)
        dailyStats.recordPomodoro(durationMinutes: 25)
        context.insert(dailyStats)
        try context.save()

        let stats = try calculator.stats(for: yesterday)
        XCTAssertNotNil(stats)
        XCTAssertEqual(stats?.completedPomodoros, 2)
        XCTAssertEqual(stats?.totalFocusMinutes, 50)
    }

    func testTotalCompletedSessionsReturnsZeroWithNoData() throws {
        let count = try calculator.totalCompletedSessions()
        XCTAssertEqual(count, 0)
    }

    func testTotalCompletedSessionsCountsOnlyCompleted() throws {
        let now = Date()

        // Create a completed session
        let completed = PomodoroSession(
            startDate: now.addingTimeInterval(-1500),
            endDate: now,
            durationMinutes: 25,
            wasCompleted: true
        )
        context.insert(completed)

        // Create an incomplete session
        let incomplete = PomodoroSession(
            startDate: now.addingTimeInterval(-600),
            endDate: now,
            durationMinutes: 25,
            wasCompleted: false
        )
        context.insert(incomplete)
        try context.save()

        let count = try calculator.totalCompletedSessions()
        XCTAssertEqual(count, 1)
    }

    func testTodaySessionsReturnsOnlyTodaySessions() throws {
        let now = Date()

        // Today's session
        let todaySession = PomodoroSession(
            startDate: now.addingTimeInterval(-1500),
            endDate: now,
            durationMinutes: 25,
            wasCompleted: true
        )
        context.insert(todaySession)

        // Yesterday's session
        let yesterday = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -1, to: now))
        let yesterdaySession = PomodoroSession(
            startDate: yesterday,
            endDate: yesterday.addingTimeInterval(1500),
            durationMinutes: 25,
            wasCompleted: true
        )
        context.insert(yesterdaySession)
        try context.save()

        let sessions = try calculator.todaySessions()
        XCTAssertEqual(sessions.count, 1)
    }

    func testCurrentStreakDaysReturnsZeroWithNoStreak() throws {
        let days = try calculator.currentStreakDays()
        XCTAssertEqual(days, 0)
    }

    func testLongestStreakDaysReturnsZeroWithNoStreak() throws {
        let days = try calculator.longestStreakDays()
        XCTAssertEqual(days, 0)
    }

    func testSessionsInDateRangeReturnsCorrectResults() throws {
        let now = Date()
        let twoDaysAgo = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -2, to: now))

        let session = PomodoroSession(
            startDate: now.addingTimeInterval(-1500),
            endDate: now,
            durationMinutes: 25,
            wasCompleted: true
        )
        context.insert(session)
        try context.save()

        let sessions = try calculator.sessions(from: twoDaysAgo, to: now)
        XCTAssertEqual(sessions.count, 1)
    }

    func testSessionsInDateRangeExcludesOutOfRange() throws {
        let now = Date()
        let threeDaysAgo = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -3, to: now))
        let twoDaysAgo = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -2, to: now))

        // Session from 3 days ago
        let oldSession = PomodoroSession(
            startDate: threeDaysAgo,
            endDate: threeDaysAgo.addingTimeInterval(1500),
            durationMinutes: 25,
            wasCompleted: true
        )
        context.insert(oldSession)
        try context.save()

        // Query only last 1 day
        let sessions = try calculator.sessions(from: twoDaysAgo, to: now)
        XCTAssertEqual(sessions.count, 0)
    }
}
