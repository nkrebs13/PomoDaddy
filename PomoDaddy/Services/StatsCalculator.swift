//
//  StatsCalculator.swift
//  PomoDaddy
//
//  Statistics queries and calculations for pomodoro data.
//

import Foundation
import SwiftData

/// Provides statistics queries and calculations for pomodoro data.
///
/// `StatsCalculator` offers a clean interface for querying aggregated
/// statistics from the SwiftData store. It handles common queries like
/// daily stats, weekly trends, and streak information.
///
/// Usage:
/// ```swift
/// let calculator = StatsCalculator(modelContext: context)
/// let todayMinutes = try calculator.todayFocusMinutes()
/// let weekly = try calculator.weeklySummary()
/// ```
struct StatsCalculator: StatsCalculating {
    // MARK: - Properties

    /// The model context used for queries.
    let modelContext: ModelContext

    // MARK: - Initialization

    /// Creates a new stats calculator.
    ///
    /// - Parameter modelContext: The SwiftData model context to query.
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Daily Stats

    /// Returns the daily statistics for today, if any exist.
    ///
    /// - Returns: The `DailyStats` for today, or `nil` if no sessions were recorded.
    /// - Throws: Any SwiftData fetch errors.
    func todayStats() throws -> DailyStats? {
        let today = Calendar.current.startOfDay(for: Date())

        var descriptor = FetchDescriptor<DailyStats>(
            predicate: DailyStats.forDate(today)
        )
        descriptor.fetchLimit = 1

        return try modelContext.fetch(descriptor).first
    }

    /// Returns the total focus minutes for today.
    ///
    /// - Returns: The total minutes of focused work today, or 0 if none.
    /// - Throws: Any SwiftData fetch errors.
    func todayFocusMinutes() throws -> Int {
        try todayStats()?.totalFocusMinutes ?? 0
    }

    /// Returns the number of completed pomodoros for today.
    ///
    /// - Returns: The count of completed sessions today, or 0 if none.
    /// - Throws: Any SwiftData fetch errors.
    func todayCompletedPomodoros() throws -> Int {
        try todayStats()?.completedPomodoros ?? 0
    }

    /// Returns the daily statistics for a specific date.
    ///
    /// - Parameter date: The date to query.
    /// - Returns: The `DailyStats` for that date, or `nil` if no sessions were recorded.
    /// - Throws: Any SwiftData fetch errors.
    func stats(for date: Date) throws -> DailyStats? {
        let targetDay = Calendar.current.startOfDay(for: date)

        var descriptor = FetchDescriptor<DailyStats>(
            predicate: DailyStats.forDate(targetDay)
        )
        descriptor.fetchLimit = 1

        return try modelContext.fetch(descriptor).first
    }

    // MARK: - Weekly Stats

    /// Returns daily statistics for the past 7 days.
    ///
    /// The returned array is sorted chronologically (oldest first)
    /// and includes only days that have recorded activity.
    ///
    /// - Returns: An array of `DailyStats` for the past week.
    /// - Throws: Any SwiftData fetch errors.
    func weeklyTrend() throws -> [DailyStats] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let weekAgo = calendar.date(byAdding: .day, value: -6, to: today) else {
            return []
        }

        let descriptor = FetchDescriptor<DailyStats>(
            predicate: DailyStats.inRange(from: weekAgo, to: today),
            sortBy: [DailyStats.chronologicalSort]
        )

