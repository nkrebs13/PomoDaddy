//
//  MenuPopoverView.swift
//  PomoDaddy
//
//  SwiftUI popover content for the menu bar status item.
//

import SwiftUI

// MARK: - Menu Popover View

/// Main popover view displayed when clicking the menu bar icon.
///
/// Features:
/// - Header with app name and settings gear
/// - Timer section with ring and countdown
/// - Control buttons (play/pause, skip, reset)
/// - Session indicators showing completed pomodoros
/// - Quick stats preview (focus time, streak)
/// - Toggle for floating window visibility
/// - Quit button
struct MenuPopoverView: View {
    // MARK: - Properties

    /// The app coordinator for accessing timer state.
    @Bindable var coordinator: AppCoordinator

    /// Whether the settings section is expanded.
    @State private var showingSettings = false

    // MARK: - Computed Properties

    /// The current timer state.
    private var timerState: TimerState {
        coordinator.stateMachine.currentState
    }

    /// The current progress (0-1).
    private var progress: Double {
        coordinator.stateMachine.progress
    }

    /// The formatted remaining time.
    private var formattedTime: String {
        coordinator.stateMachine.formattedTime
    }

    /// Number of completed pomodoros in the current cycle.
    private var completedPomodoros: Int {
        coordinator.stateMachine.completedPomodorosInCycle
    }

    /// Total pomodoros completed today.
    private var totalToday: Int {
        coordinator.stateMachine.totalCompletedToday
    }

    /// Number of pomodoros until long break.
    private var pomodorosUntilLongBreak: Int {
        coordinator.stateMachine.settings.pomodorosUntilLongBreak
    }

    /// Accent color for the current state.
    private var accentColor: Color {
        switch timerState {
        case .idle:
            .tomatoRed
        case .running(let type), .paused(let type):
            switch type {
            case .work:
                .tomatoRed
            case .shortBreak:
                .mint
            case .longBreak:
                .lavender
            }
        }
    }

