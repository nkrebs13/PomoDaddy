//
//  MockNotificationScheduler.swift
//  PomoDaddyTests
//
//  Mock notification scheduler for testing.
//

import Foundation
@testable import PomoDaddy

/// Mock notification scheduler that tracks method calls.
final class MockNotificationScheduler: NotificationScheduling {
    // MARK: - Call Tracking

    private(set) var requestAuthorizationCallCount = 0
    private(set) var checkAuthorizationStatusCallCount = 0
    private(set) var scheduleCompletionCallCount = 0
    private(set) var cancelPendingCallCount = 0
    private(set) var clearDeliveredCallCount = 0
    private(set) var registerCategoriesCallCount = 0

    private(set) var lastScheduledIntervalType: IntervalType?
    private(set) var lastScheduledSeconds: Int?
    private(set) var lastScheduledSilent: Bool?

    // MARK: - Configurable Returns

    var authorizationResult = true

    // MARK: - Protocol Methods

    func requestAuthorization() async -> Bool {
        requestAuthorizationCallCount += 1
        return authorizationResult
    }

    func checkAuthorizationStatus() async -> Bool {
        checkAuthorizationStatusCallCount += 1
        return authorizationResult
    }

    func scheduleCompletion(intervalType: IntervalType, inSeconds: Int, silent: Bool) {
        scheduleCompletionCallCount += 1
        lastScheduledIntervalType = intervalType
        lastScheduledSeconds = inSeconds
        lastScheduledSilent = silent
    }

    func cancelPending() {
        cancelPendingCallCount += 1
    }

    func clearDelivered() {
        clearDeliveredCallCount += 1
    }

    func registerCategories() {
        registerCategoriesCallCount += 1
    }
}
