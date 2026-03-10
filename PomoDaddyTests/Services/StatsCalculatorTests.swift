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

        // Create in-memory container for testing
        let schema = Schema([DailyStats.self, UserStreak.self, PomodoroSession.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
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
}
