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
        await assertEventually(timeout: 0.5) {
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

    // MARK: - Facade Properties

    func testSettingsPropertyReturnsCurrent() {
        XCTAssertEqual(coordinator.settings, mockSettingsManager.settings)
    }

    func testAutoStartBreaksGetterReflectsSettings() {
        mockSettingsManager.update { $0.autoStartBreaks = true }
        XCTAssertTrue(coordinator.autoStartBreaks)

        mockSettingsManager.update { $0.autoStartBreaks = false }
        XCTAssertFalse(coordinator.autoStartBreaks)
    }

    func testAutoStartBreaksSetterUpdatesSettings() {
        coordinator.autoStartBreaks = true
        XCTAssertTrue(mockSettingsManager.settings.autoStartBreaks)

        coordinator.autoStartBreaks = false
        XCTAssertFalse(mockSettingsManager.settings.autoStartBreaks)
    }

    func testAutoStartWorkGetterReflectsSettings() {
        mockSettingsManager.update { $0.autoStartWork = true }
        XCTAssertTrue(coordinator.autoStartWork)
    }

    func testAutoStartWorkSetterUpdatesSettings() {
        coordinator.autoStartWork = true
        XCTAssertTrue(mockSettingsManager.settings.autoStartWork)
    }

    func testCurrentIntervalTypeIsNilWhenIdle() {
        XCTAssertNil(coordinator.currentIntervalType)
    }

    func testCurrentIntervalTypeIsWorkWhenRunning() {
        coordinator.start()
        XCTAssertEqual(coordinator.currentIntervalType, .work)
    }

    func testPomodorosUntilLongBreakReflectsSettings() {
        XCTAssertEqual(coordinator.pomodorosUntilLongBreak, mockSettingsManager.settings.pomodorosUntilLongBreak)
    }

    func testIsMenuBarCountdownVisibleSetterUpdatesSettings() {
        coordinator.isMenuBarCountdownVisible = false
        XCTAssertFalse(mockSettingsManager.settings.showMenuBarCountdown)

        coordinator.isMenuBarCountdownVisible = true
        XCTAssertTrue(mockSettingsManager.settings.showMenuBarCountdown)
    }

    func testSaveStateSavesFloatingWindowPosition() {
        coordinator.saveState()
        XCTAssertEqual(mockFloatingWindowCoordinator.savePositionCallCount, 1)
    }

    func testRestoreStateShowsFloatingWindowWhenEnabled() {
        mockSettingsManager.update { $0.showFloatingWindow = true }
        coordinator.restoreState()
        XCTAssertEqual(mockFloatingWindowCoordinator.showCallCount, 1)
    }

    func testRestoreStateDoesNotShowFloatingWindowWhenDisabled() {
        mockSettingsManager.update { $0.showFloatingWindow = false }
        coordinator.restoreState()
        XCTAssertEqual(mockFloatingWindowCoordinator.showCallCount, 0)
    }

    // MARK: - Break Completion Notifications

    func testBreakCompletionNotifiesWhenEnabled() {
        mockSettingsManager.update { $0.showNotifications = true }
        coordinator.start(intervalType: .shortBreak)
        mockTimerEngine.simulateCompletion()

        XCTAssertEqual(mockNotificationScheduler.scheduleCompletionCallCount, 1)
        XCTAssertEqual(mockNotificationScheduler.lastScheduledIntervalType, .shortBreak)
    }

    func testBreakCompletionDoesNotNotifyWhenDisabled() {
        mockSettingsManager.update { $0.showNotifications = false }
        coordinator.start(intervalType: .shortBreak)
        mockTimerEngine.simulateCompletion()

        XCTAssertEqual(mockNotificationScheduler.scheduleCompletionCallCount, 0)
    }

    // MARK: - Error Path & Multi-Cycle Tests

    func testCoordinatorFunctionsAfterWorkCompletion() {
        coordinator.start()
        mockTimerEngine.simulateCompletion()

        // After completion, coordinator may auto-start break or go idle
        // (depends on default settings). Either way, reset and verify clean state.
        coordinator.reset()
        XCTAssertEqual(coordinator.currentState, .idle)

        // Coordinator should still be fully functional after reset
        coordinator.start()
        XCTAssertTrue(coordinator.currentState.isRunning)
        coordinator.pause()
        XCTAssertTrue(coordinator.currentState.isPaused)
        coordinator.resume()
        XCTAssertTrue(coordinator.currentState.isRunning)
    }

    func testResetAfterCompletionLeavesCleanState() async {
        coordinator.start()
        mockTimerEngine.simulateCompletion()

        await assertEventually(timeout: 0.5) {
            self.mockSessionCoordinator.completeSessionCallCount == 1
        }

        coordinator.reset()
        XCTAssertEqual(coordinator.currentState, .idle)
        XCTAssertFalse(coordinator.isRunning)
        XCTAssertEqual(mockSessionCoordinator.clearSessionCallCount, 1)
    }
}
