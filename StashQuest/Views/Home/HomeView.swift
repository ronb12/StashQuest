import SwiftUI
import SwiftData

struct HomeView: View {
    @Bindable var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]
    @Query(sort: \SaveEntry.date, order: .reverse) private var entries: [SaveEntry]
    @Query(filter: #Predicate<ActiveChallenge> { $0.statusRaw == "active" })
    private var activeChallenges: [ActiveChallenge]

    @State private var showLogSheet = false
    @State private var celebrationMessage: String?
    @State private var celebrationAmount: Double = 0
    @State private var confettiTrigger = 0

    private var selectedProfile: Profile? {
        if let id = settings.selectedProfileId {
            return profiles.first { $0.id == id }
        }
        return profiles.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    familyHeader
                    ProfileChipBar(profiles: profiles, selectedProfileId: $settings.selectedProfileId)

                    if let profile = selectedProfile {
                        profileSection(profile)
                    }

                    if let celebrationMessage {
                        CelebrationBanner(message: celebrationMessage, amount: celebrationAmount)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(.vertical)
            }
            .overlay(alignment: .top) {
                ConfettiView(trigger: confettiTrigger)
                    .frame(maxWidth: .infinity, maxHeight: 200)
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Log a save") { showLogSheet = true }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showLogSheet) {
                if let profile = selectedProfile {
                    LogSaveSheet(
                        profile: profile,
                        profiles: profiles,
                        settings: settings,
                        onSaved: { entry, message in
                            showCelebration(message: message, amount: entry.amount)
                        }
                    )
                }
            }
        }
    }

    private var familyHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(settings.familyDisplayName) Stash Quest")
                .font(.title2.bold())
            Text("Family total: \(SavingsCalculator.formatCurrency(SavingsCalculator.familyTotal(entries: entries)))")
                .font(.headline)
                .foregroundStyle(.teal)
            let thisWeek = SavingsCalculator.weekTotal(entries: entries)
            let lastWeek = SavingsCalculator.lastWeekTotal(entries: entries)
            Text("This week \(SavingsCalculator.formatCurrency(thisWeek)) · Last week \(SavingsCalculator.formatCurrency(lastWeek))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
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
                Label("\(streak) day streak", systemImage: "flame.fill")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
                Spacer()
                Text(profile.kind == .kid ? "In the piggy" : "Total saved")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            if !profileActive.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Active challenges")
                        .font(.headline)
                        .padding(.horizontal)
                    ForEach(profileActive, id: \.id) { active in
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
                        }
                    }
                }
            }

            matchableKidEntriesSection(for: profile)
        }
    }

    @ViewBuilder
    private func matchableKidEntriesSection(for profile: Profile) -> some View {
        if profile.kind == .adult {
            let kidProfiles = profiles.filter { $0.kind == .kid }
            let unmatchedKidStashes = entries.filter { entry in
                entry.kind == .stashed &&
                !entry.isParentMatch &&
                kidProfiles.contains(where: { $0.id == entry.profileId }) &&
                !entries.contains(where: { $0.matchedFromEntryId == entry.id })
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
                                settings: settings,
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
        celebrationMessage = message
        celebrationAmount = amount
        confettiTrigger += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { celebrationMessage = nil }
        }
    }
}

struct ActiveChallengeRow: View {
    let challenge: Challenge
    let active: ActiveChallenge
    let entries: [SaveEntry]
    let profile: Profile

    var body: some View {
        let progress = SavingsCalculator.challengeProgress(
            entries: entries,
            profileId: profile.id,
            challengeId: challenge.id,
            goal: active.targetAmount ?? challenge.goalAmount
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
            ProgressView(value: progress)
                .tint(profile.color)
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
    @Query(sort: \SaveEntry.date, order: .reverse) private var entries: [SaveEntry]

    let kidEntry: SaveEntry
    let kid: Profile
    let adult: Profile
    let settings: AppSettings
    let onMatched: (Double) -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(kid.name) stashed \(SavingsCalculator.formatCurrency(kidEntry.amount))")
                    .font(.subheadline)
                Text(kidEntry.note.isEmpty ? "Tap Match to add the same amount" : kidEntry.note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Match") {
                performMatch()
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding()
        .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    private func performMatch() {
        let amount = kidEntry.amount
        let matchEntry = SaveEntry(
            profileId: kid.id,
            amount: amount,
            kind: .stashed,
            note: "Parent Match from \(adult.name)",
            challengeId: "family-parent-match",
            matchedFromEntryId: kidEntry.id,
            isParentMatch: true
        )
        modelContext.insert(matchEntry)
        onMatched(amount)
    }
}
