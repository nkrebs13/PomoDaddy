//
//  SessionCoordinatorTests.swift
//  PomoDaddyTests
//
//  Tests for SessionCoordinator session tracking and confetti.
//

import XCTest
@testable import PomoDaddy

@MainActor
final class SessionCoordinatorTests: XCTestCase {
    var coordinator: SessionCoordinator!
    var recorder: SessionRecorder!
    var container: PomodoroDataContainer!

    override func setUp() {
        super.setUp()
        let modelContainer = PomodoroDataContainer.createInMemory()
        recorder = SessionRecorder(modelContainer: modelContainer)
        coordinator = SessionCoordinator(sessionRecorder: recorder)
    }

    override func tearDown() {
        coordinator = nil
        recorder = nil
        container = nil
        super.tearDown()
    }

    // MARK: - Session Tracking

    func testStartSession() {
        XCTAssertNil(coordinator.currentSessionStartTime)

        coordinator.startSession()
        XCTAssertNotNil(coordinator.currentSessionStartTime)
    }

    func testClearSession() {
        coordinator.startSession()
        XCTAssertNotNil(coordinator.currentSessionStartTime)

        coordinator.clearSession()
        XCTAssertNil(coordinator.currentSessionStartTime)
    }

    func testClearSessionWhenAlreadyNil() {
        XCTAssertNil(coordinator.currentSessionStartTime)
        coordinator.clearSession()
        XCTAssertNil(coordinator.currentSessionStartTime)
    }

    func testStartSessionOverwritesPrevious() {
        coordinator.startSession()
        let firstTime = coordinator.currentSessionStartTime

        // Small delay to ensure different timestamp
        Thread.sleep(forTimeInterval: 0.01)

        coordinator.startSession()
        let secondTime = coordinator.currentSessionStartTime

        XCTAssertNotEqual(firstTime, secondTime)
    }

    // MARK: - Confetti

    func testTriggerConfetti() {
        XCTAssertFalse(coordinator.showConfetti)

        coordinator.triggerConfetti()
        XCTAssertTrue(coordinator.showConfetti)
    }

    func testConfettiAutoHides() async {
        coordinator.triggerConfetti()
        XCTAssertTrue(coordinator.showConfetti)

        // Wait for confetti duration + buffer
        try? await Task.sleep(nanoseconds: AppConstants.Confetti.durationNanoseconds + 200_000_000)
        XCTAssertFalse(coordinator.showConfetti)
    }

    func testDoubleTriggerCancelsPrevious() {
        coordinator.triggerConfetti()
        XCTAssertTrue(coordinator.showConfetti)

        // Trigger again — should not crash
        coordinator.triggerConfetti()
        XCTAssertTrue(coordinator.showConfetti)
    }

    // MARK: - Complete Session

    func testCompleteSessionClearsStartTime() async {
        coordinator.startSession()
        XCTAssertNotNil(coordinator.currentSessionStartTime)

        await coordinator.completeSession(durationMinutes: 25)
        XCTAssertNil(coordinator.currentSessionStartTime)
    }

    func testCompleteSessionTriggersConfetti() async {
        coordinator.startSession()
        await coordinator.completeSession(durationMinutes: 25)
        XCTAssertTrue(coordinator.showConfetti)
    }

    func testCompleteSessionWithoutStartDoesNothing() async {
        // No startSession called
        await coordinator.completeSession(durationMinutes: 25)
        XCTAssertNil(coordinator.currentSessionStartTime)
        XCTAssertFalse(coordinator.showConfetti)
    }

    func testCompleteSessionCalledTwiceRapidly() async {
        coordinator.startSession()

        // Complete session twice — second should be no-op (startTime is nil)
        await coordinator.completeSession(durationMinutes: 25)
        XCTAssertTrue(coordinator.showConfetti)
        XCTAssertNil(coordinator.currentSessionStartTime)

        // Reset confetti to verify second call doesn't re-trigger
        coordinator.showConfetti = false
        await coordinator.completeSession(durationMinutes: 25)
        XCTAssertFalse(coordinator.showConfetti) // Guard prevents re-trigger
    }
}
