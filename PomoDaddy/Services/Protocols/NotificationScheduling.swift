//
//  NotificationScheduling.swift
//  PomoDaddy
//
//  Protocol for notification scheduling dependency injection.
//

import Foundation

/// Protocol defining the notification scheduling interface for dependency injection and testing.
protocol NotificationScheduling: AnyObject {
    /// Requests authorization to display notifications.
    /// - Returns: `true` if notifications are authorized, `false` otherwise.
    func requestAuthorization() async -> Bool

    /// Checks the current authorization status without prompting the user.
    /// - Returns: `true` if notifications are currently authorized.
    func checkAuthorizationStatus() async -> Bool

    /// Schedules a notification for when the current interval completes.
    /// - Parameters:
    ///   - intervalType: The type of interval that will complete.
    ///   - inSeconds: The number of seconds until the notification should fire.
    ///   - silent: If `true`, the notification will not play a sound.
    func scheduleCompletion(intervalType: IntervalType, inSeconds: Int, silent: Bool)

    /// Cancels any pending timer completion notification.
    func cancelPending()

    /// Removes all delivered notifications from the notification center.
    func clearDelivered()

    /// Registers notification categories for interactive notifications.
    func registerCategories()
}

// MARK: - Default Parameter Values

extension NotificationScheduling {
    /// Schedules a notification with sound enabled by default.
    func scheduleCompletion(intervalType: IntervalType, inSeconds: Int) {
        scheduleCompletion(intervalType: intervalType, inSeconds: inSeconds, silent: false)
    }
}
