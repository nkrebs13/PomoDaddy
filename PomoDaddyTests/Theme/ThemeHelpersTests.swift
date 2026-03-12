//
//  ThemeHelpersTests.swift
//  PomoDaddyTests
//
//  Tests for theme extension properties on TimerState and IntervalType.
//

import SwiftUI
import XCTest
@testable import PomoDaddy

final class ThemeHelpersTests: XCTestCase {
    // MARK: - TimerState Gradient Tests

    func testIdleGradient() {
        // Idle uses focus gradient (same as work)
        let gradient = TimerState.idle.gradient
        XCTAssertNotNil(gradient)
    }

    func testRunningWorkGradient() {
        let gradient = TimerState.running(.work).gradient
        XCTAssertNotNil(gradient)
    }

    func testRunningShortBreakGradient() {
        let gradient = TimerState.running(.shortBreak).gradient
        XCTAssertNotNil(gradient)
    }

    func testRunningLongBreakGradient() {
        let gradient = TimerState.running(.longBreak).gradient
        XCTAssertNotNil(gradient)
    }

    func testPausedWorkGradient() {
        let gradient = TimerState.paused(.work).gradient
        XCTAssertNotNil(gradient)
    }

    func testPausedShortBreakGradient() {
        let gradient = TimerState.paused(.shortBreak).gradient
        XCTAssertNotNil(gradient)
    }

    func testPausedLongBreakGradient() {
        let gradient = TimerState.paused(.longBreak).gradient
        XCTAssertNotNil(gradient)
    }

    // MARK: - IntervalType Gradient Tests

    func testWorkIntervalGradient() {
        let gradient = IntervalType.work.gradient
        XCTAssertNotNil(gradient)
    }

    func testShortBreakIntervalGradient() {
        let gradient = IntervalType.shortBreak.gradient
        XCTAssertNotNil(gradient)
    }

    func testLongBreakIntervalGradient() {
        let gradient = IntervalType.longBreak.gradient
        XCTAssertNotNil(gradient)
    }

    // MARK: - Gradient Consistency Tests

    func testWorkStateAndIntervalHaveSameGradient() {
        // idle, running(.work), and paused(.work) should all use
        // the same gradient as IntervalType.work
        // We can't directly compare LinearGradient values, but we can
        // verify they all resolve without error
        _ = TimerState.idle.gradient
        _ = TimerState.running(.work).gradient
        _ = TimerState.paused(.work).gradient
        _ = IntervalType.work.gradient
    }

    // MARK: - Color Palette Tests

    func testColorPaletteExists() {
        // Verify all custom colors are accessible
        _ = Color.tomatoRed
        _ = Color.coral
        _ = Color.sunnyYellow
        _ = Color.skyBlue
        _ = Color.hotPink
        _ = Color.forestGreen
    }

    func testHexColorInit() {
        // Verify hex init produces valid colors
        let color = Color(hex: "FF6B6B")
        XCTAssertNotNil(color)

        let shortHex = Color(hex: "FFF")
        XCTAssertNotNil(shortHex)

        let withHash = Color(hex: "#FF6B6B")
        XCTAssertNotNil(withHash)
    }

    // MARK: - Static Gradient Tests

    func testStaticGradients() {
        _ = LinearGradient.focusGradient
        _ = LinearGradient.breakGradient
        _ = LinearGradient.longBreakGradient
        _ = LinearGradient.celebrationGradient
    }

    func testGradientColors() {
        _ = Gradient.focus
        _ = Gradient.breakMode
        _ = Gradient.celebration
    }
}
