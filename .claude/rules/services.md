# Services Module Rules

- Each service must have a protocol in `Services/Protocols/`
- Services must be testable in isolation with mock dependencies
- Use `actor` for thread-safe mutable state (`SessionRecorder` is a `@ModelActor actor`)
- Use `@Observable @MainActor final class` for UI-bound services (`SessionCoordinator`, `AppNapManager`)
- Use `struct` for stateless query services (`StatsCalculator`)
- All errors must be logged with context via `Logger.logError(_:context:log:)`
- `NotificationScheduler` uses a protocol extension for the default `silent` parameter since protocol methods can't have default values
