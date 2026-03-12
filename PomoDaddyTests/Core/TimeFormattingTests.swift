//
//  TimeFormattingTests.swift
//  PomoDaddyTests
//
//  Tests for the TimeFormatting utility.
//

import XCTest
@testable import PomoDaddy

final class TimeFormattingTests: XCTestCase {
    // MARK: - formatFocusTime Tests

    func testFormatZeroMinutes() {
        XCTAssertEqual(TimeFormatting.formatFocusTime(minutes: 0), "0m")
    }

    func testFormatMinutesOnly() {
        XCTAssertEqual(TimeFormatting.formatFocusTime(minutes: 25), "25m")
        XCTAssertEqual(TimeFormatting.formatFocusTime(minutes: 59), "59m")
    }

    func testFormatExactHours() {
        XCTAssertEqual(TimeFormatting.formatFocusTime(minutes: 60), "1h")
        XCTAssertEqual(TimeFormatting.formatFocusTime(minutes: 120), "2h")
    }

    func testFormatHoursAndMinutes() {
        XCTAssertEqual(TimeFormatting.formatFocusTime(minutes: 61), "1h 1m")
        XCTAssertEqual(TimeFormatting.formatFocusTime(minutes: 90), "1h 30m")
        XCTAssertEqual(TimeFormatting.formatFocusTime(minutes: 145), "2h 25m")
    }

    func testFormatLargeValues() {
        XCTAssertEqual(TimeFormatting.formatFocusTime(minutes: 500), "8h 20m")
    }

    // MARK: - formatAxisLabel Tests

    func testAxisLabelMinutesOnly() {
        XCTAssertEqual(TimeFormatting.formatAxisLabel(minutes: 0), "0m")
        XCTAssertEqual(TimeFormatting.formatAxisLabel(minutes: 30), "30m")
        XCTAssertEqual(TimeFormatting.formatAxisLabel(minutes: 59), "59m")
    }

    func testAxisLabelHours() {
        XCTAssertEqual(TimeFormatting.formatAxisLabel(minutes: 60), "1h")
        XCTAssertEqual(TimeFormatting.formatAxisLabel(minutes: 120), "2h")
        XCTAssertEqual(TimeFormatting.formatAxisLabel(minutes: 90), "1h")
    }
}
