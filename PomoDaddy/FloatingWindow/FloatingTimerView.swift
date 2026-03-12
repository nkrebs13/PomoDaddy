//
//  FloatingTimerView.swift
//  PomoDaddy
//
//  SwiftUI view for the floating timer window content.
//

import SwiftUI

// MARK: - Floating Timer View

/// The main content view for the floating timer window.
///
/// Features:
/// - Frosted glass background with state-based gradient tint
/// - Large timer ring with countdown display
/// - Control buttons for timer management
/// - Session progress indicator
/// - Double-tap to toggle compact mode
/// - Confetti celebration on pomodoro completion
struct FloatingTimerView: View {
    // MARK: - Properties

    /// The app coordinator containing timer state.
    @Bindable var coordinator: AppCoordinator

    /// Trigger for confetti animation.
    @State private var confettiTrigger = 0

    /// Whether the view is in compact mode.
    @State private var isCompact = false

    /// Track hover state for interactive feedback.
    @State private var isHovering = false

    // MARK: - Constants

    private let expandedSize = CGSize(width: 280, height: 320)
    private let compactSize = CGSize(width: 180, height: 180)
    private let timerRingSize: CGFloat = 160
    private let compactTimerRingSize: CGFloat = 120

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background with frosted glass effect
            backgroundView

            // Main content
            VStack(spacing: isCompact ? 8 : 16) {
                // Drag handle
                DragHandleView()
                    .padding(.top, 8)

                // Timer display
                timerDisplayView

                if !isCompact {
                    // Control buttons
                    controlButtonsView

                    // Session progress dots
                    sessionProgressView
                }
            }
            .padding(isCompact ? 16 : 24)

