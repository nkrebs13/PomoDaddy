//
//  PomodoroCycleTests.swift
//  PomoDaddyTests
//
//  Integration tests for complete pomodoro cycles using MockTimerEngine.
//

import XCTest
@testable import PomoDaddy

@MainActor
final class PomodoroCycleTests: XCTestCase {
    var stateMachine: PomodoroStateMachine!
    var mockEngine: MockTimerEngine!

    override func setUp() {
        super.setUp()
        mockEngine = MockTimerEngine()
        let settings = PomodoroSettings(
            workDurationMinutes: 25,
            shortBreakDurationMinutes: 5,
            longBreakDurationMinutes: 15,
            pomodorosUntilLongBreak: 4,
            autoStartBreaks: true,
            autoStartWork: true,
            showNotifications: true,
            showFloatingWindow: true,
            showMenuBarCountdown: true
        )
        stateMachine = PomodoroStateMachine(
            timerEngine: mockEngine,
            settings: settings,
            persistence: StateMachinePersistence(defaults: UserDefaults(suiteName: "test.cycle.\(UUID())")!)
        )
    }

    override func tearDown() {
        stateMachine = nil
        mockEngine = nil
        super.tearDown()
    }

    // MARK: - Full Auto-Start Cycle

    func testFullAutoStartCycle() {
        // Start work session 1
        stateMachine.send(.start(.work))
        XCTAssertEqual(stateMachine.currentState, .running(.work))

        // Complete work 1 → auto-start short break
        mockEngine.simulateCompletion()
        XCTAssertEqual(stateMachine.currentState, .running(.shortBreak))
        XCTAssertEqual(stateMachine.completedPomodorosInCycle, 1)

        // Complete short break → auto-start work
        mockEngine.simulateCompletion()
        XCTAssertEqual(stateMachine.currentState, .running(.work))

        // Work 2 → short break
        mockEngine.simulateCompletion()
        XCTAssertEqual(stateMachine.currentState, .running(.shortBreak))
        XCTAssertEqual(stateMachine.completedPomodorosInCycle, 2)

        // Short break → work
        mockEngine.simulateCompletion()
        XCTAssertEqual(stateMachine.currentState, .running(.work))

        // Work 3 → short break
        mockEngine.simulateCompletion()
        XCTAssertEqual(stateMachine.currentState, .running(.shortBreak))
        XCTAssertEqual(stateMachine.completedPomodorosInCycle, 3)

        // Short break → work
        mockEngine.simulateCompletion()
        XCTAssertEqual(stateMachine.currentState, .running(.work))

        // Work 4 → long break (cycle complete)
        mockEngine.simulateCompletion()
        XCTAssertEqual(stateMachine.currentState, .running(.longBreak))
        XCTAssertEqual(stateMachine.completedPomodorosInCycle, 4)

        // Complete long break → cycle resets, auto-start work
        mockEngine.simulateCompletion()
        XCTAssertEqual(stateMachine.currentState, .running(.work))
        XCTAssertEqual(stateMachine.completedPomodorosInCycle, 0) // Reset after long break
        XCTAssertEqual(stateMachine.totalCompletedToday, 4)
    }

    // MARK: - Manual Cycle (No Auto-Start)

    func testManualCycleNoAutoStart() {
        stateMachine.settings.autoStartBreaks = false
        stateMachine.settings.autoStartWork = false

        // Start and complete work
        stateMachine.send(.start(.work))
        mockEngine.simulateCompletion()

        // Should go to idle, not auto-start break
        XCTAssertEqual(stateMachine.currentState, .idle)
        XCTAssertEqual(stateMachine.completedPomodorosInCycle, 1)

        // Manually start break
        stateMachine.send(.start(.shortBreak))
        XCTAssertEqual(stateMachine.currentState, .running(.shortBreak))

        // Complete break → idle (no auto-start work)
        mockEngine.simulateCompletion()
        XCTAssertEqual(stateMachine.currentState, .idle)

        // Manually start next work session
        stateMachine.send(.start(.work))
        XCTAssertEqual(stateMachine.currentState, .running(.work))
    }

    // MARK: - Skip During Work

    func testSkipDuringWorkDoesNotIncrementCount() {
        stateMachine.send(.start(.work))
        XCTAssertEqual(stateMachine.totalCompletedToday, 0)

        stateMachine.send(.skip)
        XCTAssertEqual(stateMachine.totalCompletedToday, 0)
        XCTAssertEqual(stateMachine.completedPomodorosInCycle, 0)
        XCTAssertEqual(stateMachine.currentState, .idle)
    }

    // MARK: - Reset During Cycle

    func testResetPreservesTotalCompletedToday() {
        stateMachine.send(.start(.work))
        mockEngine.simulateCompletion() // Complete work 1
        XCTAssertEqual(stateMachine.totalCompletedToday, 1)
        XCTAssertEqual(stateMachine.completedPomodorosInCycle, 1)

        stateMachine.send(.reset)
        XCTAssertEqual(stateMachine.completedPomodorosInCycle, 0) // Cycle resets
        XCTAssertEqual(stateMachine.totalCompletedToday, 1) // Preserved
    }

    // MARK: - Pause/Resume During Work

    func testPauseResumeDuringWork() {
        stateMachine.send(.start(.work))
        XCTAssertEqual(stateMachine.currentState, .running(.work))

        stateMachine.send(.pause)
        XCTAssertEqual(stateMachine.currentState, .paused(.work))
        XCTAssertEqual(mockEngine.pauseCallCount, 1)

        stateMachine.send(.resume)
        XCTAssertEqual(stateMachine.currentState, .running(.work))
        XCTAssertEqual(mockEngine.resumeCallCount, 1)
    }

    // MARK: - Callback Verification

    func testCallbacksFiredInCorrectOrder() {
        var events: [String] = []

        stateMachine.onWorkSessionComplete = { _ in events.append("work_complete") }
        stateMachine.onBreakComplete = { type in events.append("break_complete_\(type)") }
        stateMachine.onCycleComplete = { _ in events.append("cycle_complete") }

        // Work 1
        stateMachine.send(.start(.work))
        mockEngine.simulateCompletion()
        // Work 2
        mockEngine.simulateCompletion() // short break auto-completes
        mockEngine.simulateCompletion() // work 2 completes
        // Work 3
        mockEngine.simulateCompletion() // short break
        mockEngine.simulateCompletion() // work 3
        // Work 4
        mockEngine.simulateCompletion() // short break
        mockEngine.simulateCompletion() // work 4 → long break

        // Complete long break
        mockEngine.simulateCompletion()

        XCTAssertTrue(events.contains("work_complete"))
        XCTAssertTrue(events.contains("cycle_complete"))
        XCTAssertTrue(events.contains("break_complete_longBreak"))
    }
}
