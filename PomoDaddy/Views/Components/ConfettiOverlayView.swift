//
//  ConfettiOverlayView.swift
//  PomoDaddy
//
//  Confetti celebration overlay using native SwiftUI animations.
//

import SwiftUI

// MARK: - Confetti Overlay View

/// A celebration overlay that displays confetti particles falling from the top of the screen.
internal struct ConfettiOverlayView: View {
    /// Trigger binding - increment to fire confetti
    @Binding var trigger: Int

    /// Intensity level for the celebration
    var intensity: CelebrationIntensity = .normal

    /// Celebration intensity levels with different particle counts
    enum CelebrationIntensity {
        case normal // Regular pomodoro complete (30 particles)
        case milestone // Daily goal or streak milestone (50 particles)
        case epic // Major achievement (80 particles)

        var particleCount: Int {
            switch self {
            case .normal: 30
            case .milestone: 50
            case .epic: 80
            }
        }
    }

    @State private var particles: [ConfettiParticle] = []
    @State private var isAnimating: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiPiece(particle: particle, geometry: geometry)
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .onChange(of: trigger) { _, newValue in
            guard newValue > 0 else { return }
            triggerCelebration()
        }
    }

    /// Triggers the confetti celebration animation
    private func triggerCelebration() {
        // Create particles
        particles = (0 ..< intensity.particleCount).map { index in
            ConfettiParticle(
                id: UUID(),
                color: confettiColors.randomElement() ?? .tomatoRed,
                shape: ConfettiShape.allCases.randomElement() ?? .rectangle,
                xPosition: Double.random(in: 0 ... 1),
                delay: Double(index) * 0.02,
                rotationSpeed: Double.random(in: 2 ... 6),
                fallDuration: Double.random(in: 2.5 ... 4.0),
                horizontalDrift: Double.random(in: -0.2 ... 0.2)
            )
        }

        isAnimating = true

        // Clear particles after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + AnimationConstants.confettiDuration + 1.5) {
            particles.removeAll()
            isAnimating = false
        }
    }

    /// Colors for confetti pieces
    private var confettiColors: [Color] {
        [.tomatoRed, .coral, .mint, .lavender, .sunnyYellow, .hotPink]
    }
}

// MARK: - Confetti Particle Model

/// Represents a single confetti particle
internal struct ConfettiParticle: Identifiable {
    let id: UUID
    let color: Color
    let shape: ConfettiShape
    let xPosition: Double
    let delay: Double
    let rotationSpeed: Double
    let fallDuration: Double
    let horizontalDrift: Double
}

/// Shapes for confetti pieces
internal enum ConfettiShape: CaseIterable {
    case rectangle
    case circle
    case triangle
}

// MARK: - Confetti Piece View

/// Individual animated confetti piece
internal struct ConfettiPiece: View {
    let particle: ConfettiParticle
    let geometry: GeometryProxy

    @State private var yOffset: CGFloat = -20
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1.0
    @State private var xOffset: CGFloat = 0

    var body: some View {
        confettiView
            .frame(width: 10, height: 12)
            .rotationEffect(.degrees(rotation))
            .rotation3DEffect(.degrees(rotation * 0.5), axis: (x: 1, y: 0, z: 0))
            .position(
                x: geometry.size.width * particle.xPosition + xOffset,
                y: yOffset
            )
            .opacity(opacity)
            .onAppear {
                // Start the falling animation after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + particle.delay) {
                    // Falling animation
                    withAnimation(.easeIn(duration: particle.fallDuration)) {
                        yOffset = geometry.size.height + 50
                        xOffset = geometry.size.width * particle.horizontalDrift
                    }

                    // Rotation animation
                    withAnimation(.linear(duration: particle.fallDuration).repeatForever(autoreverses: false)) {
                        rotation = 360 * particle.rotationSpeed
                    }

                    // Fade out at the end
                    withAnimation(.easeIn(duration: 0.5).delay(particle.fallDuration - 0.5)) {
                        opacity = 0
                    }
                }
            }
    }

    @ViewBuilder
    private var confettiView: some View {
        switch particle.shape {
        case .rectangle:
            Rectangle().fill(particle.color)
        case .circle:
            Circle().fill(particle.color)
        case .triangle:
            Triangle().fill(particle.color)
        }
    }
}

/// Triangle shape for confetti
internal struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path: Path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var trigger: Int = 0
    @Previewable @State var intensity: ConfettiOverlayView.CelebrationIntensity = .normal

    ZStack {
        Color.black.opacity(0.3)

        ConfettiOverlayView(trigger: $trigger, intensity: intensity)

        VStack(spacing: 16) {
            Text("Confetti Test")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 12) {
                Button("Normal") {
                    intensity = .normal
                    trigger += 1
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.tomatoRed)

                Button("Milestone") {
                    intensity = .milestone
                    trigger += 1
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.mint)

                Button("Epic") {
                    intensity = .epic
                    trigger += 1
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.lavender)
            }
        }
    }
    .frame(width: 400, height: 500)
}
