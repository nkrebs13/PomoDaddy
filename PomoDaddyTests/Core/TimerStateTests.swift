//
//  TimerStateTests.swift
//  PomoDaddyTests
//
//  Tests for TimerState computed properties including play/pause icons and labels.
//

import XCTest
@testable import PomoDaddy

final class TimerStateTests: XCTestCase {
    // MARK: - playPauseIcon Tests

    func testIdleShowsPlayIcon() {
        XCTAssertEqual(TimerState.idle.playPauseIcon, "play.fill")
    }

    func testRunningShowsPauseIcon() {
        XCTAssertEqual(TimerState.running(.work).playPauseIcon, "pause.fill")
        XCTAssertEqual(TimerState.running(.shortBreak).playPauseIcon, "pause.fill")
        XCTAssertEqual(TimerState.running(.longBreak).playPauseIcon, "pause.fill")
    }

    func testPausedShowsPlayIcon() {
        XCTAssertEqual(TimerState.paused(.work).playPauseIcon, "play.fill")
        XCTAssertEqual(TimerState.paused(.shortBreak).playPauseIcon, "play.fill")
    }

    // MARK: - playPauseLabel Tests

    func testIdleLabel() {
        XCTAssertEqual(TimerState.idle.playPauseLabel, "Start focus session")
    }

    func testRunningLabel() {
        XCTAssertEqual(TimerState.running(.work).playPauseLabel, "Pause timer")
    }

    func testPausedLabel() {
        XCTAssertEqual(TimerState.paused(.work).playPauseLabel, "Resume timer")
    }

    // MARK: - displayName Tests

    func testDisplayNames() {
        XCTAssertEqual(TimerState.idle.displayName, "Ready")
        XCTAssertEqual(TimerState.running(.work).displayName, "Focus")
        XCTAssertEqual(TimerState.running(.shortBreak).displayName, "Short Break")
        XCTAssertEqual(TimerState.running(.longBreak).displayName, "Long Break")
        XCTAssertEqual(TimerState.paused(.work).displayName, "Focus (Paused)")
    }

    // MARK: - isActive/isRunning/isPaused Tests

    func testIsActive() {
        XCTAssertFalse(TimerState.idle.isActive)
        XCTAssertTrue(TimerState.running(.work).isActive)
        XCTAssertTrue(TimerState.paused(.work).isActive)
    }

    func testIsRunning() {
        XCTAssertFalse(TimerState.idle.isRunning)
        XCTAssertTrue(TimerState.running(.work).isRunning)
        XCTAssertFalse(TimerState.paused(.work).isRunning)
    }

    func testIsPaused() {
        XCTAssertFalse(TimerState.idle.isPaused)
        XCTAssertFalse(TimerState.running(.work).isPaused)
        XCTAssertTrue(TimerState.paused(.work).isPaused)
    }

    // MARK: - IntervalType Tests

    func testIntervalTypeDisplayNames() {
        XCTAssertEqual(IntervalType.work.displayName, "Focus")
        XCTAssertEqual(IntervalType.shortBreak.displayName, "Short Break")
        XCTAssertEqual(IntervalType.longBreak.displayName, "Long Break")
    }

    // MARK: - Codable Tests

    func testTimerStateCodableRoundTrip() throws {
        let states: [TimerState] = [
            .idle,
            .running(.work),
            .running(.shortBreak),
            .running(.longBreak),
            .paused(.work),
            .paused(.shortBreak),
            .paused(.longBreak)
        ]

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for state in states {
            let data = try encoder.encode(state)
            let decoded = try decoder.decode(TimerState.self, from: data)
            XCTAssertEqual(state, decoded, "Failed round-trip for \(state)")
        }
    }
}
