import XCTest

extension XCTestCase {
    /// Asserts that an async expression eventually becomes true
    func assertEventually(
        timeout: TimeInterval = 1.0,
        _ condition: @escaping () -> Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if condition() { return }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }

        XCTFail("Condition not met within \(timeout) seconds", file: file, line: line)
    }

    /// Expects a closure to throw a specific error type
    func XCTAssertThrowsErrorType<E: Error>(
        _ expression: @autoclosure () throws -> some Any,
        expectedErrorType: E.Type,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(try expression(), file: file, line: line) { error in
            XCTAssertTrue(
                error is E,
                "Expected error of type \(E.self), got \(type(of: error))",
                file: file,
                line: line
            )
        }
    }
}
