import AppKit
import SwiftUI
import UserNotifications

internal final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var coordinator: AppCoordinator?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set activation policy to accessory (no dock icon)
        NSApp.setActivationPolicy(.accessory)

        // Initialize coordinator (owns all state)
        let appCoordinator: AppCoordinator = AppCoordinator()
        coordinator = appCoordinator

        // Set notification delegate to handle interactive actions
        UNUserNotificationCenter.current().delegate = self

        // Initialize status bar controller
        statusBarController = StatusBarController(coordinator: appCoordinator)

        // Restore UI state (e.g., show floating window if enabled in settings)
        appCoordinator.restoreState()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Save timer state
        coordinator?.saveState()
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        switch response.actionIdentifier {
        case NotificationScheduler.Identifiers.actionStartNext:
            Task { @MainActor in
                coordinator?.start()
            }
        default:
            break
        }
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notifications even when app is in foreground
        completionHandler([.banner, .sound])
    }
}
