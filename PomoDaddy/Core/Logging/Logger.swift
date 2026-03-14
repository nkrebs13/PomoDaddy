import Foundation
import os.log

/// Centralized logging for PomoDaddy using os.log for structured logging
enum Logger {
    // MARK: - Subsystems

    static let timer = OSLog(subsystem: subsystem, category: "Timer")
    static let persistence = OSLog(subsystem: subsystem, category: "Persistence")
    static let notifications = OSLog(subsystem: subsystem, category: "Notifications")
    static let lifecycle = OSLog(subsystem: subsystem, category: "Lifecycle")
    static let stats = OSLog(subsystem: subsystem, category: "Stats")
    static let ui = OSLog(subsystem: subsystem, category: "UI")

    private static let subsystem = "com.nathankrebs.pomodaddy"

    // MARK: - Convenience Methods

    static func debug(_ message: String, log: OSLog = .default) {
        os_log("%{public}@", log: log, type: .debug, message)
    }

    static func info(_ message: String, log: OSLog = .default) {
        os_log("%{public}@", log: log, type: .info, message)
    }

    static func error(_ message: String, log: OSLog = .default) {
        os_log("%{public}@", log: log, type: .error, message)
    }

    static func fault(_ message: String, log: OSLog = .default) {
        os_log("%{public}@", log: log, type: .fault, message)
    }
}

// MARK: - Error Logging Extension

extension Logger {
    /// Logs an error with context
    static func logError(_ error: Error, context: String, log: OSLog) {
        os_log(
            "%{public}@: %{public}@",
            log: log,
            type: .error,
            context,
            error.localizedDescription
        )
    }
}
