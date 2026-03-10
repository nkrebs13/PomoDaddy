//
//  DataContainer.swift
//  PomoDaddy
//
//  SwiftData container configuration and setup.
//

import Foundation
import os.log
import SwiftData

/// Provides the configured SwiftData ModelContainer for the app.
enum PomodoroDataContainer {
    /// All model types managed by the container.
    static let modelTypes: [any PersistentModel.Type] = [
        PomodoroSession.self,
        DailyStats.self,
        UserStreak.self
    ]

    /// The schema for all models.
    static let schema = Schema(modelTypes)

    /// Creates the main ModelContainer for production use.
    /// - Returns: A configured ModelContainer ready for use.
    /// - Note: This container persists data to disk.
    static func create() -> ModelContainer {
        let configuration = ModelConfiguration(
            "PomoDaddy",
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            // In production, we should handle this more gracefully
            // For now, fall back to in-memory storage
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }

    /// Creates an in-memory ModelContainer for testing and previews.
    /// - Returns: A configured ModelContainer that stores data in memory only.
    static func createInMemory() -> ModelContainer {
        let configuration = ModelConfiguration(
            "PomoDaddy-InMemory",
            schema: schema,
            isStoredInMemoryOnly: true,
            allowsSave: true
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("Failed to create in-memory ModelContainer: \(error.localizedDescription)")
        }
    }

    /// Creates a preview container with sample data.
    /// - Returns: A configured ModelContainer populated with sample data.
    @MainActor
    static func createPreview() -> ModelContainer {
        let container = createInMemory()
        let context = container.mainContext

        // Add sample data
        populateSampleData(in: context)

        return container
    }

    /// Populates the context with sample data for previews and testing.
    /// - Parameter context: The ModelContext to populate.
    @MainActor
    private static func populateSampleData(in context: ModelContext) {
        let calendar = Calendar.current
        let now = Date()

        // Create sample sessions for the past week
        for dayOffset in 0 ..< 7 {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let startOfDay = calendar.startOfDay(for: day)

            // Create 2-4 sessions per day
            let sessionCount = Int.random(in: 2 ... 4)
            var dailyMinutes = 0

            for sessionIndex in 0 ..< sessionCount {
                let sessionStart = calendar.date(
                    byAdding: .hour,
                    value: 9 + (sessionIndex * 2),
                    to: startOfDay
                ) ?? startOfDay
                let duration = 25
                let sessionEnd = calendar.date(
                    byAdding: .minute,
                    value: duration,
                    to: sessionStart
                ) ?? sessionStart

                let session = PomodoroSession(
                    startDate: sessionStart,
                    endDate: sessionEnd,
                    durationMinutes: duration,
                    wasCompleted: true
                )
                context.insert(session)
                dailyMinutes += duration
            }

            // Create daily stats
            let stats = DailyStats(
                date: startOfDay,
                totalFocusMinutes: dailyMinutes,
                completedPomodoros: sessionCount
            )
            context.insert(stats)
        }

        // Create streak data
        let streak = UserStreak(
            currentStreakDays: 7,
            longestStreakDays: 14,
            lastActiveDate: now
        )
        context.insert(streak)

        do {
            try context.save()
        } catch {
            Logger.logError(error, context: "Failed to save sample data", log: Logger.persistence)
        }
    }
}

// MARK: - ModelContext Extensions

extension ModelContext {
    /// Saves changes if there are any pending changes.
    func saveIfNeeded() throws {
        if hasChanges {
            try save()
        }
    }

    /// Performs a fetch and returns the first result, or nil if none found.
    func fetchFirst<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) throws -> T? {
        var limitedDescriptor = descriptor
        limitedDescriptor.fetchLimit = 1
        return try fetch(limitedDescriptor).first
    }
}
