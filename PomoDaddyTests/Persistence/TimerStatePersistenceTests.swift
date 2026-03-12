//
//  TimerStatePersistenceTests.swift
//  PomoDaddyTests
//
//  Tests for the TimerStatePersistence service.
//

import XCTest
@testable import PomoDaddy

final class TimerStatePersistenceTests: XCTestCase {
    var persistence: TimerStatePersistence!
    var mockDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        // Use a test-specific suite name for isolation
        mockDefaults = UserDefaults(suiteName: "com.pomodaddy.tests.timerstate")!
        persistence = TimerStatePersistence(defaults: mockDefaults)
    }

    override func tearDown() {
        persistence.clear()
        mockDefaults.removePersistentDomain(forName: "com.pomodaddy.tests.timerstate")
        persistence = nil
        mockDefaults = nil
        super.tearDown()
    }

    // MARK: - Save and Load Tests

    func testSaveAndLoadState() {
        let state = PersistedTimerState(
            phase: .work,
            remainingSeconds: 1500,
            wasRunning: true,
            completedPomodorosInCycle: 2,
            todayCompletedPomodoros: 5
        )

        persistence.save(state)

        let loaded = persistence.load()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.phase, .work)
        XCTAssertEqual(loaded?.remainingSeconds, 1500)
        XCTAssertTrue(loaded?.wasRunning ?? false)
        XCTAssertEqual(loaded?.completedPomodorosInCycle, 2)
        XCTAssertEqual(loaded?.todayCompletedPomodoros, 5)
    }

    func testLoadWithNoData() {
        let loaded = persistence.load()
        XCTAssertNil(loaded)
    }

    func testLoadWithCorruptedData() {
        // Save corrupted data
        mockDefaults.set("corrupted data", forKey: "com.pomodaddy.timerState")

        let loaded = persistence.load()
        XCTAssertNil(loaded)

        // Should clear corrupted data
        XCTAssertFalse(persistence.hasPersistedState)
    }

    func testClear() {
        let state = PersistedTimerState.idle()
        persistence.save(state)
        XCTAssertNotNil(persistence.load())

        persistence.clear()
        XCTAssertNil(persistence.load())
    }

    // MARK: - State Validation Tests

    func testStateExpiration() {
        // Create a state that's 25 hours old (expired)
        let oldDate = Date().addingTimeInterval(-25 * 60 * 60)
        let state = PersistedTimerState(
            phase: .work,
            remainingSeconds: 1500,
            wasRunning: true,
            capturedAt: oldDate
        )

        persistence.save(state)

        // Loading should return nil for expired state
        let loaded = persistence.load()
        XCTAssertNil(loaded)

        // Should have cleared the expired state
        XCTAssertFalse(persistence.hasPersistedState)
    }

    func testStateValidWithin24Hours() {
        // Create a state that's 23 hours old (valid)
        let recentDate = Date().addingTimeInterval(-23 * 60 * 60)
        let state = PersistedTimerState(
            phase: .work,
            remainingSeconds: 1500,
            wasRunning: true,
            capturedAt: recentDate
        )

        persistence.save(state)

        let loaded = persistence.load()
        XCTAssertNotNil(loaded)
        XCTAssertTrue(loaded?.isValid ?? false)
    }

    // MARK: - Time Adjustment Tests

    func testAdjustedRemainingTime() {
        // Create a state from 10 seconds ago
        let captureDate = Date().addingTimeInterval(-10)
        let state = PersistedTimerState(
            phase: .work,
            remainingSeconds: 60,
            wasRunning: true,
            capturedAt: captureDate
        )

        let adjusted = state.adjustedRemainingTime()
        // Should be around 50 seconds (60 - 10)
        XCTAssertLessThan(adjusted, 60)
        XCTAssertGreaterThan(adjusted, 45) // Allow some timing variance
    }

    func testAdjustedRemainingTimeWhenPaused() {
        // When paused, remaining time should not change
        let captureDate = Date().addingTimeInterval(-10)
        let state = PersistedTimerState(
            phase: .work,
            remainingSeconds: 60,
            wasRunning: false, // Paused
            capturedAt: captureDate
        )

        let adjusted = state.adjustedRemainingTime()
        XCTAssertEqual(adjusted, 60) // Should remain unchanged
    }

    func testAdjustedRemainingTimeFloorAtZero() {
        // Create a state from 100 seconds ago with only 60 seconds remaining
        let captureDate = Date().addingTimeInterval(-100)
        let state = PersistedTimerState(
            phase: .work,
            remainingSeconds: 60,
            wasRunning: true,
            capturedAt: captureDate
        )

        let adjusted = state.adjustedRemainingTime()
        XCTAssertEqual(adjusted, 0) // Should not go negative
    }

    // MARK: - Natural Completion Tests

    func testHasNaturallyCompleted() {
        // Timer that would have completed
        let captureDate = Date().addingTimeInterval(-100)
        let state = PersistedTimerState(
            phase: .work,
            remainingSeconds: 60,
            wasRunning: true,
            capturedAt: captureDate
        )

        XCTAssertTrue(state.hasNaturallyCompleted)
    }

    func testHasNotNaturallyCompleted() {
        // Timer with time remaining
        let captureDate = Date().addingTimeInterval(-10)
        let state = PersistedTimerState(
            phase: .work,
            remainingSeconds: 60,
            wasRunning: true,
            capturedAt: captureDate
        )

        XCTAssertFalse(state.hasNaturallyCompleted)
    }

    func testPausedTimerNeverNaturallyCompletes() {
        // Even with elapsed time > remaining, paused timer doesn't complete
        let captureDate = Date().addingTimeInterval(-100)
        let state = PersistedTimerState(
            phase: .work,
            remainingSeconds: 60,
            wasRunning: false,
            capturedAt: captureDate
        )

        XCTAssertFalse(state.hasNaturallyCompleted)
    }

    // MARK: - Restoration Tests

    func testRestoreResult_NoState() {
        let result = persistence.restore()

        if case .noState = result {
            // Success
        } else {
            XCTFail("Expected noState result")
        }
    }

    func testRestoreResult_Invalid() {
        // Create expired state
        let oldDate = Date().addingTimeInterval(-25 * 60 * 60)
        let state = PersistedTimerState(
            phase: .work,
            remainingSeconds: 1500,
            wasRunning: true,
            capturedAt: oldDate
        )

        persistence.save(state)

        let result = persistence.restore()

        if case .invalid = result {
            // Success
        } else {
            XCTFail("Expected invalid result")
        }
    }

    func testRestoreResult_CompletedWhileClosed() {
        // Timer that completed while app was closed
        let captureDate = Date().addingTimeInterval(-100)
        let sessionStart = Date().addingTimeInterval(-1600)
        let state = PersistedTimerState(
            phase: .work,
            remainingSeconds: 60,
            wasRunning: true,
            sessionStartDate: sessionStart
        )

        persistence.save(state)

        let result = persistence.restore()

        if case let .completedWhileClosed(phase, startDate) = result {
            XCTAssertEqual(phase, .work)
            XCTAssertNotNil(startDate)
        } else {
            XCTFail("Expected completedWhileClosed result")
        }
    }

    func testRestoreResult_Restored() {
        // Valid state with time remaining
        let captureDate = Date().addingTimeInterval(-10)
        let state = PersistedTimerState(
            phase: .work,
            remainingSeconds: 1500,
            wasRunning: true,
            capturedAt: captureDate
        )

        persistence.save(state)

        let result = persistence.restore()

        if case let .restored(restoredState) = result {
            XCTAssertEqual(restoredState.phase, .work)
            XCTAssertLessThan(restoredState.remainingSeconds, 1500) // Time adjusted
            XCTAssertTrue(restoredState.wasRunning)
        } else {
            XCTFail("Expected restored result")
        }
    }

    // MARK: - Convenience Factory Tests

    func testIdleFactory() {
        let state = PersistedTimerState.idle(
            completedPomodorosInCycle: 2,
            todayCompletedPomodoros: 5
        )

        XCTAssertEqual(state.phase, .idle)
        XCTAssertEqual(state.remainingSeconds, 0)
        XCTAssertFalse(state.wasRunning)
        XCTAssertEqual(state.completedPomodorosInCycle, 2)
        XCTAssertEqual(state.todayCompletedPomodoros, 5)
    }

    func testWorkingFactory() {
        let startDate = Date()
        let state = PersistedTimerState.working(
            remainingSeconds: 1500,
            isRunning: true,
            sessionStartDate: startDate,
            completedPomodorosInCycle: 1,
            todayCompletedPomodoros: 3
        )

        XCTAssertEqual(state.phase, .work)
        XCTAssertEqual(state.remainingSeconds, 1500)
        XCTAssertTrue(state.wasRunning)
        XCTAssertEqual(state.sessionStartDate, startDate)
    }

    func testOnBreakFactory() {
        let shortBreak = PersistedTimerState.onBreak(
            isLongBreak: false,
            remainingSeconds: 300,
            isRunning: true,
            completedPomodorosInCycle: 1,
            todayCompletedPomodoros: 1
        )

        XCTAssertEqual(shortBreak.phase, .shortBreak)

        let longBreak = PersistedTimerState.onBreak(
            isLongBreak: true,
            remainingSeconds: 900,
            isRunning: true,
            completedPomodorosInCycle: 4,
            todayCompletedPomodoros: 4
        )

        XCTAssertEqual(longBreak.phase, .longBreak)
    }

    // MARK: - Load and Restore Tests

    func testLoadAndRestore() {
        let captureDate = Date().addingTimeInterval(-10)
        let state = PersistedTimerState(
            phase: .work,
            remainingSeconds: 1500,
            wasRunning: true,
            capturedAt: captureDate
        )

        persistence.save(state)

        let restored = persistence.loadAndRestore()
        XCTAssertNotNil(restored)
        XCTAssertLessThan(restored?.remainingSeconds ?? 0, 1500) // Time adjusted
        XCTAssertTrue(restored?.wasRunning ?? false)
    }

    func testLoadAndRestoreWithNoData() {
        let restored = persistence.loadAndRestore()
        XCTAssertNil(restored)
    }

    // MARK: - Has Persisted State Tests

    func testHasPersistedState() {
        XCTAssertFalse(persistence.hasPersistedState)

        let state = PersistedTimerState.idle()
        persistence.save(state)

        XCTAssertTrue(persistence.hasPersistedState)

        persistence.clear()

        XCTAssertFalse(persistence.hasPersistedState)
    }

    // MARK: - Restored State Tests

    func testRestoredCreatesNewState() {
        let captureDate = Date().addingTimeInterval(-10)
        let original = PersistedTimerState(
            phase: .work,
            remainingSeconds: 1500,
            wasRunning: true,
            capturedAt: captureDate,
            completedPomodorosInCycle: 2,
            todayCompletedPomodoros: 5
        )

        let restored = original.restored()

        // Adjusted time
        XCTAssertLessThan(restored.remainingSeconds, original.remainingSeconds)

        // Other properties preserved
        XCTAssertEqual(restored.phase, original.phase)
        XCTAssertEqual(restored.completedPomodorosInCycle, original.completedPomodorosInCycle)
        XCTAssertEqual(restored.todayCompletedPomodoros, original.todayCompletedPomodoros)

        // Capture date updated
        XCTAssertGreaterThan(restored.capturedAt, original.capturedAt)
    }

    func testRestoredStopsCompletedTimer() {
        let captureDate = Date().addingTimeInterval(-100)
        let original = PersistedTimerState(
            phase: .work,
            remainingSeconds: 60,
            wasRunning: true,
            capturedAt: captureDate
        )

        let restored = original.restored()

        XCTAssertFalse(restored.wasRunning) // Should stop completed timer
        XCTAssertEqual(restored.remainingSeconds, 0)
    }
}
