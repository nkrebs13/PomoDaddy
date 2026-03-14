//
//  TimerRingView.swift
//  PomoDaddy
//
//  A beautiful circular progress ring component for displaying timer progress.
//

import SwiftUI

struct TimerRingView: View {
    let progress: Double // 0.0 to 1.0
    let remainingSeconds: Int?
    let intervalType: IntervalType?
    let ringColor: Color?
    var size: CGFloat = 160
    var lineWidth: CGFloat = 8
    var showTime = true
    var showLabel = true

    /// Full initializer with interval type for automatic styling.
    init(
        progress: Double,
        remainingSeconds: Int,
        intervalType: IntervalType,
        size: CGFloat = 160,
        lineWidth: CGFloat = 8,
        showTime: Bool = true,
        showLabel: Bool = true
    ) {
        self.progress = progress
        self.remainingSeconds = remainingSeconds
        self.intervalType = intervalType
        ringColor = nil
        self.size = size
        self.lineWidth = lineWidth
        self.showTime = showTime
        self.showLabel = showLabel
    }

    /// Simple initializer with explicit ring color (for floating timer view).
    init(
        progress: Double,
        ringColor: Color,
        size: CGFloat = 160,
        lineWidth: CGFloat = 8
    ) {
        self.progress = progress
        remainingSeconds = nil
        intervalType = nil
        self.ringColor = ringColor
        self.size = size
        self.lineWidth = lineWidth
        showTime = false
        showLabel = false
    }

    /// Computed accent color - uses ringColor if set, otherwise derives from intervalType.
    private var accentColor: Color {
        if let ringColor {
            return ringColor
        }
        return intervalType?.accentColor ?? .tomatoRed
    }

    var body: some View {
        ZStack {
            // Background ring (gray, 20% opacity)
            Circle()
                .stroke(accentColor.opacity(0.2), lineWidth: lineWidth)

            // Progress ring with gradient stroke
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressGradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90)) // Start from top
                .animation(AnimationConstants.timerTick, value: progress)

            // Optional glow effect behind progress
            Circle()
                .trim(from: 0, to: progress)
                .stroke(accentColor.opacity(0.3), lineWidth: lineWidth + 8)
                .blur(radius: 8)
                .rotationEffect(.degrees(-90))

            // Center content (only shown when we have interval type data)
            if showTime || showLabel {
                VStack(spacing: 4) {
                    if showTime, let remainingSeconds {
                        Text(formatTime(remainingSeconds))
                            .font(.system(size: size * 0.25, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                    }

                    if showLabel, let intervalType {
                        Text(intervalType.displayName)
                            .font(.system(size: size * 0.09, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(width: size, height: size)
    }

    /// Returns the appropriate gradient based on interval type or ring color.
    private var progressGradient: AngularGradient {
        let colors: [Color] = if let ringColor {
            // Use the explicit ring color for gradient
            [ringColor, ringColor.opacity(0.7)]
        } else if let intervalType {
            switch intervalType {
            case .work:
                [.tomatoRed, .coral]
            case .shortBreak, .longBreak:
                [.mint, .skyBlue]
            }
        } else {
            [.tomatoRed, .coral]
        }

        return AngularGradient(
            gradient: Gradient(colors: colors),
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
        )
    }

    /// Formats remaining seconds as MM:SS.
    private func formatTime(_ seconds: Int) -> String {
        let minutes: Int = seconds / 60
        let secs: Int = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        TimerRingView(progress: 0.75, remainingSeconds: 1245, intervalType: .work)
        TimerRingView(progress: 0.3, remainingSeconds: 180, intervalType: .shortBreak, size: 100)
    }
    .padding()
}
