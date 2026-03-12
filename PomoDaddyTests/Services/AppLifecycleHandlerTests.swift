//
//  AppLifecycleHandlerTests.swift
//  PomoDaddyTests
//
//  Tests for the AppLifecycleHandler lifecycle event handling.
//

import Combine
import XCTest
@testable import PomoDaddy

@MainActor
final class AppLifecycleHandlerTests: XCTestCase {
    var saveCallCount: Int!
    var restoreCallCount: Int!
    var activateCallCount: Int!

    override func setUp() {
        super.setUp()
        saveCallCount = 0
        restoreCallCount = 0
        activateCallCount = 0
    }

    override func tearDown() {
        saveCallCount = nil
        restoreCallCount = nil
        activateCallCount = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        let handler = AppLifecycleHandler(
            onSave: { [weak self] in self?.saveCallCount += 1 },
            onRestore: { [weak self] in self?.restoreCallCount += 1 }
        )

        // Should not call callbacks on init
        XCTAssertEqual(saveCallCount, 0)
        XCTAssertEqual(restoreCallCount, 0)

        // Handler should be initialized
        XCTAssertNotNil(handler)
    }

    // MARK: - App Termination Tests

    func testWillTerminateCallsSave() {
        let expectation = expectation(description: "Save called on termination")

        let handler = AppLifecycleHandler(
            onSave: {
                expectation.fulfill()
            },
            onRestore: {}
        )

        // Simulate app termination
        NotificationCenter.default.post(
            name: NSApplication.willTerminateNotification,
            object: nil
        )

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - System Sleep Tests

    func testWillSleepCallsSave() {
        let expectation = expectation(description: "Save called on sleep")

        let handler = AppLifecycleHandler(
            onSave: {
                expectation.fulfill()
            },
            onRestore: {}
        )

        // Simulate system sleep
        NSWorkspace.shared.notificationCenter.post(
            name: NSWorkspace.willSleepNotification,
            object: nil
        )

        wait(for: [expectation], timeout: 1.0)
    }

    func testDidWakeCallsRestore() async {
        let expectation = expectation(description: "Restore called on wake")

        let handler = AppLifecycleHandler(
            onSave: {},
            onRestore: {
                expectation.fulfill()
            }
        )

        // Simulate system sleep first (sets wasAsleep flag)
        NSWorkspace.shared.notificationCenter.post(
            name: NSWorkspace.willSleepNotification,
            object: nil
        )

        // Small delay to let sleep handler execute
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Simulate system wake
        NSWorkspace.shared.notificationCenter.post(
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        await fulfillment(of: [expectation], timeout: 2.0)
    }

    func testMultipleWakeCallsHandledCorrectly() async {
        var restoreCount = 0
        let expectation = expectation(description: "Restore called only once per sleep")
        expectation.expectedFulfillmentCount = 1

        let handler = AppLifecycleHandler(
            onSave: {},
            onRestore: {
                restoreCount += 1
                expectation.fulfill()
            }
        )

        // Simulate sleep
        NSWorkspace.shared.notificationCenter.post(
            name: NSWorkspace.willSleepNotification,
            object: nil
        )

        try? await Task.sleep(nanoseconds: 100_000_000)

        // Simulate wake
        NSWorkspace.shared.notificationCenter.post(
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        await fulfillment(of: [expectation], timeout: 2.0)

        // Second wake without sleep should not call restore
        NSWorkspace.shared.notificationCenter.post(
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        try? await Task.sleep(nanoseconds: 100_000_000)

        // Should still be called only once
        XCTAssertEqual(restoreCount, 1)
    }

    // MARK: - App Activation Tests

    func testDidBecomeActiveCallsActivate() {
        let expectation = expectation(description: "Activate called")

        let handler = AppLifecycleHandler(
            onSave: {},
            onRestore: {},
            onActivate: {
                expectation.fulfill()
            }
        )

        // Simulate app becoming active
        NotificationCenter.default.post(
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )

        wait(for: [expectation], timeout: 1.0)
    }

    func testSetActivateCallback() {
        let expectation = expectation(description: "New activate callback called")

        let handler = AppLifecycleHandler(
            onSave: {},
            onRestore: {}
        )

        // Set activate callback after initialization
        handler.setActivateCallback {
            expectation.fulfill()
        }

        // Simulate app becoming active
        NotificationCenter.default.post(
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - App Resign Active Tests

    func testWillResignActiveCallsSave() {
        let expectation = expectation(description: "Save called on resign")

        let handler = AppLifecycleHandler(
            onSave: {
                expectation.fulfill()
            },
            onRestore: {}
        )

        // Simulate app resigning active
        NotificationCenter.default.post(
            name: NSApplication.willResignActiveNotification,
            object: nil
        )

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Manual Trigger Tests

    func testSaveNow() {
        let expectation = expectation(description: "Manual save called")

        let handler = AppLifecycleHandler(
            onSave: {
                expectation.fulfill()
            },
            onRestore: {}
        )

        handler.saveNow()

        wait(for: [expectation], timeout: 1.0)
    }

    func testRestoreNow() {
        let expectation = expectation(description: "Manual restore called")

        let handler = AppLifecycleHandler(
            onSave: {},
            onRestore: {
                expectation.fulfill()
            }
        )

        handler.restoreNow()

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Integration Tests

    func testCompleteLifecycle() async {
        var events: [String] = []

        let handler = AppLifecycleHandler(
            onSave: {
                events.append("save")
            },
            onRestore: {
                events.append("restore")
            },
            onActivate: {
                events.append("activate")
            }
        )

        // Simulate complete lifecycle

        // 1. App goes to background
        NotificationCenter.default.post(
            name: NSApplication.willResignActiveNotification,
            object: nil
        )

        try? await Task.sleep(nanoseconds: 50_000_000)

        // 2. System goes to sleep
        NSWorkspace.shared.notificationCenter.post(
            name: NSWorkspace.willSleepNotification,
            object: nil
        )

        try? await Task.sleep(nanoseconds: 50_000_000)

        // 3. System wakes up
        NSWorkspace.shared.notificationCenter.post(
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        try? await Task.sleep(nanoseconds: 600_000_000) // Wait for async restore

        // 4. App becomes active
        NotificationCenter.default.post(
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )

        try? await Task.sleep(nanoseconds: 50_000_000)

        // Verify event sequence
        XCTAssertTrue(events.contains("save"))
        XCTAssertTrue(events.contains("restore"))
        XCTAssertTrue(events.contains("activate"))
    }
}
