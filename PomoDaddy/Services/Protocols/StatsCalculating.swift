//
//  StatsCalculating.swift
//  PomoDaddy
//
//  Protocol for statistics calculation dependency injection.
//

import Foundation

/// Protocol defining the statistics calculation interface for dependency injection and testing.
protocol StatsCalculating {
    /// Returns the daily statistics for today, if any exist.
    func todayStats() throws -> DailyStats?

    /// Returns the total focus minutes for today.
    func todayFocusMinutes() throws -> Int

    /// Returns daily statistics for the past 7 days.
    func weeklyTrend() throws -> [DailyStats]

    /// Returns a comprehensive summary of the past week's statistics.
    func weeklySummary() throws -> StatsCalculator.WeeklySummary

    /// Returns the current user streak, if one exists.
    func currentStreak() throws -> UserStreak?
}
