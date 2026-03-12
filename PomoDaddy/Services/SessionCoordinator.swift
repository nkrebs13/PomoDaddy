//
//  SessionCoordinator.swift
//  PomoDaddy
//
//  Coordinates session tracking, recording, and celebration animations.
//

import Foundation
import Observation

/// Coordinates work session tracking and completion celebrations.
@Observable
@MainActor
final class SessionCoordinator {
    // MARK: - Properties

    /// The session recorder for persisting sessions.
    private let sessionRecorder: SessionRecorder

    /// The current work session start time (if in a work session).
    private(set) var currentSessionStartTime: Date?

    /// Whether to show confetti celebration.
    var showConfetti = false

    /// Task for hiding confetti after animation.
    private var confettiHideTask: Task<Void, Never>?

    // MARK: - Initialization

    init(sessionRecorder: SessionRecorder) {
        self.sessionRecorder = sessionRecorder
    }


    // MARK: - Session Management

    /// Starts tracking a work session.
    func startSession() {
        currentSessionStartTime = Date()
    }

    /// Clears the current session tracking.
    func clearSession() {
        currentSessionStartTime = nil
    }

    /// Records a completed work session and triggers celebration.
    /// - Parameter durationMinutes: The configured work duration in minutes.
    func completeSession(durationMinutes: Int) async {
        guard let startTime = currentSessionStartTime else { return }

        let endTime = Date()

        // Record the session
        do {
            try await sessionRecorder.record(
                startDate: startTime,
                endDate: endTime,
                durationMinutes: durationMinutes,
                wasCompleted: true
            )
        } catch {
            Logger.logError(error, context: "Failed to record session", log: Logger.stats)
        }

        // Clear session tracking
        currentSessionStartTime = nil

        // Trigger celebration
        triggerConfetti()
    }

    /// Triggers the confetti celebration animation.
    func triggerConfetti() {
        showConfetti = true

        // Reset confetti after animation
        confettiHideTask?.cancel()
        confettiHideTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: AppConstants.Confetti.durationNanoseconds)
            guard !Task.isCancelled else { return }
            self?.showConfetti = false
        }
    }
}
