//
//  MockTimerEngine.swift
//  PomoDaddyTests
//
//  Mock timer engine for testing.
//

import Foundation
@testable import PomoDaddy

/// Mock timer engine that tracks method calls and allows tests to trigger completion.
@Observable
@MainActor
final class MockTimerEngine: TimerEngineProtocol {
    // MARK: - Observable State

    var remainingSeconds: TimeInterval = 0
    var isRunning = false
    var totalDuration: TimeInterval = 0

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        let elapsed = totalDuration - remainingSeconds
        return min(1.0, max(0.0, elapsed / totalDuration))
    }

    var formattedTime: String {
        let minutes = Int(remainingSeconds) / 60
        let seconds = Int(remainingSeconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Call Tracking

    private(set) var startCallCount = 0
    private(set) var pauseCallCount = 0
    private(set) var resumeCallCount = 0
    private(set) var stopCallCount = 0
    private(set) var captureRemainingTimeCallCount = 0
    private(set) var restoreCallCount = 0
    private(set) var addTimeCallCount = 0

    private(set) var lastStartSeconds: TimeInterval?
    private(set) var lastAddedSeconds: TimeInterval?

    // MARK: - Stored Callbacks

    /// The stored completion handler — tests call `simulateCompletion()` to trigger it.
    private(set) var storedOnComplete: (() -> Void)?
    private(set) var storedOnTick: ((TimeInterval) -> Void)?

    // MARK: - Protocol Methods

    func start(
        seconds: TimeInterval,
        onTick: ((TimeInterval) -> Void)?,
        onComplete: (() -> Void)?
    ) {
        startCallCount += 1
        lastStartSeconds = seconds
        totalDuration = seconds
        remainingSeconds = seconds
        isRunning = true
        storedOnTick = onTick
        storedOnComplete = onComplete
    }

    func pause() {
        pauseCallCount += 1
        isRunning = false
    }

    func resume() {
        resumeCallCount += 1
        isRunning = true
    }

    func stop() {
        stopCallCount += 1
        isRunning = false
        remainingSeconds = 0
        totalDuration = 0
        storedOnComplete = nil
        storedOnTick = nil
    }

    func captureRemainingTime() -> TimeInterval? {
        captureRemainingTimeCallCount += 1
        return isRunning ? remainingSeconds : nil
    }

    func restore(
        remainingSeconds: TimeInterval,
        totalDuration: TimeInterval,
        wasRunning: Bool,
        onTick: ((TimeInterval) -> Void)?,
        onComplete: (() -> Void)?
    ) {
        restoreCallCount += 1
        self.remainingSeconds = remainingSeconds
        self.totalDuration = totalDuration
        isRunning = wasRunning
        storedOnTick = onTick
        storedOnComplete = onComplete
    }

    func addTime(_ seconds: TimeInterval) {
        addTimeCallCount += 1
        lastAddedSeconds = seconds
        remainingSeconds += seconds
        totalDuration += seconds
    }

    // MARK: - Test Helpers

    /// Simulates the timer completing by calling the stored completion handler.
    func simulateCompletion() {
        isRunning = false
        remainingSeconds = 0
        let completion = storedOnComplete
        storedOnComplete = nil
        storedOnTick = nil
        completion?()
    }

    /// Simulates a tick with the given remaining seconds.
    func simulateTick(remaining: TimeInterval) {
        remainingSeconds = remaining
        storedOnTick?(remaining)
    }
}
