import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var coordinator: AppCoordinator?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set activation policy to accessory (no dock icon)
        NSApp.setActivationPolicy(.accessory)

        // Initialize coordinator (owns all state)
        let appCoordinator = AppCoordinator()
        coordinator = appCoordinator

        // Initialize status bar controller
        statusBarController = StatusBarController(coordinator: appCoordinator)
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Save timer state
        coordinator?.saveState()
    }
}
