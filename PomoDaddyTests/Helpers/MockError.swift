//
//  MockError.swift
//  PomoDaddyTests
//
//  Shared error type for mock failures across test doubles.
//

import Foundation

/// Shared error type for mock failures.
enum MockError: Error {
    case simulatedFailure
}
