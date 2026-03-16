import XCTest
@testable import PomoDaddy

@MainActor
final class StateMachinePersistenceTests: XCTestCase {
    var persistence: StateMachinePersistence!
    var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "test.persistence.\(UUID())")!
        persistence = StateMachinePersistence(defaults: defaults)
    }

    override func tearDown() {
        persistence = nil
        defaults = nil
        super.tearDown()
    }

    // MARK: - Save and Load

    func testSaveAndLoadRoundTrip() {
        persistence.save(
            timerState: .running(.work),
            completedPomodorosInCycle: 2,
            totalCompletedToday: 5,
            lastResetDate: Date(),
            timerEngineState: nil
        )

        let loaded = persistence.load()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.timerState, .running(.work))
        XCTAssertEqual(loaded?.completedPomodorosInCycle, 2)
        XCTAssertEqual(loaded?.totalCompletedToday, 5)
    }

    func testLoadReturnsNilWhenEmpty() {
        let loaded = persistence.load()
        XCTAssertNil(loaded)
    }

    func testSaveIdleState() {
        persistence.save(
            timerState: .idle,
            completedPomodorosInCycle: 0,
            totalCompletedToday: 0,
            lastResetDate: Date(),
            timerEngineState: nil
        )

        let loaded = persistence.load()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.timerState, .idle)
    }

    func testSavePausedState() {
        persistence.save(
            timerState: .paused(.shortBreak),
            completedPomodorosInCycle: 1,
            totalCompletedToday: 3,
            lastResetDate: Date(),
            timerEngineState: nil
        )

        let loaded = persistence.load()
        XCTAssertEqual(loaded?.timerState, .paused(.shortBreak))
    }

    func testClearState() {
        persistence.save(
            timerState: .running(.work),
            completedPomodorosInCycle: 2,
            totalCompletedToday: 5,
            lastResetDate: Date(),
            timerEngineState: nil
        )

        persistence.clear()

        let loaded = persistence.load()
        XCTAssertNil(loaded)
    }

    func testCorruptedDataReturnsNil() {
        // Write invalid data directly
        defaults.set(Data("not valid json".utf8), forKey: AppConstants.UserDefaultsKeys.stateMachineState)

        let loaded = persistence.load()
        XCTAssertNil(loaded)
    }

    // MARK: - Timer Engine State Round-Trip

    func testSaveAndLoadWithTimerEngineState() {
        let mockEngine = MockTimerEngine()
        mockEngine.remainingSeconds = 45.5
        mockEngine.totalDuration = 60.0
        mockEngine.isRunning = true

        let engineState = TimerEngineState(from: mockEngine)

        persistence.save(
            timerState: .running(.work),
            completedPomodorosInCycle: 1,
            totalCompletedToday: 3,
            lastResetDate: Date(),
            timerEngineState: engineState
        )

        let loaded = persistence.load()
        XCTAssertNotNil(loaded)
        XCTAssertNotNil(loaded?.timerEngineState)
        XCTAssertEqual(loaded?.timerEngineState?.remainingSeconds ?? 0, 45.5, accuracy: 0.1)
        XCTAssertEqual(loaded?.timerEngineState?.totalDuration ?? 0, 60.0, accuracy: 0.1)
        XCTAssertEqual(loaded?.timerEngineState?.wasRunning, true)
    }

    func testTimerEngineStatePausedRoundTrip() {
        // MockTimerEngine.captureRemainingTime() returns nil when not running,
        // so TimerEngineState captures remainingSeconds as 0 for paused state.
        // This matches real behavior — paused remaining time comes from the engine's
        // remainingSeconds property, not captureRemainingTime().
        let mockEngine = MockTimerEngine()
        mockEngine.remainingSeconds = 120.0
        mockEngine.totalDuration = 300.0
        mockEngine.isRunning = false

        let engineState = TimerEngineState(from: mockEngine)

        persistence.save(
            timerState: .paused(.shortBreak),
            completedPomodorosInCycle: 0,
            totalCompletedToday: 1,
            lastResetDate: Date(),
            timerEngineState: engineState
        )

        let loaded = persistence.load()
        XCTAssertNotNil(loaded?.timerEngineState)
        XCTAssertEqual(loaded?.timerEngineState?.wasRunning, false)
        XCTAssertEqual(loaded?.timerEngineState?.totalDuration ?? 0, 300.0, accuracy: 0.1)
        // captureRemainingTime() returns nil when not running, so remainingSeconds is stored as 0
        XCTAssertEqual(loaded?.timerEngineState?.remainingSeconds ?? -1, 0, accuracy: 0.1)
    }
}
