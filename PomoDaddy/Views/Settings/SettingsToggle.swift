//
//  SettingsToggle.swift
//  PomoDaddy
//
//  Toggle components for the settings view.
//

import SwiftUI

// MARK: - Settings Toggle

/// A styled toggle switch with title and subtitle.
internal struct SettingsToggle: View {
    // MARK: - Properties

    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    var iconName: String = "circle"
    var iconColor: Color = .tomatoRed

    @State private var isHovering: Bool = false

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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(isOn ? "Enabled" : "Disabled")
        .accessibilityHint(subtitle)
        .accessibilityAddTraits(.isButton)
        .onTapGesture {
            withAnimation(.modeTransition) {
                isOn.toggle()
            }
        }
    }
}

// MARK: - Settings Toggle Switch

/// A custom toggle switch with smooth animations.
internal struct SettingsToggleSwitch: View {
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

// MARK: - Previews

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

#Preview("Toggle Switch") {
    HStack(spacing: 20) {
        SettingsToggleSwitch(isOn: .constant(true))
        SettingsToggleSwitch(isOn: .constant(false))
    }
    .padding()
}
