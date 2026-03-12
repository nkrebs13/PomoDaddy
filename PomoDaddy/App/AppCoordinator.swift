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
final class AppCoordinator {
    // MARK: - Dependencies

    /// The SwiftData model container for persistence.
    let modelContainer: ModelContainer

    /// Manages user settings with persistence.
    let settingsManager: SettingsManager

    /// The core timer engine.
    let timerEngine: TimerEngine

    /// The Pomodoro state machine managing timer logic and transitions.
    let stateMachine: PomodoroStateMachine

    /// Handles local notification scheduling.
    let notificationScheduler: NotificationScheduler

    /// Thread-safe session recorder (actor).
    let sessionRecorder: SessionRecorder

    /// Statistics calculator for querying aggregated data.
    let statsCalculator: StatsCalculator

    /// Manages App Nap prevention during timing.
    let appNapManager: AppNapManager

    /// Handles app lifecycle events for state persistence.
    private(set) var lifecycleHandler: AppLifecycleHandler?

    // MARK: - Sub-Coordinators

    /// Manages UI state preferences.
    let uiStateCoordinator: UIStateCoordinator

    /// Manages floating window lifecycle.
    let floatingWindowCoordinator: FloatingWindowCoordinator

    /// Manages session tracking and celebrations.
    let sessionCoordinator: SessionCoordinator

    // MARK: - Initialization

    /// Creates a new AppCoordinator, initializing all dependencies.
    init() {
        // 1. Initialize ModelContainer first (data layer)
        modelContainer = PomodoroDataContainer.create()

        // 2. Initialize SettingsManager
        settingsManager = SettingsManager()

        // 3. Initialize TimerEngine
        timerEngine = TimerEngine()

        // 4. Initialize PomodoroStateMachine with TimerEngine and settings
        stateMachine = PomodoroStateMachine(
            timerEngine: timerEngine,
            settings: settingsManager.settings
        )

        // 5. Initialize NotificationScheduler
        notificationScheduler = NotificationScheduler()

        // 6. Initialize SessionRecorder with ModelContainer
        sessionRecorder = SessionRecorder(modelContainer: modelContainer)

        // 7. Initialize StatsCalculator with ModelContext
        statsCalculator = StatsCalculator(modelContext: modelContainer.mainContext)

        // 8. Initialize AppNapManager
        appNapManager = AppNapManager()

        // 9. Initialize sub-coordinators
        uiStateCoordinator = UIStateCoordinator()
        sessionCoordinator = SessionCoordinator(sessionRecorder: sessionRecorder)
        floatingWindowCoordinator = FloatingWindowCoordinator()

        // Set the app coordinator reference (needs self, so done after init)
        floatingWindowCoordinator.setAppCoordinator(self)

        // Set up callbacks
        setupCallbacks()

        // 10. Initialize AppLifecycleHandler (needs self, so done after init)
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

    /// Whether confetti should be shown (for work session completion).
    var showConfetti: Bool {
        sessionCoordinator.showConfetti
    }

    /// Whether the floating window is visible.
    var isFloatingWindowVisible: Bool {
        get { uiStateCoordinator.isFloatingWindowVisible }
        set { uiStateCoordinator.isFloatingWindowVisible = newValue }
    }

    /// Whether the menu bar countdown is visible.
    var isMenuBarCountdownVisible: Bool {
        get { uiStateCoordinator.isMenuBarCountdownVisible }
        set { uiStateCoordinator.isMenuBarCountdownVisible = newValue }
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

    // MARK: - Stats Methods

    /// Returns today's statistics.
    func todayStats() throws -> DailyStats? {
        try statsCalculator.todayStats()
    }

    /// Returns the weekly trend data.
    func weeklyTrend() throws -> [DailyStats] {
        try statsCalculator.weeklyTrend()
    }

    /// Returns the current user streak.
    func currentStreak() throws -> UserStreak? {
        try statsCalculator.currentStreak()
    }

    /// Returns today's total focus minutes.
    func todayFocusMinutes() throws -> Int {
        try statsCalculator.todayFocusMinutes()
    }

    /// Returns the weekly summary.
    func weeklySummary() throws -> StatsCalculator.WeeklySummary {
        try statsCalculator.weeklySummary()
    }

    // MARK: - Floating Window Management

    /// Creates and shows the floating window.
    func showFloatingWindow() {
        floatingWindowCoordinator.show()
        uiStateCoordinator.isFloatingWindowVisible = true
    }

    /// Hides the floating window.
    func hideFloatingWindow() {
        floatingWindowCoordinator.hide()
        uiStateCoordinator.isFloatingWindowVisible = false
    }

    /// Toggles floating window visibility.
    func toggleFloatingWindow() {
        if uiStateCoordinator.isFloatingWindowVisible {
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
                let durationMinutes = Int(self.stateMachine.settings.workDuration / 60)
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
        uiStateCoordinator.saveState()
        floatingWindowCoordinator.savePosition()
    }

    /// Restores the UI state from persistence.
    func restoreState() {
        uiStateCoordinator.restoreState()

        // Show floating window if it should be visible
        if uiStateCoordinator.isFloatingWindowVisible {
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
