# PomoDaddy Verification Checklist

## Automated Checks
- [ ] `make build` - builds without errors
- [ ] `make lint` - no lint warnings
- [ ] `make format-check` - code formatted
- [ ] `make test` - all tests pass
- [ ] `make test-coverage` - coverage ≥ 70%
- [ ] `scripts/verify-hardening.sh` - all checks pass

## Manual Testing
- [ ] App launches without crashes
- [ ] Start/pause/resume timer works
- [ ] Complete full pomodoro cycle
- [ ] Floating window displays correctly
- [ ] Menu bar icon updates
- [ ] Notifications appear
- [ ] Settings persist across restarts
- [ ] Stats display correctly
- [ ] Confetti animation shows on completion

## Edge Cases
- [ ] Timer completes while app in background
- [ ] App survives system sleep/wake
- [ ] Settings validation prevents invalid values
- [ ] App handles corrupted UserDefaults
- [ ] State restores correctly after app restart

## Performance
- [ ] Timer accurate over 25 minutes (±100ms)
- [ ] No memory leaks (check Instruments)
- [ ] No excessive CPU usage
- [ ] UI remains responsive

## Code Quality
- [ ] No force unwraps in production code
- [ ] All errors properly handled (no silent try?)
- [ ] No print() statements (Logger used instead)
- [ ] AppCoordinator < 200 lines
- [ ] All public APIs have access control
