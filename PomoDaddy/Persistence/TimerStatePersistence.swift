//
//  TimerStatePersistence.swift
//  PomoDaddy
//
//  Persistence layer for saving and restoring timer state across app launches.
//

import Foundation

/// Represents the persisted state of the timer for app restoration.
struct PersistedTimerState: Codable, Equatable {
    // MARK: - Timer Phase

    /// The phase the timer was in when captured.
    enum Phase: String, Codable {
        case work
        case shortBreak
        case longBreak
        case idle
    }

    // MARK: - Properties

    /// The timer phase when state was captured.
    let phase: Phase

    /// Remaining time in seconds when state was captured.
    let remainingSeconds: TimeInterval

    /// Whether the timer was actively running.
    let wasRunning: Bool

    /// The timestamp when this state was captured.
    let capturedAt: Date

    /// The session start time (if in a session).
    let sessionStartDate: Date?

    /// Number of completed pomodoros in the current cycle.
    let completedPomodorosInCycle: Int

    /// Total pomodoros completed today.
    let todayCompletedPomodoros: Int

    // MARK: - Computed Properties

    /// Time elapsed since the state was captured.
    var elapsedSinceCapture: TimeInterval {
        Date().timeIntervalSince(capturedAt)
    }

    /// Whether this state is still valid for restoration.
    /// States older than 24 hours are considered stale.
    var isValid: Bool {
        elapsedSinceCapture < 24 * 60 * 60
    }

    /// Whether the timer has naturally completed based on elapsed time.
    var hasNaturallyCompleted: Bool {
        guard wasRunning else { return false }
        return elapsedSinceCapture >= remainingSeconds
    }

    // MARK: - Initialization

    /// Creates a new persisted timer state.
    init(
        phase: Phase,
        remainingSeconds: TimeInterval,
        wasRunning: Bool,
        capturedAt: Date = Date(),
        sessionStartDate: Date? = nil,
        completedPomodorosInCycle: Int = 0,
        todayCompletedPomodoros: Int = 0
    ) {
        self.phase = phase
        self.remainingSeconds = remainingSeconds
        self.wasRunning = wasRunning
        self.capturedAt = capturedAt
        self.sessionStartDate = sessionStartDate
        self.completedPomodorosInCycle = completedPomodorosInCycle
        self.todayCompletedPomodoros = todayCompletedPomodoros
    }

    // MARK: - Methods

    /// Calculates the adjusted remaining time accounting for elapsed time since capture.
    /// - Returns: The adjusted remaining time, or 0 if the timer would have completed.
    func adjustedRemainingTime() -> TimeInterval {
        guard wasRunning else {
            // Timer was paused, return the original remaining time
            return remainingSeconds
        }

        let adjusted = remainingSeconds - elapsedSinceCapture
        return max(0, adjusted)
    }

    /// Creates a restored state with adjusted timing.
    /// - Returns: A new state with times adjusted for the elapsed period.
    func restored() -> PersistedTimerState {
        PersistedTimerState(
            phase: phase,
            remainingSeconds: adjustedRemainingTime(),
            wasRunning: wasRunning && !hasNaturallyCompleted,
            capturedAt: Date(),
            sessionStartDate: sessionStartDate,
            completedPomodorosInCycle: completedPomodorosInCycle,
            todayCompletedPomodoros: todayCompletedPomodoros
        )
    }
}

// MARK: - Timer State Persistence Manager

/// Manages saving and loading timer state to UserDefaults.
final class TimerStatePersistence {
    // MARK: - Constants

    private enum Keys {
        static let timerState = "com.pomodaddy.timerState"
    }

    // MARK: - Properties

    /// The UserDefaults instance to use.
    private let defaults: UserDefaults

    /// JSON encoder for serialization.
    private let encoder = JSONEncoder()

    /// JSON decoder for deserialization.
    private let decoder = JSONDecoder()

    // MARK: - Singleton

    /// Shared instance for app-wide use.
    static let shared = TimerStatePersistence()

    // MARK: - Initialization

    /// Creates a new persistence manager.
    /// - Parameter defaults: The UserDefaults instance to use.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Public Methods

