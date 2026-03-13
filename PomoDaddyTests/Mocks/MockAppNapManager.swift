//
//  MockAppNapManager.swift
//  PomoDaddyTests
//
//  Mock App Nap manager for testing.
//

import Foundation
@testable import PomoDaddy

/// Mock App Nap manager that tracks method calls.
final class MockAppNapManager: AppNapManaging {
    // MARK: - Call Tracking

    private(set) var beginCallCount = 0
    private(set) var endCallCount = 0
    private(set) var setTimingActiveCallCount = 0
    private(set) var lastSetTimingActiveValue: Bool?

    // MARK: - Protocol Properties

    var isTimingActivityActive: Bool { beginCallCount > endCallCount }

    // MARK: - Protocol Methods

    func beginTimingActivity() {
        beginCallCount += 1
    }

    func endTimingActivity() {
        endCallCount += 1
    }

    func setTimingActive(_ isActive: Bool) {
        setTimingActiveCallCount += 1
        lastSetTimingActiveValue = isActive
        if isActive {
            beginTimingActivity()
        } else {
            endTimingActivity()
        }
    }
}
