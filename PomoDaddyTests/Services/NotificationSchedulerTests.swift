import XCTest
@testable import PomoDaddy

@MainActor
final class NotificationSchedulerTests: XCTestCase {
    var scheduler: MockNotificationScheduler!

    override func setUp() {
        super.setUp()
        scheduler = MockNotificationScheduler()
    }

    override func tearDown() {
        scheduler = nil
        super.tearDown()
    }

    // MARK: - Authorization Tests

    func testRequestAuthorizationIncrementsCallCount() async {
        _ = await scheduler.requestAuthorization()
        XCTAssertEqual(scheduler.requestAuthorizationCallCount, 1)
    }

    func testRequestAuthorizationReturnsConfiguredResult() async {
        scheduler.authorizationResult = true
        let granted = await scheduler.requestAuthorization()
        XCTAssertTrue(granted)

        scheduler.authorizationResult = false
        let denied = await scheduler.requestAuthorization()
        XCTAssertFalse(denied)
    }

    func testCheckAuthorizationStatusIncrementsCallCount() async {
        _ = await scheduler.checkAuthorizationStatus()
        XCTAssertEqual(scheduler.checkAuthorizationStatusCallCount, 1)
    }

    func testCheckAuthorizationStatusReturnsConfiguredResult() async {
        scheduler.authorizationResult = false
        let status = await scheduler.checkAuthorizationStatus()
        XCTAssertFalse(status)
    }

    // MARK: - Schedule Tests

    func testScheduleCompletionCapturesWorkInterval() {
        scheduler.scheduleCompletion(intervalType: .work, inSeconds: 1500)

        XCTAssertEqual(scheduler.scheduleCompletionCallCount, 1)
        XCTAssertEqual(scheduler.lastScheduledIntervalType, .work)
        XCTAssertEqual(scheduler.lastScheduledSeconds, 1500)
        XCTAssertEqual(scheduler.lastScheduledSilent, false)
    }

    func testScheduleCompletionCapturesShortBreak() {
        scheduler.scheduleCompletion(intervalType: .shortBreak, inSeconds: 300)

        XCTAssertEqual(scheduler.lastScheduledIntervalType, .shortBreak)
        XCTAssertEqual(scheduler.lastScheduledSeconds, 300)
    }

    func testScheduleCompletionCapturesLongBreak() {
        scheduler.scheduleCompletion(intervalType: .longBreak, inSeconds: 900)

        XCTAssertEqual(scheduler.lastScheduledIntervalType, .longBreak)
        XCTAssertEqual(scheduler.lastScheduledSeconds, 900)
    }

    func testScheduleCompletionWithSilentFlag() {
        scheduler.scheduleCompletion(intervalType: .work, inSeconds: 60, silent: true)

        XCTAssertEqual(scheduler.lastScheduledSilent, true)
    }

    func testScheduleCompletionWithZeroSecondsPassesThroughToMock() {
        // Note: real NotificationScheduler guards `inSeconds > 0` and returns early.
        // This test verifies the mock records the call regardless, which is correct
        // mock behavior — the guard logic is in the real class, not the protocol contract.
        scheduler.scheduleCompletion(intervalType: .work, inSeconds: 0)

        XCTAssertEqual(scheduler.scheduleCompletionCallCount, 1)
        XCTAssertEqual(scheduler.lastScheduledSeconds, 0)
    }

    func testScheduleCompletionWithNegativeSecondsPassesThroughToMock() {
        // Note: real NotificationScheduler guards `inSeconds > 0` and returns early.
        scheduler.scheduleCompletion(intervalType: .work, inSeconds: -10)

        XCTAssertEqual(scheduler.scheduleCompletionCallCount, 1)
        XCTAssertEqual(scheduler.lastScheduledSeconds, -10)
    }

    // MARK: - Cancel Tests

    func testCancelPendingIncrementsCallCount() {
        scheduler.cancelPending()
        XCTAssertEqual(scheduler.cancelPendingCallCount, 1)
    }

    func testMultipleCancelsIncrementCallCount() {
        scheduler.cancelPending()
        scheduler.cancelPending()
        scheduler.cancelPending()
        XCTAssertEqual(scheduler.cancelPendingCallCount, 3)
    }

    // MARK: - Clear Delivered Tests

    func testClearDeliveredIncrementsCallCount() {
        scheduler.clearDelivered()
        XCTAssertEqual(scheduler.clearDeliveredCallCount, 1)
    }

    // MARK: - Register Categories Tests

    func testRegisterCategoriesIncrementsCallCount() {
        scheduler.registerCategories()
        XCTAssertEqual(scheduler.registerCategoriesCallCount, 1)
    }

    func testRegisterCategoriesMultipleTimesIncrementsCount() {
        scheduler.registerCategories()
        scheduler.registerCategories()
        XCTAssertEqual(scheduler.registerCategoriesCallCount, 2)
    }

    // MARK: - Sequence Tests

    func testScheduleCancelScheduleSequence() {
        scheduler.scheduleCompletion(intervalType: .work, inSeconds: 60)
        scheduler.cancelPending()
        scheduler.scheduleCompletion(intervalType: .shortBreak, inSeconds: 30)

        XCTAssertEqual(scheduler.scheduleCompletionCallCount, 2)
        XCTAssertEqual(scheduler.cancelPendingCallCount, 1)
        XCTAssertEqual(scheduler.lastScheduledIntervalType, .shortBreak)
        XCTAssertEqual(scheduler.lastScheduledSeconds, 30)
    }

    func testScheduleReplacesLastCapturedArgs() {
        scheduler.scheduleCompletion(intervalType: .work, inSeconds: 60)
        scheduler.scheduleCompletion(intervalType: .shortBreak, inSeconds: 30)

        XCTAssertEqual(scheduler.scheduleCompletionCallCount, 2)
        XCTAssertEqual(scheduler.lastScheduledIntervalType, .shortBreak)
        XCTAssertEqual(scheduler.lastScheduledSeconds, 30)
    }

    // MARK: - Stress Tests

    func testRapidSchedulingCapturesFinalArgs() {
        for iteration in 0 ..< 10 {
            scheduler.scheduleCompletion(intervalType: .work, inSeconds: iteration)
            scheduler.cancelPending()
        }

        XCTAssertEqual(scheduler.scheduleCompletionCallCount, 10)
        XCTAssertEqual(scheduler.cancelPendingCallCount, 10)
        XCTAssertEqual(scheduler.lastScheduledSeconds, 9)
    }

    func testScheduleAllTypesRapidlyTracksCallCount() {
        for _ in 0 ..< 5 {
            scheduler.scheduleCompletion(intervalType: .work, inSeconds: 60)
            scheduler.scheduleCompletion(intervalType: .shortBreak, inSeconds: 30)
            scheduler.scheduleCompletion(intervalType: .longBreak, inSeconds: 90)
        }

        XCTAssertEqual(scheduler.scheduleCompletionCallCount, 15)
        XCTAssertEqual(scheduler.lastScheduledIntervalType, .longBreak)
    }
}
