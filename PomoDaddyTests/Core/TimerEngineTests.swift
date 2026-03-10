import XCTest
@testable import PomoDaddy

@MainActor
final class TimerEngineTests: XCTestCase {
    var engine: TimerEngine!

    override func setUp() {
        super.setUp()
        engine = TimerEngine()
    }

    override func tearDown() {
        engine.stop()
        engine = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        XCTAssertEqual(engine.remainingSeconds, 0)
        XCTAssertFalse(engine.isRunning)
        XCTAssertEqual(engine.totalDuration, 0)
        XCTAssertEqual(engine.progress, 0)
        XCTAssertEqual(engine.formattedTime, "00:00")
    }

    // MARK: - Start Tests

    func testStart() async {
        var tickCount = 0
        var completionCalled = false

        engine.start(
            seconds: 0.5,
            onTick: { _ in tickCount += 1 },
            onComplete: { completionCalled = true }
        )

        XCTAssertTrue(engine.isRunning)
        XCTAssertEqual(engine.totalDuration, 0.5, accuracy: 0.01)

        await assertEventually(timeout: 1.0) {
            completionCalled
        }

        XCTAssertFalse(engine.isRunning)
        XCTAssertEqual(engine.remainingSeconds, 0, accuracy: 0.1)
        XCTAssertGreaterThan(tickCount, 0)
    }

    func testStartWithZeroDuration() {
        engine.start(seconds: 0)

        // Should handle gracefully
        XCTAssertTrue(engine.isRunning)
        XCTAssertEqual(engine.totalDuration, 0)
    }

    // MARK: - Pause/Resume Tests

    func testPause() async {
        engine.start(seconds: 10)

        // Wait a bit then pause
        try? await Task.sleep(nanoseconds: 200_000_000)
        engine.pause()

        XCTAssertFalse(engine.isRunning)
        XCTAssertLessThan(engine.remainingSeconds, 10)
        XCTAssertGreaterThan(engine.remainingSeconds, 9)

        let pausedTime = engine.remainingSeconds
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Time should not decrease while paused
        XCTAssertEqual(engine.remainingSeconds, pausedTime, accuracy: 0.1)
    }

    func testResume() async {
        var completionCalled = false

        engine.start(
            seconds: 1.0,
            onComplete: { completionCalled = true }
        )

        try? await Task.sleep(nanoseconds: 300_000_000)
        engine.pause()

        let pausedTime = engine.remainingSeconds
        XCTAssertLessThan(pausedTime, 1.0)

        engine.resume()
        XCTAssertTrue(engine.isRunning)

        await assertEventually(timeout: 2.0) {
            completionCalled
        }

        XCTAssertTrue(completionCalled)
    }

    // MARK: - Stop Tests

    func testStop() {
        engine.start(seconds: 10)
        XCTAssertTrue(engine.isRunning)

        engine.stop()

        XCTAssertFalse(engine.isRunning)
        XCTAssertEqual(engine.remainingSeconds, 0)
        XCTAssertEqual(engine.totalDuration, 0)
    }

    // MARK: - Progress Tests

    func testProgress() async {
        engine.start(seconds: 1.0)

        XCTAssertEqual(engine.progress, 0, accuracy: 0.1)

        try? await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertEqual(engine.progress, 0.5, accuracy: 0.15)
    }

    func testProgressAtCompletion() async {
        var completed = false
        engine.start(seconds: 0.1, onComplete: { completed = true })

        await assertEventually(timeout: 1.0) { completed }

        XCTAssertEqual(engine.progress, 1.0)
    }

    // MARK: - Formatted Time Tests

    func testFormattedTime() {
        engine.start(seconds: 125)

        // 125 seconds = 2:05
        XCTAssertEqual(engine.formattedTime, "02:05")

        engine.stop()
        XCTAssertEqual(engine.formattedTime, "00:00")
    }

    // MARK: - State Capture Tests

    func testCaptureRemainingTime_Running() async {
        engine.start(seconds: 10)

        try? await Task.sleep(nanoseconds: 200_000_000)

        let captured = engine.captureRemainingTime()
        XCTAssertNotNil(captured)
        XCTAssertLessThan(captured!, 10)
        XCTAssertGreaterThan(captured!, 9)
    }

    func testCaptureRemainingTime_Paused() async {
        engine.start(seconds: 10)
        try? await Task.sleep(nanoseconds: 200_000_000)
        engine.pause()

        let captured = engine.captureRemainingTime()
        XCTAssertNotNil(captured)
        XCTAssertLessThan(captured!, 10)
    }

    func testCaptureRemainingTime_Idle() {
        let captured = engine.captureRemainingTime()
        XCTAssertNil(captured)
    }

    // MARK: - State Restoration Tests

    func testRestore_Running() async {
        var completed = false

        engine.restore(
            remainingSeconds: 0.5,
            totalDuration: 10,
            wasRunning: true,
            onComplete: { completed = true }
        )

        XCTAssertTrue(engine.isRunning)
        XCTAssertEqual(engine.totalDuration, 10)

        await assertEventually(timeout: 1.0) { completed }
        XCTAssertTrue(completed)
    }

    func testRestore_Paused() {
        engine.restore(
            remainingSeconds: 5,
            totalDuration: 10,
            wasRunning: false
        )

        XCTAssertFalse(engine.isRunning)
        XCTAssertEqual(engine.remainingSeconds, 5)
        XCTAssertEqual(engine.totalDuration, 10)
    }

    // MARK: - Add Time Tests

    func testAddTime_Running() async {
        engine.start(seconds: 10)

        try? await Task.sleep(nanoseconds: 100_000_000)
        let beforeAdd = engine.remainingSeconds

        engine.addTime(5)

        XCTAssertEqual(
            engine.remainingSeconds,
            beforeAdd + 5,
            accuracy: 0.2
        )
        XCTAssertEqual(engine.totalDuration, 15)
    }

    func testAddTime_Paused() {
        engine.start(seconds: 10)
        engine.pause()

        let beforeAdd = engine.remainingSeconds
        engine.addTime(5)

        XCTAssertEqual(engine.remainingSeconds, beforeAdd + 5)
        XCTAssertEqual(engine.totalDuration, 15)
    }

    func testSubtractTime() {
        engine.start(seconds: 10)
        engine.addTime(-5)

        XCTAssertLessThan(engine.totalDuration, 10)
    }

    // MARK: - Accuracy Tests

    func testTimerAccuracy() async {
        let targetDuration: TimeInterval = 1.0
        let startTime = Date()

        var completed = false
        engine.start(
            seconds: targetDuration,
            onComplete: { completed = true }
        )

        await assertEventually(timeout: 2.0) { completed }

        let actualDuration = Date().timeIntervalSince(startTime)

        // Should complete within 150ms of target
        XCTAssertEqual(actualDuration, targetDuration, accuracy: 0.15)
    }
}
