//
//  SessionRecording.swift
//  PomoDaddy
//
//  Protocol for session recording dependency injection.
//

import Foundation

/// Data for a single session to be batch-recorded.
internal struct SessionEntry {
    let startDate: Date
    let endDate: Date
    let durationMinutes: Int
    let wasCompleted: Bool
}

/// Protocol defining the session recording interface for dependency injection and testing.
///
/// Note: This protocol works with actor isolation — `SessionRecorder` is a `@ModelActor actor`,
/// so callers use `await` when calling these methods.
internal protocol SessionRecording: Actor {
    /// Records a completed pomodoro session with the given parameters.
    /// - Parameters:
    ///   - startDate: When the session started.
    ///   - endDate: When the session ended.
    ///   - durationMinutes: The configured session duration in minutes.
    ///   - wasCompleted: Whether the session was completed fully.
    func record(
        startDate: Date,
        endDate: Date,
        durationMinutes: Int,
        wasCompleted: Bool
    ) throws

    /// Records multiple sessions in a single transaction.
    /// - Parameter entries: The session data to record.
    func recordBatch(_ entries: [SessionEntry]) throws
}
