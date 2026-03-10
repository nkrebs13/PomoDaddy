//
//  DailyStats.swift
//  PomoDaddy
//
//  SwiftData model for daily aggregated statistics.
//

import Foundation
import SwiftData

/// Aggregated statistics for a single calendar day.
@Model
final class DailyStats {
    // MARK: - Properties

    /// The calendar day these stats represent (start of day, midnight).
    @Attribute(.unique) var date: Date

    /// Total minutes of focused work completed on this day.
    var totalFocusMinutes: Int

    /// Number of fully completed pomodoro sessions.
    var completedPomodoros: Int

    // MARK: - Computed Properties

    /// Total focus time formatted as hours and minutes.
    var formattedFocusTime: String {
        let hours = totalFocusMinutes / 60
        let minutes = totalFocusMinutes % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    /// Average duration per pomodoro in minutes.
    var averagePomodoroMinutes: Double {
        guard completedPomodoros > 0 else { return 0 }
        return Double(totalFocusMinutes) / Double(completedPomodoros)
    }

    // MARK: - Initialization

    /// Creates new daily stats.
    /// - Parameters:
    ///   - date: The calendar day (should be start of day).
    ///   - totalFocusMinutes: Total focus minutes (defaults to 0).
    ///   - completedPomodoros: Number of completed sessions (defaults to 0).
    init(
        date: Date,
        totalFocusMinutes: Int = 0,
        completedPomodoros: Int = 0
    ) {
        // Ensure we store the start of day
        self.date = Calendar.current.startOfDay(for: date)
        self.totalFocusMinutes = totalFocusMinutes
        self.completedPomodoros = completedPomodoros
    }

    // MARK: - Methods

    /// Records a completed pomodoro session.
    /// - Parameter minutes: The duration of the completed session.
    func recordPomodoro(durationMinutes minutes: Int) {
        totalFocusMinutes += minutes
        completedPomodoros += 1
    }

    /// Resets the daily stats (useful for testing or data correction).
    func reset() {
        totalFocusMinutes = 0
        completedPomodoros = 0
    }
}

// MARK: - Predicates & Queries

extension DailyStats {
    /// Predicate to find stats for a specific date.
    static func forDate(_ date: Date) -> Predicate<DailyStats> {
        let startOfDay = Calendar.current.startOfDay(for: date)
        return #Predicate<DailyStats> { stats in
            stats.date == startOfDay
        }
    }

    /// Predicate for stats within a date range.
    static func inRange(from startDate: Date, to endDate: Date) -> Predicate<DailyStats> {
        let start = Calendar.current.startOfDay(for: startDate)
        let end = Calendar.current.startOfDay(for: endDate)

        return #Predicate<DailyStats> { stats in
            stats.date >= start && stats.date <= end
        }
    }

    /// Sort descriptor for chronological ordering.
    static var chronologicalSort: SortDescriptor<DailyStats> {
        SortDescriptor(\.date, order: .forward)
    }

    /// Sort descriptor for reverse chronological ordering.
    static var reverseChronologicalSort: SortDescriptor<DailyStats> {
        SortDescriptor(\.date, order: .reverse)
    }
}

// MARK: - Factory Methods

extension DailyStats {
    /// Creates or finds existing stats for today.
    /// - Parameter context: The model context to search/insert in.
    /// - Returns: The DailyStats for today.
    @MainActor
    static func forToday(in context: ModelContext) throws -> DailyStats {
        let today = Calendar.current.startOfDay(for: Date())

        var descriptor = FetchDescriptor<DailyStats>(
            predicate: forDate(today)
        )
        descriptor.fetchLimit = 1

        let existing = try context.fetch(descriptor)

        if let stats = existing.first {
            return stats
        }

        let newStats = DailyStats(date: today)
        context.insert(newStats)
        return newStats
    }
}
