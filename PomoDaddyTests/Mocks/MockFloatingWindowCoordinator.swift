//
//  MockFloatingWindowCoordinator.swift
//  PomoDaddyTests
//
//  Mock floating window coordinator for testing.
//

import Foundation
@testable import PomoDaddy

/// Mock floating window coordinator that tracks method calls.
@MainActor
final class MockFloatingWindowCoordinator: FloatingWindowCoordinating {
    // MARK: - Call Tracking

    private(set) var showCallCount = 0
    private(set) var hideCallCount = 0
    private(set) var toggleCallCount = 0
    private(set) var savePositionCallCount = 0
    private(set) var setAppCoordinatorCallCount = 0

    // MARK: - Protocol Methods

    func show() {
        showCallCount += 1
    }

    func hide() {
        hideCallCount += 1
    }

    func toggle() {
        toggleCallCount += 1
    }

    func savePosition() {
        savePositionCallCount += 1
    }

    func setAppCoordinator(_ coordinator: AppCoordinator) {
        setAppCoordinatorCallCount += 1
    }
}
