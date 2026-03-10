//
//  PomodoroState.swift
//  PomoDaddy
//
//  Core state definitions for the Pomodoro timer.
//

import SwiftUI

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

    /// Accent color associated with this interval type.
    var accentColor: Color {
        switch self {
        case .work:
            .tomatoRed
        case .shortBreak:
            .mint
        case .longBreak:
            .lavender
        }
    }

    /// Default duration in seconds for this interval type.
    var defaultDuration: TimeInterval {
        switch self {
        case .work:
            TimerConfiguration.defaultWorkDuration
        case .shortBreak:
            TimerConfiguration.defaultShortBreakDuration
        case .longBreak:
            TimerConfiguration.defaultLongBreakDuration
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

    /// Accent color for the current state.
    var accentColor: Color {
        switch self {
        case .idle:
            .gray
        case .running(let type), .paused(let type):
            type.accentColor
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
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(StateType.self, forKey: .type)

        switch type {
        case .idle:
            self = .idle
        case .running:
            let intervalType = try container.decode(IntervalType.self, forKey: .intervalType)
            self = .running(intervalType)
        case .paused:
            let intervalType = try container.decode(IntervalType.self, forKey: .intervalType)
            self = .paused(intervalType)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

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
