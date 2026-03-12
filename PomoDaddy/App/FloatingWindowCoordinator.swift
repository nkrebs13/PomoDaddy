//
//  FloatingWindowCoordinator.swift
//  PomoDaddy
//
//  Manages the floating window lifecycle and visibility.
//

import Foundation

/// Coordinates the floating window controller lifecycle.
@MainActor
final class FloatingWindowCoordinator {
    // MARK: - Properties

    /// The floating window controller instance.
    private var floatingWindowController: FloatingWindowController?

    /// Weak reference to the app coordinator for creating the window.
    private weak var appCoordinator: AppCoordinator?

    // MARK: - Initialization

    init() {
        // appCoordinator will be set after initialization
    }

    /// Sets the app coordinator reference.
    func setAppCoordinator(_ coordinator: AppCoordinator) {
        self.appCoordinator = coordinator
    }

    // MARK: - Window Management

    /// Creates and shows the floating window.
    func show() {
        guard let coordinator = appCoordinator else { return }

        if floatingWindowController == nil {
            floatingWindowController = FloatingWindowController(coordinator: coordinator)
        }
        floatingWindowController?.show()
    }

    /// Hides the floating window.
    func hide() {
        floatingWindowController?.hide()
    }

    /// Toggles the floating window visibility.
    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }

    /// Returns whether the floating window is currently visible.
    var isVisible: Bool {
        floatingWindowController?.isVisible ?? false
    }

    /// Saves the floating window position.
    func savePosition() {
        floatingWindowController?.savePosition()
    }
}
