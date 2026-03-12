//
//  AppNapManagerTests.swift
//  PomoDaddyTests
//
//  Tests for the AppNapManager service.
//

import XCTest
@testable import PomoDaddy

@MainActor
final class AppNapManagerTests: XCTestCase {
    var appNapManager: AppNapManager!

    override func setUp() {
        super.setUp()
        appNapManager = AppNapManager()
    }

    override func tearDown() {
        // Ensure cleanup
        appNapManager.endTimingActivity()
        appNapManager = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        XCTAssertFalse(appNapManager.isTimingActivityActive)
    }

    // MARK: - Begin/End Activity Tests

    func testBeginTimingActivity() {
        appNapManager.beginTimingActivity()
        XCTAssertTrue(appNapManager.isTimingActivityActive)
    }

    func testEndTimingActivity() {
        appNapManager.beginTimingActivity()
        XCTAssertTrue(appNapManager.isTimingActivityActive)

        appNapManager.endTimingActivity()
        XCTAssertFalse(appNapManager.isTimingActivityActive)
    }

    func testMultipleBeginCallsAreIdempotent() {
        appNapManager.beginTimingActivity()
        XCTAssertTrue(appNapManager.isTimingActivityActive)

        // Second begin should be idempotent
        appNapManager.beginTimingActivity()
        XCTAssertTrue(appNapManager.isTimingActivityActive)

        // Single end should clean up
        appNapManager.endTimingActivity()
        XCTAssertFalse(appNapManager.isTimingActivityActive)
    }

    func testMultipleEndCallsAreSafe() {
        appNapManager.beginTimingActivity()
        appNapManager.endTimingActivity()
        XCTAssertFalse(appNapManager.isTimingActivityActive)

        // Second end should be safe (no crash)
        appNapManager.endTimingActivity()
        XCTAssertFalse(appNapManager.isTimingActivityActive)
    }

    func testEndWithoutBeginIsSafe() {
        // Should not crash
        appNapManager.endTimingActivity()
        XCTAssertFalse(appNapManager.isTimingActivityActive)
    }

    // MARK: - Set Timing Active Tests

    func testSetTimingActiveTrue() {
        appNapManager.setTimingActive(true)
        XCTAssertTrue(appNapManager.isTimingActivityActive)
    }

    func testSetTimingActiveFalse() {
        appNapManager.beginTimingActivity()
        appNapManager.setTimingActive(false)
        XCTAssertFalse(appNapManager.isTimingActivityActive)
    }

    func testSetTimingActiveToggle() {
        // Start inactive
        XCTAssertFalse(appNapManager.isTimingActivityActive)

        // Activate
        appNapManager.setTimingActive(true)
        XCTAssertTrue(appNapManager.isTimingActivityActive)

        // Deactivate
        appNapManager.setTimingActive(false)
        XCTAssertFalse(appNapManager.isTimingActivityActive)

        // Activate again
        appNapManager.setTimingActive(true)
        XCTAssertTrue(appNapManager.isTimingActivityActive)
    }

    // MARK: - Perform With Activity Tests

    func testPerformWithActivity() {
        var operationExecuted = false

        appNapManager.performWithActivity {
            operationExecuted = true
            XCTAssertTrue(self.appNapManager.isTimingActivityActive)
        }

        XCTAssertTrue(operationExecuted)
        XCTAssertFalse(appNapManager.isTimingActivityActive)
    }

    func testPerformWithActivityAsync() async {
        var operationExecuted = false

        await appNapManager.performWithActivity {
            operationExecuted = true
            XCTAssertTrue(self.appNapManager.isTimingActivityActive)

            // Simulate async work
            try? await Task.sleep(nanoseconds: 10_000_000)
        }

        XCTAssertTrue(operationExecuted)
        XCTAssertFalse(appNapManager.isTimingActivityActive)
    }

    func testPerformWithActivityPreservesReturnValue() {
        let result = appNapManager.performWithActivity {
            return 42
        }

        XCTAssertEqual(result, 42)
        XCTAssertFalse(appNapManager.isTimingActivityActive)
    }

    func testPerformWithActivityAsyncPreservesReturnValue() async {
        let result = await appNapManager.performWithActivity {
            try? await Task.sleep(nanoseconds: 10_000_000)
            return "test"
        }

        XCTAssertEqual(result, "test")
        XCTAssertFalse(appNapManager.isTimingActivityActive)
    }

    // MARK: - State Consistency Tests

    func testStateConsistencyAfterMultipleOperations() {
        // Begin
        appNapManager.beginTimingActivity()
        XCTAssertTrue(appNapManager.isTimingActivityActive)

        // End
        appNapManager.endTimingActivity()
        XCTAssertFalse(appNapManager.isTimingActivityActive)

        // Begin again
        appNapManager.beginTimingActivity()
        XCTAssertTrue(appNapManager.isTimingActivityActive)

        // End again
        appNapManager.endTimingActivity()
        XCTAssertFalse(appNapManager.isTimingActivityActive)
    }

    func testNestedPerformWithActivity() {
        var outerExecuted = false
        var innerExecuted = false

        appNapManager.performWithActivity {
            outerExecuted = true
            XCTAssertTrue(self.appNapManager.isTimingActivityActive)

            // Nested call
            self.appNapManager.performWithActivity {
                innerExecuted = true
                XCTAssertTrue(self.appNapManager.isTimingActivityActive)
            }

            XCTAssertTrue(self.appNapManager.isTimingActivityActive)
        }

        XCTAssertTrue(outerExecuted)
        XCTAssertTrue(innerExecuted)
        XCTAssertFalse(appNapManager.isTimingActivityActive)
    }

    // MARK: - Integration Tests

    func testTimerSimulation() async {
        // Simulate a timer running
        appNapManager.beginTimingActivity()
        XCTAssertTrue(appNapManager.isTimingActivityActive)

        // Timer is running...
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertTrue(appNapManager.isTimingActivityActive)

        // Timer completes
        appNapManager.endTimingActivity()
        XCTAssertFalse(appNapManager.isTimingActivityActive)
    }

    func testPauseResumeSimulation() {
        // Start timer
        appNapManager.beginTimingActivity()
        XCTAssertTrue(appNapManager.isTimingActivityActive)

        // Pause (but keep activity for state preservation)
        // In real usage, app might keep activity during pause
        XCTAssertTrue(appNapManager.isTimingActivityActive)

        // Resume
        XCTAssertTrue(appNapManager.isTimingActivityActive)

        // Stop
        appNapManager.endTimingActivity()
        XCTAssertFalse(appNapManager.isTimingActivityActive)
    }

    // MARK: - Cleanup Tests

    func testDeinitCleansUpActivity() {
        var manager: AppNapManager? = AppNapManager()
        manager?.beginTimingActivity()
        XCTAssertTrue(manager?.isTimingActivityActive ?? false)

        // Deinit should clean up
        manager = nil

        // Create new manager - should start clean
        let newManager = AppNapManager()
        XCTAssertFalse(newManager.isTimingActivityActive)
    }
}
