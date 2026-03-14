//
//  TimerEngineProtocol.swift
//  PomoDaddy
//
//  Protocol for timer engine dependency injection.
//

import Foundation

/// Protocol defining the timer engine interface for dependency injection and testing.
@MainActor
internal protocol TimerEngineProtocol: AnyObject {
    /// The number of seconds remaining in the current timer session.
    var remainingSeconds: TimeInterval { get }

    /// Whether the timer is currently running.
    var isRunning: Bool { get }

    /// The total duration of the current timer session in seconds.
    var totalDuration: TimeInterval { get }

    /// Progress from 0.0 (just started) to 1.0 (completed).
    var progress: Double { get }

    /// Formatted string representation of remaining time (MM:SS).
    var formattedTime: String { get }

    /// Starts a new timer session with the specified duration.
    /// - Parameters:
    ///   - seconds: The duration of the timer in seconds.
    ///   - onTick: Optional callback invoked on each tick with remaining seconds.
    ///   - onComplete: Optional callback invoked when the timer completes.
    func start(
        seconds: TimeInterval,
        onTick: ((TimeInterval) -> Void)?,
        onComplete: (() -> Void)?
    )

    /// Pauses the currently running timer.
    func pause()

    /// Resumes a paused timer.
    func resume()

    /// Stops the timer and resets all state.
    func stop()

    /// Captures and returns the current remaining time.
    /// - Returns: The remaining time in seconds, or nil if no timer is active.
    func captureRemainingTime() -> TimeInterval?

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
        onTick: ((TimeInterval) -> Void)?,
        onComplete: (() -> Void)?
    )

    /// Adds time to the current timer session.
    /// - Parameter seconds: The number of seconds to add (can be negative to subtract).
    func addTime(_ seconds: TimeInterval)
}
