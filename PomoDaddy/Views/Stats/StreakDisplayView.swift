//
//  StreakDisplayView.swift
//  PomoDaddy
//
//  Displays current and longest streak information in card format.
//

import SwiftData
import SwiftUI

/// A view displaying streak statistics in visually appealing cards.
///
/// `StreakDisplayView` shows:
/// - Current streak with animated flame icon
/// - Longest streak ever achieved with trophy icon
struct StreakDisplayView: View {
    // MARK: - Properties

    @Bindable var coordinator: AppCoordinator
    @Environment(\.modelContext) private var modelContext

    @State private var streakDays = 0
    @State private var longestStreak = 0
    @State private var hasAppeared = false

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Streaks")
                .font(.headline)

            HStack(spacing: 16) {
                // Current streak card
                StreakCard(
                    icon: "flame.fill",
                    iconColor: .hotPink,
                    title: "Current Streak",
                    value: "\(streakDays)",
                    subtitle: streakDays == 1 ? "day" : "days",
                    isAnimated: streakDays > 0,
                    hasAppeared: hasAppeared
                )

                // Best streak card
                StreakCard(
                    icon: "trophy.fill",
                    iconColor: .sunnyYellow,
                    title: "Best Streak",
                    value: "\(longestStreak)",
                    subtitle: longestStreak == 1 ? "day" : "days",
                    isAnimated: false,
                    hasAppeared: hasAppeared
                )
            }
        }
        .onAppear {
            loadStreakData()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4)) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Methods

    /// Loads streak data from the data store.
    private func loadStreakData() {
        do {
            let calculator = StatsCalculator(modelContext: modelContext)
            streakDays = try calculator.currentStreakDays()
            longestStreak = try calculator.longestStreakDays()
        } catch {
            // Use defaults if fetching fails
            streakDays = 0
            longestStreak = 0
        }
    }
}

// MARK: - Streak Card

/// A styled card displaying streak information with icon animation.
struct StreakCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String
    let isAnimated: Bool
    let hasAppeared: Bool

    @State private var flamePhase: CGFloat = 0

    var body: some View {
        VStack(spacing: 8) {
            // Animated icon
            iconView

            // Value
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())

            // Subtitle
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)

            // Title
            Text(title)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .scaleEffect(hasAppeared ? 1 : 0.8)
        .opacity(hasAppeared ? 1 : 0)
        .onAppear {
            if isAnimated {
                startFlameAnimation()
            }
        }
    }

    // MARK: - Subviews

    /// The animated icon view.
    private var iconView: some View {
        ZStack {
            // Glow effect
            if isAnimated {
                Circle()
                    .fill(iconColor.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .blur(radius: 8)
                    .scaleEffect(1 + flamePhase * 0.15)
            }

            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(
                    LinearGradient(
                        colors: isAnimated
                            ? [iconColor, iconColor.opacity(0.7)]
                            : [iconColor],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .scaleEffect(isAnimated ? (1 + flamePhase * 0.1) : 1)
                .offset(y: isAnimated ? -flamePhase * 2 : 0)
        }
        .frame(height: 44)
    }

    /// Gradient background for the card.
    private var cardBackground: some View {
        LinearGradient(
            colors: [
                iconColor.opacity(0.15),
                iconColor.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Animations

    /// Starts the continuous flame flicker animation.
    private func startFlameAnimation() {
        withAnimation(
            .easeInOut(duration: 0.8)
                .repeatForever(autoreverses: true)
        ) {
            flamePhase = 1
        }
    }
}

// MARK: - Preview

#Preview("Streak Display View") {
    StreakDisplayView(coordinator: AppCoordinator())
        .padding()
        .frame(width: 350)
}

#Preview("Streak Cards") {
    HStack(spacing: 16) {
        StreakCard(
            icon: "flame.fill",
            iconColor: .hotPink,
            title: "Current Streak",
            value: "7",
            subtitle: "days",
            isAnimated: true,
            hasAppeared: true
        )

        StreakCard(
            icon: "trophy.fill",
            iconColor: .sunnyYellow,
            title: "Best Streak",
            value: "14",
            subtitle: "days",
            isAnimated: false,
            hasAppeared: true
        )
    }
    .padding()
    .frame(width: 350)
}

#Preview("Streak Display View - Dark Mode") {
    StreakDisplayView(coordinator: AppCoordinator())
        .padding()
        .frame(width: 350)
        .preferredColorScheme(.dark)
}
