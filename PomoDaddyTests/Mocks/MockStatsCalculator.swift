//
//  MockStatsCalculator.swift
//  PomoDaddyTests
//
//  Mock stats calculator for testing.
//

import Foundation
@testable import PomoDaddy

/// Mock stats calculator that returns configurable stub data.
struct MockStatsCalculator: StatsCalculating {
    // MARK: - Configurable Returns

    var stubbedTodayStats: DailyStats?
    var stubbedTodayFocusMinutes: Int = 0
    var stubbedWeeklyTrend: [DailyStats] = []
    var stubbedWeeklySummary = StatsCalculator.WeeklySummary(
        totalFocusMinutes: 0,
        totalPomodoros: 0,
        activeDays: 0,
        dailyBreakdown: []
    )
    var stubbedCurrentStreak: UserStreak?

    var shouldThrow = false

    // MARK: - Protocol Methods

    func todayStats() throws -> DailyStats? {
        if shouldThrow { throw MockError.simulatedFailure }
        return stubbedTodayStats
    }

    func todayFocusMinutes() throws -> Int {
        if shouldThrow { throw MockError.simulatedFailure }
        return stubbedTodayFocusMinutes
    }

    func weeklyTrend() throws -> [DailyStats] {
        if shouldThrow { throw MockError.simulatedFailure }
        return stubbedWeeklyTrend
    }

    func weeklySummary() throws -> StatsCalculator.WeeklySummary {
        if shouldThrow { throw MockError.simulatedFailure }
        return stubbedWeeklySummary
    }

    func currentStreak() throws -> UserStreak? {
        if shouldThrow { throw MockError.simulatedFailure }
        return stubbedCurrentStreak
    }
}