        return try modelContext.fetch(descriptor)
    }

    /// A summary of statistics for the past week.
    struct WeeklySummary {
        /// Total minutes of focused work in the past 7 days.
        let totalFocusMinutes: Int

        /// Total completed pomodoro sessions in the past 7 days.
        let totalPomodoros: Int

        /// Number of days with at least one completed session.
        let activeDays: Int

        /// Daily breakdown of statistics (sorted chronologically).
        let dailyBreakdown: [DailyStats]

        /// Average focus minutes per active day.
        var averageMinutesPerDay: Double {
            guard activeDays > 0 else { return 0 }
            return Double(totalFocusMinutes) / Double(activeDays)
        }

        /// Average pomodoros per active day.
        var averagePomodorosPerDay: Double {
            guard activeDays > 0 else { return 0 }
            return Double(totalPomodoros) / Double(activeDays)
        }

        /// Total focus time formatted as hours and minutes.
        var formattedTotalTime: String {
            TimeFormatting.formatFocusTime(minutes: totalFocusMinutes)
        }
    }

    /// Returns a comprehensive summary of the past week's statistics.
    ///
    /// - Returns: A `WeeklySummary` containing aggregated statistics.
    /// - Throws: Any SwiftData fetch errors.
    func weeklySummary() throws -> WeeklySummary {
        let dailyStats = try weeklyTrend()

        let totalMinutes = dailyStats.reduce(0) { $0 + $1.totalFocusMinutes }
        let totalPomodoros = dailyStats.reduce(0) { $0 + $1.completedPomodoros }
        let activeDays = dailyStats.filter { $0.completedPomodoros > 0 }.count

        return WeeklySummary(
            totalFocusMinutes: totalMinutes,
            totalPomodoros: totalPomodoros,
            activeDays: activeDays,
            dailyBreakdown: dailyStats
        )
    }

    // MARK: - Streak

    /// Returns the current user streak, if one exists.
    ///
    /// This also validates the streak to ensure it reflects the current state
    /// (e.g., if the user hasn't been active, the streak may be reset).
    ///
    /// - Returns: The current `UserStreak`, or `nil` if none exists.
    /// - Throws: Any SwiftData fetch errors.
    func currentStreak() throws -> UserStreak? {
        var descriptor = FetchDescriptor<UserStreak>()
        descriptor.fetchLimit = 1

        guard let streak = try modelContext.fetch(descriptor).first else {
            return nil
        }

        // Validate the streak before returning
        streak.validateStreak()
        return streak
    }

    /// Returns the current streak count in days.
    ///
    /// - Returns: The number of consecutive days with activity, or 0 if none.
    /// - Throws: Any SwiftData fetch errors.
    func currentStreakDays() throws -> Int {
        try currentStreak()?.currentStreakDays ?? 0
    }

    /// Returns the longest streak ever achieved.
    ///
    /// - Returns: The longest streak in days, or 0 if no history.
    /// - Throws: Any SwiftData fetch errors.
    func longestStreakDays() throws -> Int {
        try currentStreak()?.longestStreakDays ?? 0
    }

    // MARK: - Sessions

    /// Returns all sessions for today.
    ///
    /// - Returns: An array of today's sessions, sorted by start time.
    /// - Throws: Any SwiftData fetch errors.
    func todaySessions() throws -> [PomodoroSession] {
        let today = Date()

        let descriptor = FetchDescriptor<PomodoroSession>(
            predicate: PomodoroSession.onDay(today),
            sortBy: [SortDescriptor(\.startDate, order: .forward)]
        )

        return try modelContext.fetch(descriptor)
    }

    /// Returns sessions within a date range.
    ///
    /// - Parameters:
    ///   - startDate: The start of the range (inclusive).
    ///   - endDate: The end of the range (inclusive).
    /// - Returns: An array of sessions within the range, sorted by start time.
    /// - Throws: Any SwiftData fetch errors.
    func sessions(from startDate: Date, to endDate: Date) throws -> [PomodoroSession] {
        let descriptor = FetchDescriptor<PomodoroSession>(
            predicate: PomodoroSession.inRange(from: startDate, to: endDate),
            sortBy: [SortDescriptor(\.startDate, order: .forward)]
        )

        return try modelContext.fetch(descriptor)
    }

    /// Returns the total count of completed sessions.
    ///
    /// - Returns: The total number of completed pomodoro sessions.
    /// - Throws: Any SwiftData fetch errors.
    func totalCompletedSessions() throws -> Int {
        let descriptor = FetchDescriptor<PomodoroSession>(
            predicate: PomodoroSession.completed
        )

        return try modelContext.fetchCount(descriptor)
    }
}

// MARK: - Monthly Stats

extension StatsCalculator {
    /// A summary of statistics for a calendar month.
    struct MonthlySummary {
        /// The month this summary represents.
        let month: Date

        /// Total minutes of focused work in the month.
        let totalFocusMinutes: Int

        /// Total completed pomodoro sessions in the month.
        let totalPomodoros: Int

        /// Number of days with at least one completed session.
        let activeDays: Int

        /// Daily breakdown of statistics.
        let dailyBreakdown: [DailyStats]
    }

    /// Returns statistics for the current calendar month.
    ///
    /// - Returns: A `MonthlySummary` for the current month.
    /// - Throws: Any SwiftData fetch errors.
    func currentMonthSummary() throws -> MonthlySummary {
        let calendar = Calendar.current
        let now = Date()

        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else
        {
            return MonthlySummary(
                month: now,
                totalFocusMinutes: 0,
                totalPomodoros: 0,
                activeDays: 0,
                dailyBreakdown: []
            )
        }

        let descriptor = FetchDescriptor<DailyStats>(
            predicate: DailyStats.inRange(from: monthStart, to: monthEnd),
            sortBy: [DailyStats.chronologicalSort]
        )

        let dailyStats = try modelContext.fetch(descriptor)

        let totalMinutes = dailyStats.reduce(0) { $0 + $1.totalFocusMinutes }
        let totalPomodoros = dailyStats.reduce(0) { $0 + $1.completedPomodoros }
        let activeDays = dailyStats.filter { $0.completedPomodoros > 0 }.count

        return MonthlySummary(
            month: monthStart,
            totalFocusMinutes: totalMinutes,
            totalPomodoros: totalPomodoros,
            activeDays: activeDays,
            dailyBreakdown: dailyStats
        )
    }
}
