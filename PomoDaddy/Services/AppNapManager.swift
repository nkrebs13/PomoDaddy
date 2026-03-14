//
//  AppNapManager.swift
//  PomoDaddy
//
//  Prevents App Nap during active timing sessions.
//

import Foundation

/// Manages App Nap prevention during active pomodoro timing sessions.
///
/// macOS uses App Nap to reduce power consumption by throttling background apps.
/// This can cause timer inaccuracy when PomoDaddy is not in focus. `AppNapManager`
/// uses `ProcessInfo` activity assertions to prevent App Nap while a timer is running.
///
/// Key behaviors:
/// - Prevents App Nap and idle system sleep during active timing
/// - Automatically releases the assertion when timing ends
/// - Safe to call multiple times (idempotent operations)
///
/// Usage:
/// ```swift
/// let appNapManager = AppNapManager()
///
/// // When timer starts
/// appNapManager.beginTimingActivity()
///
/// // When timer stops
/// appNapManager.endTimingActivity()
/// ```
///
/// - Important: Always call `endTimingActivity()` when the timer stops to allow
///   power-saving features to resume. Failing to do so will impact battery life.
final class AppNapManager: AppNapManaging {
    // MARK: - Properties

    /// The current activity assertion token, if any.
    private var activityToken: NSObjectProtocol?

    /// Whether an activity assertion is currently active.
    var isTimingActivityActive: Bool {
        activityToken != nil
    }

    // MARK: - Initialization

    /// Creates a new App Nap manager.
    init() {}

    deinit {
        // Ensure we clean up the activity token
        endTimingActivity()
    }

    // MARK: - Activity Management

    /// Begins an activity assertion to prevent App Nap during timing.
    ///
    /// This method creates an activity assertion with the following options:
    /// - `.userInitiated`: Indicates this is important user-initiated work
    /// - `.idleSystemSleepDisabled`: Prevents the system from sleeping while idle
    ///
    /// It's safe to call this method multiple times; subsequent calls are no-ops
    /// if an assertion is already active.
    ///
    /// - Note: Call `endTimingActivity()` when the timer stops to release
    ///   the assertion and restore normal power management.
    func beginTimingActivity() {
        // Don't create duplicate tokens
        guard activityToken == nil else {
            #if DEBUG
            Logger.debug("Activity already active, skipping", log: Logger.lifecycle)
            #endif
            return
        }

        activityToken = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .idleSystemSleepDisabled],
            reason: "Pomodoro timer is running"
        )

        #if DEBUG
        Logger.debug("Started timing activity - App Nap disabled", log: Logger.lifecycle)
        #endif
    }

    /// Ends the activity assertion, allowing App Nap to resume.
    ///
    /// This method releases the activity assertion created by `beginTimingActivity()`,
    /// allowing macOS to resume normal power management.
    ///
    /// It's safe to call this method multiple times; calls when no assertion
    /// is active are no-ops.
    func endTimingActivity() {
        guard let token = activityToken else {
            #if DEBUG
            Logger.debug("No activity to end", log: Logger.lifecycle)
            #endif
            return
        }

        ProcessInfo.processInfo.endActivity(token)
        activityToken = nil

        #if DEBUG
        Logger.debug("Ended timing activity - App Nap re-enabled", log: Logger.lifecycle)
        #endif
    }

    /// Toggles the activity state based on whether timing is active.
    ///
    /// Convenience method for updating the activity state based on a boolean.
    ///
    /// - Parameter isActive: Whether timing is currently active.
    func setTimingActive(_ isActive: Bool) {
        if isActive {
            beginTimingActivity()
        } else {
            endTimingActivity()
        }
    }
}
