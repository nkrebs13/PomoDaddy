//
//  StatsView.swift
//  PomoDaddy
//
//  Main container view for displaying statistics and productivity insights.
//

import Charts
import SwiftUI

/// Main statistics view that displays productivity metrics and trends.
///
/// `StatsView` serves as the container for all statistics-related components,
/// organized by time period (Today, Week, Month). It provides a comprehensive
/// overview of the user's Pomodoro activity.
struct StatsView: View {
    // MARK: - Properties

    @Bindable var coordinator: AppCoordinator
    @State private var selectedPeriod: StatsPeriod = .week
    @State private var appearAnimation = false

    // MARK: - Time Period

    /// Available time periods for statistics display.
    enum StatsPeriod: String, CaseIterable, Identifiable {
        case today = "Today"
        case week = "Week"
        case month = "Month"

        var id: String {
            rawValue
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Period picker
                periodPicker
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : -10)

                // Daily focus ring (large, centered)
                DailyFocusView(coordinator: coordinator)
                    .opacity(appearAnimation ? 1 : 0)
                    .scaleEffect(appearAnimation ? 1 : 0.9)

                // Weekly trend chart
                if selectedPeriod != .today {
                    WeeklyTrendChartView(coordinator: coordinator)
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)
                }

                // Streak display cards
                StreakDisplayView(coordinator: coordinator)
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 30)
            }
            .padding()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appearAnimation = true
            }
        }
        .onDisappear {
            appearAnimation = false
        }
    }

    // MARK: - Subviews

    /// Period selection picker with segmented style.
    private var periodPicker: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(StatsPeriod.allCases) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview("Stats View") {
    StatsView(coordinator: AppCoordinator())
        .frame(width: 350, height: 600)
}

#Preview("Stats View - Dark Mode") {
    StatsView(coordinator: AppCoordinator())
        .frame(width: 350, height: 600)
        .preferredColorScheme(.dark)
}
