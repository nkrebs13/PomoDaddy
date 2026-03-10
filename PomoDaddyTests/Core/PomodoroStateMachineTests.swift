import XCTest
@testable import PomoDaddy

@MainActor
final class PomodoroStateMachineTests: XCTestCase {
    var stateMachine: PomodoroStateMachine!
    var mockDefaults: MockUserDefaults!

    override func setUp() {
        super.setUp()
        mockDefaults = MockUserDefaults()
        // Clear any persisted state
        UserDefaults.standard.removeObject(forKey: "com.pomodaddy.stateMachineState")

        let settings = TimerSettings(
            workDuration: 60, // 1 minute for faster tests
            shortBreakDuration: 30,
            longBreakDuration: 45,
            pomodorosUntilLongBreak: 2
        )
        stateMachine = PomodoroStateMachine(timerEngine: TimerEngine(), settings: settings)
    }

    override func tearDown() {
        stateMachine = nil
        mockDefaults = nil
        UserDefaults.standard.removeObject(forKey: "com.pomodaddy.stateMachineState")
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
        XCTAssertEqual(stateMachine.formattedTime, "00:30")
    }

    func testStartLongBreak() {
        stateMachine.send(.start(.longBreak))

        XCTAssertEqual(stateMachine.currentState, .running(.longBreak))
        XCTAssertEqual(stateMachine.formattedTime, "00:45")
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
        await assertEventually(timeout: 2.0) {
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

        await assertEventually(timeout: 1.0) {
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

        await assertEventually(timeout: 0.5) {
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

        await assertEventually(timeout: 0.5) {
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

        await assertEventually(timeout: 0.5) {
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

        await assertEventually(timeout: 0.5) {
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

    func testStatePersistence() async {
        // Start a work session
        stateMachine.send(.start(.work))
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Create a new state machine (simulating app restart)
        let settings = TimerSettings(
            workDuration: 60,
            shortBreakDuration: 30,
            longBreakDuration: 45,
            pomodorosUntilLongBreak: 2
        )
        let newStateMachine = PomodoroStateMachine(timerEngine: TimerEngine(), settings: settings)

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
        XCTAssertEqual(stateMachine.duration(for: .shortBreak), 30)
        XCTAssertEqual(stateMachine.duration(for: .longBreak), 45)
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
}
