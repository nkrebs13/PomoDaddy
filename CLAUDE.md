# PomoDaddy

A macOS menu bar Pomodoro timer app with playful design, stats tracking, and celebration animations.

## Quick Start

1. Install dependencies: `brew install xcodegen` (if not installed)
2. Generate Xcode project: `xcodegen generate`
3. Open in Xcode: `open PomoDaddy.xcodeproj`
4. Build and run (Cmd+R)

## Development Commands

| Command | Description |
|---------|-------------|
| `make build` | Generate project and build |
| `make test` | Run all tests |
| `make test-coverage` | Run tests with coverage reporting |
| `make lint` | Run SwiftLint (strict mode) |
| `make format` | Format code with SwiftFormat |
| `make format-check` | Check formatting without modifying |
| `make clean` | Clean build artifacts |
| `make setup` | Install all dependencies |
| `xcodegen generate` | Regenerate Xcode project (required after adding/moving files) |

## Project Structure

- `PomoDaddy/App/` - App entry point, AppDelegate, AppCoordinator, FloatingWindowCoordinator
- `PomoDaddy/Core/` - Timer engine, state machine, protocols, configuration
- `PomoDaddy/MenuBar/` - Status bar controller, menu bar icon, popover
- `PomoDaddy/FloatingWindow/` - Floating timer window
- `PomoDaddy/Views/` - SwiftUI components, settings, stats
- `PomoDaddy/Models/` - SwiftData models
- `PomoDaddy/Services/` - Notifications, recording, lifecycle
- `PomoDaddy/Services/Protocols/` - Service protocol definitions for DI
- `PomoDaddy/Persistence/` - Data container, settings manager, state persistence
- `PomoDaddy/Theme/` - Colors, animations
- `PomoDaddyTests/Mocks/` - Protocol-based mock implementations for testing

## Architecture Patterns

- **Protocol-based DI**: All services have protocols (`TimerEngineProtocol`, `NotificationScheduling`, `SessionRecording`, etc.). `AppCoordinator` accepts `any Protocol` existentials via a testable init.
- **State machine**: `PomodoroStateMachine` manages all timer state transitions via `send(_:)`. Callbacks (`onWorkSessionComplete`, `onBreakComplete`, etc.) propagate events.
- **Actor-based persistence**: `SessionRecorder` is a `@ModelActor actor` for thread-safe SwiftData access.
- **Coordinator pattern**: `AppCoordinator` is the DI container and facade. `SessionCoordinator` handles session tracking. `FloatingWindowCoordinator` manages window lifecycle.
- **Views use concrete types**: SwiftUI views accept concrete `AppCoordinator` (not protocols) because `@Observable` macro doesn't work with protocol existentials in SwiftUI observation tracking.

## Testing

- **Mocks**: Protocol-based mocks in `PomoDaddyTests/Mocks/` track call counts and arguments
- **MockTimerEngine**: Call `simulateCompletion()` to trigger timer completion instantly
- **Persistence isolation**: Always use `UserDefaults(suiteName: "test.<context>.\(UUID())")` — never `.standard`
- **SwiftData isolation**: Use `ModelContainer` with `isStoredInMemoryOnly: true`
- **Async assertions**: Use `assertEventually(timeout:)` for async test verification
- **Coverage threshold**: 35% (whole-app including untestable SwiftUI views; core/services coverage is 85%+)

## Key Files

| Purpose | File |
|---------|------|
| Timer Logic | `Core/TimerEngine.swift:1` |
| Timer Protocol | `Core/TimerEngineProtocol.swift:1` |
| State Machine | `Core/PomodoroStateMachine.swift:1` |
| App Coordinator | `App/AppCoordinator.swift:1` |
| Menu Bar | `MenuBar/StatusBarController.swift:1` |
| Floating Window | `FloatingWindow/FloatingWindowController.swift:1` |
| Settings | `Persistence/SettingsManager.swift:1` |
| Service Protocols | `Services/Protocols/` |
| Test Mocks | `PomoDaddyTests/Mocks/` |

## Code Quality

- **SwiftLint**: Strict mode, `todo` rule enabled. Test files have a nested `.swiftlint.yml` with test-appropriate overrides.
- **SwiftFormat**: Enforced via `make format-check`
- **Pre-commit hooks**: Run lint and format checks before commit
- **CI**: GitHub Actions on macOS-15. Build, lint, test, coverage check.

## Documentation

- `docs/architecture.md` - System architecture and data flow
- `docs/building.md` - Build and distribution instructions
- `docs/components.md` - UI component reference
