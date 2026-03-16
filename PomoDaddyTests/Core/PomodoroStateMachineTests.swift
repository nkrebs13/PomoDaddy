import XCTest
@testable import PomoDaddy

@MainActor
final class PomodoroStateMachineTests: XCTestCase {
    var stateMachine: PomodoroStateMachine!
    var mockTimerEngine: MockTimerEngine!

    override func setUp() {
        super.setUp()
        mockTimerEngine = MockTimerEngine()

        let settings = PomodoroSettings(
            workDurationMinutes: 1,
            shortBreakDurationMinutes: 1,
            longBreakDurationMinutes: 1,
            pomodorosUntilLongBreak: 2,
            autoStartBreaks: false,
            autoStartWork: false,
            showNotifications: true,
            showFloatingWindow: true,
            showMenuBarCountdown: true
        )
        // Use isolated UserDefaults per test to prevent cross-test state leakage
        let persistence = StateMachinePersistence(
            defaults: UserDefaults(suiteName: "test.statemachine.\(UUID())")!
        )
        stateMachine = PomodoroStateMachine(timerEngine: mockTimerEngine, settings: settings, persistence: persistence)
    }

    override func tearDown() {
        stateMachine = nil
        mockTimerEngine = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        XCTAssertEqual(stateMachine.currentState, .idle)
        XCTAssertEqual(stateMachine.completedPomodorosInCycle, 0)
        XCTAssertEqual(stateMachine.totalCompletedToday, 0)
        XCTAssertFalse(stateMachine.isRunning)
    }

    // MARK: - Start Tests

    func testStartWork() {
        stateMachine.send(.start(.work))

        XCTAssertEqual(stateMachine.currentState, .running(.work))
        XCTAssertTrue(stateMachine.isRunning)
        XCTAssertEqual(stateMachine.formattedTime, "01:00")
    }

    func testStartWithoutIntervalType() {
        stateMachine.send(.start())

        // Should start work session by default
        XCTAssertEqual(stateMachine.currentState, .running(.work))
    }

    func testStartShortBreak() {
        stateMachine.send(.start(.shortBreak))

        XCTAssertEqual(stateMachine.currentState, .running(.shortBreak))
        XCTAssertEqual(stateMachine.formattedTime, "01:00")
    }

    func testStartLongBreak() {
        stateMachine.send(.start(.longBreak))

        XCTAssertEqual(stateMachine.currentState, .running(.longBreak))
        XCTAssertEqual(stateMachine.formattedTime, "01:00")
    }

    // MARK: - Pause/Resume Tests

    func testPause() {
        stateMachine.send(.start(.work))
        XCTAssertTrue(stateMachine.isRunning)

        stateMachine.send(.pause)

        XCTAssertEqual(stateMachine.currentState, .paused(.work))
        XCTAssertFalse(stateMachine.isRunning)
    }

    func testResume() {
        stateMachine.send(.start(.work))

        stateMachine.send(.pause)
        XCTAssertFalse(stateMachine.isRunning)

        stateMachine.send(.resume)
        XCTAssertEqual(stateMachine.currentState, .running(.work))
        XCTAssertTrue(stateMachine.isRunning)
    }

    func testPauseWhenIdle() {
        stateMachine.send(.pause)
        // Should remain idle, no crash
        XCTAssertEqual(stateMachine.currentState, .idle)
    }

    func testResumeWhenIdle() {
        stateMachine.send(.resume)
        // Should remain idle, no crash
        XCTAssertEqual(stateMachine.currentState, .idle)
    }

    // MARK: - Complete Tests

    func testCompleteWorkSession() {
        var workCompleted = false
        stateMachine.onWorkSessionComplete = { _ in
            workCompleted = true
        }

        stateMachine.send(.start(.work))
        stateMachine.send(.complete)

        XCTAssertTrue(workCompleted)
        XCTAssertEqual(stateMachine.completedPomodorosInCycle, 1)
        XCTAssertEqual(stateMachine.totalCompletedToday, 1)
    }

