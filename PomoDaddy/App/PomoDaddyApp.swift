import SwiftUI

@main
struct PomoDaddyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate: AppDelegate

    var body: some Scene {
        // Menu bar apps don't need WindowGroup
        // Settings window can be added later if needed
        Settings {
            EmptyView()
        }
    }
}
