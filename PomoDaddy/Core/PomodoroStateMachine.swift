//
//  PomodoroStateMachine.swift
//  PomoDaddy
//
//  State machine managing all Pomodoro timer logic and transitions.
//

import Foundation
import Observation
import os.log

// MARK: - Pomodoro Events

/// Events that can trigger state transitions in the Pomodoro state machine.
internal enum PomodoroEvent {
    case start(IntervalType? = nil)
    case pause
    case resume
    case complete
    case reset
    case skip
}

// MARK: - Pomodoro State Machine

/// Manages the complete Pomodoro workflow including state transitions,
/// interval tracking, and integration with the timer engine.
@Observable
@MainActor
internal final class PomodoroStateMachine {
    // MARK: - Public Properties

    /// The current state of the Pomodoro timer.
    private(set) var currentState: TimerState = .idle

    /// Number of completed pomodoros in the current cycle (resets after long break).
    private(set) var completedPomodorosInCycle: Int = 0

    /// Total number of pomodoros completed today.
    private(set) var totalCompletedToday: Int = 0

    /// The underlying timer engine.
    let timerEngine: any TimerEngineProtocol

    /// User-configurable timer settings.
    var settings: PomodoroSettings

    /// Persistence service for state machine state.
    private let persistence: StateMachinePersistence

    // MARK: - Callbacks

    /// Called when a work session completes.
    var onWorkSessionComplete: ((Int) -> Void)?

    /// Called when a break completes.
    var onBreakComplete: ((IntervalType) -> Void)?

    /// Called when the timer state changes.
    var onStateChange: ((TimerState, TimerState) -> Void)?

    /// Called when a cycle completes (after long break).
    var onCycleComplete: ((Int) -> Void)?

    // MARK: - Private Properties

    /// The date when today's count was last reset.
    private var lastResetDate: Date?

    // MARK: - Initialization

    init(
        timerEngine: any TimerEngineProtocol = TimerEngine(),
        settings: PomodoroSettings = .default,
        persistence: StateMachinePersistence = .shared
    ) {
        self.timerEngine = timerEngine
        self.settings = settings
        self.persistence = persistence
        lastResetDate = Calendar.current.startOfDay(for: Date())

        loadPersistedState()
    }

    // MARK: - Public Methods

    /// Processes an event and performs the appropriate state transition.
    /// - Parameter event: The event to process.
    func send(_ event: PomodoroEvent) {
        resetDailyCountIfNeeded()

        switch event {
        case .start(let intervalType):
            handleStart(intervalType: intervalType)

        case .pause:
            handlePause()

        case .resume:
            handleResume()

        case .complete:
            handleComplete()

        case .reset:
            handleReset()

        case .skip:
            handleSkip()
        }

        // Note: persistState() is called from notifyStateChange() to avoid redundant persists
    }

    /// Returns the next interval type that will follow the current one.
    func nextIntervalType() -> IntervalType {
        switch currentState {
        case .idle:
            // If we've completed pomodoros but haven't taken a break yet,
            // return the appropriate break type
            if completedPomodorosInCycle > 0 {
                if completedPomodorosInCycle >= settings.pomodorosUntilLongBreak {
                    return .longBreak
                } else {
                    return .shortBreak
                }
            }
            return .work

        case .running(let type), .paused(let type):
            switch type {
            case .work:
                // After work, determine break type
                let nextPomodoroCount: Int = completedPomodorosInCycle + 1
                if nextPomodoroCount >= settings.pomodorosUntilLongBreak {
                    return .longBreak
                }
                return .shortBreak

            case .shortBreak, .longBreak:
                return .work
            }
        }
    }

    /// Returns the duration for a given interval type.
    func duration(for intervalType: IntervalType) -> TimeInterval {
        switch intervalType {
        case .work:
            settings.workDuration
        case .shortBreak:
            settings.shortBreakDuration
        case .longBreak:
            settings.longBreakDuration
        }
    }

    /// Returns the formatted remaining time from the timer engine.
    var formattedTime: String {
        timerEngine.formattedTime
    }

    /// Returns the progress from the timer engine.
    var progress: Double {
        timerEngine.progress
    }

    /// Returns whether the timer is currently running.
    var isRunning: Bool {
        timerEngine.isRunning
    }

    // MARK: - Private Methods - Event Handlers

    private func handleStart(intervalType: IntervalType?) {
        let type: IntervalType = intervalType ?? nextIntervalType()
        let duration: TimeInterval = duration(for: type)

        let oldState: TimerState = currentState
        currentState = .running(type)

        timerEngine.start(
            seconds: duration,
            onTick: nil,
            onComplete: { [weak self] in
                self?.send(.complete)
            }
        )

        notifyStateChange(from: oldState, to: currentState)
    }

