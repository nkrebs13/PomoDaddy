import XCTest
@testable import PomoDaddy

final class CalendarExtensionsTests: XCTestCase {
    // MARK: - startOfDay

    func testStartOfDayReturnsMidnight() {
        let date = TestFixtures.date(year: 2026, month: 3, day: 15, hour: 14, minute: 30)
        let startOfDay = Calendar.startOfDay(for: date)
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: startOfDay)

        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    func testStartOfDayPreservesCalendarDay() {
        let date = TestFixtures.date(year: 2026, month: 3, day: 15, hour: 23, minute: 59)
        let startOfDay = Calendar.startOfDay(for: date)
        let components = Calendar.current.dateComponents([.year, .month, .day], from: startOfDay)

        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 3)
        XCTAssertEqual(components.day, 15)
    }

    // MARK: - isDate(_:inSameDayAs:)

    func testIsDateInSameDayReturnsTrueForSameDay() {
        let date1 = TestFixtures.date(year: 2026, month: 3, day: 15, hour: 8)
        let date2 = TestFixtures.date(year: 2026, month: 3, day: 15, hour: 22)

        XCTAssertTrue(Calendar.isDate(date1, inSameDayAs: date2))
    }

    func testIsDateInSameDayReturnsFalseForDifferentDays() {
        let date1 = TestFixtures.date(year: 2026, month: 3, day: 15)
        let date2 = TestFixtures.date(year: 2026, month: 3, day: 16)

        XCTAssertFalse(Calendar.isDate(date1, inSameDayAs: date2))
    }

    func testIsDateInSameDayMidnightBoundary() {
        let midnight = TestFixtures.date(year: 2026, month: 3, day: 15)
        let justBefore = midnight.addingTimeInterval(-1)

        XCTAssertFalse(Calendar.isDate(midnight, inSameDayAs: justBefore))
    }

    // MARK: - dateRange

    func testDateRangeReturnsCorrectCount() {
        let endDate = TestFixtures.date(year: 2026, month: 3, day: 15)
        let dates = Calendar.dateRange(days: 7, ending: endDate)
        XCTAssertEqual(dates.count, 7)
    }

    func testDateRangeReturnsChronologicalOrder() {
        let endDate = TestFixtures.date(year: 2026, month: 3, day: 15)
        let dates = Calendar.dateRange(days: 5, ending: endDate)

        for index in 1 ..< dates.count {
            XCTAssertTrue(
                dates[index] > dates[index - 1],
                "Date at index \(index) should be after date at index \(index - 1)"
            )
        }
    }

    func testDateRangeWithZeroDaysReturnsEmpty() {
        let dates = Calendar.dateRange(days: 0)
        XCTAssertTrue(dates.isEmpty)
    }

    func testDateRangeWithNegativeDaysReturnsEmpty() {
        let dates = Calendar.dateRange(days: -3)
        XCTAssertTrue(dates.isEmpty)
    }

    func testDateRangeWithOneDayReturnsSingleDate() {
        let endDate = TestFixtures.date(year: 2026, month: 3, day: 15)
        let dates = Calendar.dateRange(days: 1, ending: endDate)

        XCTAssertEqual(dates.count, 1)
    }

    func testDateRangeWithCustomEndDate() throws {
        let endDate = TestFixtures.date(year: 2026, month: 1, day: 10)
        let dates = Calendar.dateRange(days: 3, ending: endDate)

        XCTAssertEqual(dates.count, 3)
        let lastDate = try XCTUnwrap(dates.last)
        let lastComponents = Calendar.current.dateComponents([.year, .month, .day], from: lastDate)
        XCTAssertEqual(lastComponents.month, 1)
        XCTAssertEqual(lastComponents.day, 10)
    }

    func testDateRangeAllDatesAreStartOfDay() {
        let endDate = TestFixtures.date(year: 2026, month: 3, day: 15)
        let dates = Calendar.dateRange(days: 5, ending: endDate)

        for date in dates {
            let components = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
            XCTAssertEqual(components.hour, 0, "Date should be midnight: \(date)")
            XCTAssertEqual(components.minute, 0, "Date should be midnight: \(date)")
            XCTAssertEqual(components.second, 0, "Date should be midnight: \(date)")
        }
    }

    // MARK: - dayBoundaries

    func testDayBoundariesReturnsStartAndEndOfDay() {
        let date = TestFixtures.date(year: 2026, month: 3, day: 15, hour: 14)
        let boundaries = Calendar.dayBoundaries(for: date)

        XCTAssertNotNil(boundaries)

        if let boundaries {
            let startComponents = Calendar.current.dateComponents([.hour, .minute, .second], from: boundaries.start)
            XCTAssertEqual(startComponents.hour, 0)
            XCTAssertEqual(startComponents.minute, 0)
            XCTAssertEqual(startComponents.second, 0)
        }
    }

    func testDayBoundariesEndIsNextDay() {
        let date = TestFixtures.date(year: 2026, month: 3, day: 15)
        let boundaries = Calendar.dayBoundaries(for: date)

        XCTAssertNotNil(boundaries)

        if let boundaries {
            let endComponents = Calendar.current.dateComponents(
                [.day, .hour, .minute],
                from: boundaries.end
            )
            XCTAssertEqual(endComponents.day, 16)
            XCTAssertEqual(endComponents.hour, 0)
            XCTAssertEqual(endComponents.minute, 0)
        }
    }

    func testDayBoundariesForSpecificDate() {
        let date = TestFixtures.date(year: 2026, month: 6, day: 20, hour: 15)
        let boundaries = Calendar.dayBoundaries(for: date)

        XCTAssertNotNil(boundaries)

        if let boundaries {
            let startComponents = Calendar.current.dateComponents([.year, .month, .day], from: boundaries.start)
            XCTAssertEqual(startComponents.year, 2026)
            XCTAssertEqual(startComponents.month, 6)
            XCTAssertEqual(startComponents.day, 20)

            let endComponents = Calendar.current.dateComponents([.year, .month, .day], from: boundaries.end)
            XCTAssertEqual(endComponents.day, 21)
        }
    }
}
