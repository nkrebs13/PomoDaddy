//
//  PomodoroState.swift
//  PomoDaddy
//
//  Core state definitions for the Pomodoro timer.
//

import Foundation

// MARK: - Interval Type

/// Represents the type of interval in a Pomodoro session.
enum IntervalType: String, Codable, CaseIterable, Identifiable {
    case work
    case shortBreak
    case longBreak

    var id: String {
        rawValue
    }

    /// Human-readable display name for the interval type.
    var displayName: String {
        switch self {
        case .work:
            "Focus"
        case .shortBreak:
            "Short Break"
        case .longBreak:
            "Long Break"
        }
    }

    /// Default duration in seconds for this interval type.
    var defaultDuration: TimeInterval {
        let defaults = PomodoroSettings.default
        switch self {
        case .work:
            return defaults.workDuration
        case .shortBreak:
            return defaults.shortBreakDuration
        case .longBreak:
            return defaults.longBreakDuration
        }
    }
}

// MARK: - Timer State

/// Represents the current state of the Pomodoro timer.
enum TimerState: Equatable {
    case idle
    case running(IntervalType)
    case paused(IntervalType)

    /// The interval type associated with this state, if any.
    var intervalType: IntervalType? {
        switch self {
        case .idle:
            nil
        case .running(let type), .paused(let type):
            type
        }
    }

    /// Whether the timer is currently active (running or paused).
    var isActive: Bool {
        switch self {
        case .idle:
            false
        case .running, .paused:
            true
        }
    }

    /// Whether the timer is currently running.
    var isRunning: Bool {
        if case .running = self {
            return true
        }
        return false
    }

    /// Whether the timer is currently paused.
    var isPaused: Bool {
        if case .paused = self {
            return true
        }
        return false
    }

    /// Human-readable display name for the current state.
    var displayName: String {
        switch self {
        case .idle:
            "Ready"
        case .running(let type):
            type.displayName
        case .paused(let type):
            "\(type.displayName) (Paused)"
        }
    }

    /// SF Symbol name for play/pause button based on current state.
    var playPauseIcon: String {
        switch self {
        case .idle, .paused:
            "play.fill"
        case .running:
            "pause.fill"
        }
    }

    /// Accessibility label for play/pause button based on current state.
    var playPauseLabel: String {
        switch self {
        case .idle:
            "Start focus session"
        case .running:
            "Pause timer"
        case .paused:
            "Resume timer"
        }
    }
}

// MARK: - Codable Conformance for TimerState

extension TimerState: Codable {
    private enum CodingKeys: String, CodingKey {
        case type
        case intervalType
    }

    private enum StateType: String, Codable {
        case idle
        case running
        case paused
    }

    init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
        let type: StateType = try container.decode(StateType.self, forKey: .type)

        switch type {
        case .idle:
            self = .idle
        case .running:
            let intervalType: IntervalType = try container.decode(IntervalType.self, forKey: .intervalType)
            self = .running(intervalType)
        case .paused:
            let intervalType: IntervalType = try container.decode(IntervalType.self, forKey: .intervalType)
            self = .paused(intervalType)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container: KeyedEncodingContainer<CodingKeys> = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .idle:
            try container.encode(StateType.idle, forKey: .type)
        case .running(let intervalType):
            try container.encode(StateType.running, forKey: .type)
            try container.encode(intervalType, forKey: .intervalType)
        case .paused(let intervalType):
            try container.encode(StateType.paused, forKey: .type)
            try container.encode(intervalType, forKey: .intervalType)
        }
    }
}
