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

    /// Floating window controller (created lazily when needed).
    private var floatingWindowController: FloatingWindowController?

    /// Task for hiding confetti animation (cancelled in deinit to prevent leaks).
    private var confettiHideTask: Task<Void, Never>?

    // MARK: - UI State

    /// Whether the floating window is visible.
    var isFloatingWindowVisible = true {
        didSet {
            if oldValue != isFloatingWindowVisible {
                handleFloatingWindowVisibilityChange()
            }
        }
    }

    /// Whether the menu bar countdown is visible.
    var isMenuBarCountdownVisible = true

    /// Whether confetti should be shown (for work session completion).
    var showConfetti = false

    // MARK: - Session Tracking

    /// The start time of the current work session (for recording).
    private var currentSessionStartTime: Date?

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
        let timerSettings = Self.createTimerSettings(from: settingsManager.settings)
        stateMachine = PomodoroStateMachine(
            timerEngine: timerEngine,
            settings: timerSettings
        )

        // 5. Initialize NotificationScheduler
        notificationScheduler = NotificationScheduler()

        // 6. Initialize SessionRecorder with ModelContainer
        sessionRecorder = SessionRecorder(modelContainer: modelContainer)

        // 7. Initialize StatsCalculator with ModelContext
        statsCalculator = StatsCalculator(modelContext: modelContainer.mainContext)

        // 8. Initialize AppNapManager
        appNapManager = AppNapManager()

        // Restore persisted UI state
        restoreState()

        // Set up callbacks
        setupCallbacks()

        // 9. Initialize AppLifecycleHandler (needs self, so done after init)
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

    // MARK: - Timer Control Methods

    /// Starts the timer with the next appropriate interval type.
    func start() {
        // Track session start time for work intervals
        if stateMachine.nextIntervalType() == .work {
            currentSessionStartTime = Date()
        }
        stateMachine.send(.start())
    }

    /// Starts the timer with a specific interval type.
    func start(intervalType: IntervalType) {
        if intervalType == .work {
            currentSessionStartTime = Date()
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
        currentSessionStartTime = nil
        stateMachine.send(.reset)
    }

    /// Skips the current interval.
    func skip() {
        currentSessionStartTime = nil
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
        if floatingWindowController == nil {
            floatingWindowController = FloatingWindowController(coordinator: self)
        }
        floatingWindowController?.show()
        isFloatingWindowVisible = true
    }

    /// Hides the floating window.
    func hideFloatingWindow() {
        floatingWindowController?.hide()
        isFloatingWindowVisible = false
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

            // Record the completed session
            Task { @MainActor in
                await self.recordCompletedSession()
            }

            // Trigger confetti celebration
            showConfetti = true

            // Reset confetti after animation
            confettiHideTask?.cancel()
            confettiHideTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                guard !Task.isCancelled else { return }
                self.showConfetti = false
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

                // Track session start for work intervals
                if case .running(.work) = newState, currentSessionStartTime == nil {
                    currentSessionStartTime = Date()
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

    /// Records a completed work session to the database.
    private func recordCompletedSession() async {
        guard let startTime = currentSessionStartTime else { return }

        let endTime = Date()
        let durationMinutes = Int(stateMachine.settings.workDuration / 60)

        do {
            try await sessionRecorder.record(
                startDate: startTime,
                endDate: endTime,
                durationMinutes: durationMinutes,
                wasCompleted: true
            )
        } catch {
            Logger.logError(error, context: "Failed to record session", log: Logger.stats)
        }

        // Reset for next session
        currentSessionStartTime = nil
    }

    /// Handles floating window visibility changes.
    private func handleFloatingWindowVisibilityChange() {
        if isFloatingWindowVisible {
            showFloatingWindow()
        } else {
            hideFloatingWindow()
        }

        // Persist the preference
        UserDefaults.standard.set(isFloatingWindowVisible, forKey: "isFloatingWindowVisible")
    }

    // MARK: - State Persistence

    /// Keys for UserDefaults persistence.
    private enum PersistenceKeys {
        static let isFloatingWindowVisible = "isFloatingWindowVisible"
        static let isMenuBarCountdownVisible = "isMenuBarCountdownVisible"
    }

    /// Saves the current UI state.
    func saveState() {
        UserDefaults.standard.set(isFloatingWindowVisible, forKey: PersistenceKeys.isFloatingWindowVisible)
        UserDefaults.standard.set(isMenuBarCountdownVisible, forKey: PersistenceKeys.isMenuBarCountdownVisible)

        // Save floating window position
        floatingWindowController?.savePosition()
    }

    /// Restores the UI state from persistence.
    func restoreState() {
        // Restore floating window visibility preference
        if UserDefaults.standard.object(forKey: PersistenceKeys.isFloatingWindowVisible) != nil {
            isFloatingWindowVisible = UserDefaults.standard.bool(forKey: PersistenceKeys.isFloatingWindowVisible)
        }

        // Restore menu bar countdown visibility preference
        if UserDefaults.standard.object(forKey: PersistenceKeys.isMenuBarCountdownVisible) != nil {
            isMenuBarCountdownVisible = UserDefaults.standard.bool(forKey: PersistenceKeys.isMenuBarCountdownVisible)
        }

        // Show floating window if it should be visible
        if isFloatingWindowVisible {
            showFloatingWindow()
        }
    }

    // MARK: - Settings Sync

    /// Creates TimerSettings from PomodoroSettings.
    private static func createTimerSettings(from pomodoroSettings: PomodoroSettings) -> TimerSettings {
        TimerSettings(
            workDuration: pomodoroSettings.workDuration,
            shortBreakDuration: pomodoroSettings.shortBreakDuration,
            longBreakDuration: pomodoroSettings.longBreakDuration,
            pomodorosUntilLongBreak: pomodoroSettings.pomodorosUntilLongBreak,
            autoStartBreaks: pomodoroSettings.autoStartNextSession,
            autoStartWork: pomodoroSettings.autoStartNextSession,
            soundEnabled: true,
            notificationsEnabled: pomodoroSettings.showNotifications
        )
    }

    /// Updates the state machine settings when user changes preferences.
    func updateSettings() {
        let timerSettings = Self.createTimerSettings(from: settingsManager.settings)
        stateMachine.settings = timerSettings
    }
}

// MARK: - Preview Support

extension AppCoordinator {
    /// Creates an AppCoordinator for SwiftUI previews.
    static var preview: AppCoordinator {
        AppCoordinator()
    }
}