    func testCompleteShortBreak() {
        var breakCompleted = false
        stateMachine.onBreakComplete = { type in
            breakCompleted = true
            XCTAssertEqual(type, .shortBreak)
        }

        stateMachine.send(.start(.shortBreak))
        stateMachine.send(.complete)

        XCTAssertTrue(breakCompleted)
    }

    func testCompleteLongBreak() {
        var cycleCompleted = false
        stateMachine.onCycleComplete = { _ in
            cycleCompleted = true
        }

        // Complete enough work sessions to trigger long break
        stateMachine.send(.start(.work))
        stateMachine.send(.complete)
        stateMachine.send(.start(.work))
        stateMachine.send(.complete)

        // Now complete long break
        stateMachine.send(.start(.longBreak))
        stateMachine.send(.complete)

        XCTAssertTrue(cycleCompleted)
        XCTAssertEqual(stateMachine.completedPomodorosInCycle, 0) // Reset after long break
    }

    // MARK: - Reset Tests

    func testReset() {
        stateMachine.send(.start(.work))

        stateMachine.send(.reset)

        XCTAssertEqual(stateMachine.currentState, .idle)
        XCTAssertEqual(stateMachine.completedPomodorosInCycle, 0)
        XCTAssertFalse(stateMachine.isRunning)
        XCTAssertEqual(stateMachine.formattedTime, "00:00")
    }

    func testResetDoesNotResetTotalCompletedToday() {
        // Complete a work session
        stateMachine.send(.start(.work))
        stateMachine.send(.complete)

        let totalBefore = stateMachine.totalCompletedToday
        XCTAssertEqual(totalBefore, 1)

        stateMachine.send(.reset)

        // Total should remain
        XCTAssertEqual(stateMachine.totalCompletedToday, totalBefore)
    }

    // MARK: - Skip Tests

    func testSkip() {
        stateMachine.send(.start(.work))
        XCTAssertTrue(stateMachine.isRunning)

        stateMachine.send(.skip)

        XCTAssertEqual(stateMachine.currentState, .idle)
        XCTAssertFalse(stateMachine.isRunning)
        // Skip should not increase completed count
        XCTAssertEqual(stateMachine.totalCompletedToday, 0)
    }

    func testSkipWhenIdle() {
        stateMachine.send(.skip)
        // Should remain idle, no crash
        XCTAssertEqual(stateMachine.currentState, .idle)
    }

    // MARK: - Next Interval Tests

    func testNextIntervalAfterWork() {
        stateMachine.send(.start(.work))

        let next = stateMachine.nextIntervalType()
        XCTAssertEqual(next, .shortBreak)
    }

    func testNextIntervalAfterShortBreak() {
        stateMachine.send(.start(.shortBreak))

        let next = stateMachine.nextIntervalType()
        XCTAssertEqual(next, .work)
    }

    func testNextIntervalAfterMultipleWorkSessions() {
        // Complete first work session
        stateMachine.send(.start(.work))
        stateMachine.send(.complete)

        // Complete second work session (reaches threshold of 2)
        stateMachine.send(.start(.work))
        stateMachine.send(.complete)

        // After second work session, should get long break
        let next = stateMachine.nextIntervalType()
        XCTAssertEqual(next, .longBreak)
    }

    func testNextIntervalWhenIdle() {
        let next = stateMachine.nextIntervalType()
        XCTAssertEqual(next, .work)
    }

    // MARK: - Auto-Start Tests

    func testAutoStartBreakAfterWork() {
        stateMachine.settings.autoStartBreaks = true

        stateMachine.send(.start(.work))
        stateMachine.send(.complete)

        // Should auto-start break
        XCTAssertEqual(stateMachine.currentState, .running(.shortBreak))
    }

    func testNoAutoStartBreakWhenDisabled() {
        stateMachine.settings.autoStartBreaks = false

        stateMachine.send(.start(.work))
        stateMachine.send(.complete)

        // Should remain idle
        XCTAssertEqual(stateMachine.currentState, .idle)
    }

    func testAutoStartWorkAfterBreak() {
        stateMachine.settings.autoStartWork = true

        stateMachine.send(.start(.shortBreak))
        stateMachine.send(.complete)

        // Should auto-start work
        XCTAssertEqual(stateMachine.currentState, .running(.work))
    }

