import os.log
import XCTest
@testable import PomoDaddy

final class LoggerTests: XCTestCase {
    // Logger methods use os_log which doesn't crash or return values,
    // so we verify they execute without errors.

    func testDebugDoesNotCrash() {
        Logger.debug("test debug message")
        Logger.debug("test debug with log", log: Logger.timer)
    }

    func testInfoDoesNotCrash() {
        Logger.info("test info message")
        Logger.info("test info with log", log: Logger.persistence)
    }

    func testErrorDoesNotCrash() {
        Logger.error("test error message")
        Logger.error("test error with log", log: Logger.notifications)
    }

    func testFaultDoesNotCrash() {
        Logger.fault("test fault message")
        Logger.fault("test fault with log", log: Logger.lifecycle)
    }

    func testLogErrorDoesNotCrash() {
        let error = NSError(domain: "test", code: 42, userInfo: [NSLocalizedDescriptionKey: "test error"])
        Logger.logError(error, context: "test context", log: Logger.stats)
    }

    func testAllLogCategoriesExist() {
        // Verify all log categories are accessible
        _ = Logger.timer
        _ = Logger.persistence
        _ = Logger.notifications
        _ = Logger.lifecycle
        _ = Logger.stats
        _ = Logger.ui
    }
}
