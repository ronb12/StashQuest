import SwiftUI

struct VaultView: View {
    let total: Double
    let nextMilestone: Double
    let progress: Double
    let isKid: Bool

    @State private var iconBounceTrigger = 0
    @State private var displayedProgress: Double = 0

    private var accent: Color { isKid ? .orange : .teal }
    private var fillColors: [Color] { isKid ? [.orange, .yellow] : [.teal, .mint] }

    private var fillHeight: CGFloat {
        max(8, 120 * displayedProgress)
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(accent.opacity(0.15))
                    .frame(height: 120)

                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: fillColors,
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(height: fillHeight)
                    .padding(8)
                    .overlay(alignment: .top) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.25), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: min(fillHeight, 20))
                            .padding(8)
                            .opacity(fillHeight > 12 ? 1 : 0)
                    }
                    .animation(AppAnimations.vaultFill, value: fillHeight)

                if fillHeight > 18 {
                    Capsule()
                        .fill(.white.opacity(0.22))
                        .frame(width: 52, height: 4)
                        .offset(y: -(fillHeight - 8))
                        .padding(.bottom, 8)
                        .animation(AppAnimations.vaultFill, value: fillHeight)
                }

                Image(systemName: isKid ? "banknote" : "archivebox.fill")
                    .font(.title)
                    .foregroundStyle(accent)
                    .symbolEffect(.bounce, value: iconBounceTrigger)
                    .offset(y: -40)
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 20))

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    AnimatedCurrencyText(
                        amount: total,
                        font: isKid ? .title.bold() : .title2.bold(),
                        accentColor: accent
                    )
                    ProgressView(value: displayedProgress)
                        .tint(accent)
                        .animation(AppAnimations.vaultFill, value: displayedProgress)
                }
                Spacer(minLength: 12)
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Next milestone")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(SavingsCalculator.formatCurrency(nextMilestone))
                        .font(.caption.bold())
                        .foregroundStyle(accent)
                        .contentTransition(.numericText())
                        .animation(AppAnimations.smooth, value: nextMilestone)
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.primary.opacity(0.06), radius: 6, y: 2)
        }
        .onAppear {
            displayedProgress = progress
        }
        .onChange(of: progress) { old, new in
            withAnimation(AppAnimations.vaultFill) {
                displayedProgress = new
            }
            if abs(new - old) > 0.001 {
                iconBounceTrigger += 1
            }
        }
    }
}

struct ProfileChipBar: View {
    let profiles: [Profile]
    @Binding var selectedProfileId: UUID?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(profiles, id: \.id) { profile in
                    let selected = selectedProfileId == profile.id
                    Button {
                        withAnimation(AppAnimations.snappy) {
                            selectedProfileId = profile.id
                        }
                        HapticFeedback.light()
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(profile.color)
                                .frame(width: selected ? 12 : 10, height: selected ? 12 : 10)
                            Text(profile.name)
                                .font(.subheadline.weight(selected ? .semibold : .medium))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            selected
                                ? profile.color.opacity(0.25)
                                : Color.secondary.opacity(0.12),
                            in: Capsule()
                        )
                        .overlay {
                            Capsule()
                                .strokeBorder(selected ? profile.color.opacity(0.5) : .clear, lineWidth: 1.5)
                        }
                        .scaleEffect(selected ? 1.04 : 1)
                    }
                    .buttonStyle(PopButtonStyle())
                    .accessibilityIdentifier("profileChip_\(profile.id.uuidString)")
                }
            }
            .padding(.horizontal)
        }
        .animation(AppAnimations.snappy, value: selectedProfileId)
    }
}

struct ConfettiView: View {
    let trigger: Int

    @State private var animate = false

    private struct Particle: Identifiable {
        let id: Int
        let color: Color
        let xDrift: CGFloat
        let yDrop: CGFloat
        let size: CGFloat
        let isCircle: Bool
    }

    private let particles: [Particle] = (0..<32).map { index in
        Particle(
            id: index,
            color: [.teal, .orange, .yellow, .pink, .mint, .purple][index % 6],
            xDrift: CGFloat([-1, 1][index % 2]) * CGFloat.random(in: 40...130),
            yDrop: CGFloat.random(in: 80...220),
            size: CGFloat([6, 8, 10][index % 3]),
            isCircle: index.isMultiple(of: 3)
        )
    }

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Group {
                    if particle.isCircle {
                        Circle().fill(particle.color)
                    } else {
                        RoundedRectangle(cornerRadius: 2).fill(particle.color)
                    }
                }
                .frame(width: particle.size, height: particle.isCircle ? particle.size : particle.size * 1.6)
                .rotationEffect(.degrees(animate ? Double.random(in: -180...180) : 0))
                .offset(
                    x: animate ? particle.xDrift : 0,
                    y: animate ? particle.yDrop : -16
                )
                .opacity(animate ? 0 : 1)
                .animation(
                    .easeOut(duration: 0.85).delay(Double(particle.id) * 0.018),
                    value: animate
                )
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, _ in
            animate = false
            DispatchQueue.main.async {
                animate = true
            }
        }
    }
}

struct CelebrationBanner: View {
    let message: String
    let amount: Double

    @State private var pulse = false

    var body: some View {
        HStack {
            Image(systemName: "sparkles")
                .symbolEffect(.bounce, value: pulse)
                .foregroundStyle(.teal)
            VStack(alignment: .leading, spacing: 2) {
                Text(message)
                    .font(.subheadline.bold())
                AnimatedCurrencyText(amount: amount, font: .caption.bold(), color: .secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color.teal.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.teal.opacity(pulse ? 0.45 : 0.15), lineWidth: 1.5)
        }
        .scaleEffect(pulse ? 1.02 : 0.98)
        .onAppear {
            withAnimation(AppAnimations.bouncy) {
                pulse = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(AppAnimations.gentle) {
                    pulse = false
                }
            }
        }
    }
}

struct OutflowBanner: View {
    let message: String
    let amount: Double
    let kind: SaveKind

    @State private var pulse = false

    private var accent: Color { kind.amountColor }

    var body: some View {
        HStack {
            Image(systemName: kind == .spent ? "cart.fill" : "heart.fill")
                .symbolEffect(.bounce, value: pulse)
                .foregroundStyle(accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(message)
                    .font(.subheadline.bold())
                Text("−\(SavingsCalculator.formatCurrency(amount))")
                    .font(.caption.bold())
                    .foregroundStyle(accent)
            }
            Spacer()
        }
        .padding()
        .background(accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(accent.opacity(pulse ? 0.4 : 0.18), lineWidth: 1.5)
        }
        .scaleEffect(pulse ? 0.98 : 1)
        .onAppear {
            withAnimation(AppAnimations.gentle) {
                pulse = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                pulse = false
            }
        }
    }
}
