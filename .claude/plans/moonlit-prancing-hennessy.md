# Plan: Fix popover positioning & consolidate settings toggles

## Context

After testing PomoDaddy with both the floating window and menu bar popover open, two issues were found:

1. **Popover shifts horizontally** — When the timer is running and "Show Time in Menu Bar" is on, the status item width changes (22pt → ~70pt). Since macOS status items grow leftward (right edge is anchored), the button's center shifts. The popover is anchored to `button.bounds`, so its arrow moves with the center — sliding left and right as the timer ticks. The arrow ends up misaligned with the icon.

2. **Settings toggles split** — "Show Floating Window" and "Show Time in Menu Bar" are always visible in the popover, while "Auto-start Breaks" and "Auto-start Work" are hidden behind the gear icon. User wants all four behind the gear.

## Phase 1: Fix popover anchor & consolidate settings

### Work Unit 1: Anchor popover to right edge of status button

**File:** `PomoDaddy/MenuBar/StatusBarController.swift:171-173`

**Problem:** `popover.show(relativeTo: button.bounds, ...)` anchors the arrow to the center of the full button rect. As button width changes, center shifts on screen.

**Fix:** Anchor to a fixed-width rect at the right edge of the button. The right edge of a macOS status item is positionally stable — it doesn't move when the item's width changes. Use a 22pt-wide rect (icon width) at the right edge:

```swift
func showPopover() {
    guard let button = statusItem.button else { return }
    // Anchor to the right edge of the button — this point is
    // screen-stable regardless of status item width changes.
    let anchorWidth: CGFloat = min(button.bounds.width, 22)
    let anchorRect = NSRect(
        x: button.bounds.width - anchorWidth,
        y: button.bounds.origin.y,
        width: anchorWidth,
        height: button.bounds.height
    )
    popover.show(relativeTo: anchorRect, of: button, preferredEdge: .minY)
    popover.contentViewController?.view.window?.makeKey()
}
```

**Verification:** Build and run. Open popover, start timer with "Show Time in Menu Bar" on. The popover arrow should stay fixed even as the status item width changes.

**Commit:** `fix: anchor popover to stable right edge of status bar button`

### Work Unit 2: Move display toggles behind settings gear

**File:** `PomoDaddy/MenuBar/MenuPopoverView.swift:351-406`

**Current layout:**
```
settingsSection:
  ├── Toggle "Show Floating Window"    ← always visible
  ├── Toggle "Show Time in Menu Bar"   ← always visible
  └── if showingSettings {
        ├── Divider
        ├── Toggle "Auto-start Breaks"
        └── Toggle "Auto-start Work"
      }
```

**Target layout:**
```
settingsSection:
  └── if showingSettings {
        ├── Toggle "Show Floating Window"
        ├── Toggle "Show Time in Menu Bar"
        ├── Divider
        ├── Toggle "Auto-start Breaks"
        └── Toggle "Auto-start Work"
      }
```

Move the two display toggles inside the `if showingSettings` block, above the divider.

**Verification:** Build and run. Gear icon should toggle all four settings. When collapsed, no toggles visible.

**Commit:** `fix: consolidate all settings behind gear icon toggle`

## Files Modified

| File | Change |
|------|--------|
| `PomoDaddy/MenuBar/StatusBarController.swift` | Anchor popover to right-edge rect |
| `PomoDaddy/MenuBar/MenuPopoverView.swift` | Move display toggles inside `if showingSettings` |

## Verification

1. `make build` — must compile
2. `make test` — all tests pass
3. `make lint` — no new warnings
4. Manual: open popover, start timer with menu bar countdown on, verify popover stays fixed
5. Manual: click gear icon, verify all 4 toggles appear/disappear together
