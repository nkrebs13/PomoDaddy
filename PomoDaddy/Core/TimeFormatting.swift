//
//  TimeFormatting.swift
//  PomoDaddy
//
//  Shared time formatting utilities.
//

import Foundation

/// Shared formatting for focus time durations.
enum TimeFormatting {
    /// Formats minutes as a human-readable string (e.g., "1h 25m", "45m", "0m").
    static func formatFocusTime(minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60

        if hours > 0 {
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(mins)m"
    }

    /// Formats minutes as a compact axis label (e.g., "2h", "45m").
    static func formatAxisLabel(minutes: Int) -> String {
        if minutes >= 60 {
            return "\(minutes / 60)h"
        }
        return "\(minutes)m"
    }
}
