//
//  PomodoroSession.swift
//  PomoDaddy
//
//  SwiftData model for tracking completed pomodoro sessions.
//

import Foundation
import SwiftData

/// Represents a single pomodoro focus session.
@Model
internal final class PomodoroSession {
    // MARK: - Properties

    /// Unique identifier for this session.
    @Attribute(.unique) var id: UUID

    /// When the session started.
    var startDate: Date

    /// When the session ended (either completed or interrupted).
    var endDate: Date

    /// The configured duration for this session in minutes.
    var durationMinutes: Int

    /// Whether the session was completed fully or interrupted early.
    var wasCompleted: Bool

    // MARK: - Computed Properties

    /// The calendar day (start of day) for this session, useful for grouping.
    var calendarDay: Date {
        Calendar.current.startOfDay(for: startDate)
    }

    /// The actual duration of the session in minutes.
    var actualDurationMinutes: Int {
        let interval: TimeInterval = endDate.timeIntervalSince(startDate)
        return Int(interval / 60)
    }

    // MARK: - Initialization

    /// Creates a new pomodoro session.
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID).
    ///   - startDate: When the session started.
    ///   - endDate: When the session ended.
    ///   - durationMinutes: The configured session duration.
    ///   - wasCompleted: Whether the session completed fully.
    init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date,
        durationMinutes: Int,
        wasCompleted: Bool
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.durationMinutes = durationMinutes
        self.wasCompleted = wasCompleted
    }

    /// Convenience initializer for creating a completed session that just finished.
    /// - Parameters:
    ///   - startDate: When the session started.
    ///   - durationMinutes: The session duration in minutes.
    convenience init(completedAt endDate: Date = Date(), startDate: Date, durationMinutes: Int) {
        self.init(
            startDate: startDate,
            endDate: endDate,
            durationMinutes: durationMinutes,
            wasCompleted: true
        )
    }
}

// MARK: - Predicates

extension PomodoroSession {
    /// Predicate for sessions on a specific calendar day.
    static func onDay(_ date: Date) -> Predicate<PomodoroSession> {
        let calendar: Calendar = Calendar.current
        let startOfDay: Date = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            // Calendar arithmetic should never fail, but handle defensively
            return #Predicate<PomodoroSession> { _ in false }
        }

        return #Predicate<PomodoroSession> { session in
            session.startDate >= startOfDay && session.startDate < endOfDay
        }
    }

    /// Predicate for completed sessions only.
    static var completed: Predicate<PomodoroSession> {
        #Predicate<PomodoroSession> { session in
            session.wasCompleted == true
        }
    }

    /// Predicate for sessions within a date range.
    static func inRange(from startDate: Date, to endDate: Date) -> Predicate<PomodoroSession> {
        #Predicate<PomodoroSession> { session in
            session.startDate >= startDate && session.startDate <= endDate
        }
    }
}