    /// Saves the current timer state.
    /// - Parameter state: The state to save.
    func save(_ state: PersistedTimerState) {
        do {
            let data = try encoder.encode(state)
            defaults.set(data, forKey: Keys.timerState)
        } catch {
            Logger.logError(error, context: "Failed to save timer state", log: Logger.persistence)
        }
    }

    /// Loads the persisted timer state.
    /// - Returns: The persisted state if available and valid, nil otherwise.
    func load() -> PersistedTimerState? {
        guard let data = defaults.data(forKey: Keys.timerState) else {
            return nil
        }

        do {
            let state = try decoder.decode(PersistedTimerState.self, from: data)

            // Validate the state
            guard state.isValid else {
                clear()
                return nil
            }

            return state
        } catch {
            Logger.logError(error, context: "Failed to load timer state", log: Logger.persistence)
            clear()
            return nil
        }
    }

    /// Loads and restores the timer state with time adjustments.
    /// - Returns: The restored state with adjusted timing, nil if no valid state exists.
    func loadAndRestore() -> PersistedTimerState? {
        guard let state = load() else {
            return nil
        }

        return state.restored()
    }

    /// Clears the persisted timer state.
    func clear() {
        defaults.removeObject(forKey: Keys.timerState)
    }

    /// Checks if there is a valid persisted state.
    var hasPersistedState: Bool {
        load() != nil
    }
}

// MARK: - Restoration Result

/// Result of attempting to restore timer state.
enum TimerRestoreResult {
    /// Successfully restored with the given state.
    case restored(PersistedTimerState)

    /// Timer completed while app was closed.
    case completedWhileClosed(phase: PersistedTimerState.Phase, sessionStartDate: Date?)

    /// No state to restore.
    case noState

    /// State was invalid or expired.
    case invalid
}

extension TimerStatePersistence {
    /// Attempts to restore timer state and determines the appropriate action.
    /// - Returns: A restoration result indicating what action to take.
    func restore() -> TimerRestoreResult {
        guard let state = load() else {
            return .noState
        }

        guard state.isValid else {
            clear()
            return .invalid
        }

        if state.hasNaturallyCompleted {
            clear()
            return .completedWhileClosed(
                phase: state.phase,
                sessionStartDate: state.sessionStartDate
            )
        }

        return .restored(state.restored())
    }
}

// MARK: - Convenience Factory Methods

extension PersistedTimerState {
    /// Creates a state representing an idle timer.
    static func idle(
        completedPomodorosInCycle: Int = 0,
        todayCompletedPomodoros: Int = 0
    ) -> PersistedTimerState {
        PersistedTimerState(
            phase: .idle,
            remainingSeconds: 0,
            wasRunning: false,
            completedPomodorosInCycle: completedPomodorosInCycle,
            todayCompletedPomodoros: todayCompletedPomodoros
        )
    }

    /// Creates a state for an active work session.
    static func working(
        remainingSeconds: TimeInterval,
        isRunning: Bool,
        sessionStartDate: Date,
        completedPomodorosInCycle: Int,
        todayCompletedPomodoros: Int
    ) -> PersistedTimerState {
        PersistedTimerState(
            phase: .work,
            remainingSeconds: remainingSeconds,
            wasRunning: isRunning,
            sessionStartDate: sessionStartDate,
            completedPomodorosInCycle: completedPomodorosInCycle,
            todayCompletedPomodoros: todayCompletedPomodoros
        )
    }

    /// Creates a state for a break session.
    static func onBreak(
        isLongBreak: Bool,
        remainingSeconds: TimeInterval,
        isRunning: Bool,
        completedPomodorosInCycle: Int,
        todayCompletedPomodoros: Int
    ) -> PersistedTimerState {
        PersistedTimerState(
            phase: isLongBreak ? .longBreak : .shortBreak,
            remainingSeconds: remainingSeconds,
            wasRunning: isRunning,
            completedPomodorosInCycle: completedPomodorosInCycle,
            todayCompletedPomodoros: todayCompletedPomodoros
        )
    }
}
