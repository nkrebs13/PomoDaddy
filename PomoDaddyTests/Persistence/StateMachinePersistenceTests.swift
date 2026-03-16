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
        defaults.set(Data("not valid json".utf8), forKey: "com.pomodaddy.stateMachine")

        let loaded = persistence.load()
        XCTAssertNil(loaded)
    }
}
