import SwiftUI
import SwiftData

struct HomeView: View {
    @Bindable var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]
    @Query(sort: \SaveEntry.date, order: .reverse) private var entries: [SaveEntry]
    @Query(filter: #Predicate<ActiveChallenge> { $0.statusRaw == "active" })
    private var activeChallenges: [ActiveChallenge]

    @State private var logMoneyRequest: LogMoneySheetRequest?
    @State private var celebrationMessage: String?
    @State private var celebrationAmount: Double = 0
    @State private var outflowMessage: String?
    @State private var outflowAmount: Double = 0
    @State private var outflowKind: SaveKind = .spent
    @State private var confettiTrigger = 0
    @State private var showGiveDonationBanner = false

    private var familyGoalSummaries: [(challenge: Challenge, goal: Double, logged: Double, progress: Double)] {
        SavingsCalculator.activeFamilyGoalSummaries(activeChallenges: activeChallenges, entries: entries)
    }

    private var selectedProfile: Profile? {
        if let id = settings.selectedProfileId,
           let match = profiles.first(where: { $0.id == id }) {
            return match
        }
        return profiles.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    familyHeader

                    if !familyGoalSummaries.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Family goals")
                                .font(.headline)
                                .padding(.horizontal)
                            ForEach(familyGoalSummaries, id: \.challenge.id) { summary in
                                FamilyGoalCard(
                                    challenge: summary.challenge,
                                    goal: summary.goal,
                                    logged: summary.logged,
                                    progress: summary.progress
                                )
                                .padding(.horizontal)
                            }
                        }
                    }

                    ProfileChipBar(profiles: profiles, selectedProfileId: $settings.selectedProfileId)

                    if let profile = selectedProfile {
                        profileSection(profile)
                            .id(profile.id)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }

                    if let celebrationMessage {
                        ZStack(alignment: .top) {
                            CelebrationBanner(message: celebrationMessage, amount: celebrationAmount)
                            ConfettiView(trigger: confettiTrigger)
                                .frame(maxWidth: .infinity, maxHeight: 100)
                                .clipped()
                                .allowsHitTesting(false)
                        }
                        .transition(.scale(scale: 0.92).combined(with: .opacity))
                        .padding(.horizontal)
                    }

                    if showGiveDonationBanner {
                        GiveDonationBanner()
                            .padding(.horizontal)
                            .transition(.opacity)
                    }

                    if let outflowMessage {
                        OutflowBanner(message: outflowMessage, amount: outflowAmount, kind: outflowKind)
                            .transition(.scale(scale: 0.92).combined(with: .opacity))
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .animation(AppAnimations.smooth, value: settings.selectedProfileId)
                .animation(AppAnimations.bouncy, value: celebrationMessage)
                .animation(AppAnimations.gentle, value: outflowMessage)
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Log money") { openLogMoney() }
                        .fontWeight(.semibold)
                        .disabled(selectedProfile == nil)
                        .accessibilityIdentifier("logMoneyOpenButton")
                }
            }
            .sheet(item: $logMoneyRequest) { request in
                LogSaveSheet(
                    profile: request.profile,
                    profiles: profiles,
                    settings: settings,
                    onSaved: { entry, message in
                        if entry.kind == .gave && SavingsCalculator.isGiveALittleActive(activeChallenges: activeChallenges) {
                            withAnimation(AppAnimations.gentle) {
                                showGiveDonationBanner = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                withAnimation(AppAnimations.gentle) {
                                    showGiveDonationBanner = false
                                }
                            }
                        }
                        if entry.kind.reducesVault {
                            showOutflowNotice(message: message, amount: entry.amount, kind: entry.kind)
                        } else {
                            showCelebration(message: message, amount: entry.amount)
                        }
                    }
                )
            }
            .onAppear {
                healSelectedProfileIfNeeded()
            }
            .onChange(of: profiles.map(\.id)) { _, _ in
                healSelectedProfileIfNeeded()
            }
        }
    }

    private func openLogMoney() {
        healSelectedProfileIfNeeded()
        guard let profile = selectedProfile else { return }
        logMoneyRequest = LogMoneySheetRequest(profile: profile)
    }

    private func healSelectedProfileIfNeeded() {
        if let id = settings.selectedProfileId,
           profiles.contains(where: { $0.id == id }) {
            return
        }
        settings.selectedProfileId = profiles.first?.id
    }

    private var familyTotal: Double {
        SavingsCalculator.familyTotal(entries: entries)
    }

    private var familyHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(settings.familyDisplayName) Stash Quest")
                .font(.title2.bold())
            HStack(spacing: 6) {
                Text("Family total:")
                    .font(.headline)
                AnimatedCurrencyText(
                    amount: familyTotal,
                    font: .headline.bold(),
                    color: .teal,
                    accentColor: .teal
                )
            }
            let thisWeek = SavingsCalculator.weekTotal(entries: entries)
            let lastWeek = SavingsCalculator.lastWeekTotal(entries: entries)
            HStack(alignment: .firstTextBaseline, spacing: 20) {
                weekStatColumn(title: "This week", amount: thisWeek, emphasizeNegative: true)
                weekStatColumn(title: "Last week", amount: lastWeek, emphasizeNegative: false)
            }
        }
        .padding(.horizontal)
    }

    private func weekStatColumn(title: String, amount: Double, emphasizeNegative: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(SavingsCalculator.formatCurrency(amount))
                .font(.caption.bold())
                .foregroundStyle(weekAmountColor(amount, emphasizeNegative: emphasizeNegative))
                .monospacedDigit()
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
    }

    private func weekAmountColor(_ amount: Double, emphasizeNegative: Bool) -> Color {
        if emphasizeNegative && amount < 0 {
            return .orange
        }
        return amount == 0 ? .secondary : .primary
    }

    @ViewBuilder
    private func profileSection(_ profile: Profile) -> some View {
        let total = SavingsCalculator.totalSaved(entries: entries, profileId: profile.id)
        let vault = SavingsCalculator.vaultProgress(total: total, isKid: profile.kind == .kid)
        let streak = SavingsCalculator.streakDays(entries: entries, profileId: profile.id)
        let profileActive = activeChallenges.filter { $0.profileId == profile.id }

        VStack(alignment: .leading, spacing: 16) {
            VaultView(
                total: vault.current,
                nextMilestone: vault.nextMilestone,
                progress: vault.progress,
                isKid: profile.kind == .kid
            )
            .padding(.horizontal)

            HStack {
                Label("\(streak) day savings streak", systemImage: "flame.fill")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
                    .symbolEffect(.pulse, options: streak > 0 ? .repeating : .default, value: streak)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(profile.kind == .kid ? "In the piggy" : "Total saved")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(SavingsCalculator.formatCurrency(total))
                        .font(.caption.bold())
                        .monospacedDigit()
                }
            }
            .padding(.horizontal)

            if !profileActive.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Active challenges")
                        .font(.headline)
                        .padding(.horizontal)
                    ForEach(Array(profileActive.enumerated()), id: \.element.id) { index, active in
                        if let challenge = ChallengeCatalog.challenge(id: active.challengeId) {
                            NavigationLink {
                                ChallengeDetailView(challenge: challenge, profile: profile, settings: settings)
                            } label: {
                                ActiveChallengeRow(
                                    challenge: challenge,
                                    active: active,
                                    entries: entries,
                                    profile: profile
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                            .staggeredAppear(index: index)
                        }
                    }
                }
            }

            matchableKidEntriesSection(for: profile)
            kidMatchBannerSection(for: profile)
        }
    }

    @ViewBuilder
    private func kidMatchBannerSection(for profile: Profile) -> some View {
        if profile.kind == .kid {
            let unmatched = entries.filter {
                ParentMatchRules.entryEligibleForMatch(
                    $0,
                    entries: entries,
                    activeChallenges: activeChallenges,
                    profiles: profiles
                ) && $0.profileId == profile.id
            }
            if let latest = unmatched.first {
                KidMatchBanner(
                    stashAmount: latest.amount,
                    remainingMatches: ParentMatchRules.remainingWeeklyMatches(for: profile.id, entries: entries)
                )
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private func matchableKidEntriesSection(for profile: Profile) -> some View {
        if profile.kind == .adult {
            let kidProfiles = profiles.filter { $0.kind == .kid }
            let unmatchedKidStashes = entries.filter { entry in
                kidProfiles.contains(where: { $0.id == entry.profileId }) &&
                ParentMatchRules.entryEligibleForMatch(
                    entry,
                    entries: entries,
                    activeChallenges: activeChallenges,
                    profiles: profiles
                )
            }

            if !unmatchedKidStashes.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Parent Match available")
                        .font(.headline)
                        .padding(.horizontal)
                    ForEach(unmatchedKidStashes.prefix(5), id: \.id) { kidEntry in
                        if let kid = profiles.first(where: { $0.id == kidEntry.profileId }) {
                            ParentMatchRow(
                                kidEntry: kidEntry,
                                kid: kid,
                                adult: profile,
                                entries: entries,
                                activeChallenges: activeChallenges,
                                profiles: profiles,
                                onMatched: { amount in
                                    showCelebration(message: "Matched \(kid.name)!", amount: amount)
                                }
                            )
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
    }

    private func showCelebration(message: String, amount: Double) {
        HapticFeedback.success()
        withAnimation(AppAnimations.bouncy) {
            celebrationMessage = message
            celebrationAmount = amount
            outflowMessage = nil
        }
        confettiTrigger += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(AppAnimations.gentle) {
                celebrationMessage = nil
            }
        }
    }

    private func showOutflowNotice(message: String, amount: Double, kind: SaveKind) {
        withAnimation(AppAnimations.gentle) {
            outflowMessage = message
            outflowAmount = amount
            outflowKind = kind
            celebrationMessage = nil
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(AppAnimations.gentle) {
                outflowMessage = nil
            }
        }
    }
}

struct ActiveChallengeRow: View {
    let challenge: Challenge
    let active: ActiveChallenge
    let entries: [SaveEntry]
    let profile: Profile

    var body: some View {
        let goal = active.targetAmount ?? challenge.goalAmount
        let isFamilyGoal = challenge.isFamilyGoal
        let logged = isFamilyGoal
            ? SavingsCalculator.familyChallengeTotal(entries: entries, challengeId: challenge.id)
            : entries
                .filter { $0.profileId == profile.id && $0.challengeId == challenge.id }
                .reduce(0) { $0 + $1.signedAmount }
        let progress = isFamilyGoal
            ? SavingsCalculator.familyChallengeProgress(entries: entries, challengeId: challenge.id, goal: goal)
            : SavingsCalculator.challengeProgress(
                entries: entries,
                profileId: profile.id,
                challengeId: challenge.id,
                goal: goal
            )

        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(challenge.name)
                    .font(.subheadline.bold())
                Spacer()
                Text(challenge.duration.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let goal, goal > 0 {
                ProgressView(value: progress)
                    .tint(profile.color)
                    .animation(AppAnimations.smooth, value: progress)
                Text("\(SavingsCalculator.formatCurrency(logged)) of \(SavingsCalculator.formatCurrency(goal))\(isFamilyGoal ? " combined" : "")")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            let paperChecked = active.checkedSlots.count
            let paperTotal = challenge.checklistSlotCount
            if paperTotal > 0 {
                HStack(spacing: 4) {
                    Image(systemName: challenge.checklistMarkedIcon)
                        .font(.caption2)
                        .foregroundStyle(profile.color)
                    Text("Paper \(paperChecked)/\(paperTotal)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if goal == nil || goal == 0 {
                if paperChecked == 0 {
                    Text("Logged: \(SavingsCalculator.formatCurrency(logged))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Text(challenge.rule)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding()
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct ParentMatchRow: View {
    @Environment(\.modelContext) private var modelContext

    let kidEntry: SaveEntry
    let kid: Profile
    let adult: Profile
    let entries: [SaveEntry]
    let activeChallenges: [ActiveChallenge]
    let profiles: [Profile]
    let onMatched: (Double) -> Void

    @State private var matchPressed = false
    @State private var isMatching = false

    private var remaining: Int {
        ParentMatchRules.remainingWeeklyMatches(for: kid.id, entries: entries)
    }

    private var canMatch: Bool {
        !isMatching && remaining > 0 && ParentMatchRules.entryEligibleForMatch(
            kidEntry,
            entries: entries,
            activeChallenges: activeChallenges,
            profiles: profiles
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(kid.name) stashed \(SavingsCalculator.formatCurrency(kidEntry.amount))")
                        .font(.subheadline)
                    Text(kidEntry.note.isEmpty ? "Add the same amount to their piggy" : kidEntry.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(remaining) match\(remaining == 1 ? "" : "es") left this week")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
                Spacer()
            }
            HStack(spacing: 8) {
                Button("Match") {
                    performMatch(fraction: 1)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(!canMatch)
                .accessibilityIdentifier("parentMatchFullButton")

                Button("Half") {
                    performMatch(fraction: 0.5)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
                .disabled(!canMatch)
                .accessibilityIdentifier("parentMatchHalfButton")
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .scaleEffect(matchPressed ? 0.98 : 1)
        .transition(.scale.combined(with: .opacity))
        .opacity(isMatching ? 0.7 : 1)
    }

    private func performMatch(fraction: Double) {
        guard canMatch else { return }
        isMatching = true

        withAnimation(AppAnimations.snappy) { matchPressed = true }
        HapticFeedback.success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            matchPressed = false
        }
        let amount = max(0.01, (kidEntry.amount * fraction * 100).rounded() / 100)
        let matchEntry = SaveEntry(
            profileId: kid.id,
            amount: amount,
            kind: .stashed,
            note: fraction >= 1
                ? "Parent Match from \(adult.name)"
                : "Half Match from \(adult.name)",
            challengeId: "family-parent-match",
            matchedFromEntryId: kidEntry.id,
            isParentMatch: true
        )
        modelContext.insert(matchEntry)
        if modelContext.commitSave() {
            onMatched(amount)
        } else {
            modelContext.rollback()
            isMatching = false
        }
    }
}

private struct LogMoneySheetRequest: Identifiable {
    let id: UUID
    let profile: Profile

    init(profile: Profile) {
        self.id = profile.id
        self.profile = profile
    }
}
