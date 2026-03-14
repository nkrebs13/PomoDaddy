//
//  SessionRecorder.swift
//  PomoDaddy
//
//  Thread-safe session recording using Swift actors.
//

import Foundation
import SwiftData

/// A thread-safe actor for recording pomodoro sessions and updating statistics.
///
/// `SessionRecorder` uses Swift's `@ModelActor` macro to safely manage
/// SwiftData operations in a concurrent context. All database operations
/// are serialized through the actor, ensuring data consistency.
///
/// Usage:
/// ```swift
/// let recorder = SessionRecorder(modelContainer: container)
/// await recorder.record(session)
/// ```
@ModelActor
actor SessionRecorder: SessionRecording {
    // MARK: - Public Methods

    /// Records a completed pomodoro session and updates all related statistics.
    ///
    /// This method performs the following operations atomically:
    /// 1. Inserts the session into the database
    /// 2. Updates the daily statistics for the session's day
    /// 3. Updates the user's activity streak
    /// 4. Saves all changes to the persistent store
    ///
    /// - Parameter session: The pomodoro session to record.
    /// - Throws: Any SwiftData errors that occur during the save operation.
    func record(_ session: PomodoroSession) throws {
        // Insert the session
        modelContext.insert(session)

        // Update related statistics
        try updateDailyStats(for: session)
        try updateStreak(for: session.startDate)

        // Persist changes
        try modelContext.save()
    }

    /// Records a completed pomodoro session with the given parameters.
    ///
    /// Convenience method that creates a `PomodoroSession` from individual values.
    ///
    /// - Parameters:
    ///   - startDate: When the session started.
    ///   - endDate: When the session ended.
    ///   - durationMinutes: The configured session duration in minutes.
    ///   - wasCompleted: Whether the session was completed fully.
    /// - Throws: Any SwiftData errors that occur during the save operation.
    func record(
        startDate: Date,
        endDate: Date,
        durationMinutes: Int,
        wasCompleted: Bool
    ) throws {
        let session = PomodoroSession(
            startDate: startDate,
            endDate: endDate,
            durationMinutes: durationMinutes,
            wasCompleted: wasCompleted
        )
        try record(session)
    }

    // MARK: - Private Methods

    /// Updates the daily statistics for the session's calendar day.
    ///
    /// - Parameter session: The session to record in daily stats.
    /// - Throws: Any SwiftData errors during fetch or insert.
    private func updateDailyStats(for session: PomodoroSession) throws {
        // Only count completed sessions in stats
        guard session.wasCompleted else { return }

        let calendarDay: Date = session.calendarDay

        // Try to find existing stats for this day
        var descriptor = FetchDescriptor<DailyStats>(
            predicate: DailyStats.forDate(calendarDay)
        )
        descriptor.fetchLimit = 1

        let existingStats: [DailyStats] = try modelContext.fetch(descriptor)

        let stats: DailyStats
        if let existing = existingStats.first {
            stats = existing
        } else {
            // Create new stats for this day
            stats = DailyStats(date: calendarDay)
            modelContext.insert(stats)
        }

        // Record the pomodoro
        stats.recordPomodoro(durationMinutes: session.durationMinutes)
    }

    /// Updates the user's activity streak based on the session date.
    ///
    /// - Parameter date: The date of the activity to record.
    /// - Throws: Any SwiftData errors during fetch or insert.
    private func updateStreak(for date: Date) throws {
        // Get or create the user streak
        let descriptor = FetchDescriptor<UserStreak>()
        let existingStreaks: [UserStreak] = try modelContext.fetch(descriptor)

        let streak: UserStreak
        if let existing = existingStreaks.first {
            streak = existing
        } else {
            // Create new streak tracker
            streak = UserStreak()
            modelContext.insert(streak)
        }

        // Record the activity
        streak.recordActivity(on: date)
    }
}

// MARK: - Batch Operations

extension SessionRecorder {
    /// Records multiple sessions in a single transaction.
    ///
    /// This is more efficient than recording sessions individually
    /// when importing or syncing multiple sessions.
    ///
    /// - Parameter sessions: The sessions to record.
    /// - Throws: Any SwiftData errors that occur during the save operation.
    func recordBatch(_ entries: [SessionEntry]) throws {
        // Cache DailyStats per calendar day to avoid re-fetching unsaved objects
        var dailyStatsCache: [Date: DailyStats] = [:]

        for entry in entries {
            let session = PomodoroSession(
                startDate: entry.startDate,
                endDate: entry.endDate,
                durationMinutes: entry.durationMinutes,
                wasCompleted: entry.wasCompleted
            )
            modelContext.insert(session)

            guard session.wasCompleted else { continue }

            let calendarDay: Date = session.calendarDay
            let stats: DailyStats
            if let cached = dailyStatsCache[calendarDay] {
                stats = cached
            } else {
                var descriptor = FetchDescriptor<DailyStats>(
                    predicate: DailyStats.forDate(calendarDay)
                )
                descriptor.fetchLimit = 1

                if let existing = try modelContext.fetch(descriptor).first {
                    stats = existing
                } else {
                    stats = DailyStats(date: calendarDay)
                    modelContext.insert(stats)
                }
                dailyStatsCache[calendarDay] = stats
            }
            stats.recordPomodoro(durationMinutes: session.durationMinutes)
        }

        // Update streak once based on the most recent entry
        if let mostRecent = entries.max(by: { $0.startDate < $1.startDate }) {
            try updateStreak(for: mostRecent.startDate)
        }

        try modelContext.save()
    }

    /// Deletes a session by its persistent identifier and adjusts related statistics.
    ///
    /// Uses `PersistentIdentifier` instead of a session object to safely work across
    /// different ModelContexts (the actor has its own context separate from the caller's).
    ///
    /// - Parameter sessionID: The persistent identifier of the session to delete.
    /// - Throws: Any SwiftData errors that occur during the operation.
    func delete(_ sessionID: PersistentIdentifier) throws {
        guard let session = modelContext.model(for: sessionID) as? PomodoroSession else {
            return
        }

        // Adjust daily stats if the session was completed
        if session.wasCompleted {
            let calendarDay: Date = session.calendarDay

            var descriptor = FetchDescriptor<DailyStats>(
                predicate: DailyStats.forDate(calendarDay)
            )
            descriptor.fetchLimit = 1

            if let stats = try modelContext.fetch(descriptor).first {
                stats.totalFocusMinutes = max(0, stats.totalFocusMinutes - session.durationMinutes)
                stats.completedPomodoros = max(0, stats.completedPomodoros - 1)
            }
        }

        modelContext.delete(session)
        try modelContext.save()
    }
}
