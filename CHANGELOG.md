# Changelog

All notable changes to PomoDaddy will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- **Critical:** Fixed duplicate auto-start binding where both "Auto-start Breaks" and "Auto-start Focus" toggles controlled the same setting. Users can now independently control auto-start behavior for breaks vs work sessions.
- **Critical:** Fixed app crash on SwiftData initialization failures. App now gracefully falls back to in-memory storage instead of crashing when persistent storage fails.

### Changed
- Replaced all `print()` statements with proper `Logger` infrastructure for better debugging and log management
- Improved error handling throughout persistence layer with structured logging

### Added
- Pre-commit hooks for automated quality checks (SwiftLint, SwiftFormat, force unwrap detection, print statement detection)
- Security scanning script to detect potential security issues (hardcoded secrets, insecure APIs)
- Makefile commands: `make install-hooks`, `make security-check`
- Documentation for remaining accessibility work in `ACCESSIBILITY_TODO.md`
- Test coverage for `autoStartNextSession` backward-compatible computed property edge cases

### Internal
- Split `autoStartNextSession` into separate `autoStartBreaks` and `autoStartWork` properties with backward-compatible computed property
- Updated all test files to use new auto-start property names
- Enhanced Makefile with additional developer commands

## [Previous Releases]

See git history for previous changes.
