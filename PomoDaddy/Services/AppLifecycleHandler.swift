//
//  AppLifecycleHandler.swift
//  PomoDaddy
//
//  Handles application lifecycle events for state persistence and timer management.
//

import AppKit
import Combine
import Foundation
/// Manages application lifecycle events to ensure proper state persistence and timer accuracy.
///
/// `AppLifecycleHandler` observes system notifications for events that require
/// the app to save state or adjust timer calculations:
///
/// - **App Termination**: Saves timer state before the app quits
/// - **System Sleep**: Saves state before the Mac goes to sleep
/// - **System Wake**: Restores and adjusts timer after waking from sleep
/// - **App Activation**: Refreshes UI when the app becomes active
///
/// Usage:
/// ```swift
/// let handler = AppLifecycleHandler(
///     onSave: { timerEngine.saveState() },
///     onRestore: { timerEngine.restoreState() }
/// )
/// ```
final class AppLifecycleHandler {
    // MARK: - Properties

    /// Set of Combine cancellables for notification subscriptions.
    private var cancellables = Set<AnyCancellable>()

    /// Callback invoked when state should be saved.
    private let onSave: () -> Void

    /// Callback invoked when state should be restored or adjusted.
    private let onRestore: () -> Void

    /// Callback invoked when the app becomes active (optional).
    private var onActivate: (() -> Void)?

    /// Tracks whether the system was sleeping.
    private var wasAsleep = false

    // MARK: - Initialization

    /// Creates a new lifecycle handler with save and restore callbacks.
    ///
    /// - Parameters:
    ///   - onSave: Callback to invoke when state should be saved.
    ///   - onRestore: Callback to invoke when state should be restored.
    ///   - onActivate: Optional callback when app becomes active.
    init(
        onSave: @escaping () -> Void,
        onRestore: @escaping () -> Void,
        onActivate: (() -> Void)? = nil
    ) {
        self.onSave = onSave
        self.onRestore = onRestore
        self.onActivate = onActivate

        setupObservers()
    }

    deinit {
        cancellables.removeAll()
    }

    // MARK: - Setup

    /// Sets up all lifecycle notification observers.
    private func setupObservers() {
        // App will terminate - save state
        NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)
            .sink { [weak self] _ in
                self?.handleWillTerminate()
            }
            .store(in: &cancellables)

        // System will sleep - save state
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.willSleepNotification)
            .sink { [weak self] _ in
                self?.handleWillSleep()
            }
            .store(in: &cancellables)

        // System did wake - restore/adjust timer
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)
            .sink { [weak self] _ in
                self?.handleDidWake()
            }
            .store(in: &cancellables)

        // App became active - refresh UI
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.handleDidBecomeActive()
            }
            .store(in: &cancellables)

        // App will resign active - optional save
        NotificationCenter.default.publisher(for: NSApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.handleWillResignActive()
            }
            .store(in: &cancellables)
    }

    // MARK: - Event Handlers

    /// Handles the app termination event.
    private func handleWillTerminate() {
        #if DEBUG
        Logger.debug("App will terminate - saving state", log: Logger.lifecycle)
        #endif
        onSave()
    }

    /// Handles the system sleep event.
    private func handleWillSleep() {
        #if DEBUG
        Logger.debug("System will sleep - saving state", log: Logger.lifecycle)
        #endif
        wasAsleep = true
        onSave()
    }

    /// Handles the system wake event.
    private func handleDidWake() {
        #if DEBUG
        Logger.debug("System did wake - restoring state", log: Logger.lifecycle)
        #endif

        guard wasAsleep else { return }
        wasAsleep = false

        // Small delay to let the system stabilize after wake
        Task { @MainActor in
            try await Task.sleep(nanoseconds: 500_000_000)
            onRestore()
        }
    }

    /// Handles the app becoming active.
    private func handleDidBecomeActive() {
        #if DEBUG
        Logger.debug("App did become active", log: Logger.lifecycle)
        #endif
        onActivate?()
    }

    /// Handles the app resigning active status.
    private func handleWillResignActive() {
        #if DEBUG
        Logger.debug("App will resign active", log: Logger.lifecycle)
        #endif
        // Optionally save state when going to background
        // This provides an extra safety net
        onSave()
    }

    // MARK: - Public Methods

    /// Sets the callback to invoke when the app becomes active.
    ///
    /// - Parameter callback: The callback to invoke.
    func setActivateCallback(_ callback: @escaping () -> Void) {
        onActivate = callback
    }

    /// Manually triggers a save operation.
    ///
    /// Call this when you want to explicitly save state outside
    /// of automatic lifecycle events.
    func saveNow() {
        onSave()
    }

    /// Manually triggers a restore operation.
    ///
    /// Call this when you want to explicitly restore state outside
    /// of automatic lifecycle events.
    func restoreNow() {
        onRestore()
    }
}

// MARK: - Screen Lock Handling

extension AppLifecycleHandler {
    /// Adds observers for screen lock/unlock events.
    ///
    /// Note: Screen lock notifications require additional entitlements
    /// and may not be available in all contexts.
    func observeScreenLock() {
        // Screen lock notification
        DistributedNotificationCenter.default().publisher(
            for: Notification.Name("com.apple.screenIsLocked")
        )
        .sink { [weak self] _ in
            #if DEBUG
            Logger.debug("Screen locked - saving state", log: Logger.lifecycle)
            #endif
            self?.onSave()
        }
        .store(in: &cancellables)

        // Screen unlock notification
        DistributedNotificationCenter.default().publisher(
            for: Notification.Name("com.apple.screenIsUnlocked")
        )
        .sink { [weak self] _ in
            #if DEBUG
            Logger.debug("Screen unlocked", log: Logger.lifecycle)
            #endif
            self?.onActivate?()
        }
        .store(in: &cancellables)
    }
}
