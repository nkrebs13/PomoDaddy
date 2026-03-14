//
//  StateMachinePersistence.swift
//  PomoDaddy
//
//  Persistence service for PomodoroStateMachine state.
//

import Foundation

// MARK: - Persisted State

/// Represents the complete persisted state of the Pomodoro state machine.
struct PersistedStateMachineState: Codable {
    let timerState: TimerState
    let completedPomodorosInCycle: Int
    let totalCompletedToday: Int
    let lastResetDate: Date
    let timerEngineState: TimerEngineState?
}

// MARK: - State Machine Persistence Service

/// Handles persistence of PomodoroStateMachine state to UserDefaults.
final class StateMachinePersistence {
    // MARK: - Properties

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let stateKey: String

    // MARK: - Singleton

    static let shared = StateMachinePersistence()

    // MARK: - Initialization

    init(defaults: UserDefaults = .standard, stateKey: String = AppConstants.UserDefaultsKeys.stateMachineState) {
        self.defaults = defaults
        self.stateKey = stateKey
    }

    // MARK: - Public Methods

    /// Persists the state machine state.
    func save(
        timerState: TimerState,
        completedPomodorosInCycle: Int,
        totalCompletedToday: Int,
        lastResetDate: Date,
        timerEngineState: TimerEngineState?
    ) {
        let state = PersistedStateMachineState(
            timerState: timerState,
            completedPomodorosInCycle: completedPomodorosInCycle,
            totalCompletedToday: totalCompletedToday,
            lastResetDate: lastResetDate,
            timerEngineState: timerEngineState
        )

        do {
            let encoded: Data = try encoder.encode(state)
            defaults.set(encoded, forKey: stateKey)
        } catch {
            Logger.logError(error, context: "Failed to persist state machine state", log: Logger.persistence)
            // Clear corrupted state
            defaults.removeObject(forKey: stateKey)
        }
    }

    /// Loads the persisted state machine state.
    /// - Returns: The persisted state, or nil if not available or corrupted.
    func load() -> PersistedStateMachineState? {
        guard let data = defaults.data(forKey: stateKey) else {
            return nil
        }

        do {
            return try decoder.decode(PersistedStateMachineState.self, from: data)
        } catch {
            Logger.logError(error, context: "Failed to decode persisted state", log: Logger.persistence)
            // Clear corrupted data
            defaults.removeObject(forKey: stateKey)
            return nil
        }
    }

    /// Clears the persisted state.
    func clear() {
        defaults.removeObject(forKey: stateKey)
    }
}
