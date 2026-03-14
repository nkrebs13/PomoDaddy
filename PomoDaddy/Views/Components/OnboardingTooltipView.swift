//
//  OnboardingTooltipView.swift
//  PomoDaddy
//
//  First-run onboarding tooltip shown in the menu bar popover.
//

import SwiftUI

// MARK: - Onboarding Tooltip View

/// A brief tooltip shown on first launch to highlight key features.
///
/// Displays two tips about right-click context menu and floating window,
/// then dismisses permanently when the user taps "Got it".
internal struct OnboardingTooltipView: View {
    // MARK: - Properties

    /// Action called when the user dismisses the tooltip.
    let onDismiss: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Welcome to PomoDaddy!")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 8) {
                tipRow(
                    icon: "cursorarrow.click.2",
                    text: "Right-click the menu bar icon for quick actions"
                )

                tipRow(
                    icon: "macwindow",
                    text: "Enable the floating window for an always-visible timer"
                )
            }

            Button {
                onDismiss()
            } label: {
                Text("Got it")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.tomatoRed, in: Capsule())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.tomatoRed.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Tip Row

    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Color.tomatoRed)
                .frame(width: 20)

            Text(text)
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview("Onboarding Tooltip") {
    OnboardingTooltipView(onDismiss: {})
        .padding()
        .frame(width: 300)
}

#Preview("Onboarding Tooltip - Dark") {
    OnboardingTooltipView(onDismiss: {})
        .padding()
        .frame(width: 300)
        .preferredColorScheme(.dark)
}
