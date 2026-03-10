//
//  SettingsView.swift
//  PomoDaddy
//
//  Comprehensive settings view for configuring timer durations, behavior, and display options.
//

import SwiftUI

// MARK: - Settings View

/// A full settings view that appears within the menu popover.
/// Provides controls for timer durations, behavior toggles, display options, and quick presets.
struct SettingsView: View {
    // MARK: - Properties

    @Bindable var coordinator: AppCoordinator
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with back button
                headerSection

                // Timer Durations Section
                SettingsSection(title: "Timer Durations") {
                    DurationStepper(
                        label: "Focus",
                        value: Binding(
                            get: { coordinator.settingsManager.settings.workDurationMinutes },
                            set: { coordinator.settingsManager.setWorkDuration(minutes: $0) }
                        ),
                        range: 1...60,
                        unit: "min",
                        iconName: "flame.fill",
                        iconColor: .tomatoRed
                    )
                    DurationStepper(
                        label: "Short Break",
                        value: Binding(
                            get: { coordinator.settingsManager.settings.shortBreakDurationMinutes },
                            set: { coordinator.settingsManager.setShortBreakDuration(minutes: $0) }
                        ),
                        range: 1...30,
                        unit: "min",
                        iconName: "leaf.fill",
                        iconColor: .mint
                    )
                    DurationStepper(
                        label: "Long Break",
                        value: Binding(
                            get: { coordinator.settingsManager.settings.longBreakDurationMinutes },
                            set: { coordinator.settingsManager.setLongBreakDuration(minutes: $0) }
                        ),
                        range: 5...60,
                        unit: "min",
                        iconName: "cup.and.saucer.fill",
                        iconColor: .lavender
                    )
                    DurationStepper(
                        label: "Long Break After",
                        value: Binding(
                            get: { coordinator.settingsManager.settings.pomodorosUntilLongBreak },
                            set: { coordinator.settingsManager.setPomodorosUntilLongBreak(count: $0) }
                        ),
                        range: 2...8,
                        unit: "pomodoros",
                        iconName: "repeat.circle.fill",
                        iconColor: .skyBlue
                    )
                }

                // Behavior Section
                SettingsSection(title: "Behavior") {
                    SettingsToggle(
                        title: "Auto-start Breaks",
                        subtitle: "Automatically start break after focus ends",
                        isOn: Binding(
                            get: { coordinator.settingsManager.settings.autoStartNextSession },
                            set: { coordinator.settingsManager.setAutoStartNextSession(enabled: $0) }
                        ),
                        iconName: "arrow.triangle.2.circlepath",
                        iconColor: .mint
                    )
                    SettingsToggle(
                        title: "Auto-start Focus",
                        subtitle: "Automatically start focus after break ends",
                        isOn: Binding(
                            get: { coordinator.settingsManager.settings.autoStartNextSession },
                            set: { coordinator.settingsManager.setAutoStartNextSession(enabled: $0) }
                        ),
                        iconName: "play.circle.fill",
                        iconColor: .tomatoRed
                    )
                }

                // Display Section
                SettingsSection(title: "Display") {
                    SettingsToggle(
                        title: "Floating Window",
                        subtitle: "Show floating timer window",
                        isOn: $coordinator.isFloatingWindowVisible,
                        iconName: "macwindow",
                        iconColor: .skyBlue
                    )
                    SettingsToggle(
                        title: "Menu Bar Countdown",
                        subtitle: "Show remaining time in menu bar",
                        isOn: $coordinator.isMenuBarCountdownVisible,
                        iconName: "menubar.rectangle",
                        iconColor: .lavender
                    )
                }

                // Notifications Section
                SettingsSection(title: "Notifications") {
                    SettingsToggle(
                        title: "Show Notifications",
                        subtitle: "Alert when timer completes",
                        isOn: Binding(
                            get: { coordinator.settingsManager.settings.showNotifications },
                            set: { coordinator.settingsManager.setShowNotifications(enabled: $0) }
                        ),
                        iconName: "bell.fill",
                        iconColor: .sunnyYellow
                    )
                }

                // Quick Presets Section
                SettingsSection(title: "Quick Presets") {
                    HStack(spacing: 12) {
                        PresetButton(
                            title: "Classic",
                            subtitle: "25/5/15",
                            isSelected: isPresetSelected(.classic)
                        ) {
                            withAnimation(.modeTransition) {
                                coordinator.settingsManager.applyPreset(.classic)
                            }
                        }
                        PresetButton(
                            title: "Extended",
                            subtitle: "50/10/30",
                            isSelected: isPresetSelected(.extendedFocus)
                        ) {
                            withAnimation(.modeTransition) {
                                coordinator.settingsManager.applyPreset(.extendedFocus)
                            }
                        }
                        PresetButton(
                            title: "Quick",
                            subtitle: "15/3/10",
                            isSelected: isPresetSelected(.quickSprints)
                        ) {
                            withAnimation(.modeTransition) {
                                coordinator.settingsManager.applyPreset(.quickSprints)
                            }
                        }
                    }
                }

