//
//  TimerEngine.swift
//  PomoDaddy
//
//  Core timer engine using timestamp-based timing for accuracy.
//

import Foundation
import Combine
import Observation

// MARK: - Timer Engine

/// A timestamp-based timer engine that maintains accuracy across sleep/background states.
///
/// This engine uses the system clock to calculate remaining time, ensuring that
/// the timer remains accurate even if the app is suspended or the device sleeps.
@Observable
final class TimerEngine {

    // MARK: - Public Properties

    /// The number of seconds remaining in the current timer session.
    private(set) var remainingSeconds: TimeInterval = 0

    /// Whether the timer is currently running.
    private(set) var isRunning: Bool = false

    /// The total duration of the current timer session in seconds.
    private(set) var totalDuration: TimeInterval = 0

    /// Progress from 0.0 (just started) to 1.0 (completed).
    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        let elapsed = totalDuration - remainingSeconds
        return min(1.0, max(0.0, elapsed / totalDuration))
    }

    /// Formatted string representation of remaining time (MM:SS).
    var formattedTime: String {
        let minutes = Int(remainingSeconds) / 60
        let seconds = Int(remainingSeconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Private Properties

    /// The target end date for the current timer session.
    private var targetEndDate: Date?

    /// The remaining time when the timer was paused.
    private var pausedRemainingTime: TimeInterval?

    /// Subscription to the timer publisher.
    private var timerCancellable: AnyCancellable?

    /// Callback invoked when the timer completes.
    private var completionHandler: (() -> Void)?

    /// Callback invoked on each tick (for UI updates).
    private var tickHandler: ((TimeInterval) -> Void)?

    /// The interval between timer ticks in seconds.
    private let tickInterval: TimeInterval = 0.1

    // MARK: - Initialization

    init() {}

    deinit {
        stop()
    }

    // MARK: - Public Methods

    /// Starts a new timer session with the specified duration.
    /// - Parameters:
    ///   - seconds: The duration of the timer in seconds.
    ///   - onTick: Optional callback invoked on each tick with remaining seconds.
    ///   - onComplete: Optional callback invoked when the timer completes.
    func start(
        seconds: TimeInterval,
        onTick: ((TimeInterval) -> Void)? = nil,
        onComplete: (() -> Void)? = nil
    ) {
        stop()

        totalDuration = seconds
        remainingSeconds = seconds
        targetEndDate = Date().addingTimeInterval(seconds)
        pausedRemainingTime = nil
        tickHandler = onTick
        completionHandler = onComplete
        isRunning = true

        startTimerPublisher()
    }

    /// Pauses the currently running timer.
    func pause() {
        guard isRunning, let endDate = targetEndDate else { return }

        // Capture the exact remaining time
        pausedRemainingTime = max(0, endDate.timeIntervalSince(Date()))
        remainingSeconds = pausedRemainingTime ?? 0
        targetEndDate = nil
        isRunning = false

        stopTimerPublisher()
    }

    /// Resumes a paused timer.
    func resume() {
        guard !isRunning, let pausedTime = pausedRemainingTime, pausedTime > 0 else { return }

        targetEndDate = Date().addingTimeInterval(pausedTime)
        pausedRemainingTime = nil
        isRunning = true

        startTimerPublisher()
    }

    /// Stops the timer and resets all state.
    func stop() {
        stopTimerPublisher()

        targetEndDate = nil
        pausedRemainingTime = nil
        remainingSeconds = 0
        totalDuration = 0
        isRunning = false
        completionHandler = nil
        tickHandler = nil
    }

    /// Captures and returns the current remaining time.
    /// Useful for persisting state when the app goes to background.
    /// - Returns: The remaining time in seconds, or nil if no timer is active.
    func captureRemainingTime() -> TimeInterval? {
        if isRunning, let endDate = targetEndDate {
            return max(0, endDate.timeIntervalSince(Date()))
        } else if let pausedTime = pausedRemainingTime {
            return pausedTime
        }
        return nil
    }

    /// Restores the timer from a saved state.
    /// - Parameters:
    ///   - remainingSeconds: The remaining time in seconds.
    ///   - totalDuration: The total duration of the session.
    ///   - wasRunning: Whether the timer was running when saved.
    ///   - onTick: Optional callback invoked on each tick.
    ///   - onComplete: Optional callback invoked when the timer completes.
    func restore(
        remainingSeconds: TimeInterval,
        totalDuration: TimeInterval,
        wasRunning: Bool,
        onTick: ((TimeInterval) -> Void)? = nil,
        onComplete: (() -> Void)? = nil
    ) {
        stop()

        self.totalDuration = totalDuration
        self.remainingSeconds = remainingSeconds
        self.tickHandler = onTick
        self.completionHandler = onComplete

        if wasRunning && remainingSeconds > 0 {
            targetEndDate = Date().addingTimeInterval(remainingSeconds)
            isRunning = true
            startTimerPublisher()
        } else if remainingSeconds > 0 {
            pausedRemainingTime = remainingSeconds
            isRunning = false
        }
    }

    /// Adds time to the current timer session.
    /// - Parameter seconds: The number of seconds to add (can be negative to subtract).
    func addTime(_ seconds: TimeInterval) {
        if isRunning, let endDate = targetEndDate {
            let newEndDate = endDate.addingTimeInterval(seconds)
            let newRemaining = newEndDate.timeIntervalSince(Date())

            if newRemaining > 0 {
                targetEndDate = newEndDate
                remainingSeconds = newRemaining
                totalDuration += seconds
            }
        } else if var pausedTime = pausedRemainingTime {
            pausedTime = max(0, pausedTime + seconds)
            pausedRemainingTime = pausedTime
            remainingSeconds = pausedTime
            totalDuration += seconds
        }
    }

    // MARK: - Private Methods

    private func startTimerPublisher() {
        timerCancellable = Timer.publish(every: tickInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func stopTimerPublisher() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func tick() {
        guard isRunning, let endDate = targetEndDate else { return }

        let remaining = endDate.timeIntervalSince(Date())

        if remaining <= 0 {
            // Timer completed
            remainingSeconds = 0
            isRunning = false
            stopTimerPublisher()

            let completion = completionHandler
            completionHandler = nil
            tickHandler = nil

            completion?()
        } else {
            remainingSeconds = remaining
            tickHandler?(remaining)
        }
    }
}

// MARK: - Timer Engine State

/// Represents the persistable state of a TimerEngine.
struct TimerEngineState: Codable {
    let remainingSeconds: TimeInterval
    let totalDuration: TimeInterval
    let wasRunning: Bool
    let savedAt: Date

    /// Creates a state snapshot from a TimerEngine.
    init(from engine: TimerEngine) {
        self.remainingSeconds = engine.captureRemainingTime() ?? 0
        self.totalDuration = engine.totalDuration
        self.wasRunning = engine.isRunning
        self.savedAt = Date()
    }

    /// Calculates the adjusted remaining time accounting for elapsed time since save.
    /// - Parameter adjustForElapsed: If true, subtracts time elapsed since save (for running timers).
    func adjustedRemainingSeconds(adjustForElapsed: Bool = true) -> TimeInterval {
        if wasRunning && adjustForElapsed {
            let elapsed = Date().timeIntervalSince(savedAt)
            return max(0, remainingSeconds - elapsed)
        }
        return remainingSeconds
    }
}
