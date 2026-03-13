# Core Module Rules

- All types in `Core/` must have corresponding protocols (except value types like `PomodoroEvent`, `TimerState`, `IntervalType`)
- No direct UI framework imports (SwiftUI, AppKit) in `Core/` — this module must remain UI-agnostic
- State transitions must go through `send(_:)` on `PomodoroStateMachine` — no direct state mutation from outside
- `TimerEngine` is `@Observable @MainActor` — always access from main actor
- `PomodoroStateMachine` uses callback closures (`onWorkSessionComplete`, `onBreakComplete`, `onStateChange`, `onCycleComplete`) for event propagation — not Combine or async streams
- Persistence is injected via `StateMachinePersistence` parameter (defaults to `.shared` for production, use isolated `UserDefaults(suiteName:)` in tests)
