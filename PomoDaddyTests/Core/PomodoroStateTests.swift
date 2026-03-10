import XCTest
@testable import PomoDaddy

final class PomodoroStateTests: XCTestCase {
    // MARK: - Interval Type Tests

    func testIntervalTypeDisplayNames() {
        XCTAssertEqual(IntervalType.work.displayName, "Focus")
        XCTAssertEqual(IntervalType.shortBreak.displayName, "Short Break")
        XCTAssertEqual(IntervalType.longBreak.displayName, "Long Break")
    }

    func testIntervalTypeDefaultDurations() {
        XCTAssertEqual(IntervalType.work.defaultDuration, 25 * 60)
        XCTAssertEqual(IntervalType.shortBreak.defaultDuration, 5 * 60)
        XCTAssertEqual(IntervalType.longBreak.defaultDuration, 15 * 60)
    }

    func testIntervalTypeCaseIterable() {
        let allCases = IntervalType.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.work))
        XCTAssertTrue(allCases.contains(.shortBreak))
        XCTAssertTrue(allCases.contains(.longBreak))
    }

    func testIntervalTypeIdentifiable() {
        XCTAssertEqual(IntervalType.work.id, "work")
        XCTAssertEqual(IntervalType.shortBreak.id, "shortBreak")
        XCTAssertEqual(IntervalType.longBreak.id, "longBreak")
    }

    // MARK: - Timer State Tests

    func testIdleState() {
        let state = TimerState.idle

        XCTAssertNil(state.intervalType)
        XCTAssertFalse(state.isActive)
        XCTAssertFalse(state.isRunning)
        XCTAssertFalse(state.isPaused)
        XCTAssertEqual(state.displayName, "Ready")
    }

    func testRunningWorkState() {
        let state = TimerState.running(.work)

        XCTAssertEqual(state.intervalType, .work)
        XCTAssertTrue(state.isActive)
        XCTAssertTrue(state.isRunning)
        XCTAssertFalse(state.isPaused)
        XCTAssertEqual(state.displayName, "Focus")
    }

    func testPausedWorkState() {
        let state = TimerState.paused(.work)

        XCTAssertEqual(state.intervalType, .work)
        XCTAssertTrue(state.isActive)
        XCTAssertFalse(state.isRunning)
        XCTAssertTrue(state.isPaused)
        XCTAssertEqual(state.displayName, "Focus (Paused)")
    }

    func testRunningBreakStates() {
        let shortBreakState = TimerState.running(.shortBreak)
        XCTAssertEqual(shortBreakState.intervalType, .shortBreak)
        XCTAssertTrue(shortBreakState.isActive)
        XCTAssertEqual(shortBreakState.displayName, "Short Break")

        let longBreakState = TimerState.running(.longBreak)
        XCTAssertEqual(longBreakState.intervalType, .longBreak)
        XCTAssertTrue(longBreakState.isActive)
        XCTAssertEqual(longBreakState.displayName, "Long Break")
    }

    // MARK: - State Equality Tests

    func testStateEquality() {
        XCTAssertEqual(TimerState.idle, TimerState.idle)
        XCTAssertEqual(TimerState.running(.work), TimerState.running(.work))
        XCTAssertEqual(TimerState.paused(.shortBreak), TimerState.paused(.shortBreak))
    }

    func testStateInequality() {
        XCTAssertNotEqual(TimerState.idle, TimerState.running(.work))
        XCTAssertNotEqual(TimerState.running(.work), TimerState.paused(.work))
        XCTAssertNotEqual(TimerState.running(.work), TimerState.running(.shortBreak))
        XCTAssertNotEqual(TimerState.paused(.shortBreak), TimerState.paused(.longBreak))
    }

    // MARK: - State Codable Tests

    func testStateEncodeDecode() throws {
        let states: [TimerState] = [
            .idle,
            .running(.work),
            .running(.shortBreak),
            .running(.longBreak),
            .paused(.work),
            .paused(.shortBreak),
            .paused(.longBreak)
        ]

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for state in states {
            let data = try encoder.encode(state)
            let decoded = try decoder.decode(TimerState.self, from: data)
            XCTAssertEqual(decoded, state)
        }
    }

    func testIntervalTypeCodable() throws {
        let types: [IntervalType] = [.work, .shortBreak, .longBreak]

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for type in types {
            let data = try encoder.encode(type)
            let decoded = try decoder.decode(IntervalType.self, from: data)
            XCTAssertEqual(decoded, type)
        }
    }

    // MARK: - Switch Statement Coverage

    func testStateMatchingInSwitch() {
        let states: [TimerState] = [
            .idle,
            .running(.work),
            .paused(.shortBreak)
        ]

        for state in states {
            switch state {
            case .idle:
                XCTAssertEqual(state, .idle)
            case .running(let type):
                XCTAssertNotNil(type)
                XCTAssertTrue(state.isRunning)
            case .paused(let type):
                XCTAssertNotNil(type)
                XCTAssertTrue(state.isPaused)
            }
        }
    }

    // MARK: - State Transition Logic

    func testStateIsActiveTransitions() {
        // Idle is not active
        XCTAssertFalse(TimerState.idle.isActive)

        // All running states are active
        XCTAssertTrue(TimerState.running(.work).isActive)
        XCTAssertTrue(TimerState.running(.shortBreak).isActive)
        XCTAssertTrue(TimerState.running(.longBreak).isActive)

        // All paused states are active
        XCTAssertTrue(TimerState.paused(.work).isActive)
        XCTAssertTrue(TimerState.paused(.shortBreak).isActive)
        XCTAssertTrue(TimerState.paused(.longBreak).isActive)
    }
}
