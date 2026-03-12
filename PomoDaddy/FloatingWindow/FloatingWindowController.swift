//
//  FloatingWindowController.swift
//  PomoDaddy
//
//  NSPanel-based floating window controller for the always-on-top timer display.
//

import AppKit
import SwiftUI

// MARK: - Floating Window Controller

/// Manages an NSPanel-based floating window that displays the timer.
///
/// Features:
/// - Stays above other windows (.floating level)
/// - Doesn't steal focus from other apps (.nonactivatingPanel)
/// - Draggable by background
/// - Persists position across launches
/// - Visible on all Spaces
final class FloatingWindowController {
    // MARK: - Properties

    /// The floating panel instance.
    private var panel: NSPanel?

    /// Reference to the app coordinator for state access.
    private weak var coordinator: AppCoordinator?

    /// The hosted SwiftUI view.
    private var hostingView: NSHostingView<FloatingTimerView>?

    // MARK: - Constants

    /// Frame autosave name for position persistence.
    private static let frameAutosaveName = AppConstants.FloatingWindow.frameAutosaveName

    /// Default window size.
    private static let defaultSize = NSSize(
        width: AppConstants.FloatingWindow.defaultWidth,
        height: AppConstants.FloatingWindow.defaultHeight
    )

    /// Compact window size.
    private static let compactSize = NSSize(
        width: AppConstants.FloatingWindow.compactWidth,
        height: AppConstants.FloatingWindow.compactHeight
    )

    // MARK: - Initialization

    /// Creates a new floating window controller.
    /// - Parameter coordinator: The app coordinator providing timer state.
    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
        createPanel()
    }

    deinit {
        panel?.close()
        panel = nil
    }

    // MARK: - Panel Creation

    /// Creates and configures the NSPanel with all required properties.
    private func createPanel() {
        guard let coordinator else { return }

        // Calculate initial frame
        let contentRect = NSRect(
            x: 0,
            y: 0,
            width: Self.defaultSize.width,
            height: Self.defaultSize.height
        )

        // Create panel with borderless style for custom appearance
        let styleMask: NSWindow.StyleMask = [
            .borderless,
            .nonactivatingPanel
        ]

        let panel = NSPanel(
            contentRect: contentRect,
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )

        // Configure panel behavior
        configurePanel(panel)

        // Create and set the content view
        let floatingView = FloatingTimerView(coordinator: coordinator)
        let hostingView = NSHostingView(rootView: floatingView)
        hostingView.frame = contentRect

        panel.contentView = hostingView
        self.hostingView = hostingView
        self.panel = panel

        // Restore saved position or center on screen
        restorePosition(panel)
    }

    /// Configures the panel with all necessary properties for floating behavior.
    /// - Parameter panel: The panel to configure.
    private func configurePanel(_ panel: NSPanel) {
        // Window level - stays above normal windows
        panel.level = .floating

        // Transparency and appearance
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true

        // Behavior flags
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.canHide = false

        // Allow window to appear on all Spaces and in full screen apps
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary
        ]

        // Don't show in window menu or mission control
        panel.isExcludedFromWindowsMenu = true

        // Allow mouse events to pass through to window for dragging
        panel.acceptsMouseMovedEvents = true
        panel.ignoresMouseEvents = false

        // Set frame autosave name for position persistence
        panel.setFrameAutosaveName(Self.frameAutosaveName)

        // Prevent the panel from becoming the key window
        // (keeps focus on whatever app the user is working in)
        panel.becomesKeyOnlyIfNeeded = true
    }

    /// Restores the panel position from saved state or centers it.
    /// - Parameter panel: The panel to position.
    private func restorePosition(_ panel: NSPanel) {
        // If setFrameAutosaveName worked, the frame is already restored
        // Otherwise, center the window on the main screen
        if !panel.setFrameUsingName(Self.frameAutosaveName) {
            if let screen = NSScreen.main {
                let screenFrame = screen.visibleFrame
                let x = screenFrame.maxX - panel.frame.width - 20
                let y = screenFrame.maxY - panel.frame.height - 20
                panel.setFrameOrigin(NSPoint(x: x, y: y))
            }
        }
    }

    // MARK: - Public Interface

    /// Shows the floating window.
    func show() {
        panel?.orderFront(nil)
    }

    /// Hides the floating window.
    func hide() {
        panel?.orderOut(nil)
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
        panel?.isVisible ?? false
    }

    // MARK: - Window Size Management

    /// Updates the window size for compact or full mode.
    /// - Parameter compact: Whether to use compact size.
    func setCompactMode(_ compact: Bool) {
        guard let panel else { return }

        let newSize = compact ? Self.compactSize : Self.defaultSize

        // Animate the size change
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            var newFrame = panel.frame
            // Keep top-right corner anchored
            newFrame.origin.y += newFrame.height - newSize.height
            newFrame.size = newSize

            panel.animator().setFrame(newFrame, display: true)
        }
    }

    /// Brings the floating window to front without stealing focus.
    func bringToFront() {
        panel?.orderFrontRegardless()
    }

    /// Saves the current window position.
    func savePosition() {
        panel?.saveFrame(usingName: Self.frameAutosaveName)
    }
}

// MARK: - FloatingWindowController Extension for Testing

#if DEBUG
extension FloatingWindowController {
    /// Returns the panel for testing purposes.
    var testPanel: NSPanel? {
        panel
    }
}
#endif
