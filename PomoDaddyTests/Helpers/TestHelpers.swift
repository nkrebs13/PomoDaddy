import Foundation
import SwiftData
import XCTest
@testable import PomoDaddy

/// Test helpers for creating test instances and utilities
enum TestHelpers {
    /// Creates an in-memory model container for testing
    static func createTestContainer() -> ModelContainer {
        PomodoroDataContainer.createInMemory()
    }

    /// Creates a test timer engine
    static func createTestTimerEngine() -> TimerEngine {
        TimerEngine()
    }

    /// Creates a test state machine with custom settings
    static func createTestStateMachine(
        settings: TimerSettings = TimerSettings()
    ) -> PomodoroStateMachine {
        PomodoroStateMachine(
            timerEngine: TimerEngine(),
            settings: settings
        )
    }

    /// Waits for async expectation with timeout
    static func wait(
        seconds: TimeInterval = 1.0,
        file: StaticString = #file,
        line: UInt = #line,
        _ closure: @escaping () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(seconds)
        while Date() < deadline {
            if closure() { return }
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        XCTFail("Timeout waiting for condition", file: file, line: line)
    }
}
