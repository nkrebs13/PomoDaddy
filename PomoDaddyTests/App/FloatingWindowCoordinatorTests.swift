//
//  FloatingWindowCoordinatorTests.swift
//  PomoDaddyTests
//
//  Tests for FloatingWindowCoordinator using mock protocol verification.
//

import XCTest
@testable import PomoDaddy

@MainActor
final class FloatingWindowCoordinatorTests: XCTestCase {
    var mockCoordinator: MockFloatingWindowCoordinator!

    override func setUp() {
        super.setUp()
        mockCoordinator = MockFloatingWindowCoordinator()
    }

    override func tearDown() {
        mockCoordinator = nil
        super.tearDown()
    }

    // MARK: - Protocol Conformance via Mock

    func testShowIncrementsCallCount() {
        mockCoordinator.show()
        XCTAssertEqual(mockCoordinator.showCallCount, 1)

        mockCoordinator.show()
        XCTAssertEqual(mockCoordinator.showCallCount, 2)
    }

    func testHideIncrementsCallCount() {
        mockCoordinator.hide()
        XCTAssertEqual(mockCoordinator.hideCallCount, 1)
    }

    func testToggleIncrementsCallCount() {
        mockCoordinator.toggle()
        XCTAssertEqual(mockCoordinator.toggleCallCount, 1)
    }

    func testSavePositionIncrementsCallCount() {
        mockCoordinator.savePosition()
        XCTAssertEqual(mockCoordinator.savePositionCallCount, 1)
    }

    func testSetAppCoordinatorIncrementsCallCount() throws {
        let persistence = try StateMachinePersistence(
            defaults: XCTUnwrap(UserDefaults(suiteName: "test.fwc.\(UUID())"))
        )
        let coordinator = AppCoordinator(
            modelContainer: TestHelpers.createTestContainer(),
            settingsManager: MockSettingsManager(),
            timerEngine: MockTimerEngine(),
            notificationScheduler: MockNotificationScheduler(),
            sessionRecorder: MockSessionRecorder(),
            appNapManager: MockAppNapManager(),
            sessionCoordinator: MockSessionCoordinator(),
            floatingWindowCoordinator: mockCoordinator,
            persistence: persistence
        )

        // setAppCoordinator is called during AppCoordinator init
        XCTAssertEqual(mockCoordinator.setAppCoordinatorCallCount, 1)

        // Calling again increments
        mockCoordinator.setAppCoordinator(coordinator)
        XCTAssertEqual(mockCoordinator.setAppCoordinatorCallCount, 2)
    }

    // MARK: - Concrete Coordinator

    func testConcreteCoordinatorInitialization() {
        let coordinator = FloatingWindowCoordinator()
        // Should not be visible initially
        XCTAssertFalse(coordinator.isVisible)
    }

    func testConcreteHideWithoutShowDoesNotCrash() {
        let coordinator = FloatingWindowCoordinator()
        // Should not crash when hiding without showing first
        coordinator.hide()
        XCTAssertFalse(coordinator.isVisible)
    }

    func testConcreteSavePositionWithoutWindowDoesNotCrash() {
        let coordinator = FloatingWindowCoordinator()
        // Should not crash when no window exists
        coordinator.savePosition()
    }

    func testConcreteToggleWithoutAppCoordinatorDoesNotShow() {
        let coordinator = FloatingWindowCoordinator()
        // toggle calls show() which guards on appCoordinator being set
        coordinator.toggle()
        XCTAssertFalse(coordinator.isVisible)
    }
}
