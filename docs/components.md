# UI Components Reference

This document describes the reusable UI components, styling, and animations in PomoDaddy.

## TimerRingView

A circular progress ring for displaying timer state.

**Location:** `Views/Components/TimerRingView.swift`

### Usage

```swift
TimerRingView(
    progress: 0.75,           // 0.0 to 1.0
    remainingSeconds: 1245,   // Seconds remaining
    intervalType: .work       // .work, .shortBreak, .longBreak
)
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `progress` | `Double` | required | Progress from 0.0 to 1.0 |
| `remainingSeconds` | `Int` | required | Seconds to display as MM:SS |
| `intervalType` | `IntervalType` | required | Determines color scheme |
| `size` | `CGFloat` | 160 | Diameter of the ring |
| `lineWidth` | `CGFloat` | 8 | Stroke width |
| `showTime` | `Bool` | true | Show time in center |
| `showLabel` | `Bool` | true | Show interval label |

### Variants

```swift
// Full-size with all elements
TimerRingView(progress: 0.5, remainingSeconds: 750, intervalType: .work)

// Compact for menu bar
TimerRingView(
    progress: 0.5,
    remainingSeconds: 750,
    intervalType: .work,
    size: 80,
    lineWidth: 4,
    showLabel: false
)

// Minimal for status display
TimerRingView(
    progress: 0.5,
    remainingSeconds: 750,
    intervalType: .shortBreak,
    size: 40,
    showTime: false,
    showLabel: false
)
```

## Color Palette

**Location:** `Theme/ColorPalette.swift`

### Primary Colors

| Color | Hex | Usage |
|-------|-----|-------|
| `tomatoRed` | #FF6B6B | Focus mode primary |
| `coral` | #FF8E72 | Focus mode secondary, hover states |
| `mint` | #4ECDC4 | Short break primary |
| `lavender` | #A78BFA | Long break primary |
| `sunnyYellow` | #F6E05E | Celebrations |
| `skyBlue` | #63B3ED | Information, break secondary |
| `hotPink` | #ED64A6 | Streak celebrations |
| `forestGreen` | #38A169 | Completion states |

### Usage

```swift
// Direct color access
Text("Focus")
    .foregroundStyle(Color.tomatoRed)

// Background
.background(Color.mint)
```

### Gradients

```swift
// Focus mode gradient (tomatoRed -> coral)
LinearGradient.focusGradient

// Break mode gradient (mint -> skyBlue)
LinearGradient.breakGradient

// Celebration gradient (sunnyYellow -> hotPink -> lavender)
LinearGradient.celebrationGradient
```

### Gradient Usage

```swift
// As background
Rectangle()
    .fill(LinearGradient.focusGradient)

// As overlay
Circle()
    .stroke(LinearGradient.breakGradient, lineWidth: 4)
```

## Animation Constants

**Location:** `Theme/AnimationConstants.swift`

### Animations

| Constant | Value | Usage |
|----------|-------|-------|
| `buttonHover` | Spring(0.3, 0.6) | Button hover state |
| `buttonPress` | Spring(0.2, 0.5) | Button press state |
| `modeTransition` | Spring(0.5, 0.7) | Focus/break transitions |
| `timerTick` | EaseOut(0.15) | Timer updates |
| `popoverAppear` | EaseOut(0.25) | Popover animation |

### Scale Values

| Constant | Value | Usage |
|----------|-------|-------|
| `hoverScale` | 1.08 | Button hover scale |
| `pressedScale` | 0.95 | Button pressed scale |
| `defaultScale` | 1.0 | Normal state |

### Shadow Values

| Constant | Value | Usage |
|----------|-------|-------|
| `hoverShadowRadius` | 8 | Shadow on hover |
| `hoverShadowOpacity` | 0.15 | Shadow opacity |

### Usage

```swift
// Using animation constants directly
.animation(AnimationConstants.buttonHover, value: isHovering)

// Using Animation extension
.animation(.modeTransition, value: intervalType)

// Celebration duration
.onAppear {
    DispatchQueue.main.asyncAfter(deadline: .now() + AnimationConstants.confettiDuration) {
        showConfetti = false
    }
}
```

## AnimatedButtonStyle

A playful button style with hover and press animations.

**Location:** `Views/Components/AnimatedButtonStyle.swift`

### Usage

```swift
// Basic usage
Button("Start Focus") {
    startFocus()
}
.buttonStyle(.animated)

// With custom scales
Button("Custom") {
    action()
}
.buttonStyle(.animated(hoverScale: 1.15, pressedScale: 0.9))
```

### Behavior

- **Hover:** Scales to 1.08x with subtle shadow
- **Press:** Scales to 0.95x for tactile feedback
- **Release:** Springs back to 1.0x

### Complete Button Example

```swift
Button {
    stateMachine.send(.start(.work))
} label: {
    HStack(spacing: 8) {
        Image(systemName: "play.fill")
        Text("Start Focus")
    }
    .font(.headline)
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
    .foregroundStyle(.white)
    .background(Color.tomatoRed)
    .clipShape(Capsule())
}
.buttonStyle(.animated)
```

## Interval Type Colors

Each interval type has associated colors accessed via `IntervalType`:

```swift
// Get accent color for interval
let color = intervalType.accentColor

// Conditional styling
.foregroundStyle(
    stateMachine.currentState.intervalType?.accentColor ?? .gray
)
```

| IntervalType | Accent Color |
|--------------|--------------|
| `.work` | Red |
| `.shortBreak` | Green |
| `.longBreak` | Blue |

## Common Patterns

### Animated State Changes

```swift
@State private var intervalType: IntervalType = .work

var body: some View {
    TimerRingView(
        progress: progress,
        remainingSeconds: remaining,
        intervalType: intervalType
    )
    .animation(.modeTransition, value: intervalType)
}
```

### Gradient Backgrounds

```swift
var backgroundGradient: LinearGradient {
    switch intervalType {
    case .work:
        return .focusGradient
    case .shortBreak, .longBreak:
        return .breakGradient
    }
}

var body: some View {
    content
        .background(backgroundGradient)
}
```

### Responsive Buttons

```swift
Button {
    withAnimation(.buttonPress) {
        action()
    }
} label: {
    label
}
.buttonStyle(.animated)
```