                // Reset Section
                SettingsSection(title: "Reset") {
                    Button(action: {
                        withAnimation(.modeTransition) {
                            coordinator.settingsManager.resetToDefaults()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                                .foregroundStyle(.secondary)
                            Text("Reset to Defaults")
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }

                // About Section
                SettingsSection(title: "About") {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundStyle(Color.tomatoRed)
                        Text("PomoDaddy")
                            .fontWeight(.medium)
                        Spacer()
                        Text("Version 1.0")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
        }
        .frame(width: 300, height: 450)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Subviews

    /// Header section with back button and title.
    private var headerSection: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Back")
                        .font(.subheadline)
                }
                .foregroundStyle(Color.tomatoRed)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Settings")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            // Invisible spacer to balance the back button
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
                Text("Back")
                    .font(.subheadline)
            }
            .opacity(0)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Helper Methods

    /// Checks if the given preset matches the current settings.
    private func isPresetSelected(_ preset: SettingsPreset) -> Bool {
        let settings = coordinator.settingsManager.settings
        switch preset {
        case .classic:
            return settings.workDurationMinutes == 25 &&
                   settings.shortBreakDurationMinutes == 5 &&
                   settings.longBreakDurationMinutes == 15
        case .extendedFocus:
            return settings.workDurationMinutes == 50 &&
                   settings.shortBreakDurationMinutes == 10 &&
                   settings.longBreakDurationMinutes == 30
        case .quickSprints:
            return settings.workDurationMinutes == 15 &&
                   settings.shortBreakDurationMinutes == 3 &&
                   settings.longBreakDurationMinutes == 10
        }
    }
}

// MARK: - Settings Section

/// A reusable section container with a title and content.
struct SettingsSection<Content: View>: View {
    // MARK: - Properties

    let title: String
    @ViewBuilder let content: Content

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            VStack(spacing: 8) {
                content
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
            )
        }
    }
}

// MARK: - Duration Stepper

/// A stepper control for adjusting duration values with +/- buttons.
struct DurationStepper: View {
    // MARK: - Properties

    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String
    var iconName: String = "clock"
    var iconColor: Color = .tomatoRed

    @State private var isHoveringMinus = false
    @State private var isHoveringPlus = false

    // MARK: - Body

    var body: some View {
        HStack {
            // Icon and label
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .foregroundStyle(iconColor)
                    .font(.system(size: 14))
                    .frame(width: 20)

                Text(label)
                    .font(.subheadline)
                    .lineLimit(1)
            }

            Spacer()

            // Stepper controls
            HStack(spacing: 8) {
                // Minus button
                stepperButton(
                    systemName: "minus",
                    isHovering: $isHoveringMinus,
                    isEnabled: value > range.lowerBound
                ) {
                    if value > range.lowerBound {
                        withAnimation(.buttonPress) {
                            value -= 1
                        }
                    }
                }

                // Value display
                Text("\(value)")
                    .font(.system(.subheadline, design: .monospaced))
                    .fontWeight(.medium)
                    .frame(minWidth: 28)
                    .contentTransition(.numericText())

                // Plus button
                stepperButton(
                    systemName: "plus",
                    isHovering: $isHoveringPlus,
                    isEnabled: value < range.upperBound
                ) {
                    if value < range.upperBound {
                        withAnimation(.buttonPress) {
                            value += 1
                        }
                    }
                }

                // Unit label
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .leading)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Private Views

    /// Creates a stepper button with hover effects.
    @ViewBuilder
    private func stepperButton(
        systemName: String,
        isHovering: Binding<Bool>,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(isEnabled ? .primary : .tertiary)
                .frame(width: 22, height: 22)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isHovering.wrappedValue && isEnabled ?
                              Color(nsColor: .controlAccentColor).opacity(0.15) :
                              Color(nsColor: .controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .scaleEffect(isHovering.wrappedValue && isEnabled ? AnimationConstants.hoverScale : 1.0)
        .animation(.buttonHover, value: isHovering.wrappedValue)
        .onHover { hovering in
            isHovering.wrappedValue = hovering
        }
    }
}

// MARK: - Settings Toggle

/// A styled toggle switch with title and subtitle.
struct SettingsToggle: View {
    // MARK: - Properties

    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    var iconName: String = "circle"
    var iconColor: Color = .tomatoRed

    @State private var isHovering = false

    // MARK: - Body

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Icon
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
                .font(.system(size: 14))
                .frame(width: 20)

            // Labels
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Custom toggle
            SettingsToggleSwitch(isOn: $isOn)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovering ? Color(nsColor: .controlAccentColor).opacity(0.05) : .clear)
        )
        .animation(.buttonHover, value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture {
            withAnimation(.modeTransition) {
                isOn.toggle()
            }
        }
    }
}

