import SwiftUI

struct FamilyGoalCard: View {
    let challenge: Challenge
    let goal: Double
    let logged: Double
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Family goal", systemImage: "person.3.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.purple)
                Spacer()
                Text(challenge.name)
                    .font(.subheadline.bold())
            }
            ProgressView(value: progress)
                .tint(.purple)
            Text("\(SavingsCalculator.formatCurrency(logged)) of \(SavingsCalculator.formatCurrency(goal)) combined")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Everyone's logs count toward this target.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.purple.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityIdentifier("familyGoalCard_\(challenge.id)")
    }
}

struct KidMatchBanner: View {
    let stashAmount: Double
    let remainingMatches: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.2.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text("Ask a grown-up to match!")
                    .font(.subheadline.bold())
                Text("You stashed \(SavingsCalculator.formatCurrency(stashAmount)). Switch to a grown-up profile on Home to tap Match.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if remainingMatches < ParentMatchRules.weeklyMatchCap {
                    Text("\(remainingMatches) match\(remainingMatches == 1 ? "" : "es") left this week")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityIdentifier("kidMatchBanner")
    }
}

struct GiveDonationBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "heart.fill")
                .foregroundStyle(.red)
            VStack(alignment: .leading, spacing: 4) {
                Text("Give a Little challenge")
                    .font(.subheadline.bold())
                Text("Mark donated once your family has actually given to the cause.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityIdentifier("giveDonationBanner")
    }
}
