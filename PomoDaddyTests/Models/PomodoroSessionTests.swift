import XCTest
@testable import PomoDaddy

final class PomodoroSessionTests: XCTestCase {
    // MARK: - Initialization Tests

    func testSessionInitialization() {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(25 * 60)

        let session = PomodoroSession(
            startDate: startDate,
            endDate: endDate,
            durationMinutes: 25,
            wasCompleted: true
        )

        XCTAssertEqual(session.startDate, startDate)
        XCTAssertEqual(session.endDate, endDate)
        XCTAssertEqual(session.durationMinutes, 25)
        XCTAssertTrue(session.wasCompleted)
    }

    // MARK: - Predicate Tests

    func testOnDayPredicate() {
        let today = TestFixtures.today
        let yesterday = TestFixtures.yesterday

        // Create sessions for today and yesterday
        let todaySession = TestFixtures.createSession(startDate: today)
        let yesterdaySession = TestFixtures.createSession(startDate: yesterday)

        // Note: Predicates can't be fully tested without SwiftData context
        // but we can verify they compile and don't crash
        _ = PomodoroSession.onDay(today)
        _ = PomodoroSession.onDay(yesterday)
    }

    func testCompletedPredicate() {
        _ = PomodoroSession.completed
        // Verify predicate compiles
    }

    // MARK: - Helper Tests

    func testSessionCreationFromFixture() {
        let session = TestFixtures.createSession(
            startDate: Date(),
            durationMinutes: 30,
            wasCompleted: false
        )

        XCTAssertEqual(session.durationMinutes, 30)
        XCTAssertFalse(session.wasCompleted)
    }

    func testDateFixtures() {
        let today = TestFixtures.today
        let yesterday = TestFixtures.yesterday
        let tomorrow = TestFixtures.tomorrow

        let calendar = Calendar.current

        XCTAssertEqual(calendar.startOfDay(for: Date()), today)

        let daysBetween = calendar.dateComponents([.day], from: yesterday, to: today).day
        XCTAssertEqual(daysBetween, 1)

        let daysBetween2 = calendar.dateComponents([.day], from: today, to: tomorrow).day
        XCTAssertEqual(daysBetween2, 1)
    }

    func testInRangePredicate() {
        let startDate = TestFixtures.today
        let endDate = TestFixtures.tomorrow

        _ = PomodoroSession.inRange(from: startDate, to: endDate)
        // Verify predicate compiles
    }
}
