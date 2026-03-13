# Changelog

All notable changes to PomoDaddy will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project uses [CalVer](https://calver.org/) versioning (`YYYY.M.BUILD`).

## [Unreleased]

## [2026.3.4] - 2026-03-13

### Added
- Floating window close button with proper rounded-corner clearance
- First-run onboarding tooltip in menu bar popover
- App icon (AI-generated playful tomato in all 10 macOS sizes)
- Full VoiceOver accessibility support (labels, traits, hints)
- Protocol-based dependency injection for all services
- Comprehensive test suite (29+ tests covering core, services, persistence)
- Pre-commit hooks (SwiftLint strict, SwiftFormat, force-unwrap detection)
- Security scanning scripts
- GitHub Actions CI (lint, format, test, coverage)
- Release workflow for signed DMG distribution
- Homebrew Cask distribution via `nkrebs13/tap`

### Changed
- Consolidated all settings behind gear icon (floating window, menu bar countdown, auto-start)
- Anchored popover to right edge of status bar button (no more horizontal shifting)
- Close button uses overlay with opacity for VoiceOver discoverability
- Extracted `TimeFormatting` utility and centralized constants
- Consolidated `TimerConfiguration` into `PomodoroSettings`
- Cached focus time text to avoid per-render SwiftData queries
- Extracted notification constants, removed redundant calls

### Fixed
- Menu bar popover shifting left-to-right when timer countdown changes width
- Close button clipped by floating window rounded corners
- Close button hit-test area blocking timer controls during hover
- SessionRecorder cross-actor SwiftData isolation bug
- Midnight boundary test flakiness in SessionRecorder tests
- Floating window not showing on first toggle
- Duplicate auto-start toggle in settings
- Memory leaks from closure retain cycles (3 fixed)
- Force unwraps replaced with safe alternatives (3 fixed)

## [2026.3.0] - 2026-03-12

Initial public release.

### Features
- Menu bar Pomodoro timer with dynamic progress icon
- Floating draggable timer window with position memory
- Classic Pomodoro technique (25/5/15) with customizable intervals
- Statistics tracking with daily totals, weekly trends, and streaks
- Celebration confetti animations on session completion
- Non-intrusive notifications
- App-only keyboard shortcuts
