import XCTest
@testable import PomoDaddy

@MainActor
final class PomodoroStateMachineTests: XCTestCase {
    var stateMachine: PomodoroStateMachine!
    var mockDefaults: MockUserDefaults!

    override func setUp() {
        super.setUp()
        mockDefaults = MockUserDefaults()

        let settings = PomodoroSettings(
            workDurationMinutes: 1, // 1 minute for faster tests
            shortBreakDurationMinutes: 1, // Round up from 30 seconds
            longBreakDurationMinutes: 1, // Round up from 45 seconds
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
        stateMachine = PomodoroStateMachine(timerEngine: TimerEngine(), settings: settings, persistence: persistence)
    }

    override func tearDown() {
        stateMachine = nil
        mockDefaults = nil
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

    func testPause() async {
        stateMachine.send(.start(.work))
        XCTAssertTrue(stateMachine.isRunning)

        try? await Task.sleep(nanoseconds: 100_000_000)
        stateMachine.send(.pause)

        XCTAssertEqual(stateMachine.currentState, .paused(.work))
        XCTAssertFalse(stateMachine.isRunning)
    }

    func testResume() async {
        stateMachine.send(.start(.work))
        try? await Task.sleep(nanoseconds: 100_000_000)

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

    func testCompleteWorkSession() async {
        var workCompleted = false
        stateMachine.onWorkSessionComplete = { _ in
            workCompleted = true
        }

        stateMachine.send(.start(.work))

        // Wait for completion (using short duration)
        await assertEventually(timeout: 70.0) {
            workCompleted
        }

        XCTAssertTrue(workCompleted)
        XCTAssertEqual(stateMachine.completedPomodorosInCycle, 1)
        XCTAssertEqual(stateMachine.totalCompletedToday, 1)
    }

    func testCompleteShortBreak() async {
        var breakCompleted = false
        stateMachine.onBreakComplete = { type in
            breakCompleted = true
            XCTAssertEqual(type, .shortBreak)
        }

        stateMachine.send(.start(.shortBreak))

        await assertEventually(timeout: 70.0) {
            breakCompleted
        }

        XCTAssertTrue(breakCompleted)
    }

    func testCompleteLongBreak() async {
        var cycleCompleted = false
        stateMachine.onCycleComplete = { _ in
            cycleCompleted = true
        }

        // Complete enough work sessions to trigger long break
        stateMachine.send(.start(.work))
        stateMachine.send(.complete) // Simulate completion
        stateMachine.send(.start(.work))
        stateMachine.send(.complete) // Second work session

        // Now complete long break
        stateMachine.send(.start(.longBreak))
        stateMachine.send(.complete)

        await assertEventually(timeout: 70.0) {
            cycleCompleted
        }

        XCTAssertTrue(cycleCompleted)
        XCTAssertEqual(stateMachine.completedPomodorosInCycle, 0) // Reset after long break
    }

    // MARK: - Reset Tests

    func testReset() async {
        stateMachine.send(.start(.work))
        try? await Task.sleep(nanoseconds: 100_000_000)

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

    func testAutoStartBreakAfterWork() async {
        var workCompleted = false
        stateMachine.settings.autoStartBreaks = true

        stateMachine.onWorkSessionComplete = { _ in
            workCompleted = true
        }

        stateMachine.send(.start(.work))
        stateMachine.send(.complete)

        await assertEventually(timeout: 70.0) {
            workCompleted
        }

        // Should auto-start break
        XCTAssertEqual(stateMachine.currentState, .running(.shortBreak))
    }

    func testNoAutoStartBreakWhenDisabled() async {
        var workCompleted = false
        stateMachine.settings.autoStartBreaks = false

        stateMachine.onWorkSessionComplete = { _ in
            workCompleted = true
        }

        stateMachine.send(.start(.work))
        stateMachine.send(.complete)

        await assertEventually(timeout: 70.0) {
            workCompleted
        }

        // Should remain idle
        XCTAssertEqual(stateMachine.currentState, .idle)
    }

    func testAutoStartWorkAfterBreak() async {
        var breakCompleted = false
        stateMachine.settings.autoStartWork = true

        stateMachine.onBreakComplete = { _ in
            breakCompleted = true
        }

        stateMachine.send(.start(.shortBreak))
        stateMachine.send(.complete)

        await assertEventually(timeout: 70.0) {
            breakCompleted
        }

        // Should auto-start work
        XCTAssertEqual(stateMachine.currentState, .running(.work))
    }

    // MARK: - State Change Callback Tests

    func testStateChangeCallback() async {
        var stateChanges: [(TimerState, TimerState)] = []
        stateMachine.onStateChange = { old, new in
            stateChanges.append((old, new))
        }

        stateMachine.send(.start(.work))

        try? await Task.sleep(nanoseconds: 100_000_000)
        stateMachine.send(.pause)

        try? await Task.sleep(nanoseconds: 100_000_000)
        stateMachine.send(.resume)

        stateMachine.send(.reset)

        // Should have recorded all state changes
        XCTAssertGreaterThan(stateChanges.count, 0)
    }

    // MARK: - Persistence Tests

    func testStatePersistence() {
        // Use a shared persistence instance to simulate app restart
        let sharedPersistence = StateMachinePersistence(
            defaults: UserDefaults(suiteName: "test.persistence.\(UUID())")!
        )
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

        // Start a work session with the shared persistence
        let firstMachine = PomodoroStateMachine(
            timerEngine: MockTimerEngine(), settings: settings, persistence: sharedPersistence
        )
        firstMachine.send(.start(.work))

        // Create a new state machine with the same persistence (simulating app restart)
        let newStateMachine = PomodoroStateMachine(
            timerEngine: MockTimerEngine(), settings: settings, persistence: sharedPersistence
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

    func testProgress() async {
        stateMachine.send(.start(.work))

        // Initial progress should be near 0
        XCTAssertEqual(stateMachine.progress, 0, accuracy: 0.1)

        // Wait for some time to pass
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

        // Progress should have increased
        XCTAssertGreaterThan(stateMachine.progress, 0)
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

    func testRapidEventSequence() async {
        stateMachine.send(.start(.work))
        XCTAssertEqual(stateMachine.currentState, .running(.work))

        try? await Task.sleep(nanoseconds: 50_000_000)
        stateMachine.send(.pause)
        XCTAssertEqual(stateMachine.currentState, .paused(.work))

        stateMachine.send(.resume)
        XCTAssertEqual(stateMachine.currentState, .running(.work))

        try? await Task.sleep(nanoseconds: 50_000_000)
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
}
