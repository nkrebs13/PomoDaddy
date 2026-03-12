//
//  AppCoordinatorTests.swift
//  PomoDaddyTests
//
//  Tests for AppCoordinator control methods and settings sync.
//

import XCTest
@testable import PomoDaddy

@MainActor
final class AppCoordinatorTests: XCTestCase {
    /// Shared coordinator — created once per test class to avoid repeated
    /// ModelContainer + notification-auth overhead that causes the first
    /// test in each process to fail.
    private static var sharedCoordinator: AppCoordinator!

    var coordinator: AppCoordinator {
        Self.sharedCoordinator
    }

    override class func setUp() {
        super.setUp()
        sharedCoordinator = AppCoordinator()
    }

    override class func tearDown() {
        sharedCoordinator = nil
        super.tearDown()
    }

    override func setUp() {
        super.setUp()
        // Reset to idle before each test
        coordinator.reset()
    }

    // MARK: - Initial State

    func testInitialState() {
        XCTAssertEqual(coordinator.currentState, .idle)
        XCTAssertFalse(coordinator.isRunning)
        XCTAssertEqual(coordinator.completedPomodorosInCycle, 0)
    }

    // MARK: - Timer Control

    func testStart() {
        coordinator.start()
        XCTAssertTrue(coordinator.currentState.isRunning)
        XCTAssertEqual(coordinator.currentState, .running(.work))
    }

    func testPause() {
        coordinator.start()
        coordinator.pause()
        XCTAssertTrue(coordinator.currentState.isPaused)
    }

    func testResume() {
        coordinator.start()
        coordinator.pause()
        coordinator.resume()
        XCTAssertTrue(coordinator.currentState.isRunning)
    }

    func testReset() {
        coordinator.start()
        coordinator.reset()
        XCTAssertEqual(coordinator.currentState, .idle)
    }

    func testSkip() {
        coordinator.start()
        coordinator.skip()
        XCTAssertEqual(coordinator.currentState, .idle)
    }

    // MARK: - togglePlayPause

    func testTogglePlayPauseFromIdle() {
        coordinator.togglePlayPause()
        XCTAssertTrue(coordinator.currentState.isRunning)
    }

    func testTogglePlayPauseFromRunning() {
        coordinator.start()
        coordinator.togglePlayPause()
        XCTAssertTrue(coordinator.currentState.isPaused)
    }

    func testTogglePlayPauseFromPaused() {
        coordinator.start()
        coordinator.pause()
        coordinator.togglePlayPause()
        XCTAssertTrue(coordinator.currentState.isRunning)
    }

    // MARK: - Settings Sync

    func testUpdateSettingsSyncsToStateMachine() {
        let newDuration = 50 * 60.0 // 50 minutes
        coordinator.settingsManager.setWorkDuration(minutes: 50)

        // Settings sync happens via onChange callback
        XCTAssertEqual(coordinator.stateMachine.settings.workDuration, newDuration)

        // Restore default
        coordinator.settingsManager.setWorkDuration(minutes: 25)
    }

    func testSettingsManagerOnChangeTriggersSync() {
        coordinator.settingsManager.setShortBreakDuration(minutes: 10)

        // onChange callback should have called updateSettings()
        XCTAssertEqual(
            coordinator.stateMachine.settings.shortBreakDuration,
            10 * 60.0
        )

        // Restore default
        coordinator.settingsManager.setShortBreakDuration(minutes: 5)
    }

    // MARK: - Session Tracking

    func testStartTracksSessionForWork() {
        coordinator.start()
        // After starting work, sessionCoordinator should have a start time
        XCTAssertNotNil(coordinator.sessionCoordinator.currentSessionStartTime)
    }

    func testStartBreakDoesNotTrackSession() {
        coordinator.start(intervalType: .shortBreak)
        // Break intervals should not track sessions
        XCTAssertNil(coordinator.sessionCoordinator.currentSessionStartTime)
    }

    func testResetClearsSession() {
        coordinator.start()
        XCTAssertNotNil(coordinator.sessionCoordinator.currentSessionStartTime)

        coordinator.reset()
        XCTAssertNil(coordinator.sessionCoordinator.currentSessionStartTime)
    }

    func testSkipClearsSession() {
        coordinator.start()
        XCTAssertNotNil(coordinator.sessionCoordinator.currentSessionStartTime)

        coordinator.skip()
        XCTAssertNil(coordinator.sessionCoordinator.currentSessionStartTime)
    }
}