            // Confetti overlay for celebrations
            ConfettiOverlayView(trigger: $confettiTrigger)
        }
        .frame(
            width: isCompact ? compactSize.width : expandedSize.width,
            height: isCompact ? compactSize.height : expandedSize.height
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 8)
        .onTapGesture(count: 2) {
            withAnimation(AnimationConstants.modeTransition) {
                isCompact.toggle()
            }
        }
        .onHover { hovering in
            withAnimation(AnimationConstants.buttonHover) {
                isHovering = hovering
            }
        }
        .onChange(of: coordinator.stateMachine.completedPomodorosInCycle) { oldValue, newValue in
            // Trigger confetti when a pomodoro completes (count increases)
            if newValue > oldValue {
                confettiTrigger += 1
            }
        }
    }

    // MARK: - Background View

    private var backgroundView: some View {
        ZStack {
            // Frosted glass material
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)

            // Gradient tint based on current state
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(stateGradient.opacity(0.3))
        }
    }

    /// Returns the appropriate gradient based on current timer state.
    private var stateGradient: LinearGradient {
        switch coordinator.stateMachine.currentState {
        case .idle:
            LinearGradient(
                colors: [.gray.opacity(0.3), .gray.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .running(let type), .paused(let type):
            switch type {
            case .work:
                .focusGradient
            case .shortBreak:
                .breakGradient
            case .longBreak:
                .longBreakGradient
            }
        }
    }

    // MARK: - Timer Display View

    private var timerDisplayView: some View {
        VStack(spacing: isCompact ? 4 : 8) {
            // Timer ring with countdown
            ZStack {
                // Timer ring (to be created as TimerRingView)
                TimerRingView(
                    progress: coordinator.stateMachine.progress,
                    ringColor: currentAccentColor,
                    size: isCompact ? compactTimerRingSize : timerRingSize
                )

                // Countdown text in center
                VStack(spacing: 2) {
                    Text(coordinator.stateMachine.formattedTime)
                        .font(.system(size: isCompact ? 28 : 48, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(currentAccentColor)
                        .contentTransition(.numericText())
                        .animation(AnimationConstants.timerTick, value: coordinator.stateMachine.formattedTime)
                }
            }

            // Mode label
            Text(modeLabelText)
                .font(.system(size: isCompact ? 12 : 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .animation(AnimationConstants.modeTransition, value: coordinator.stateMachine.currentState)
        }
    }

    /// Returns the display text for current mode.
    private var modeLabelText: String {
        coordinator.stateMachine.currentState.displayName
    }

    /// Returns the accent color based on current state.
    private var currentAccentColor: Color {
        switch coordinator.stateMachine.currentState {
        case .idle:
            .gray
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

    // MARK: - Control Buttons View

    private var controlButtonsView: some View {
        HStack(spacing: 20) {
            // Previous / Reset button
            ControlButton(
                icon: "arrow.counterclockwise",
                action: {
                    coordinator.reset()
                },
                isEnabled: coordinator.stateMachine.currentState.isActive
            )

            // Play / Pause button
            ControlButton(
                icon: playPauseIcon,
                action: {
                    handlePlayPause()
                },
                isPrimary: true,
                accentColor: currentAccentColor
            )

            // Skip button
            ControlButton(
                icon: "forward.fill",
                action: {
                    coordinator.skip()
                },
                isEnabled: coordinator.stateMachine.currentState.isActive
            )
        }
    }

    /// Returns the appropriate icon for play/pause button.
    private var playPauseIcon: String {
        switch coordinator.stateMachine.currentState {
        case .idle:
            "play.fill"
        case .running:
            "pause.fill"
        case .paused:
            "play.fill"
        }
    }

    /// Handles play/pause button tap.
    private func handlePlayPause() {
        switch coordinator.stateMachine.currentState {
        case .idle:
            coordinator.start()
        case .running:
            coordinator.pause()
        case .paused:
            coordinator.resume()
        }
    }

    // MARK: - Session Progress View

    private var sessionProgressView: some View {
        HStack(spacing: 8) {
            ForEach(0 ..< coordinator.stateMachine.settings.pomodorosUntilLongBreak, id: \.self) { index in
                Circle()
                    .fill(index < coordinator.stateMachine.completedPomodorosInCycle
                        ? currentAccentColor
                        : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(
                        AnimationConstants.modeTransition,
                        value: coordinator.stateMachine.completedPomodorosInCycle
                    )
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - Drag Handle View

/// A minimal drag handle indicator at the top of the window.
struct DragHandleView: View {
    var body: some View {
        Capsule()
            .fill(Color.primary.opacity(0.2))
            .frame(width: 36, height: 4)
    }
}

// MARK: - Control Button

/// A styled control button for timer actions.
struct ControlButton: View {
    let icon: String
    let action: () -> Void
    var isPrimary = false
    var isEnabled = true
    var accentColor: Color = .primary

    @State private var isHovering = false
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: isPrimary ? 24 : 16, weight: .semibold))
                .foregroundStyle(isPrimary ? .white : (isEnabled ? .primary : .secondary))
                .frame(width: isPrimary ? 56 : 40, height: isPrimary ? 56 : 40)
                .background(
                    Circle()
                        .fill(isPrimary ? accentColor : Color.primary.opacity(0.1))
                )
                .scaleEffect(scaleValue)
                .shadow(
                    color: isHovering && isEnabled ? .black.opacity(0.15) : .clear,
                    radius: isHovering ? 8 : 0,
                    y: isHovering ? 4 : 0
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled && !isPrimary)
        .onHover { hovering in
            withAnimation(AnimationConstants.buttonHover) {
                isHovering = hovering
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(AnimationConstants.buttonPress) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(AnimationConstants.buttonPress) {
                        isPressed = false
                    }
                }
        )
    }

    private var scaleValue: CGFloat {
        if isPressed {
            return AnimationConstants.pressedScale
        } else if isHovering, isEnabled || isPrimary {
            return AnimationConstants.hoverScale
        }
        return AnimationConstants.defaultScale
    }
}

// MARK: - Preview

#Preview("Floating Timer View - Default") {
    FloatingTimerView(coordinator: AppCoordinator())
        .frame(width: 280, height: 320)
}

#Preview("Floating Timer View - Compact") {
    FloatingTimerView(coordinator: AppCoordinator())
        .frame(width: 180, height: 180)
}
