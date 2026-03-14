//
//  SessionCoordinating.swift
//  PomoDaddy
//
//  Protocol for session coordination dependency injection.
//

import Foundation

/// Protocol defining the session coordination interface for dependency injection and testing.
@MainActor
protocol SessionCoordinating: AnyObject {
    /// The current work session start time (if in a work session).
    var currentSessionStartTime: Date? { get }

    /// Whether to show confetti celebration.
    var showConfetti: Bool { get set }

    /// Starts tracking a work session.
    func startSession()

    /// Clears the current session tracking.
    func clearSession()

    /// Records a completed work session and triggers celebration.
    /// - Parameter durationMinutes: The configured work duration in minutes.
    func completeSession(durationMinutes: Int) async
}
