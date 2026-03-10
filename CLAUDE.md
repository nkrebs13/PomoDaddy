# PomoDaddy

A macOS menu bar Pomodoro timer app with playful design, stats tracking, and celebration animations.

## Quick Start

1. Install dependencies: `brew install xcodegen` (if not installed)
2. Generate Xcode project: `xcodegen generate`
3. Open in Xcode: `open PomoDaddy.xcodeproj`
4. Build and run (Cmd+R)

## Project Structure

- `PomoDaddy/App/` - App entry point, AppDelegate, AppCoordinator
- `PomoDaddy/Core/` - Timer engine, state machine, configuration
- `PomoDaddy/MenuBar/` - Status bar controller, menu bar icon, popover
- `PomoDaddy/FloatingWindow/` - Floating timer window
- `PomoDaddy/Views/` - SwiftUI components, settings, stats
- `PomoDaddy/Models/` - SwiftData models
- `PomoDaddy/Services/` - Notifications, recording, lifecycle
- `PomoDaddy/Persistence/` - Data container, settings manager
- `PomoDaddy/Theme/` - Colors, animations

## Documentation

For detailed documentation, see:
- `docs/architecture.md` - System architecture and data flow
- `docs/building.md` - Build and distribution instructions
- `docs/components.md` - UI component reference

## Key Files

| Purpose | File |
|---------|------|
| Timer Logic | `Core/TimerEngine.swift:1` |
| State Machine | `Core/PomodoroStateMachine.swift:1` |
| Menu Bar | `MenuBar/StatusBarController.swift:1` |
| Floating Window | `FloatingWindow/FloatingWindowController.swift:1` |
| Settings | `Persistence/SettingsManager.swift:1` |
