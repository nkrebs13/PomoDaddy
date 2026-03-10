//
//  UserStreak.swift
//  PomoDaddy
//
//  SwiftData model for tracking user activity streaks.
//

import Foundation
import SwiftData

/// Tracks the user's daily activity streak for gamification.
@Model
final class UserStreak {

    // MARK: - Properties

    /// The current consecutive days streak.
    var currentStreakDays: Int

    /// The longest streak ever achieved.
    var longestStreakDays: Int

    /// The last date the user completed at least one pomodoro.
    var lastActiveDate: Date?

    // MARK: - Computed Properties

    /// Whether the user has been active today.
    var isActiveToday: Bool {
        guard let lastActive = lastActiveDate else { return false }
        return Calendar.current.isDateInToday(lastActive)
    }

    /// Whether the streak is still valid (active today or yesterday).
    var isStreakActive: Bool {
        guard let lastActive = lastActiveDate else { return false }
        let calendar = Calendar.current

        if calendar.isDateInToday(lastActive) {
            return true
        }

        if calendar.isDateInYesterday(lastActive) {
            return true
        }

        return false
    }

    /// Days since last activity (0 if active today).
    var daysSinceLastActivity: Int {
        guard let lastActive = lastActiveDate else { return -1 }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastDay = calendar.startOfDay(for: lastActive)

        let components = calendar.dateComponents([.day], from: lastDay, to: today)
        return components.day ?? 0
    }

    // MARK: - Initialization

    /// Creates a new streak tracker.
    /// - Parameters:
    ///   - currentStreakDays: Current streak count (defaults to 0).
    ///   - longestStreakDays: Longest streak achieved (defaults to 0).
    ///   - lastActiveDate: Last activity date (defaults to nil).
    init(
        currentStreakDays: Int = 0,
        longestStreakDays: Int = 0,
        lastActiveDate: Date? = nil
    ) {
        self.currentStreakDays = currentStreakDays
        self.longestStreakDays = longestStreakDays
        self.lastActiveDate = lastActiveDate
    }

    // MARK: - Methods

    /// Records activity on a given date and updates the streak accordingly.
    /// - Parameter date: The date of the activity (defaults to now).
    func recordActivity(on date: Date = Date()) {
        let calendar = Calendar.current
        let activityDay = calendar.startOfDay(for: date)

        // If no previous activity, start the streak
        guard let lastActive = lastActiveDate else {
            currentStreakDays = 1
            longestStreakDays = max(longestStreakDays, 1)
            lastActiveDate = activityDay
            return
        }

        let lastActiveDay = calendar.startOfDay(for: lastActive)

        // Already recorded activity for this day
        if calendar.isDate(activityDay, inSameDayAs: lastActiveDay) {
            return
        }

        // Check if this is the next consecutive day
        let daysDifference = calendar.dateComponents([.day], from: lastActiveDay, to: activityDay).day ?? 0

        if daysDifference == 1 {
            // Consecutive day - extend the streak
            currentStreakDays += 1
            longestStreakDays = max(longestStreakDays, currentStreakDays)
        } else if daysDifference > 1 {
            // Streak broken - reset to 1
            currentStreakDays = 1
        }
        // If daysDifference < 0, we're recording activity for a past date, ignore

        if daysDifference >= 0 {
            lastActiveDate = activityDay
        }
    }

    /// Checks and updates the streak status based on current date.
    /// Call this on app launch to handle streak expiration.
    func validateStreak() {
        guard let lastActive = lastActiveDate else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastActiveDay = calendar.startOfDay(for: lastActive)

        let daysDifference = calendar.dateComponents([.day], from: lastActiveDay, to: today).day ?? 0

        // If more than 1 day has passed, the streak is broken
        if daysDifference > 1 {
            currentStreakDays = 0
        }
    }

    /// Resets all streak data.
    func reset() {
        currentStreakDays = 0
        longestStreakDays = 0
        lastActiveDate = nil
    }
}

// MARK: - Factory Methods

extension UserStreak {

    /// Gets the singleton UserStreak, creating one if it doesn't exist.
    /// - Parameter context: The model context.
    /// - Returns: The user's streak record.
    @MainActor
    static func current(in context: ModelContext) throws -> UserStreak {
        let descriptor = FetchDescriptor<UserStreak>()
        let existing = try context.fetch(descriptor)

        if let streak = existing.first {
            // Validate streak on access
            streak.validateStreak()
            return streak
        }

        let newStreak = UserStreak()
        context.insert(newStreak)
        return newStreak
    }
}
