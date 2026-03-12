//
//  SessionRecorderTests.swift
//  PomoDaddyTests
//
//  Tests for the SessionRecorder actor.
//

import SwiftData
import XCTest
@testable import PomoDaddy

@MainActor
final class SessionRecorderTests: XCTestCase {
    var modelContainer: ModelContainer!
    var sessionRecorder: SessionRecorder!

    override func setUp() async throws {
        try await super.setUp()
        // Create in-memory container for testing
        modelContainer = PomodoroDataContainer.createInMemory()
        sessionRecorder = SessionRecorder(modelContainer: modelContainer)
    }

    override func tearDown() async throws {
        sessionRecorder = nil
        modelContainer = nil
        try await super.tearDown()
    }

    // MARK: - Basic Recording Tests

    func testRecordSession() async throws {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(25 * 60)

        try await sessionRecorder.record(
            startDate: startDate,
            endDate: endDate,
            durationMinutes: 25,
            wasCompleted: true
        )

        // Verify session was recorded
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<PomodoroSession>()
        let sessions = try context.fetch(descriptor)

        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.durationMinutes, 25)
        XCTAssertTrue(sessions.first?.wasCompleted ?? false)
    }

    func testRecordSessionUpdatesDailyStats() async throws {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(25 * 60)

        try await sessionRecorder.record(
            startDate: startDate,
            endDate: endDate,
            durationMinutes: 25,
            wasCompleted: true
        )

        // Verify daily stats were updated
        let context = modelContainer.mainContext
        let today = Calendar.current.startOfDay(for: Date())
        var descriptor = FetchDescriptor<DailyStats>(
            predicate: DailyStats.forDate(today)
        )
        descriptor.fetchLimit = 1

        let stats = try context.fetch(descriptor)

        XCTAssertEqual(stats.count, 1)
        XCTAssertEqual(stats.first?.completedPomodoros, 1)
        XCTAssertEqual(stats.first?.totalFocusMinutes, 25)
    }

    func testRecordSessionUpdatesStreak() async throws {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(25 * 60)

        try await sessionRecorder.record(
            startDate: startDate,
            endDate: endDate,
            durationMinutes: 25,
            wasCompleted: true
        )

        // Verify streak was updated
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<UserStreak>()
        let streaks = try context.fetch(descriptor)

        XCTAssertEqual(streaks.count, 1)
        XCTAssertEqual(streaks.first?.currentStreakDays, 1)
    }

    func testRecordMultipleSessions() async throws {
        let startDate = Date()

        // Record 3 sessions
        for i in 0 ..< 3 {
            let sessionStart = startDate.addingTimeInterval(TimeInterval(i * 30 * 60))
            let sessionEnd = sessionStart.addingTimeInterval(25 * 60)

            try await sessionRecorder.record(
                startDate: sessionStart,
                endDate: sessionEnd,
                durationMinutes: 25,
                wasCompleted: true
            )
        }

        // Verify all sessions were recorded
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<PomodoroSession>()
        let sessions = try context.fetch(descriptor)

        XCTAssertEqual(sessions.count, 3)

        // Verify daily stats reflect all sessions
        let today = Calendar.current.startOfDay(for: Date())
        var statsDescriptor = FetchDescriptor<DailyStats>(
            predicate: DailyStats.forDate(today)
        )
        statsDescriptor.fetchLimit = 1
        let stats = try context.fetch(statsDescriptor)

        XCTAssertEqual(stats.first?.completedPomodoros, 3)
        XCTAssertEqual(stats.first?.totalFocusMinutes, 75)
    }

    func testRecordIncompleteSession() async throws {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(10 * 60)

        try await sessionRecorder.record(
            startDate: startDate,
            endDate: endDate,
            durationMinutes: 25,
            wasCompleted: false
        )

        // Session should be recorded
        let context = modelContainer.mainContext
        let sessionDescriptor = FetchDescriptor<PomodoroSession>()
        let sessions = try context.fetch(sessionDescriptor)

        XCTAssertEqual(sessions.count, 1)
        XCTAssertFalse(sessions.first?.wasCompleted ?? true)

        // But stats should NOT be updated for incomplete sessions
        let today = Calendar.current.startOfDay(for: Date())
        var statsDescriptor = FetchDescriptor<DailyStats>(
            predicate: DailyStats.forDate(today)
        )
        statsDescriptor.fetchLimit = 1
        let stats = try context.fetch(statsDescriptor)

        XCTAssertEqual(stats.count, 0) // No stats for incomplete sessions
    }

    // MARK: - Batch Operations Tests

    func testRecordBatch() async throws {
        let startDate = Date()
        let sessions = (0 ..< 5).map { i in
            let sessionStart = startDate.addingTimeInterval(TimeInterval(i * 30 * 60))
            let sessionEnd = sessionStart.addingTimeInterval(25 * 60)
            return PomodoroSession(
                startDate: sessionStart,
                endDate: sessionEnd,
                durationMinutes: 25,
                wasCompleted: true
            )
        }

        try await sessionRecorder.recordBatch(sessions)

        // Verify all sessions were recorded
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<PomodoroSession>()
        let recordedSessions = try context.fetch(descriptor)

        XCTAssertEqual(recordedSessions.count, 5)

        // Verify stats updated correctly
        let today = Calendar.current.startOfDay(for: Date())
        var statsDescriptor = FetchDescriptor<DailyStats>(
            predicate: DailyStats.forDate(today)
        )
        statsDescriptor.fetchLimit = 1
        let stats = try context.fetch(statsDescriptor)

        XCTAssertEqual(stats.first?.completedPomodoros, 5)
        XCTAssertEqual(stats.first?.totalFocusMinutes, 125)
    }

    // MARK: - Deletion Tests

    func testDeleteSession() async throws {
        // First, record a session
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(25 * 60)

        try await sessionRecorder.record(
            startDate: startDate,
            endDate: endDate,
            durationMinutes: 25,
            wasCompleted: true
        )

        // Use a fresh context to find the session's ID
        let freshContext = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<PomodoroSession>()
        let sessions = try freshContext.fetch(descriptor)
        let session = try XCTUnwrap(sessions.first)
        let sessionID = session.persistentModelID

        // Delete it via the actor using the persistent identifier
        try await sessionRecorder.delete(sessionID)

        // Use another fresh context to verify deletion
        let verifyContext = ModelContext(modelContainer)
        let remainingSessions = try verifyContext.fetch(descriptor)
        XCTAssertEqual(remainingSessions.count, 0)

        // Verify stats were adjusted
        let today = Calendar.current.startOfDay(for: Date())
        var statsDescriptor = FetchDescriptor<DailyStats>(
            predicate: DailyStats.forDate(today)
        )
        statsDescriptor.fetchLimit = 1
        let stats = try verifyContext.fetch(statsDescriptor)

        // Stats should either be gone or have zero values
        if let stat = stats.first {
            XCTAssertEqual(stat.completedPomodoros, 0)
            XCTAssertEqual(stat.totalFocusMinutes, 0)
        }
    }

    func testDeleteSessionAdjustsStats() async throws {
        // Record multiple sessions
        let startDate = Date()

        for i in 0 ..< 3 {
            let sessionStart = startDate.addingTimeInterval(TimeInterval(i * 30 * 60))
            let sessionEnd = sessionStart.addingTimeInterval(25 * 60)

            try await sessionRecorder.record(
                startDate: sessionStart,
                endDate: sessionEnd,
                durationMinutes: 25,
                wasCompleted: true
            )
        }

        // Delete one session using persistent identifier
        let freshContext = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<PomodoroSession>()
        let sessions = try freshContext.fetch(descriptor)
        let sessionToDelete = try XCTUnwrap(sessions.first)
        let sessionID = sessionToDelete.persistentModelID

        try await sessionRecorder.delete(sessionID)

        // Verify stats were adjusted correctly using fresh context
        let verifyContext = ModelContext(modelContainer)
        let today = Calendar.current.startOfDay(for: Date())
        var statsDescriptor = FetchDescriptor<DailyStats>(
            predicate: DailyStats.forDate(today)
        )
        statsDescriptor.fetchLimit = 1
        let stats = try verifyContext.fetch(statsDescriptor)

        XCTAssertEqual(stats.first?.completedPomodoros, 2)
        XCTAssertEqual(stats.first?.totalFocusMinutes, 50)
    }
}
