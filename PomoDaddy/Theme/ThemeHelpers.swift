//
//  ThemeHelpers.swift
//  PomoDaddy
//
//  Centralized theme utilities for gradients and colors to eliminate duplication.
//

import SwiftUI

// MARK: - TimerState Theme Extensions

extension TimerState {
    /// The accent gradient for this timer state.
    var gradient: LinearGradient {
        switch self {
        case .idle, .running(.work), .paused(.work):
            return .focusGradient
        case .running(.shortBreak), .paused(.shortBreak):
            return .breakGradient
        case .running(.longBreak), .paused(.longBreak):
            return .longBreakGradient
        }
    }
}

// MARK: - IntervalType Theme Extensions

extension IntervalType {
    /// The accent gradient for this interval type.
    var gradient: LinearGradient {
        switch self {
        case .work:
            return .focusGradient
        case .shortBreak:
            return .breakGradient
        case .longBreak:
            return .longBreakGradient
        }
    }
}
