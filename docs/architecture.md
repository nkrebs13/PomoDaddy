# PomoDaddy Architecture

This document describes the system architecture, data flow, and key design decisions.

## Component Diagram

```
+------------------+     +---------------------+
|   PomoDaddyApp   |---->|    AppCoordinator   |
+------------------+     +---------------------+
                                   |
                    +--------------+--------------+
                    |              |              |
                    v              v              v
         +------------------+  +--------+  +------------------+
         | StatusBarController|  | Views  |  | FloatingWindow   |
         +------------------+  +--------+  |   Controller      |
                    |              |       +------------------+
                    |              |              |
                    +--------------+--------------+
                                   |
                                   v
                    +------------------------------+
                    |    PomodoroStateMachine      |
                    |  +------------------------+  |
                    |  |      TimerEngine       |  |
                    |  +------------------------+  |
                    +------------------------------+
                                   |
                    +--------------+--------------+
                    |              |              |
                    v              v              v
              +---------+   +-----------+   +----------+
              | Services|   | Persistence|   |  Models  |
              +---------+   +-----------+   +----------+
```

## Core Components

### AppCoordinator (`App/AppCoordinator.swift`)

Central coordinator that owns all major dependencies and manages app-wide state.

**Responsibilities:**
- Initializes and owns the `PomodoroStateMachine`
- Manages UI state (floating window visibility, menu bar countdown)
- Coordinates callbacks between state machine and services
- Handles state persistence across launches

### PomodoroStateMachine (`Core/PomodoroStateMachine.swift`)

Event-driven state machine managing all Pomodoro timer logic.

**States:**
- `idle` - Timer not active, ready to start
- `running(IntervalType)` - Timer actively counting down
- `paused(IntervalType)` - Timer paused mid-interval

**Events:**
- `start(IntervalType?)` - Begin a new interval
- `pause` - Pause running timer
- `resume` - Resume paused timer
- `complete` - Interval completed (auto-fired by TimerEngine)
- `reset` - Reset to idle state
- `skip` - Skip current interval without completion

### TimerEngine (`Core/TimerEngine.swift`)

Timestamp-based timer ensuring accuracy across sleep/background states.

**Key Design:**
- Uses `Date` timestamps instead of accumulated time
- Survives app suspension and device sleep
- Supports save/restore for state persistence
- Fires callbacks on tick and completion

## Data Flow

### Timer Start Flow

```
User Tap -> View -> stateMachine.send(.start)
                          |
                          v
                   handleStart()
                          |
                          v
              timerEngine.start(duration)
                          |
                          v
                   Timer Publisher
                          |
                          v (on complete)
              stateMachine.send(.complete)
                          |
                          v
                 handleComplete()
                          |
    +---------------------+---------------------+
    |                     |                     |
    v                     v                     v
onWorkSessionComplete  onBreakComplete   Next interval
                                         (if auto-start)
```

### State Change Notification Flow

```
State Transition -> onStateChange callback
                          |
                          v
                 AppCoordinator.saveState()
                          |
          +---------------+---------------+
          |               |               |
          v               v               v
    UserDefaults    UI Updates    Service Triggers
```

## State Management

### Observable Pattern

The app uses Swift's `@Observable` macro for reactive state:

- `AppCoordinator` - App-wide observable state
- `PomodoroStateMachine` - Timer state and counts
- `TimerEngine` - Timer progress and remaining time

Views observe these objects and automatically update when state changes.

### State Persistence

**Immediate State (UserDefaults):**
- Timer state (`TimerState`)
- Remaining time
- Completed pomodoros count
- UI preferences

**Historical Data (SwiftData):**
- `PomodoroSession` - Individual session records
- `DailyStats` - Aggregated daily statistics
- `UserStreak` - Streak tracking

## Persistence Strategy

### SwiftData Models (`Models/`)

| Model | Purpose |
|-------|---------|
| `PomodoroSession` | Individual completed sessions |
| `DailyStats` | Aggregated daily focus time |
| `UserStreak` | Current and longest streaks |

### DataContainer (`Persistence/DataContainer.swift`)

Provides configured `ModelContainer` instances:
- `create()` - Production container with disk persistence
- `createInMemory()` - Testing container
- `createPreview()` - SwiftUI preview container with sample data

### TimerStatePersistence (`Persistence/TimerStatePersistence.swift`)

Handles saving/restoring timer state across app launches:
- Captures remaining time at suspension
- Adjusts for elapsed time on restoration
- Handles timer completion during app closure

## AppKit/SwiftUI Integration

PomoDaddy is a menu bar app requiring both AppKit (for system integration) and SwiftUI (for modern UI).

### Integration Points

**StatusBarController (AppKit):**
- Manages `NSStatusItem` in menu bar
- Hosts SwiftUI views in `NSPopover`
- Handles status item button and menu

**FloatingWindowController (AppKit):**
- Creates `NSWindow` for floating timer
- Configures window level, collection behavior
- Hosts SwiftUI `FloatingTimerView`

**Views (SwiftUI):**
- `MenuPopoverView` - Content shown in popover
- `FloatingTimerView` - Floating window content
- `TimerRingView` - Circular progress indicator

### Hosting Pattern

```swift
// AppKit controller creates NSHostingView
let hostingView = NSHostingView(rootView:
    SwiftUIView()
        .environment(coordinator)
)
```

## Services

| Service | Purpose |
|---------|---------|
| `NotificationScheduler` | Local notifications for timer events |
| `SessionRecorder` | Records completed sessions to SwiftData |
| `StatsCalculator` | Computes statistics from session data |
| `AppLifecycleHandler` | Responds to app state changes |
| `AppNapManager` | Prevents App Nap during active timers |

## External Dependencies

- **Vortex** (v1.0.0+) - Particle effects for celebration animations
