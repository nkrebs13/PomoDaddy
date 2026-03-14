//
//  AppNapManaging.swift
//  PomoDaddy
//
//  Protocol for App Nap management dependency injection.
//

import Foundation

/// Protocol defining the App Nap management interface for dependency injection and testing.
internal protocol AppNapManaging: AnyObject {
    /// Whether an activity assertion is currently active.
    var isTimingActivityActive: Bool { get }

    /// Begins an activity assertion to prevent App Nap during timing.
    func beginTimingActivity()

    /// Ends the activity assertion, allowing App Nap to resume.
    func endTimingActivity()

    /// Toggles the activity state based on whether timing is active.
    /// - Parameter isActive: Whether timing is currently active.
    func setTimingActive(_ isActive: Bool)
}
