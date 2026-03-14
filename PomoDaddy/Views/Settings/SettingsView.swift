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
internal struct SettingsView: View {
    // MARK: - Properties

    @Bindable var coordinator: AppCoordinator
    @Environment(\.dismiss) private var dismiss: DismissAction

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
                        range: 1 ... 60,
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
                        range: 1 ... 30,
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
                        range: 5 ... 60,
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
                        range: 2 ... 8,
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
                            get: { coordinator.settingsManager.settings.autoStartBreaks },
                            set: { coordinator.settingsManager.setAutoStartBreaks(enabled: $0) }
                        ),
                        iconName: "arrow.triangle.2.circlepath",
                        iconColor: .mint
                    )
                    SettingsToggle(
                        title: "Auto-start Focus",
                        subtitle: "Automatically start focus after break ends",
                        isOn: Binding(
                            get: { coordinator.settingsManager.settings.autoStartWork },
                            set: { coordinator.settingsManager.setAutoStartWork(enabled: $0) }
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
                    Button(
                        action: {
                            withAnimation(.modeTransition) {
                                coordinator.settingsManager.resetToDefaults()
                            }
                        },
                        label: {
                            HStack {
                            Image(systemName: "arrow.counterclockwise")
                                .foregroundStyle(.secondary)
                            Text("Reset to Defaults")
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        }
                    )
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
                        Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
        }
        .frame(width: AppConstants.Settings.width, height: AppConstants.Settings.height)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Subviews

    /// Header section with back button and title.
    private var headerSection: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Back")
                        .font(.subheadline)
                }
                .foregroundStyle(Color.tomatoRed)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back to timer")

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
        let current: PomodoroSettings = coordinator.settingsManager.settings
        let target: PomodoroSettings = switch preset {
        case .classic: .classic
        case .extendedFocus: .extendedFocus
        case .quickSprints: .quickSprints
        }
        return current.workDurationMinutes == target.workDurationMinutes &&
            current.shortBreakDurationMinutes == target.shortBreakDurationMinutes &&
            current.longBreakDurationMinutes == target.longBreakDurationMinutes
    }
}

// MARK: - Preview

#Preview("Settings View") {
    SettingsView(coordinator: AppCoordinator.preview)
        .frame(width: 300, height: 500)
}