    private func handlePause() {
        guard case .running(let type) = currentState else { return }

        let oldState: TimerState = currentState
        timerEngine.pause()
        currentState = .paused(type)

        notifyStateChange(from: oldState, to: currentState)
    }

    private func handleResume() {
        guard case .paused(let type) = currentState else { return }

        let oldState: TimerState = currentState
        timerEngine.resume()
        currentState = .running(type)

        notifyStateChange(from: oldState, to: currentState)
    }

    private func handleComplete() {
        guard let intervalType: IntervalType = currentState.intervalType else { return }

        let oldState: TimerState = currentState

        switch intervalType {
        case .work:
            completedPomodorosInCycle += 1
            totalCompletedToday += 1

            onWorkSessionComplete?(totalCompletedToday)

            // Determine next break type
            let nextBreak: IntervalType = if completedPomodorosInCycle >= settings.pomodorosUntilLongBreak {
                .longBreak
            } else {
                .shortBreak
            }

            // Auto-start break if enabled
            if settings.autoStartBreaks {
                currentState = .running(nextBreak)
                startTimer(for: nextBreak)
            } else {
                currentState = .idle
                timerEngine.stop()
            }

        case .shortBreak:
            onBreakComplete?(intervalType)
            transitionAfterBreak()

        case .longBreak:
            let completedCycles: Int = totalCompletedToday / settings.pomodorosUntilLongBreak
            onCycleComplete?(completedCycles)
            onBreakComplete?(intervalType)
            completedPomodorosInCycle = 0
            transitionAfterBreak()
        }

        notifyStateChange(from: oldState, to: currentState)
    }

    private func handleReset() {
        let oldState: TimerState = currentState

        timerEngine.stop()
        currentState = .idle
        completedPomodorosInCycle = 0
        // Note: totalCompletedToday is NOT reset here, only on new day

        notifyStateChange(from: oldState, to: currentState)
    }

    private func handleSkip() {
        guard currentState.isActive else { return }

        // Skip current interval without counting it as complete
        let oldState: TimerState = currentState
        timerEngine.stop()
        currentState = .idle

        notifyStateChange(from: oldState, to: currentState)
    }

    // MARK: - Private Methods - Helpers

    /// Transitions to work or idle after a break completes, based on auto-start setting.
    private func transitionAfterBreak() {
        if settings.autoStartWork {
            currentState = .running(.work)
            startTimer(for: .work)
        } else {
            currentState = .idle
            timerEngine.stop()
        }
    }

    private func startTimer(for intervalType: IntervalType) {
        let duration: TimeInterval = duration(for: intervalType)
        timerEngine.start(
            seconds: duration,
            onTick: nil,
            onComplete: { [weak self] in
                self?.send(.complete)
            }
        )
    }

    private func notifyStateChange(from oldState: TimerState, to newState: TimerState) {
        onStateChange?(oldState, newState)
        // Persist state only when it actually changes
        persistState()
    }

    private func resetDailyCountIfNeeded() {
        let today: Date = Calendar.current.startOfDay(for: Date())

        if let lastReset: Date = lastResetDate, !Calendar.current.isDate(lastReset, inSameDayAs: today) {
            totalCompletedToday = 0
            completedPomodorosInCycle = 0
            lastResetDate = today
        }
    }

    // MARK: - Persistence

    private func persistState() {
        persistence.save(
            timerState: currentState,
            completedPomodorosInCycle: completedPomodorosInCycle,
            totalCompletedToday: totalCompletedToday,
            lastResetDate: lastResetDate ?? Date(),
            timerEngineState: timerEngine.isRunning || timerEngine.remainingSeconds > 0
                ? TimerEngineState(from: timerEngine)
                : nil
        )
    }

    private func loadPersistedState() {
        guard let state = persistence.load() else {
            return
        }

        // Check if we need to reset for a new day
        let today: Date = Calendar.current.startOfDay(for: Date())
        if Calendar.current.isDate(state.lastResetDate, inSameDayAs: today) {
            totalCompletedToday = state.totalCompletedToday
            completedPomodorosInCycle = state.completedPomodorosInCycle
        }
        lastResetDate = state.lastResetDate

        // Restore timer state if applicable
        if let engineState = state.timerEngineState {
            let adjustedRemaining: TimeInterval = engineState.adjustedRemainingSeconds()

            if adjustedRemaining > 0 {
                // Timer was active and hasn't completed
                currentState = state.timerState

                timerEngine.restore(
                    remainingSeconds: adjustedRemaining,
                    totalDuration: engineState.totalDuration,
                    wasRunning: engineState.wasRunning,
                    onTick: nil,
                    onComplete: { [weak self] in
                        self?.send(.complete)
                    }
                )
            } else if engineState.wasRunning {
                // Timer completed while app was closed
                send(.complete)
            }
        }
    }
}
