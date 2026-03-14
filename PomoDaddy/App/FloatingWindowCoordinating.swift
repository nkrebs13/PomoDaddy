//
//  FloatingWindowCoordinating.swift
//  PomoDaddy
//
//  Protocol for floating window coordination dependency injection.
//

import Foundation

/// Protocol defining the floating window coordination interface for dependency injection and testing.
///
/// Note: `setAppCoordinator(_:)` takes concrete `AppCoordinator` (not a protocol) because
/// the floating window creates views that require `@Bindable AppCoordinator` for SwiftUI observation.
@MainActor
protocol FloatingWindowCoordinating: AnyObject {
    /// Creates and shows the floating window.
    func show()

    /// Hides the floating window.
    func hide()

    /// Toggles the floating window visibility.
    func toggle()

    /// Saves the floating window position.
    func savePosition()

    /// Sets the app coordinator reference.
    /// - Parameter coordinator: The app coordinator instance.
    func setAppCoordinator(_ coordinator: AppCoordinator)
}
