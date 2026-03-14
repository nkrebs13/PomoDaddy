//
//  NotificationScheduler.swift
//  PomoDaddy
//
//  Manages local notifications for timer completion events.
//

import Foundation
import os.log
import UserNotifications

/// Handles scheduling and managing local notifications for pomodoro timer events.
///
/// This class provides a clean interface for:
/// - Requesting notification permissions from the user
/// - Scheduling notifications when a timer interval completes
/// - Canceling pending notifications when timers are stopped or reset
///
/// Usage:
/// ```swift
/// let scheduler = NotificationScheduler()
/// let authorized = await scheduler.requestAuthorization()
/// if authorized {
///     scheduler.scheduleCompletion(intervalType: .work, inSeconds: 1500)
/// }
/// ```
final class NotificationScheduler: NotificationScheduling {
    // MARK: - Constants

    /// Notification action and category identifiers shared with AppDelegate.
    enum Identifiers {
        static let actionStartNext = "START_NEXT"
        static let actionDismiss = "DISMISS"
        static let categoryTimerCompletion = "TIMER_COMPLETION"
    }

    /// Identifier for the pending timer completion notification.
    private let pendingId = "com.pomodaddy.timerCompletion"

    // MARK: - Properties

    /// The user notification center instance.
    private let center = UNUserNotificationCenter.current()

    // MARK: - Initialization

    /// Creates a new notification scheduler.
    init() {}

    // MARK: - Authorization

    /// Requests authorization to display notifications.
    ///
    /// This method presents the system authorization dialog if the user hasn't
    /// already made a decision. If authorization was previously denied, this
    /// will return `false` without showing a dialog.
    ///
    /// - Returns: `true` if notifications are authorized, `false` otherwise.
    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            Logger.logError(error, context: "Failed to request notification authorization", log: Logger.notifications)
            return false
        }
    }

    /// Checks the current authorization status without prompting the user.
    ///
    /// - Returns: `true` if notifications are currently authorized.
    func checkAuthorizationStatus() async -> Bool {
        let settings: UNNotificationSettings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    // MARK: - Scheduling

    /// Schedules a notification for when the current interval completes.
    ///
    /// This method cancels any existing pending notification before scheduling
    /// a new one, ensuring only one timer completion notification is pending at a time.
    ///
    /// - Parameters:
    ///   - intervalType: The type of interval that will complete.
    ///   - inSeconds: The number of seconds until the notification should fire.
    ///   - silent: If `true`, the notification will not play a sound.
    func scheduleCompletion(intervalType: IntervalType, inSeconds: Int, silent: Bool = false) {
        // Cancel any existing notification first
        cancelPending()

        // Don't schedule if time is zero or negative
        guard inSeconds > 0 else { return }

        // Create the notification content
        let content = UNMutableNotificationContent()
        content.title = notificationTitle(for: intervalType)
        content.body = notificationBody(for: intervalType)
        content.categoryIdentifier = Identifiers.categoryTimerCompletion

        // Set sound based on user preference
        if !silent {
            content.sound = .default
        }

        // Create the trigger
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(inSeconds),
            repeats: false
        )

        // Create and add the request
        let request = UNNotificationRequest(
            identifier: pendingId,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                Logger.logError(error, context: "Failed to schedule notification", log: Logger.notifications)
            }
        }
    }

    /// Cancels any pending timer completion notification.
    ///
    /// Call this when:
    /// - The timer is stopped or reset
    /// - The user manually completes or skips an interval
    /// - A new notification is being scheduled (handled automatically)
    func cancelPending() {
        center.removePendingNotificationRequests(withIdentifiers: [pendingId])
    }

    /// Removes all delivered notifications from the notification center.
    ///
    /// Call this when the app becomes active to clear any lingering notifications.
    func clearDelivered() {
        center.removeDeliveredNotifications(withIdentifiers: [pendingId])
    }

    // MARK: - Private Helpers

    /// Returns the notification title for the given interval type.
    private func notificationTitle(for intervalType: IntervalType) -> String {
        switch intervalType {
        case .work:
            "Pomodoro Complete!"
        case .shortBreak, .longBreak:
            "Break Over!"
        }
    }

    /// Returns the notification body message for the given interval type.
    private func notificationBody(for intervalType: IntervalType) -> String {
        switch intervalType {
        case .work:
            "Great work! Time to take a well-deserved break."
        case .shortBreak:
            "Ready to focus? Let's get back to work!"
        case .longBreak:
            "Feeling refreshed? Time to start a new focus session!"
        }
    }
}

// MARK: - Notification Categories

extension NotificationScheduler {
    /// Registers notification categories for interactive notifications.
    ///
    /// Call this once during app initialization to enable notification actions.
    func registerCategories() {
        let startAction = UNNotificationAction(
            identifier: Identifiers.actionStartNext,
            title: "Start Next",
            options: .foreground
        )

        let dismissAction = UNNotificationAction(
            identifier: Identifiers.actionDismiss,
            title: "Dismiss",
            options: .destructive
        )

        let category = UNNotificationCategory(
            identifier: Identifiers.categoryTimerCompletion,
            actions: [startAction, dismissAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        center.setNotificationCategories([category])
    }
}
