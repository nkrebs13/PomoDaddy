//
//  MockSessionCoordinator.swift
//  PomoDaddyTests
//
//  Mock session coordinator for testing.
//

import Foundation
@testable import PomoDaddy

/// Mock session coordinator that tracks method calls.
@Observable
@MainActor
final class MockSessionCoordinator: SessionCoordinating {
    // MARK: - Call Tracking

    private(set) var startSessionCallCount = 0
    private(set) var clearSessionCallCount = 0
    private(set) var completeSessionCallCount = 0
    private(set) var lastCompletedDurationMinutes: Int?

    // MARK: - Protocol Properties

    var currentSessionStartTime: Date?
    var showConfetti = false

    // MARK: - Protocol Methods

    func startSession() {
        startSessionCallCount += 1
        currentSessionStartTime = Date()
    }

    func clearSession() {
        clearSessionCallCount += 1
        currentSessionStartTime = nil
    }

    func completeSession(durationMinutes: Int) async {
        completeSessionCallCount += 1
        lastCompletedDurationMinutes = durationMinutes
        currentSessionStartTime = nil
        showConfetti = true
    }
}
