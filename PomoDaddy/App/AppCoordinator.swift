//
//  AppCoordinator.swift
//  PomoDaddy
//
//  Central coordinator that wires up all app components and manages state.
//

import os.log
import SwiftData
import SwiftUI

/// Central coordinator that initializes and wires together all app components.
///
/// AppCoordinator is responsible for:
/// - Initializing all dependencies in the correct order
/// - Setting up callbacks between components
/// - Providing computed properties for the UI
/// - Managing state persistence across app lifecycle
@Observable
@MainActor
internal final class AppCoordinator {
    // MARK: - Dependencies

    /// The SwiftData model container for persistence.
    let modelContainer: ModelContainer

    /// Manages user settings with persistence.
    let settingsManager: any SettingsManaging

    /// The core timer engine.
    let timerEngine: any TimerEngineProtocol

    /// The Pomodoro state machine managing timer logic and transitions.
    let stateMachine: PomodoroStateMachine

    /// Handles local notification scheduling.
    let notificationScheduler: any NotificationScheduling

    /// Thread-safe session recorder (actor).
    let sessionRecorder: any SessionRecording

    /// Manages App Nap prevention during timing.
    let appNapManager: any AppNapManaging

    /// Handles app lifecycle events for state persistence.
    private(set) var lifecycleHandler: AppLifecycleHandler?

    // MARK: - Sub-Coordinators

    /// Manages floating window lifecycle.
    let floatingWindowCoordinator: any FloatingWindowCoordinating

    /// Manages session tracking and celebrations.
    let sessionCoordinator: any SessionCoordinating

    // MARK: - Initialization

    /// Creates a new AppCoordinator, initializing all dependencies.
    convenience init() {
        let modelContainer: ModelContainer = PomodoroDataContainer.create()
        let settingsManager: SettingsManager = SettingsManager()
        let timerEngine: TimerEngine = TimerEngine()
        let sessionRecorder: SessionRecorder = SessionRecorder(modelContainer: modelContainer)

        self.init(
            modelContainer: modelContainer,
            settingsManager: settingsManager,
            timerEngine: timerEngine,
            notificationScheduler: NotificationScheduler(),
            sessionRecorder: sessionRecorder,
            appNapManager: AppNapManager(),
            sessionCoordinator: SessionCoordinator(sessionRecorder: sessionRecorder),
            floatingWindowCoordinator: FloatingWindowCoordinator()
        )
    }

    /// Creates an AppCoordinator with injectable dependencies for testing.
    init(
        modelContainer: ModelContainer,
        settingsManager: any SettingsManaging,
        timerEngine: any TimerEngineProtocol,
        notificationScheduler: any NotificationScheduling,
        sessionRecorder: any SessionRecording,
        appNapManager: any AppNapManaging,
        sessionCoordinator: any SessionCoordinating,
        floatingWindowCoordinator: any FloatingWindowCoordinating,
        persistence: StateMachinePersistence = .shared
    ) {
        self.modelContainer = modelContainer
        self.settingsManager = settingsManager
        self.timerEngine = timerEngine
        self.notificationScheduler = notificationScheduler
        self.sessionRecorder = sessionRecorder
        self.appNapManager = appNapManager
        self.sessionCoordinator = sessionCoordinator
        self.floatingWindowCoordinator = floatingWindowCoordinator

        // Initialize PomodoroStateMachine with timer engine and settings
        stateMachine = PomodoroStateMachine(
            timerEngine: timerEngine,
            settings: settingsManager.settings,
            persistence: persistence
        )

        // Set the app coordinator reference (needs self, so done after init)
        floatingWindowCoordinator.setAppCoordinator(self)

        // Wire settings sync: when SettingsManager changes, update state machine
        settingsManager.onChange = { [weak self] in
            self?.updateSettings()
        }

        // Set up callbacks
        setupCallbacks()

        // Initialize AppLifecycleHandler (needs self, so done after init)
        lifecycleHandler = AppLifecycleHandler(
            onSave: { [weak self] in
                self?.saveState()
            },
            onRestore: { [weak self] in
                self?.restoreState()
            },
            onActivate: { [weak self] in
                self?.notificationScheduler.clearDelivered()
            }
        )

        // Request notification authorization
        Task {
            await notificationScheduler.requestAuthorization()
            notificationScheduler.registerCategories()
        }
    }

    // MARK: - Computed Properties for UI

    /// The current timer state.
    var currentState: TimerState {
        stateMachine.currentState
    }

    /// The remaining seconds on the timer.
    var remainingSeconds: TimeInterval {
        timerEngine.remainingSeconds
    }

    /// The progress from 0.0 to 1.0.
    var progress: Double {
        timerEngine.progress
    }

    /// The number of completed pomodoros in the current cycle.
    var completedPomodorosInCycle: Int {
        stateMachine.completedPomodorosInCycle
    }

    /// The total completed pomodoros today.
    var totalCompletedToday: Int {
        stateMachine.totalCompletedToday
    }

    /// The formatted remaining time (MM:SS).
    var formattedTime: String {
        timerEngine.formattedTime
    }

    /// Whether the timer is currently running.
    var isRunning: Bool {
        timerEngine.isRunning
    }

