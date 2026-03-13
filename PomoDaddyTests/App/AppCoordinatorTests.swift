//
//  AppCoordinatorTests.swift
//  PomoDaddyTests
//
//  Tests for AppCoordinator control methods and settings sync using protocol-based mocks.
//

import XCTest
@testable import PomoDaddy

@MainActor
final class AppCoordinatorTests: XCTestCase {
    var coordinator: AppCoordinator!
    var mockTimerEngine: MockTimerEngine!
    var mockNotificationScheduler: MockNotificationScheduler!
    var mockSessionRecorder: MockSessionRecorder!
    var mockAppNapManager: MockAppNapManager!
    var mockSessionCoordinator: MockSessionCoordinator!
    var mockFloatingWindowCoordinator: MockFloatingWindowCoordinator!
    var mockSettingsManager: MockSettingsManager!

    override func setUp() {
        super.setUp()

        mockTimerEngine = MockTimerEngine()
        mockNotificationScheduler = MockNotificationScheduler()
        mockSessionRecorder = MockSessionRecorder()
        mockAppNapManager = MockAppNapManager()
        mockSessionCoordinator = MockSessionCoordinator()
        mockFloatingWindowCoordinator = MockFloatingWindowCoordinator()
        mockSettingsManager = MockSettingsManager()

        // Use isolated UserDefaults per test to prevent cross-test state leakage
        let isolatedPersistence = StateMachinePersistence(
            defaults: UserDefaults(suiteName: "test.coordinator.\(UUID())")!
        )

        coordinator = AppCoordinator(
            modelContainer: TestHelpers.createTestContainer(),
            settingsManager: mockSettingsManager,
            timerEngine: mockTimerEngine,
            notificationScheduler: mockNotificationScheduler,
            sessionRecorder: mockSessionRecorder,
            appNapManager: mockAppNapManager,
            sessionCoordinator: mockSessionCoordinator,
            floatingWindowCoordinator: mockFloatingWindowCoordinator,
            persistence: isolatedPersistence
        )
    }

    override func tearDown() {
        coordinator = nil
        mockTimerEngine = nil
        mockNotificationScheduler = nil
        mockSessionRecorder = nil
        mockAppNapManager = nil
        mockSessionCoordinator = nil
        mockFloatingWindowCoordinator = nil
        mockSettingsManager = nil
        super.tearDown()
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
        XCTAssertEqual(mockTimerEngine.startCallCount, 1)
    }

    func testStartWithIntervalType() {
        coordinator.start(intervalType: .shortBreak)
        XCTAssertEqual(coordinator.currentState, .running(.shortBreak))
        XCTAssertEqual(mockTimerEngine.startCallCount, 1)
    }

    func testPause() {
        coordinator.start()
        coordinator.pause()
        XCTAssertTrue(coordinator.currentState.isPaused)
        XCTAssertEqual(mockTimerEngine.pauseCallCount, 1)
    }

    func testResume() {
        coordinator.start()
        coordinator.pause()
        coordinator.resume()
        XCTAssertTrue(coordinator.currentState.isRunning)
        XCTAssertEqual(mockTimerEngine.resumeCallCount, 1)
    }

    func testReset() {
        coordinator.start()
        coordinator.reset()
        XCTAssertEqual(coordinator.currentState, .idle)
        XCTAssertEqual(mockTimerEngine.stopCallCount, 1) // reset calls stop
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
        mockSettingsManager.setWorkDuration(minutes: 50)
        XCTAssertEqual(coordinator.stateMachine.settings.workDuration, 50 * 60.0)
    }

    // MARK: - Session Tracking

    func testStartTracksSessionForWork() {
        coordinator.start()
        XCTAssertEqual(mockSessionCoordinator.startSessionCallCount, 1)
    }

    func testStartBreakDoesNotTrackSession() {
        coordinator.start(intervalType: .shortBreak)
        XCTAssertEqual(mockSessionCoordinator.startSessionCallCount, 0)
    }

    func testResetClearsSession() {
        coordinator.start()
        coordinator.reset()
        XCTAssertEqual(mockSessionCoordinator.clearSessionCallCount, 1)
    }

    func testSkipClearsSession() {
        coordinator.start()
        coordinator.skip()
        XCTAssertEqual(mockSessionCoordinator.clearSessionCallCount, 1)
    }

    // MARK: - Callback Wiring

    func testWorkCompletionTriggersSessionRecording() async {
        coordinator.start()

        // Simulate timer completing
        mockTimerEngine.simulateCompletion()

        // Allow async work to complete
        await assertEventually(timeout: 2.0) {
            self.mockSessionCoordinator.completeSessionCallCount == 1
        }
    }

    func testWorkCompletionNotifiesWhenEnabled() {
        mockSettingsManager.update { $0.showNotifications = true }
        coordinator.start()
        mockTimerEngine.simulateCompletion()

        XCTAssertEqual(mockNotificationScheduler.scheduleCompletionCallCount, 1)
        XCTAssertEqual(mockNotificationScheduler.lastScheduledIntervalType, .work)
    }

    func testWorkCompletionDoesNotNotifyWhenDisabled() {
        mockSettingsManager.update { $0.showNotifications = false }
        coordinator.start()
        mockTimerEngine.simulateCompletion()

        XCTAssertEqual(mockNotificationScheduler.scheduleCompletionCallCount, 0)
    }

    func testStateChangeToRunningBeginsAppNapActivity() {
        coordinator.start()
        XCTAssertEqual(mockAppNapManager.beginCallCount, 1)
    }

    func testStateChangeToIdleEndsAppNapActivity() {
        coordinator.start()
        coordinator.reset()
        XCTAssertEqual(mockAppNapManager.endCallCount, 1)
    }

    // MARK: - Floating Window

    func testFloatingWindowCoordinatorReceivesAppCoordinator() {
        XCTAssertEqual(mockFloatingWindowCoordinator.setAppCoordinatorCallCount, 1)
    }
}
