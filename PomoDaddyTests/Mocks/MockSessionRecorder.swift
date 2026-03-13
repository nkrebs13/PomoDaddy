//
//  MockSessionRecorder.swift
//  PomoDaddyTests
//
//  Mock session recorder for testing.
//

import Foundation
@testable import PomoDaddy

/// Mock session recorder that tracks method calls.
actor MockSessionRecorder: SessionRecording {
    // MARK: - Call Tracking

    private(set) var recordCallCount = 0
    private(set) var recordBatchCallCount = 0

    private(set) var lastRecordedStartDate: Date?
    private(set) var lastRecordedEndDate: Date?
    private(set) var lastRecordedDurationMinutes: Int?
    private(set) var lastRecordedWasCompleted: Bool?
    private(set) var lastBatchCount: Int?

    // MARK: - Configurable Behavior

    var shouldThrow = false

    // MARK: - Protocol Methods

    func record(
        startDate: Date,
        endDate: Date,
        durationMinutes: Int,
        wasCompleted: Bool
    ) throws {
        if shouldThrow {
            throw MockError.simulatedFailure
        }
        recordCallCount += 1
        lastRecordedStartDate = startDate
        lastRecordedEndDate = endDate
        lastRecordedDurationMinutes = durationMinutes
        lastRecordedWasCompleted = wasCompleted
    }

    func recordBatch(_ entries: [(startDate: Date, endDate: Date, durationMinutes: Int, wasCompleted: Bool)]) throws {
        if shouldThrow {
            throw MockError.simulatedFailure
        }
        recordBatchCallCount += 1
        lastBatchCount = entries.count
    }
}
