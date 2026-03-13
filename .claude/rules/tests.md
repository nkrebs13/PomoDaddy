# Test Module Rules

- Use protocol-based mocks from `PomoDaddyTests/Mocks/`
- Prefer `MockTimerEngine` over real `TimerEngine` in unit tests — `MockTimerEngine.simulateCompletion()` triggers the stored `onComplete` callback instantly
- Use `UserDefaults(suiteName: "test.<context>.\(UUID())")` for `StateMachinePersistence` isolation — NEVER use `UserDefaults.standard` or `.shared` persistence in tests
- Use `ModelContainer` with `isStoredInMemoryOnly: true` for SwiftData test isolation
- Integration tests go in `PomoDaddyTests/Integration/`
- Test names follow pattern: `testMethodNameConditionExpectedResult` (camelCase)
- Use `assertEventually(timeout:)` helper for async assertions
- Nested `.swiftlint.yml` disables rules inappropriate for tests (force_unwrapping, explicit_top_level_acl, etc.)
