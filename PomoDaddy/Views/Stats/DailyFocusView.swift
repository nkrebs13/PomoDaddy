//
//  DailyFocusView.swift
//  PomoDaddy
//
//  Displays today's focus progress with a prominent progress ring.
//

import os.log
import SwiftData
import SwiftUI

/// A view displaying today's focus progress with an animated progress ring.
///
/// `DailyFocusView` shows:
/// - A large progress ring showing daily goal completion
/// - Total focus time in the center
/// - Completed pomodoro count
/// - Row of tomato icons for visual session tracking
struct DailyFocusView: View {
    // MARK: - Properties

    @Bindable var coordinator: AppCoordinator
    @Environment(\.modelContext) private var modelContext

    @State private var focusMinutes = 0
    @State private var completedPomodoros = 0
    @State private var ringProgress: Double = 0
    @State private var hasAppeared = false

    /// Daily goal in minutes.
    private let dailyGoalMinutes = AppConstants.DailyFocus.dailyGoalMinutes

    /// Maximum tomatoes to display in the row.
    private let maxTomatoDisplay = AppConstants.DailyFocus.maxTomatoDisplay

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            // Section header
            HStack {
                Text("Today's Focus")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
            }

            // Large progress ring
            progressRing

            // Completed pomodoros text
            Text("\(completedPomodoros) pomodoro\(completedPomodoros == 1 ? "" : "s") completed")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Tomato icons row
            if completedPomodoros > 0 {
                tomatoRow
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            loadTodayStats()
            animateOnAppear()
        }
    }

    // MARK: - Subviews

    /// Large animated progress ring with focus time.
    private var progressRing: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(lineWidth: 12)
                .opacity(0.2)
                .foregroundStyle(Color.tomatoRed)

            // Glow effect
            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(Color.tomatoRed.opacity(0.3), lineWidth: 20)
                .blur(radius: 10)
                .rotationEffect(.degrees(-90))

            // Progress ring with gradient
            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.tomatoRed, .coral]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 1.0, dampingFraction: 0.7), value: ringProgress)

            // Center content
            VStack(spacing: 4) {
                Text(formattedFocusTime)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Text("of \(dailyGoalMinutes / 60)h goal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 180, height: 180)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Daily focus progress: \(formattedFocusTime) of \(dailyGoalMinutes / 60) hour goal, \(Int(ringProgress * 100)) percent complete")
        .accessibilityAddTraits(.updatesFrequently)
    }

    /// Row of tomato icons representing completed sessions.
    private var tomatoRow: some View {
        HStack(spacing: 8) {
            ForEach(0 ..< min(completedPomodoros, maxTomatoDisplay), id: \.self) { index in
                tomatoIcon(index: index)
            }

            // Show overflow indicator
            if completedPomodoros > maxTomatoDisplay {
                Text("+\(completedPomodoros - maxTomatoDisplay)")
                    .font(.caption.bold())
                    .foregroundStyle(Color.tomatoRed)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(completedPomodoros) completed pomodoros today")
        .padding(.vertical, 8)
    }

    /// Individual tomato icon with staggered animation.
    private func tomatoIcon(index: Int) -> some View {
        Image(systemName: "circle.fill")
            .font(.system(size: 12))
            .foregroundStyle(
                LinearGradient(
                    colors: [.tomatoRed, .coral],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .scaleEffect(hasAppeared ? 1.0 : 0.5)
            .opacity(hasAppeared ? 1.0 : 0.0)
            .animation(
                .spring(response: 0.4, dampingFraction: 0.6)
                    .delay(Double(index) * 0.08),
                value: hasAppeared
            )
    }

    // MARK: - Computed Properties

    /// Formats focus minutes as "Xh Ym" or "Ym".
    private var formattedFocusTime: String {
        TimeFormatting.formatFocusTime(minutes: focusMinutes)
    }

    // MARK: - Methods

    /// Loads today's statistics from the data store.
    private func loadTodayStats() {
        do {
            let calculator = StatsCalculator(modelContext: modelContext)
            focusMinutes = try calculator.todayFocusMinutes()
            completedPomodoros = try calculator.todayCompletedPomodoros()
        } catch {
            Logger.logError(error, context: "Failed to load today's stats", log: Logger.stats)
            focusMinutes = 0
            completedPomodoros = 0
        }
    }

    /// Animates the ring and icons on appear.
    private func animateOnAppear() {
        // Calculate target progress (capped at 100%)
        let targetProgress = min(Double(focusMinutes) / Double(dailyGoalMinutes), 1.0)

        // Delay the animation slightly for visual impact
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) {
                ringProgress = targetProgress
            }

            // Trigger tomato icons animation
            withAnimation {
                hasAppeared = true
            }
        }
    }
}

// MARK: - Preview

#Preview("Daily Focus View") {
    DailyFocusView(coordinator: AppCoordinator())
        .padding()
        .frame(width: 350)
}

#Preview("Daily Focus View - Dark Mode") {
    DailyFocusView(coordinator: AppCoordinator())
        .padding()
        .frame(width: 350)
        .preferredColorScheme(.dark)
}
