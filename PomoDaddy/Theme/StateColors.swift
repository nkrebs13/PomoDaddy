//
//  StateColors.swift
//  PomoDaddy
//
//  SwiftUI color extensions for timer state types.
//  Extracted from Core/PomodoroState.swift to keep Core UI-framework-free.
//

import SwiftUI

// MARK: - IntervalType Colors

extension IntervalType {
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
}

// MARK: - TimerState Colors

extension TimerState {
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