    // MARK: - State Change Callback Tests

    func testStateChangeCallback() {
        var stateChanges: [(TimerState, TimerState)] = []
        stateMachine.onStateChange = { old, new in
            stateChanges.append((old, new))
        }

        stateMachine.send(.start(.work))
        stateMachine.send(.pause)
        stateMachine.send(.resume)
        stateMachine.send(.reset)

        // Should have recorded all state changes: idle→running, running→paused, paused→running, running→idle
        XCTAssertEqual(stateChanges.count, 4)
    }

    // MARK: - Persistence Tests

    func testStatePersistence() throws {
        // Use a shared persistence instance to simulate app restart
        let sharedPersistence = try StateMachinePersistence(
            defaults: XCTUnwrap(UserDefaults(suiteName: "test.persistence.\(UUID())"))
        )

        // Start a work session with the shared persistence
        let firstMachine = PomodoroStateMachine(
            timerEngine: MockTimerEngine(), settings: stateMachine.settings, persistence: sharedPersistence
        )
        firstMachine.send(.start(.work))

        // Create a new state machine with the same persistence (simulating app restart)
        let newStateMachine = PomodoroStateMachine(
            timerEngine: MockTimerEngine(), settings: stateMachine.settings, persistence: sharedPersistence
        )

        // Should restore state
        XCTAssertEqual(newStateMachine.currentState, .running(.work))
    }

    // MARK: - Daily Reset Tests

    func testDailyCountReset() {
        // This is hard to test without mocking dates
        // Verify that resetDailyCountIfNeeded doesn't crash
        stateMachine.send(.start(.work))
        stateMachine.send(.complete)

        XCTAssertEqual(stateMachine.totalCompletedToday, 1)
    }

    // MARK: - Duration Tests

    func testDurationForIntervalTypes() {
        XCTAssertEqual(stateMachine.duration(for: .work), 60)
        XCTAssertEqual(stateMachine.duration(for: .shortBreak), 60)
        XCTAssertEqual(stateMachine.duration(for: .longBreak), 60)
    }

    // MARK: - Progress Tests

    func testProgress() {
        stateMachine.send(.start(.work))

        // Initial progress should be 0 (mock starts at full remaining)
        XCTAssertEqual(stateMachine.progress, 0, accuracy: 0.01)

        // Simulate partial progress via mock tick
        mockTimerEngine.simulateTick(remaining: 30) // Half of 60-second timer

        // Progress should reflect elapsed time
        XCTAssertEqual(stateMachine.progress, 0.5, accuracy: 0.01)
    }

    // MARK: - Cycle Tracking Tests

    func testPomodorosCycleTracking() {
        XCTAssertEqual(stateMachine.completedPomodorosInCycle, 0)

        // Complete first work session
        stateMachine.send(.start(.work))
        stateMachine.send(.complete)
        XCTAssertEqual(stateMachine.completedPomodorosInCycle, 1)

        // Complete second work session
        stateMachine.send(.start(.work))
        stateMachine.send(.complete)
        XCTAssertEqual(stateMachine.completedPomodorosInCycle, 2)

        // Complete long break - should reset cycle
        stateMachine.send(.start(.longBreak))
        stateMachine.send(.complete)
        XCTAssertEqual(stateMachine.completedPomodorosInCycle, 0)
    }

    // MARK: - Edge Case Tests

    func testCompleteWhenIdleIsNoOp() {
        XCTAssertEqual(stateMachine.currentState, .idle)
        stateMachine.send(.complete)
        XCTAssertEqual(stateMachine.currentState, .idle)
        XCTAssertEqual(stateMachine.completedPomodorosInCycle, 0)
        XCTAssertEqual(stateMachine.totalCompletedToday, 0)
    }

    func testNextIntervalTypeAtExactThreshold() {
        // Set pomodorosUntilLongBreak to 2
        // Complete exactly 2 pomodoros
        stateMachine.send(.start(.work))
        stateMachine.send(.complete)
        stateMachine.send(.start(.work))
        stateMachine.send(.complete)

        // At exact threshold, should return long break
        let next = stateMachine.nextIntervalType()
        XCTAssertEqual(next, .longBreak)
    }