    /// The current interval type, if any.
    var currentIntervalType: IntervalType? {
        currentState.intervalType
    }

    /// The number of pomodoros until the next long break.
    var pomodorosUntilLongBreak: Int {
        stateMachine.settings.pomodorosUntilLongBreak
    }

    /// Whether the floating window is visible.
    var isFloatingWindowVisible: Bool {
        get { settingsManager.settings.showFloatingWindow }
        set {
            if newValue {
                showFloatingWindow()
            } else {
                hideFloatingWindow()
            }
        }
    }

    /// Whether the menu bar countdown is visible.
    var isMenuBarCountdownVisible: Bool {
        get { settingsManager.settings.showMenuBarCountdown }
        set { settingsManager.setShowMenuBarCountdown(enabled: newValue) }
    }

    // MARK: - Timer Control Methods

    /// Starts the timer with the next appropriate interval type.
    func start() {
        // Track session start time for work intervals
        if stateMachine.nextIntervalType() == .work {
            sessionCoordinator.startSession()
        }
        stateMachine.send(.start())
    }

    /// Starts the timer with a specific interval type.
    func start(intervalType: IntervalType) {
        if intervalType == .work {
            sessionCoordinator.startSession()
        }
        stateMachine.send(.start(intervalType))
    }

    /// Pauses the timer.
    func pause() {
        stateMachine.send(.pause)
    }

    /// Resumes the timer.
    func resume() {
        stateMachine.send(.resume)
    }

    /// Resets the timer.
    func reset() {
        sessionCoordinator.clearSession()
        stateMachine.send(.reset)
    }

    /// Skips the current interval.
    func skip() {
        sessionCoordinator.clearSession()
        stateMachine.send(.skip)
    }

    /// Toggles play/pause based on current state.
    func togglePlayPause() {
        switch currentState {
        case .idle:
            start()
        case .running:
            pause()
        case .paused:
            resume()
        }
    }

    /// Gracefully quits the application after saving state.
    func quit() {
        saveState()
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Floating Window Management

    /// Creates and shows the floating window.
    func showFloatingWindow() {
        floatingWindowCoordinator.show()
        settingsManager.setShowFloatingWindow(enabled: true)
    }

    /// Hides the floating window.
    func hideFloatingWindow() {
        floatingWindowCoordinator.hide()
        settingsManager.setShowFloatingWindow(enabled: false)
    }

    /// Toggles floating window visibility.
    func toggleFloatingWindow() {
        if isFloatingWindowVisible {
            hideFloatingWindow()
        } else {
            showFloatingWindow()
        }
    }

    // MARK: - Private Setup

    /// Sets up all state machine and component callbacks.
    private func setupCallbacks() {
        // Work session completion callback
        stateMachine.onWorkSessionComplete = { [weak self] _ in
            guard let self else { return }

            // Record the completed session and trigger confetti
            Task { @MainActor in
                let durationMinutes: Int = Int(self.stateMachine.settings.workDuration / 60)
                await self.sessionCoordinator.completeSession(durationMinutes: durationMinutes)
            }

            // Show notification if enabled
            if settingsManager.settings.showNotifications {
                notificationScheduler.scheduleCompletion(
                    intervalType: .work,
                    inSeconds: 0 // Immediate notification
                )
            }

            saveState()
        }

        // Break completion callback
        stateMachine.onBreakComplete = { [weak self] intervalType in
            guard let self else { return }

            // Show notification if enabled
            if settingsManager.settings.showNotifications {
                notificationScheduler.scheduleCompletion(
                    intervalType: intervalType,
                    inSeconds: 0 // Immediate notification
                )
            }

            saveState()
        }

        // Cycle completion callback
        stateMachine.onCycleComplete = { [weak self] _ in
            self?.saveState()
        }

        // State change callback - manage App Nap
        stateMachine.onStateChange = { [weak self] _, newState in
            guard let self else { return }

            // Update App Nap based on timer state
            switch newState {
            case .running:
                appNapManager.beginTimingActivity()

                // Track session start for work intervals (in case not already tracked)
                if case .running(.work) = newState, sessionCoordinator.currentSessionStartTime == nil {
                    sessionCoordinator.startSession()
                }

            case .idle, .paused:
                // Only end activity when fully idle
                if case .idle = newState {
                    appNapManager.endTimingActivity()
                }
            }

            saveState()
        }
    }

    // MARK: - State Persistence

    /// Saves the current UI state.
    func saveState() {
        // Settings are auto-saved by SettingsManager via didSet
        floatingWindowCoordinator.savePosition()
    }

    /// Restores the UI state from persistence.
    func restoreState() {
        // Settings are auto-loaded by SettingsManager in init()

        // Show floating window if it should be visible
        if isFloatingWindowVisible {
            showFloatingWindow()
        }
    }

    // MARK: - Settings Sync

    /// Updates the state machine settings when user changes preferences.
    func updateSettings() {
        stateMachine.settings = settingsManager.settings
    }
}

// MARK: - Preview Support

extension AppCoordinator {
    /// Creates an AppCoordinator for SwiftUI previews.
    static var preview: AppCoordinator {
        AppCoordinator()
    }
}
