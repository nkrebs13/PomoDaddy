//
//  DynamicMenuBarIconView.swift
//  PomoDaddy
//
//  Custom NSView for animated menu bar icon with progress ring.
//

import AppKit
import SwiftUI

// MARK: - Dynamic Menu Bar Icon View

/// Custom NSView that displays an animated menu bar icon.
///
/// Features:
/// - Tomato icon when idle
/// - Circular progress ring around tomato when timer is running
/// - Different colors for work (tomatoRed) vs break (mint/lavender)
/// - Optional countdown time text
/// - Smooth animations
final class DynamicMenuBarIconView: NSView {
    // MARK: - Properties

    /// Reference to the app coordinator for state access.
    private weak var coordinator: AppCoordinator?

    /// Hosting view for SwiftUI content.
    private var hostingView: NSHostingView<MenuBarIconContent>?

    /// Standard menu bar icon size.
    private static let iconSize: CGFloat = 22

    // MARK: - Initialization

    /// Creates a new dynamic menu bar icon view.
    /// - Parameter coordinator: The app coordinator managing timer state.
    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
        super.init(frame: NSRect(x: 0, y: 0, width: Self.iconSize, height: Self.iconSize))

        setupHostingView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    override var intrinsicContentSize: NSSize {
        // Calculate width based on whether time text is shown
        if let coordinator,
           coordinator.isMenuBarCountdownVisible,
           coordinator.currentState.isActive
        {
            // Icon + spacing + time text (approximately)
            return NSSize(width: 70, height: Self.iconSize)
        }
        return NSSize(width: Self.iconSize, height: Self.iconSize)
    }

    override func layout() {
        super.layout()
        hostingView?.frame = bounds
    }

    // MARK: - Setup

    /// Sets up the SwiftUI hosting view.
    private func setupHostingView() {
        guard let coordinator else { return }

        let content = MenuBarIconContent(coordinator: coordinator)
        let hosting: NSHostingView<MenuBarIconContent> = NSHostingView(rootView: content)
        hosting.frame = bounds
        hosting.autoresizingMask = [.width, .height]

        addSubview(hosting)
        hostingView = hosting
    }

    // MARK: - Public Methods

    /// Updates the icon view to reflect current state.
    func update() {
        // Invalidate intrinsic content size to trigger relayout.
        // rootView replacement is unnecessary — @Observable drives re-renders automatically.
        invalidateIntrinsicContentSize()
    }
}

// MARK: - Menu Bar Icon Content

/// SwiftUI view rendering the menu bar icon content.
struct MenuBarIconContent: View {
    // MARK: - Properties

    /// The app coordinator for accessing timer state.
    @Bindable var coordinator: AppCoordinator

    /// Size of the tomato icon.
    private let iconSize: CGFloat = 16

    /// Size of the progress ring.
    private let ringSize: CGFloat = 20

    /// Line width of the progress ring.
    private let ringLineWidth: CGFloat = 2

    // MARK: - Computed Properties

    /// The current timer state.
    private var timerState: TimerState {
        coordinator.currentState
    }

    /// The current progress (0-1).
    private var progress: Double {
        coordinator.progress
    }

    /// The formatted remaining time.
    private var formattedTime: String {
        coordinator.formattedTime
    }

    /// Whether time text should be shown.
    private var showTimeText: Bool {
        coordinator.isMenuBarCountdownVisible && timerState.isActive
    }

    /// The accent color for the current state.
    /// Menu bar tomato stays red even when idle (unlike floating window which grays out).
    private var accentColor: Color {
        timerState.isActive ? timerState.accentColor : .tomatoRed
    }

    /// The background track color.
    private var trackColor: Color {
        accentColor.opacity(0.3)
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 4) {
            // Tomato icon with progress ring
            ZStack {
                // Progress ring background track
                if timerState.isActive {
                    Circle()
                        .stroke(trackColor, lineWidth: ringLineWidth)
                        .frame(width: ringSize, height: ringSize)
                }

                // Progress ring
                if timerState.isActive {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            accentColor,
                            style: StrokeStyle(
                                lineWidth: ringLineWidth,
                                lineCap: .round
                            )
                        )
                        .frame(width: ringSize, height: ringSize)
                        .rotationEffect(.degrees(-90))
                        .animation(.timerTick, value: progress)
                }

                // Tomato icon
                tomatoIcon
                    .frame(width: iconSize, height: iconSize)
            }
            .frame(width: 22, height: 22)

            // Time text
            if showTimeText {
                Text(formattedTime)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.primary)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.popoverAppear, value: showTimeText)
    }

    // MARK: - Tomato Icon

    /// The tomato icon view.
    private var tomatoIcon: some View {
        ZStack {
            // Tomato body
            Circle()
                .fill(accentColor)
                .frame(width: 12, height: 12)

            // Tomato stem
            Path { path in
                path.move(to: CGPoint(x: 6, y: 0))
                path.addCurve(
                    to: CGPoint(x: 8, y: 3),
                    control1: CGPoint(x: 6, y: 1),
                    control2: CGPoint(x: 7, y: 2)
                )
            }
            .stroke(Color.forestGreen, lineWidth: 1.5)
            .frame(width: 12, height: 12)
            .offset(y: -3)

            // Tomato leaf
            Ellipse()
                .fill(Color.forestGreen)
                .frame(width: 4, height: 2)
                .rotationEffect(.degrees(-30))
                .offset(x: 2, y: -5)

            // Pause indicator when paused
            if timerState.isPaused {
                HStack(spacing: 1) {
                    Rectangle()
                        .fill(.white)
                        .frame(width: 2, height: 5)
                    Rectangle()
                        .fill(.white)
                        .frame(width: 2, height: 5)
                }
            }
        }
        .opacity(timerState.isPaused ? 0.7 : 1.0)
    }
}

// MARK: - Preview

#Preview("Menu Bar Icon - Idle") {
    let coordinator = AppCoordinator()
    return MenuBarIconContent(coordinator: coordinator)
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
}

#Preview("Menu Bar Icon - Running") {
    let coordinator = AppCoordinator()
    // Note: Preview would show idle state since we can't easily mock the state machine
    return MenuBarIconContent(coordinator: coordinator)
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
}
