import SwiftUI
import SwiftData

struct ChallengeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SaveEntry.date, order: .reverse) private var entries: [SaveEntry]
    @Query(filter: #Predicate<ActiveChallenge> { $0.statusRaw == "active" })
    private var activeChallenges: [ActiveChallenge]
    @Query private var stamps: [CompletedStamp]

    let challenge: Challenge
    let profile: Profile
    let settings: AppSettings

    @State private var showLogSheet = false
    @State private var customGoalText = ""

    private var active: ActiveChallenge? {
        activeChallenges.first { $0.profileId == profile.id && $0.challengeId == challenge.id }
    }

    private var isCompleted: Bool {
        stamps.contains { $0.profileId == profile.id && $0.challengeId == challenge.id }
    }

    private var challengeEntries: [SaveEntry] {
        entries.filter { $0.profileId == profile.id && $0.challengeId == challenge.id }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                ruleSection
                if active != nil || isCompleted {
                    progressSection
                    entriesSection
                }
                actionButtons
            }
            .padding()
        }
        .navigationTitle(challenge.name)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showLogSheet) {
            LogSaveSheet(
                profile: profile,
                profiles: [],
                settings: settings,
                initialChallengeId: challenge.id,
                onSaved: { _, _ in }
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(challenge.audience.rawValue)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.teal.opacity(0.15), in: Capsule())
                Text(challenge.duration.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if isCompleted {
                    Label("Completed", systemImage: "seal.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            Text(challenge.category.rawValue)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var ruleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("The rule")
                .font(.headline)
            Text(challenge.rule)
                .font(profile.kind == .kid ? .title3 : .body)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    private var progressSection: some View {
        let goal = active?.targetAmount ?? challenge.goalAmount
        let progress = SavingsCalculator.challengeProgress(
            entries: entries,
            profileId: profile.id,
            challengeId: challenge.id,
            goal: goal
        )
        return VStack(alignment: .leading, spacing: 8) {
            Text("Progress")
                .font(.headline)
            if let goal {
                ProgressView(value: progress)
                    .tint(profile.color)
                Text("\(SavingsCalculator.formatCurrency(progress * goal)) of \(SavingsCalculator.formatCurrency(goal))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Logged: \(SavingsCalculator.formatCurrency(challengeEntries.reduce(0) { $0 + $1.signedAmount }))")
                    .font(.subheadline)
            }
        }
    }

    private var entriesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Logs for this challenge")
                .font(.headline)
            if challengeEntries.isEmpty {
                Text("No logs yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(challengeEntries, id: \.id) { entry in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(entry.kind.label)
                                .font(.subheadline.bold())
                            if !entry.note.isEmpty {
                                Text(entry.note).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text(SavingsCalculator.formatCurrency(entry.signedAmount))
                            .foregroundStyle(entry.kind == .gave ? .red : .teal)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        if active == nil && !isCompleted {
            if challenge.goalAmount != nil {
                TextField("Goal amount (optional)", text: $customGoalText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
            }
            Button("Start challenge") {
                startChallenge()
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)
            .frame(maxWidth: .infinity)
        } else if active != nil {
            Button("Log a save") { showLogSheet = true }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
                .frame(maxWidth: .infinity)

            Button("Mark complete") {
                completeChallenge()
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
        }
    }

    private func startChallenge() {
        let goal: Double?
        if let custom = Double(customGoalText.replacingOccurrences(of: ",", with: ".")), custom > 0 {
            goal = custom
        } else {
            goal = challenge.goalAmount
        }
        let activeChallenge = ActiveChallenge(profileId: profile.id, challengeId: challenge.id, targetAmount: goal)
        modelContext.insert(activeChallenge)
    }

    private func completeChallenge() {
        active?.status = .completed
        let stamp = CompletedStamp(profileId: profile.id, challengeId: challenge.id)
        modelContext.insert(stamp)
    }
}
