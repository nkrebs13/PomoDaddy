//
//  SettingsSection.swift
//  PomoDaddy
//
//  A reusable section container with a title and content.
//

import SwiftUI

// MARK: - Settings Section

/// A reusable section container with a title and content.
internal struct SettingsSection<Content: View>: View {
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

// MARK: - Preview

#Preview("Settings Section") {
    VStack {
        SettingsSection(title: "Timer Durations") {
            Text("Content goes here")
        }
    }
    .padding()
    .frame(width: 300)
}
