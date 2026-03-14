//
//  WeeklyTrendChartView.swift
//  PomoDaddy
//
//  Displays a 7-day trend chart using Swift Charts.
//

import Charts
import os.log
import SwiftData
import SwiftUI

/// A chart view displaying the weekly focus time trend.
///
/// `WeeklyTrendChartView` shows a bar chart of the past 7 days' focus minutes,
/// with today's bar highlighted in a distinct color.
internal struct WeeklyTrendChartView: View {
    // MARK: - Properties

    @Bindable var coordinator: AppCoordinator
    @Environment(\.modelContext) private var modelContext: ModelContext

    @State private var weeklyData: [DayData] = []
    @State private var hasAppeared: Bool = false
    @State private var selectedDay: DayData?

    // MARK: - Data Model

    /// Represents a single day's data for the chart.
    struct DayData: Identifiable {
        let id: UUID = UUID()
        let date: Date
        let dayName: String
        let focusMinutes: Int
        let isToday: Bool

        /// Formatted focus time for display.
        var formattedTime: String {
            TimeFormatting.formatFocusTime(minutes: focusMinutes)
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("This Week")
                    .font(.headline)

                Spacer()

                // Weekly total
                if let totalMinutes = weeklyData.reduce(0, { $0 + $1.focusMinutes }) as Int?, totalMinutes > 0 {
                    Text(formatTotalTime(totalMinutes))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // Chart
            chartContent
                .frame(height: 150)

            // Selected day detail (when tapped)
            if let selected = selectedDay {
                selectedDayDetail(selected)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            loadWeeklyData()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Subviews

    /// The main chart content.
    private var chartContent: some View {
        Chart(weeklyData) { day in
            BarMark(
                x: .value("Day", day.dayName),
                y: .value("Minutes", hasAppeared ? day.focusMinutes : 0)
            )
            .foregroundStyle(
                day.isToday
                    ? Color.tomatoRed
                    : Color.tomatoRed.opacity(0.5)
            )
            .cornerRadius(4)
            .annotation(position: .top) {
                if day.focusMinutes > 0, day.isToday {
                    Text("\(day.focusMinutes)m")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    .foregroundStyle(Color.secondary.opacity(0.3))
                AxisValueLabel {
                    if let minutes = value.as(Int.self) {
                        Text(formatAxisLabel(minutes))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let dayName = value.as(String.self) {
                        Text(dayName)
                            .font(.caption)
                            .foregroundStyle(
                                weeklyData.first(where: { $0.dayName == dayName })?.isToday == true
                                    ? Color.tomatoRed
                                    : Color.secondary
                            )
                    }
                }
            }
        }
        .chartYScale(domain: 0 ... (maxMinutes > 0 ? Double(maxMinutes) * 1.2 : 60))
        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: hasAppeared)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Weekly focus chart: \(weeklyData.map { "\($0.dayName) \($0.formattedTime)" }.joined(separator: ", "))")
    }

    /// Detail view for a selected day.
    private func selectedDayDetail(_ day: DayData) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(day.isToday ? "Today" : fullDayName(day.date))
                    .font(.subheadline.bold())
                Text(day.formattedTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                withAnimation {
                    selectedDay = nil
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Computed Properties

    /// Maximum minutes in the dataset for scale calculation.
    private var maxMinutes: Int {
        weeklyData.map(\.focusMinutes).max() ?? 0
    }

    // MARK: - Helper Methods

    /// Loads the weekly trend data from the data store.
    private func loadWeeklyData() {
        let calendar: Calendar = Calendar.current
        let today: Date = calendar.startOfDay(for: Date())

        // Generate array for past 7 days
        var data: [DayData] = []

        do {
            let calculator: StatsCalculator = StatsCalculator(modelContext: modelContext)
            let stats: [DailyStats] = try calculator.weeklyTrend()

            for dayOffset in (0 ..< 7).reversed() {
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }

                let dayName: String = dayAbbreviation(for: date)
                let isToday: Bool = dayOffset == 0

                // Find stats for this date
                let focusMinutes: Int = stats.first {
                    calendar.isDate($0.date, inSameDayAs: date)
                }?.totalFocusMinutes ?? 0

                data.append(DayData(
                    date: date,
                    dayName: dayName,
                    focusMinutes: focusMinutes,
                    isToday: isToday
                ))
            }
        } catch {
            Logger.logError(error, context: "Failed to load weekly trend data", log: Logger.stats)
            // Generate empty data if fetching fails
            for dayOffset in (0 ..< 7).reversed() {
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }

                data.append(DayData(
                    date: date,
                    dayName: dayAbbreviation(for: date),
                    focusMinutes: 0,
                    isToday: dayOffset == 0
                ))
            }
        }

        weeklyData = data
    }

    /// Returns the abbreviated day name for a date.
    private func dayAbbreviation(for date: Date) -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    /// Returns the full day name for a date.
    private func fullDayName(_ date: Date) -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }

    /// Formats minutes as axis labels.
    private func formatAxisLabel(_ minutes: Int) -> String {
        TimeFormatting.formatAxisLabel(minutes: minutes)
    }

    /// Formats total weekly time.
    private func formatTotalTime(_ minutes: Int) -> String {
        "Total: \(TimeFormatting.formatFocusTime(minutes: minutes))"
    }
}

// MARK: - Preview

#Preview("Weekly Trend Chart") {
    WeeklyTrendChartView(coordinator: AppCoordinator())
        .padding()
        .frame(width: 350)
}

#Preview("Weekly Trend Chart - Dark Mode") {
    WeeklyTrendChartView(coordinator: AppCoordinator())
        .padding()
        .frame(width: 350)
        .preferredColorScheme(.dark)
}
