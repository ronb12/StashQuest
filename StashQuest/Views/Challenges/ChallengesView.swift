import SwiftUI
import SwiftData

struct ChallengesView: View {
    @Bindable var settings: AppSettings
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]

    @State private var audienceFilter: ChallengeAudience = .grownUp

    private var selectedProfile: Profile? {
        if let id = settings.selectedProfileId,
           let match = profiles.first(where: { $0.id == id }) {
            return match
        }
        return profiles.first
    }

    private var filteredChallenges: [Challenge] {
        ChallengeCatalog.challenges(for: audienceFilter)
    }

    private var challengeProfile: Profile? {
        if let selected = selectedProfile, profileMatchesAudience(selected, audienceFilter) {
            return selected
        }
        return defaultProfile(for: audienceFilter)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Audience", selection: $audienceFilter) {
                    ForEach(ChallengeAudience.allCases, id: \.self) { audience in
                        Text(audience.rawValue).tag(audience)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top)

                if let profile = challengeProfile {
                    HStack {
                        Circle().fill(profile.color).frame(width: 8, height: 8)
                        Text("Challenges for \(profile.name)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                } else {
                    ContentUnavailableView(
                        audienceFilter == .kid ? "No kid profile yet" : "No profile yet",
                        systemImage: "person.crop.circle.badge.plus",
                        description: Text(audienceEmptyMessage)
                    )
                    .padding(.top, 24)
                }

                if challengeProfile != nil {
                    List(filteredChallenges) { challenge in
                        if let profile = challengeProfile {
                            NavigationLink {
                                ChallengeDetailView(challenge: challenge, profile: profile, settings: settings)
                            } label: {
                                ChallengeRow(challenge: challenge)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .animation(AppAnimations.smooth, value: audienceFilter)
                }
            }
            .navigationTitle("Challenges")
            .onChange(of: audienceFilter) { _, audience in
                HapticFeedback.light()
                withAnimation(AppAnimations.snappy) {
                    syncProfile(for: audience)
                }
            }
            .onAppear {
                syncProfile(for: audienceFilter)
            }
        }
    }

    private func syncProfile(for audience: ChallengeAudience) {
        if let profile = defaultProfile(for: audience) {
            settings.selectedProfileId = profile.id
        }
    }

    private func profileMatchesAudience(_ profile: Profile, _ audience: ChallengeAudience) -> Bool {
        switch audience {
        case .grownUp: return profile.kind == .adult
        case .kid: return profile.kind == .kid
        case .family: return true
        }
    }

    private func defaultProfile(for audience: ChallengeAudience) -> Profile? {
        switch audience {
        case .grownUp: return profiles.first { $0.kind == .adult }
        case .kid: return profiles.first { $0.kind == .kid }
        case .family: return profiles.first
        }
    }

    private var audienceEmptyMessage: String {
        switch audienceFilter {
        case .kid:
            return "Add a kid profile on the You tab to use kid challenges."
        case .grownUp:
            return "Add a grown-up profile on the You tab."
        case .family:
            return "Add a profile on the You tab to start challenges."
        }
    }
}

struct ChallengeRow: View {
    let challenge: Challenge

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(challenge.name)
                    .font(.headline)
                Spacer()
                Text(challenge.category.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(categoryColor.opacity(0.2), in: Capsule())
            }
            Text(challenge.rule)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            HStack {
                Label(challenge.duration.rawValue, systemImage: "clock")
                Spacer()
                if challenge.hasPaperChecklist {
                    Label("\(challenge.checklistSlotCount) checks", systemImage: challenge.checklistEmptyIcon)
                }
                Text("Default \(challenge.defaultAmountLabel)")
                    .foregroundStyle(.teal)
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var categoryColor: Color {
        switch challenge.category {
        case .skip: return .orange
        case .stash: return .teal
        case .goal: return .purple
        }
    }
}