    func testRapidEventSequence() {
        stateMachine.send(.start(.work))
        XCTAssertEqual(stateMachine.currentState, .running(.work))

        stateMachine.send(.pause)
        XCTAssertEqual(stateMachine.currentState, .paused(.work))

        stateMachine.send(.resume)
        XCTAssertEqual(stateMachine.currentState, .running(.work))

        stateMachine.send(.pause)
        XCTAssertEqual(stateMachine.currentState, .paused(.work))

        stateMachine.send(.resume)
        XCTAssertEqual(stateMachine.currentState, .running(.work))
    }

    func testTransitionAfterBreakWithAutoStartEnabled() {
        stateMachine.settings.autoStartWork = true
        stateMachine.send(.start(.shortBreak))
        stateMachine.send(.complete)

        // Should auto-start work
        XCTAssertEqual(stateMachine.currentState, .running(.work))
    }

    func testTransitionAfterBreakWithAutoStartDisabled() {
        stateMachine.settings.autoStartWork = false
        stateMachine.send(.start(.shortBreak))
        stateMachine.send(.complete)

        // Should go to idle
        XCTAssertEqual(stateMachine.currentState, .idle)
    }

    func testTransitionAfterLongBreakWithAutoStartEnabled() {
        stateMachine.settings.autoStartWork = true
        stateMachine.send(.start(.longBreak))
        stateMachine.send(.complete)

        XCTAssertEqual(stateMachine.currentState, .running(.work))
        XCTAssertEqual(stateMachine.completedPomodorosInCycle, 0)
    }

    func testTransitionAfterLongBreakWithAutoStartDisabled() {
        stateMachine.settings.autoStartWork = false
        stateMachine.send(.start(.longBreak))
        stateMachine.send(.complete)

        XCTAssertEqual(stateMachine.currentState, .idle)
        XCTAssertEqual(stateMachine.completedPomodorosInCycle, 0)
    }

    // MARK: - Additional Edge Cases

    func testResumeWhileRunningIsNoOp() {
        stateMachine.send(.start(.work))
        let stateBefore = stateMachine.currentState
        stateMachine.send(.resume)
        XCTAssertEqual(stateMachine.currentState, stateBefore)
    }

    func testDoubleStartResetsTimer() {
        stateMachine.send(.start(.work))
        stateMachine.send(.start(.shortBreak))
        XCTAssertEqual(stateMachine.currentState, .running(.shortBreak))
    }

    func testCycleCompletionCallbackFiresAfterLongBreak() {
        var callbackFired = false
        stateMachine.onCycleComplete = { _ in callbackFired = true }

        // Complete enough work sessions to reach long break
        for _ in 0 ..< stateMachine.settings.pomodorosUntilLongBreak {
            stateMachine.send(.start(.work))
            stateMachine.send(.complete)
        }

        // Complete the long break
        stateMachine.send(.start(.longBreak))
        stateMachine.send(.complete)

        XCTAssertTrue(callbackFired)
    }

    func testStateChangeCallbackReceivesOldAndNewState() {
        var receivedOld: TimerState?
        var receivedNew: TimerState?
        stateMachine.onStateChange = { old, new in
            receivedOld = old
            receivedNew = new
        }

        stateMachine.send(.start(.work))

        XCTAssertEqual(receivedOld, .idle)
        XCTAssertEqual(receivedNew, .running(.work))
    }

    func testNextIntervalTypeAfterWorkBeforeLongBreak() {
        // With pomodorosUntilLongBreak = 2, after 1 work session
        // the next should be short break
        stateMachine.send(.start(.work))
        let nextType = stateMachine.nextIntervalType()
        XCTAssertEqual(nextType, .shortBreak)
    }

    func testFormattedTimeFromStateMachine() {
        // Just verify it returns a non-empty string
        let time = stateMachine.formattedTime
        XCTAssertFalse(time.isEmpty)
    }
}
