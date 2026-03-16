import XCTest
@testable import PomoDaddy

final class CalendarExtensionsTests: XCTestCase {
    // MARK: - startOfDay

    func testStartOfDayReturnsMidnight() {
        let date = Date()
        let startOfDay = Calendar.startOfDay(for: date)
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: startOfDay)

        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    // MARK: - isDate(_:inSameDayAs:)

    func testIsDateInSameDayReturnsTrueForSameDay() {
        let date1 = Date()
        let date2 = date1.addingTimeInterval(3600) // 1 hour later

        XCTAssertTrue(Calendar.isDate(date1, inSameDayAs: date2))
    }

    func testIsDateInSameDayReturnsFalseForDifferentDays() {
        let date1 = Calendar.current.startOfDay(for: Date())
        let date2 = date1.addingTimeInterval(-1) // 1 second before midnight = yesterday

        XCTAssertFalse(Calendar.isDate(date1, inSameDayAs: date2))
    }

    // MARK: - dateRange

    func testDateRangeReturnsCorrectCount() {
        let dates = Calendar.dateRange(days: 7)
        XCTAssertEqual(dates.count, 7)
    }

    func testDateRangeReturnsChronologicalOrder() {
        let dates = Calendar.dateRange(days: 5)

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

    // MARK: - dayBoundaries

    func testDayBoundariesReturnsStartAndEndOfDay() {
        let date = Date()
        let boundaries = Calendar.dayBoundaries(for: date)

        XCTAssertNotNil(boundaries)

        if let boundaries {
            let startComponents = Calendar.current.dateComponents([.hour, .minute, .second], from: boundaries.start)
            XCTAssertEqual(startComponents.hour, 0)
            XCTAssertEqual(startComponents.minute, 0)
            XCTAssertEqual(startComponents.second, 0)
        }
    }

    func testDayBoundariesEndIsNextDayMidnight() {
        let date = Date()
        let boundaries = Calendar.dayBoundaries(for: date)

        XCTAssertNotNil(boundaries)

        if let boundaries {
            let difference = boundaries.end.timeIntervalSince(boundaries.start)
            // Should be exactly 24 hours (86400 seconds)
            XCTAssertEqual(difference, 86400, accuracy: 1)
        }
    }
}
