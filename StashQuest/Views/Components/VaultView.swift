import SwiftUI

struct VaultView: View {
    let total: Double
    let nextMilestone: Double
    let progress: Double
    let isKid: Bool

    var body: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(isKid ? Color.orange.opacity(0.15) : Color.teal.opacity(0.15))
                    .frame(height: 120)

                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: isKid ? [.orange, .yellow] : [.teal, .mint],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(height: max(8, 120 * progress))
                    .padding(8)
                    .animation(.spring(duration: 0.5), value: progress)

                Image(systemName: isKid ? "banknote" : "archivebox.fill")
                    .font(.title)
                    .foregroundStyle(isKid ? .orange : .teal)
                    .offset(y: -40)
            }
            .frame(height: 120)

            HStack {
                Text(SavingsCalculator.formatCurrency(total))
                    .font(isKid ? .title.bold() : .title2.bold())
                Spacer()
                Text("Next: \(SavingsCalculator.formatCurrency(nextMilestone))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct ProfileChipBar: View {
    let profiles: [Profile]
    @Binding var selectedProfileId: UUID?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(profiles, id: \.id) { profile in
                    Button {
                        selectedProfileId = profile.id
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(profile.color)
                                .frame(width: 10, height: 10)
                            Text(profile.name)
                                .font(.subheadline.weight(.medium))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            selectedProfileId == profile.id
                                ? profile.color.opacity(0.25)
                                : Color.secondary.opacity(0.12),
                            in: Capsule()
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct ConfettiView: View {
    @State private var animate = false
    let trigger: Int

    var body: some View {
        ZStack {
            ForEach(0..<24, id: \.self) { index in
                Circle()
                    .fill(colors[index % colors.count])
                    .frame(width: 8, height: 8)
                    .offset(
                        x: animate ? CGFloat.random(in: -120...120) : 0,
                        y: animate ? CGFloat.random(in: -180...40) : -20
                    )
                    .opacity(animate ? 0 : 1)
                    .animation(
                        .easeOut(duration: 0.9).delay(Double(index) * 0.02),
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

    private let colors: [Color] = [.teal, .orange, .yellow, .pink, .mint, .purple]
}

struct CelebrationBanner: View {
    let message: String
    let amount: Double

    var body: some View {
        HStack {
            Image(systemName: "sparkles")
            VStack(alignment: .leading, spacing: 2) {
                Text(message)
                    .font(.subheadline.bold())
                Text(SavingsCalculator.formatCurrency(amount))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color.teal.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
    }
}
