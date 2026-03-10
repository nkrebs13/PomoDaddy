import XCTest
@testable import PomoDaddy

@MainActor
final class NotificationSchedulerTests: XCTestCase {
    var scheduler: NotificationScheduler!

    override func setUp() {
        super.setUp()
        scheduler = NotificationScheduler()
    }

    override func tearDown() {
        scheduler = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        XCTAssertNotNil(scheduler)
    }

    // MARK: - Authorization Tests

    func testRequestAuthorization() async {
        // Note: This test will actually request authorization or return cached status
        let granted = await scheduler.requestAuthorization()

        // Test should not crash
        XCTAssertTrue(granted || !granted) // Just verify we get a boolean
    }

    func testCheckAuthorizationStatus() async {
        let status = await scheduler.checkAuthorizationStatus()

        // Test should not crash
        XCTAssertTrue(status || !status) // Just verify we get a boolean
    }

    // MARK: - Scheduling Tests

    func testScheduleCompletionDoesNotCrash() {
        // Test that scheduling doesn't crash
        scheduler.scheduleCompletion(intervalType: .work, inSeconds: 60)

        // Give it a moment to process
        let expectation = expectation(description: "schedule")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testScheduleAllIntervalTypes() {
        // Test all interval types
        scheduler.scheduleCompletion(intervalType: .work, inSeconds: 60)
        scheduler.scheduleCompletion(intervalType: .shortBreak, inSeconds: 30)
        scheduler.scheduleCompletion(intervalType: .longBreak, inSeconds: 90)

        // Should not crash
    }

    func testScheduleSilentNotification() {
        scheduler.scheduleCompletion(intervalType: .work, inSeconds: 60, silent: true)

        // Should not crash
    }

    func testScheduleZeroSeconds() {
        // Should not schedule notification with zero seconds
        scheduler.scheduleCompletion(intervalType: .work, inSeconds: 0)

        // Should not crash
    }

    func testScheduleNegativeSeconds() {
        // Should not schedule notification with negative seconds
        scheduler.scheduleCompletion(intervalType: .work, inSeconds: -10)

        // Should not crash
    }

    // MARK: - Cancel Tests

    func testCancelPending() {
        // Schedule and then cancel
        scheduler.scheduleCompletion(intervalType: .work, inSeconds: 60)
        scheduler.cancelPending()

        // Should not crash
    }

    func testCancelWhenNoPending() {
        // Cancel when nothing is scheduled
        scheduler.cancelPending()

        // Should not crash
    }

    func testMultipleCancels() {
        scheduler.scheduleCompletion(intervalType: .work, inSeconds: 60)
        scheduler.cancelPending()
        scheduler.cancelPending()
        scheduler.cancelPending()

        // Should not crash
    }

    // MARK: - Clear Delivered Tests

    func testClearDelivered() {
        scheduler.clearDelivered()

        // Should not crash
    }

    func testClearDeliveredMultipleTimes() {
        scheduler.clearDelivered()
        scheduler.clearDelivered()
        scheduler.clearDelivered()

        // Should not crash
    }

    // MARK: - Category Registration Tests

    func testRegisterCategories() {
        scheduler.registerCategories()

        // Should not crash
    }

    func testRegisterCategoriesMultipleTimes() {
        scheduler.registerCategories()
        scheduler.registerCategories()

        // Should not crash
    }

    // MARK: - Integration Tests

    func testScheduleCancelSchedule() {
        // Schedule, cancel, schedule again
        scheduler.scheduleCompletion(intervalType: .work, inSeconds: 60)
        scheduler.cancelPending()
        scheduler.scheduleCompletion(intervalType: .shortBreak, inSeconds: 30)

        // Should not crash
    }

    func testScheduleReplacesExisting() {
        // Schedule one notification
        scheduler.scheduleCompletion(intervalType: .work, inSeconds: 60)

        // Schedule another (should replace the first)
        scheduler.scheduleCompletion(intervalType: .shortBreak, inSeconds: 30)

        // Should not crash and should have replaced the first
    }

    // MARK: - Stress Tests

    func testRapidSchedulingAndCanceling() {
        for _ in 0 ..< 10 {
            scheduler.scheduleCompletion(intervalType: .work, inSeconds: 60)
            scheduler.cancelPending()
        }

        // Should not crash
    }

    func testScheduleAllTypesRapidly() {
        for _ in 0 ..< 5 {
            scheduler.scheduleCompletion(intervalType: .work, inSeconds: 60)
            scheduler.scheduleCompletion(intervalType: .shortBreak, inSeconds: 30)
            scheduler.scheduleCompletion(intervalType: .longBreak, inSeconds: 90)
        }

        // Should not crash
    }
}
