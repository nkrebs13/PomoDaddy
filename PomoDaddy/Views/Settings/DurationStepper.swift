//
//  DurationStepper.swift
//  PomoDaddy
//
//  A stepper control for adjusting duration values with +/- buttons.
//

import SwiftUI

// MARK: - Duration Stepper

/// A stepper control for adjusting duration values with +/- buttons.
internal struct DurationStepper: View {
    // MARK: - Properties

    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String
    var iconName: String = "clock"
    var iconColor: Color = .tomatoRed

    @State private var isHoveringMinus: Bool = false
    @State private var isHoveringPlus: Bool = false

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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value) \(unit)")
        .accessibilityValue("\(value)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                if value < range.upperBound { value += 1 }
            case .decrement:
                if value > range.lowerBound { value -= 1 }
            @unknown default:
                break
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Private Views

    /// Creates a stepper button with hover effects.
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

// MARK: - Preview

#Preview("Duration Stepper") {
    VStack(spacing: 16) {
        DurationStepper(
            label: "Focus",
            value: .constant(25),
            range: 1 ... 60,
            unit: "min",
            iconName: "flame.fill",
            iconColor: .tomatoRed
        )
        DurationStepper(
            label: "Short Break",
            value: .constant(5),
            range: 1 ... 30,
            unit: "min",
            iconName: "leaf.fill",
            iconColor: .mint
        )
    }
    .padding()
    .frame(width: 300)
}
