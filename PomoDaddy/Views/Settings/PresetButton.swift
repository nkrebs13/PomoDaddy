//
//  PresetButton.swift
//  PomoDaddy
//
//  A button for applying preset configurations.
//

import SwiftUI

// MARK: - Preset Button

/// A button for applying preset configurations.
internal struct PresetButton: View {
    // MARK: - Properties

    let title: String
    let subtitle: String
    var isSelected: Bool = false
    let action: () -> Void

    @State private var isHovering: Bool = false
    @State private var isPressed: Bool = false

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
        .accessibilityLabel("\(title) preset: \(subtitle)")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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

#Preview("Preset Buttons") {
    HStack(spacing: 12) {
        PresetButton(title: "Classic", subtitle: "25/5/15", isSelected: true) {}
        PresetButton(title: "Extended", subtitle: "50/10/30", isSelected: false) {}
        PresetButton(title: "Quick", subtitle: "15/3/10", isSelected: false) {}
    }
    .padding()
    .frame(width: 300)
}
