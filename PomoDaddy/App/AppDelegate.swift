import AppKit
import SwiftUI
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var coordinator: AppCoordinator?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set activation policy to accessory (no dock icon)
        NSApp.setActivationPolicy(.accessory)

        // Initialize coordinator (owns all state)
        let appCoordinator = AppCoordinator()
        coordinator = appCoordinator

        // Set notification delegate to handle interactive actions
        UNUserNotificationCenter.current().delegate = self

        // Initialize status bar controller
        statusBarController = StatusBarController(coordinator: appCoordinator)
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
        case "START_NEXT":
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
