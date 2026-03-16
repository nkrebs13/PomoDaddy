import SwiftData
import XCTest
@testable import PomoDaddy

@MainActor
final class DataContainerTests: XCTestCase {
    func testCreateReturnsValidContainer() {
        let container = PomodoroDataContainer.create()
        XCTAssertNotNil(container)
    }

    func testCreateInMemoryContainerWorks() {
        let container = PomodoroDataContainer.createInMemory()
        XCTAssertNotNil(container)

        let context = container.mainContext
        let session = PomodoroSession(
            startDate: Date(),
            endDate: Date(),
            durationMinutes: 25,
            wasCompleted: true
        )
        context.insert(session)
        XCTAssertNoThrow(try context.save())
    }

    func testPreviewContainerHasSampleData() {
        let container = PomodoroDataContainer.createPreview()
        let context = container.mainContext

        let descriptor = FetchDescriptor<PomodoroSession>()
        let sessions = try? context.fetch(descriptor)
        XCTAssertNotNil(sessions)
        XCTAssertGreaterThan(sessions?.count ?? 0, 0, "Preview container should have sample sessions")
    }

    func testPreviewContainerHasDailyStats() {
        let container = PomodoroDataContainer.createPreview()
        let context = container.mainContext

        let descriptor = FetchDescriptor<DailyStats>()
        let stats = try? context.fetch(descriptor)
        XCTAssertNotNil(stats)
        XCTAssertGreaterThan(stats?.count ?? 0, 0, "Preview container should have sample daily stats")
    }

    func testSchemaIncludesAllModels() {
        XCTAssertEqual(PomodoroDataContainer.modelTypes.count, 3)
    }
}
