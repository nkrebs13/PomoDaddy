//
//  UIStateCoordinator.swift
//  PomoDaddy
//
//  Manages UI state preferences (floating window visibility, menu bar countdown).
//

import Foundation
import Observation

/// Coordinates UI state preferences and their persistence.
@Observable
final class UIStateCoordinator {
    // MARK: - Properties

    /// Whether the floating window is visible.
    var isFloatingWindowVisible = true {
        didSet {
            if oldValue != isFloatingWindowVisible {
                saveState()
            }
        }
    }

    /// Whether the menu bar countdown is visible.
    var isMenuBarCountdownVisible = true {
        didSet {
            if oldValue != isMenuBarCountdownVisible {
                saveState()
            }
        }
    }

    private let persistence: UserDefaults

    // MARK: - Initialization

    init(persistence: UserDefaults = .standard) {
        self.persistence = persistence
        restoreState()
    }

    // MARK: - Persistence

    /// Saves the current UI state to persistence.
    func saveState() {
        persistence.set(
            isFloatingWindowVisible,
            forKey: AppConstants.UserDefaultsKeys.isFloatingWindowVisible
        )
        persistence.set(
            isMenuBarCountdownVisible,
            forKey: AppConstants.UserDefaultsKeys.isMenuBarCountdownVisible
        )
    }

    /// Restores the UI state from persistence.
    func restoreState() {
        // Restore floating window visibility preference (defaults to true if not set)
        isFloatingWindowVisible = persistence.object(
            forKey: AppConstants.UserDefaultsKeys.isFloatingWindowVisible
        ) as? Bool ?? true

        // Restore menu bar countdown visibility preference (defaults to true if not set)
        isMenuBarCountdownVisible = persistence.object(
            forKey: AppConstants.UserDefaultsKeys.isMenuBarCountdownVisible
        ) as? Bool ?? true
    }
}