// MARK: - Settings Toggle Switch

/// A custom toggle switch with smooth animations.
struct SettingsToggleSwitch: View {
    // MARK: - Properties

    @Binding var isOn: Bool

    // MARK: - Constants

    private let width: CGFloat = 38
    private let height: CGFloat = 22
    private let thumbSize: CGFloat = 18
    private let thumbPadding: CGFloat = 2

    // MARK: - Body

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            // Track
            Capsule()
                .fill(isOn ? Color.tomatoRed : Color(nsColor: .separatorColor))
                .frame(width: width, height: height)

            // Thumb
            Circle()
                .fill(.white)
                .frame(width: thumbSize, height: thumbSize)
                .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                .padding(.horizontal, thumbPadding)
        }
        .animation(.modeTransition, value: isOn)
        .onTapGesture {
            isOn.toggle()
        }
    }
}

// MARK: - Preset Button

/// A button for applying preset configurations.
struct PresetButton: View {
    // MARK: - Properties

    let title: String
    let subtitle: String
    var isSelected: Bool = false
    let action: () -> Void

    @State private var isHovering = false
    @State private var isPressed = false

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? .white : .primary)

                Text(subtitle)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.tomatoRed : Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected ? Color.tomatoRed : Color(nsColor: .separatorColor),
                        lineWidth: isSelected ? 0 : 0.5
                    )
            )
            .shadow(
                color: isSelected ? Color.tomatoRed.opacity(0.3) : .clear,
                radius: isSelected ? 4 : 0,
                y: isSelected ? 2 : 0
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(scaleValue)
        .animation(.buttonHover, value: isHovering)
        .animation(.buttonPress, value: isPressed)
        .onHover { hovering in
            isHovering = hovering
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    // MARK: - Private Computed Properties

    private var scaleValue: CGFloat {
        if isPressed {
            return AnimationConstants.pressedScale
        } else if isHovering {
            return AnimationConstants.hoverScale
        }
        return AnimationConstants.defaultScale
    }
}

// MARK: - Preview

#Preview("Settings View") {
    SettingsView(coordinator: AppCoordinator.preview)
        .frame(width: 300, height: 500)
}

#Preview("Settings Section") {
    VStack {
        SettingsSection(title: "Timer Durations") {
            Text("Content goes here")
        }
    }
    .padding()
    .frame(width: 300)
}

#Preview("Duration Stepper") {
    VStack(spacing: 16) {
        DurationStepper(
            label: "Focus",
            value: .constant(25),
            range: 1...60,
            unit: "min",
            iconName: "flame.fill",
            iconColor: .tomatoRed
        )
        DurationStepper(
            label: "Short Break",
            value: .constant(5),
            range: 1...30,
            unit: "min",
            iconName: "leaf.fill",
            iconColor: .mint
        )
    }
    .padding()
    .frame(width: 300)
}

#Preview("Settings Toggle") {
    VStack(spacing: 16) {
        SettingsToggle(
            title: "Auto-start Breaks",
            subtitle: "Automatically start break after focus ends",
            isOn: .constant(true),
            iconName: "arrow.triangle.2.circlepath",
            iconColor: .mint
        )
        SettingsToggle(
            title: "Show Notifications",
            subtitle: "Alert when timer completes",
            isOn: .constant(false),
            iconName: "bell.fill",
            iconColor: .sunnyYellow
        )
    }
    .padding()
    .frame(width: 300)
}

#Preview("Preset Buttons") {
    HStack(spacing: 12) {
        PresetButton(title: "Classic", subtitle: "25/5/15", isSelected: true) {}
        PresetButton(title: "Extended", subtitle: "50/10/30", isSelected: false) {}
        PresetButton(title: "Quick", subtitle: "15/3/10", isSelected: false) {}
    }
    .padding()
    .frame(width: 300)
}

#Preview("Toggle Switch") {
    HStack(spacing: 20) {
        SettingsToggleSwitch(isOn: .constant(true))
        SettingsToggleSwitch(isOn: .constant(false))
    }
    .padding()
}

