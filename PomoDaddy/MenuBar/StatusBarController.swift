//
//  StatusBarController.swift
//  PomoDaddy
//
//  Controls the menu bar status item, popover, and dynamic icon.
//

import AppKit
import Combine
import SwiftUI

// MARK: - Status Bar Controller

/// Controls the menu bar status item and its associated popover.
///
/// Responsibilities:
/// - Creates and manages the NSStatusItem in the menu bar
/// - Displays a custom DynamicMenuBarIconView showing timer state
/// - Shows/hides a popover with timer controls on click
/// - Closes popover when clicking outside
@MainActor
final class StatusBarController {
    // MARK: - Properties

    /// The status item displayed in the menu bar.
    private var statusItem: NSStatusItem

    /// The popover containing timer controls.
    private var popover: NSPopover

    /// Reference to the app coordinator for state management.
    private weak var coordinator: AppCoordinator?

    /// The custom icon view displaying timer state.
    private var iconView: DynamicMenuBarIconView?

    /// Monitor for detecting clicks outside the popover.
    private var eventMonitor: Any?

    /// Cancellable for the icon update polling timer.
    private var pollCancellable: AnyCancellable?

    // MARK: - Initialization

    /// Creates a new status bar controller.
    /// - Parameter coordinator: The app coordinator managing timer state.
    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator

        // Create status item with variable length to accommodate time display
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // Create popover for timer controls
        popover = NSPopover()

        setupStatusItem()
        setupPopover()
        setupEventMonitor()
        setupObservation()
    }

    deinit {
        // Remove event monitor on deallocation
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    // MARK: - Setup

    /// Sets up the status bar item with a custom icon view.
    private func setupStatusItem() {
        guard let coordinator else { return }

        // Create custom icon view
        let iconView = DynamicMenuBarIconView(coordinator: coordinator)
        self.iconView = iconView

        // Configure the status item button
        if let button = statusItem.button {
            // Set the custom view as a subview of the button
            iconView.translatesAutoresizingMaskIntoConstraints = false
            button.addSubview(iconView)

            NSLayoutConstraint.activate([
                iconView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
                iconView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
                iconView.topAnchor.constraint(equalTo: button.topAnchor),
                iconView.bottomAnchor.constraint(equalTo: button.bottomAnchor)
            ])

            // Set button action
            button.action = #selector(statusBarButtonClicked(_:))
            button.target = self

            // Enable sending action on left click
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    /// Sets up the popover with SwiftUI content.
    private func setupPopover() {
        guard let coordinator else { return }

        popover.contentSize = NSSize(width: AppConstants.MenuPopover.width, height: AppConstants.MenuPopover.height)
        popover.behavior = .transient
        popover.animates = true

        // Create SwiftUI content view
        let contentView = MenuPopoverView(coordinator: coordinator)
        popover.contentViewController = NSHostingController(rootView: contentView)
    }

    /// Sets up event monitor to close popover when clicking outside.
    private func setupEventMonitor() {
        // Monitor for clicks outside the popover
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if let self, popover.isShown {
                hidePopover()
            }
        }
    }

    /// Sets up observation of coordinator state changes.
    private func setupObservation() {
        // Update icon periodically since @Observable doesn't work directly with NSView.
        // Use 1s interval — countdown only changes once per second.
        startPolling()
    }

    /// Starts the icon update polling timer.
    private func startPolling() {
        stopPolling()
        pollCancellable = Timer.publish(every: AppConstants.MenuBar.iconUpdateInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateIcon()
            }
    }

    /// Stops the icon update polling timer.
    private func stopPolling() {
        pollCancellable?.cancel()
        pollCancellable = nil
    }

    // MARK: - Public Methods

    /// Updates the icon view to reflect current timer state.
    func updateIcon() {
        iconView?.update()

        // Update status item length based on whether time is shown
        if let coordinator,
           coordinator.isMenuBarCountdownVisible,
           coordinator.stateMachine.currentState.isActive
        {
            statusItem.length = NSStatusItem.variableLength
        } else {
            statusItem.length = 22
        }

        // Update accessibility label
        if let coordinator {
            let state = coordinator.stateMachine.currentState
            statusItem.button?.setAccessibilityLabel("PomoDaddy: \(state.displayName)")
        }
    }

    /// Shows the popover attached to the status item.
    func showPopover() {
        guard let button = statusItem.button else { return }

        // Anchor to the rightmost portion of the button. macOS status items
        // grow leftward — the right edge is screen-stable regardless of
        // width changes from the timer countdown text.
        let anchorWidth: CGFloat = min(button.bounds.width, 22)
        let anchorRect = NSRect(
            x: button.bounds.width - anchorWidth,
            y: button.bounds.origin.y,
            width: anchorWidth,
            height: button.bounds.height
        )
        popover.show(relativeTo: anchorRect, of: button, preferredEdge: .minY)

        // Make the popover's window key to receive keyboard events
        popover.contentViewController?.view.window?.makeKey()
    }

    /// Hides the popover.
    func hidePopover() {
        popover.performClose(nil)
    }

    /// Toggles the popover visibility.
    func togglePopover() {
        if popover.isShown {
            hidePopover()
        } else {
            showPopover()
        }
    }

    // MARK: - Actions

    /// Handles clicks on the status bar button.
    @objc
    private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else {
            togglePopover()
            return
        }

        if event.type == .rightMouseUp {
            // Right click shows context menu
            showContextMenu()
        } else {
            // Left click toggles popover
            togglePopover()
        }
    }

    /// Shows a context menu on right-click.
    private func showContextMenu() {
        let menu = NSMenu()

        // Quick actions
        if let coordinator {
            let state = coordinator.stateMachine.currentState

            if state.isRunning {
                menu.addItem(NSMenuItem(title: "Pause", action: #selector(pauseTimer), keyEquivalent: ""))
            } else if state.isPaused {
                menu.addItem(NSMenuItem(title: "Resume", action: #selector(resumeTimer), keyEquivalent: ""))
            } else {
                menu.addItem(NSMenuItem(title: "Start Focus", action: #selector(startTimer), keyEquivalent: ""))
            }

            menu.addItem(NSMenuItem.separator())
        }

        // Toggle floating window
        let windowItem = NSMenuItem(
            title: "Show Floating Window",
            action: #selector(toggleFloatingWindow),
            keyEquivalent: ""
        )
        windowItem.state = coordinator?.isFloatingWindowVisible == true ? .on : .off
        menu.addItem(windowItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        menu.addItem(NSMenuItem(title: "Quit PomoDaddy", action: #selector(quitApp), keyEquivalent: "q"))

        // Set targets
        for item in menu.items {
            item.target = self
        }

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc
    private func startTimer() {
        coordinator?.start()
    }

    @objc
    private func pauseTimer() {
        coordinator?.pause()
    }

    @objc
    private func resumeTimer() {
        coordinator?.resume()
    }

    @objc
    private func toggleFloatingWindow() {
        coordinator?.isFloatingWindowVisible.toggle()
    }

    @objc
    private func quitApp() {
        coordinator?.quit()
    }
}
