import SwiftUI
import SwiftData

struct ChallengeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]
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
        if challenge.isFamilyGoal {
            return entries.filter { $0.challengeId == challenge.id }
        }
        return entries.filter { $0.profileId == profile.id && $0.challengeId == challenge.id }
    }

    private var completionHint: String {
        let hasPaper = challenge.checklistSlotCount > 0
        let hasGoal = (active?.targetAmount ?? challenge.goalAmount ?? 0) > 0
        switch (hasPaper, hasGoal) {
        case (true, true):
            return "Complete by checking every box on the paper list or reaching the dollar goal."
        case (true, false):
            return "Complete by checking every box on the paper list."
        case (false, true):
            return "Complete by reaching the dollar goal."
        default:
            return "Log entries linked to this challenge to track progress."
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                ruleSection
                completionHintSection
                if let active, !isCompleted {
                    ChallengePaperChecklistView(
                        challenge: challenge,
                        active: active,
                        accent: profile.color,
                        onAllChecked: {
                            if !isCompleted {
                                completeChallenge()
                            }
                        }
                    )
                }
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
                profiles: profiles,
                settings: settings,
                initialChallengeId: challenge.id,
                onSaved: { _, _ in }
            )
        }
        .onAppear {
            settings.selectedProfileId = profile.id
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
            Text(challenge.isFamilyGoal ? "Family challenge" : "For \(profile.name)")
                .font(.subheadline)
                .foregroundStyle(profile.color)
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

    private var completionHintSection: some View {
        Text(completionHint)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
    }

    private var progressSection: some View {
        let goal = active?.targetAmount ?? challenge.goalAmount
        let isFamilyGoal = challenge.isFamilyGoal
        let logged = isFamilyGoal
            ? SavingsCalculator.familyChallengeTotal(entries: entries, challengeId: challenge.id)
            : challengeEntries.reduce(0) { $0 + $1.signedAmount }
        let progress = isFamilyGoal
            ? SavingsCalculator.familyChallengeProgress(entries: entries, challengeId: challenge.id, goal: goal)
            : SavingsCalculator.challengeProgress(
                entries: entries,
                profileId: profile.id,
                challengeId: challenge.id,
                goal: goal
            )

        return VStack(alignment: .leading, spacing: 8) {
            Text(isFamilyGoal ? "Family progress" : "Progress")
                .font(.headline)
            if let active, active.status == .active {
                let paperProgress = ChallengeChecklistHelper.progress(active: active, challenge: challenge)
                HStack(spacing: 6) {
                    Image(systemName: challenge.checklistMarkedIcon)
                        .foregroundStyle(profile.color)
                    Text("Paper: \(active.checkedSlots.count)/\(challenge.checklistSlotCount) checked")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: paperProgress)
                    .tint(profile.color)
            }
            if let goal, goal > 0 {
                ProgressView(value: progress)
                    .tint(profile.color)
                    .animation(AppAnimations.smooth, value: progress)
                Text("\(SavingsCalculator.formatCurrency(logged)) of \(SavingsCalculator.formatCurrency(goal))\(isFamilyGoal ? " combined" : "")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if active == nil || active?.status != .active {
                Text("Logged: \(SavingsCalculator.formatCurrency(logged))")
                    .font(.subheadline)
            }
        }
    }

    private var entriesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(challenge.isFamilyGoal ? "Family logs" : "Logs for this challenge")
                .font(.headline)
            if challengeEntries.isEmpty {
                Text("No logs yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(challengeEntries, id: \.id) { entry in
                    HStack {
                        VStack(alignment: .leading) {
                            HStack(spacing: 6) {
                                Text(entry.kind.label)
                                    .font(.subheadline.bold())
                                if challenge.isFamilyGoal,
                                   let owner = profiles.first(where: { $0.id == entry.profileId }) {
                                    Text(owner.name)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            if !entry.note.isEmpty {
                                Text(entry.note).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text(SavingsCalculator.formatCurrency(entry.signedAmount))
                            .foregroundStyle(entry.kind.challengeLedgerColor)
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
            .accessibilityIdentifier("startChallengeButton")
        } else if let active, active.status == .active {
            Button("Log money") { showLogSheet = true }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("challengeLogMoneyButton")

            Button("Mark complete") {
                completeChallenge()
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("markChallengeCompleteButton")

            Button("End challenge", role: .destructive) {
                endChallenge()
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("endChallengeButton")
        }
    }

    private func startChallenge() {
        guard active == nil, !isCompleted else { return }

        let goal: Double?
        if let custom = CurrencyParser.parse(customGoalText) {
            goal = custom
        } else {
            goal = challenge.goalAmount
        }
        let activeChallenge = ActiveChallenge(profileId: profile.id, challengeId: challenge.id, targetAmount: goal)
        modelContext.insert(activeChallenge)
        settings.selectedProfileId = profile.id
        modelContext.commitSave()
    }

    private func completeChallenge() {
        active?.status = .completed
        StampHelper.awardStampIfNeeded(
            context: modelContext,
            profileId: profile.id,
            challengeId: challenge.id,
            existingStamps: stamps
        )
        modelContext.commitSave()
    }

    private func endChallenge() {
        active?.status = .paused
        modelContext.commitSave()
    }
}
