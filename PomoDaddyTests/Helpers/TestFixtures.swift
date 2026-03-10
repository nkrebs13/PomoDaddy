import Foundation
@testable import PomoDaddy

/// Test fixtures for creating sample data
enum TestFixtures {
    // MARK: - Timer Settings

    static let defaultSettings = TimerSettings()

    static let customSettings = TimerSettings(
        workDuration: 30 * 60,
        shortBreakDuration: 10 * 60,
        longBreakDuration: 20 * 60,
        pomodorosUntilLongBreak: 3,
        autoStartBreaks: true,
        autoStartWork: true,
        soundEnabled: false,
        notificationsEnabled: false
    )

    // MARK: - Pomodoro Sessions

    static func createSession(
        startDate: Date = Date(),
        durationMinutes: Int = 25,
        wasCompleted: Bool = true
    ) -> PomodoroSession {
        let endDate = startDate.addingTimeInterval(TimeInterval(durationMinutes * 60))
        return PomodoroSession(
            startDate: startDate,
            endDate: endDate,
            durationMinutes: durationMinutes,
            wasCompleted: wasCompleted
        )
    }

    // MARK: - Date Helpers

    static func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0
    ) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }

    static var today: Date {
        Calendar.current.startOfDay(for: Date())
    }

    static var yesterday: Date {
        Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
    }

    static var tomorrow: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
    }
}
