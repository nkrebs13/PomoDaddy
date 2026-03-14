//
//  Calendar+Extensions.swift
//  PomoDaddy
//
//  Centralized calendar and date utilities to eliminate duplication.
//

import Foundation

extension Calendar {
    /// Shared calendar instance used throughout the app.
    static let shared = Calendar.current

    /// Returns the start of the day for the given date.
    /// - Parameter date: The date to find the start of day for.
    /// - Returns: A date representing midnight at the start of the given date.
    static func startOfDay(for date: Date) -> Date {
        shared.startOfDay(for: date)
    }

    /// Checks if two dates are on the same day.
    /// - Parameters:
    ///   - date1: The first date to compare.
    ///   - date2: The second date to compare.
    /// - Returns: True if both dates are on the same calendar day.
    static func isDate(_ date1: Date, inSameDayAs date2: Date) -> Bool {
        shared.isDate(date1, inSameDayAs: date2)
    }

    /// Returns an array of dates for the past N days, including today.
    /// - Parameters:
    ///   - days: The number of days to include (must be positive).
    ///   - endDate: The ending date (defaults to today).
    /// - Returns: An array of dates in chronological order, or empty array if days <= 0.
    static func dateRange(days: Int, ending endDate: Date = Date()) -> [Date] {
        guard days > 0 else { return [] }
        let startOfToday: Date = startOfDay(for: endDate)
        return (0 ..< days).compactMap { offset in
            shared.date(byAdding: .day, value: -offset, to: startOfToday)
        }.reversed()
    }

    /// Returns the start and end dates for a given date's day.
    /// - Parameter date: The date to get the day boundaries for.
    /// - Returns: A tuple containing the start and end of the day, or nil if calculation fails.
    static func dayBoundaries(for date: Date) -> (start: Date, end: Date)? {
        let start: Date = startOfDay(for: date)
        guard let end = shared.date(byAdding: .day, value: 1, to: start) else {
            return nil
        }
        return (start, end)
    }
}