    /// Accent gradient for the current state.
    private var accentGradient: LinearGradient {
        switch timerState {
        case .idle, .running(.work), .paused(.work):
            .focusGradient
        case .running(.shortBreak), .paused(.shortBreak):
            .breakGradient
        case .running(.longBreak), .paused(.longBreak):
            LinearGradient(
                colors: [.lavender, .skyBlue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // Header
            headerSection

            Divider()

            // Timer section
            timerSection

            // Control buttons
            controlButtons

            Divider()

            // Session indicators
            sessionIndicators

            // Quick stats
            quickStats

            Divider()

            // Settings toggle
            settingsSection

            // Quit button
            quitButton
        }
        .frame(width: AppConstants.MenuPopover.width)
        .padding()
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            // App name
            Text("PomoDaddy")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            // Settings gear button
            Button {
                withAnimation(.modeTransition) {
                    showingSettings.toggle()
                }
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(showingSettings ? 90 : 0))
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
    }

    // MARK: - Timer Section

    private var timerSection: some View {
        VStack(spacing: 12) {
            // Timer ring with countdown
            ZStack {
                // Background track
                Circle()
                    .stroke(accentColor.opacity(0.2), lineWidth: 8)
                    .frame(width: AppConstants.MenuPopover.timerRingSize, height: AppConstants.MenuPopover.timerRingSize)

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        accentGradient,
                        style: StrokeStyle(
                            lineWidth: 8,
                            lineCap: .round
                        )
                    )
                    .frame(width: AppConstants.MenuPopover.timerRingSize, height: AppConstants.MenuPopover.timerRingSize)
                    .rotationEffect(.degrees(-90))
                    .animation(.timerTick, value: progress)

                // Time display
                VStack(spacing: 2) {
                    Text(formattedTime)
                        .font(.system(size: 32, weight: .medium, design: .monospaced))
                        .foregroundStyle(.primary)

                    Text(timerState.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Control Buttons

    private var controlButtons: some View {
        HStack(spacing: 16) {
            // Reset button
            Button {
                coordinator.stateMachine.send(.reset)
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 44, height: 44)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.animated)
            .disabled(!timerState.isActive)
            .opacity(timerState.isActive ? 1 : 0.5)
            .help("Reset timer")

            // Play/Pause button
            Button {
                handlePlayPause()
            } label: {
                Image(systemName: playPauseIcon)
                    .font(.system(size: 24, weight: .semibold))
                    .frame(width: 64, height: 64)
                    .foregroundStyle(.white)
                    .background(accentGradient)
                    .clipShape(Circle())
            }
            .buttonStyle(.animated)
            .help(playPauseHelpText)

            // Skip button
            Button {
                coordinator.stateMachine.send(.skip)
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 44, height: 44)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.animated)
            .disabled(!timerState.isActive)
            .opacity(timerState.isActive ? 1 : 0.5)
            .help("Skip to next interval")
        }
    }

    private var playPauseIcon: String {
        switch timerState {
        case .idle:
            "play.fill"
        case .running:
            "pause.fill"
        case .paused:
            "play.fill"
        }
    }

    private var playPauseHelpText: String {
        switch timerState {
        case .idle:
            "Start focus session"
        case .running:
            "Pause timer"
        case .paused:
            "Resume timer"
        }
    }

    private func handlePlayPause() {
        switch timerState {
        case .idle:
            coordinator.stateMachine.send(.start())
        case .running:
            coordinator.stateMachine.send(.pause)
        case .paused:
            coordinator.stateMachine.send(.resume)
        }
    }

    // MARK: - Session Indicators

    private var sessionIndicators: some View {
        VStack(spacing: 8) {
            Text("Current Cycle")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                ForEach(0 ..< pomodorosUntilLongBreak, id: \.self) { index in
                    Circle()
                        .fill(index < completedPomodoros ? Color.tomatoRed : Color.secondary.opacity(0.2))
                        .frame(width: 12, height: 12)
                        .overlay {
                            if index < completedPomodoros {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 6, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .animation(.modeTransition, value: completedPomodoros)
                }
            }
        }
    }

    // MARK: - Quick Stats

    private var quickStats: some View {
        HStack(spacing: 24) {
            // Focus time today
            VStack(spacing: 4) {
                Text("\(totalToday)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(accentColor)

                Text("Pomodoros")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .frame(height: 30)

            // Estimated focus time
            VStack(spacing: 4) {
                Text(focusTimeText)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.forestGreen)

                Text("Focus Time")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var focusTimeText: String {
        let workDuration = coordinator.stateMachine.settings.workDuration
        let totalMinutes = Int(Double(totalToday) * workDuration / 60)

        if totalMinutes >= 60 {
            let hours = totalMinutes / 60
            let mins = totalMinutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(totalMinutes)m"
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(spacing: 12) {
            // Floating window toggle
            Toggle(isOn: $coordinator.isFloatingWindowVisible) {
                HStack {
                    Image(systemName: "macwindow")
                        .foregroundStyle(.secondary)
                    Text("Show Floating Window")
                        .font(.subheadline)
                }
            }
            .toggleStyle(.switch)

            // Menu bar countdown toggle
            Toggle(isOn: $coordinator.isMenuBarCountdownVisible) {
                HStack {
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)
                    Text("Show Time in Menu Bar")
                        .font(.subheadline)
                }
            }
            .toggleStyle(.switch)

            // Expanded settings
            if showingSettings {
                VStack(spacing: 8) {
                    Divider()

                    // Auto-start breaks
                    Toggle(isOn: Binding(
                        get: { coordinator.stateMachine.settings.autoStartBreaks },
                        set: {
                            var settings = coordinator.stateMachine.settings
                            settings.autoStartBreaks = $0
                            coordinator.stateMachine.settings = settings
                        }
                    )) {
                        Text("Auto-start Breaks")
                            .font(.subheadline)
                    }
                    .toggleStyle(.switch)

                    // Auto-start work
                    Toggle(isOn: Binding(
                        get: { coordinator.stateMachine.settings.autoStartWork },
                        set: {
                            var settings = coordinator.stateMachine.settings
                            settings.autoStartWork = $0
                            coordinator.stateMachine.settings = settings
                        }
                    )) {
                        Text("Auto-start Work")
                            .font(.subheadline)
                    }
                    .toggleStyle(.switch)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Quit Button

    private var quitButton: some View {
        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            HStack {
                Image(systemName: "power")
                Text("Quit PomoDaddy")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .help("Quit PomoDaddy")
    }
}

// MARK: - Preview

#Preview("Menu Popover - Idle") {
    MenuPopoverView(coordinator: AppCoordinator())
        .frame(width: 300)
}

#Preview("Menu Popover - Dark Mode") {
    MenuPopoverView(coordinator: AppCoordinator())
        .frame(width: 300)
        .preferredColorScheme(.dark)
}
