import SwiftUI
import SwiftData

struct ChallengesView: View {
    @Bindable var settings: AppSettings
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]

    @State private var audienceFilter: ChallengeAudience = .grownUp

    private var selectedProfile: Profile? {
        if let id = settings.selectedProfileId {
            return profiles.first { $0.id == id }
        }
        return profiles.first
    }

    private var filteredChallenges: [Challenge] {
        ChallengeCatalog.challenges(for: audienceFilter)
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
                .padding()

                List(filteredChallenges) { challenge in
                    if let profile = selectedProfile, profileMatchesAudience(profile, challenge) {
                        NavigationLink {
                            ChallengeDetailView(challenge: challenge, profile: profile, settings: settings)
                        } label: {
                            ChallengeRow(challenge: challenge)
                        }
                    } else if let profile = defaultProfile(for: challenge) {
                        NavigationLink {
                            ChallengeDetailView(challenge: challenge, profile: profile, settings: settings)
                        } label: {
                            ChallengeRow(challenge: challenge)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Challenges")
        }
    }

    private func profileMatchesAudience(_ profile: Profile, _ challenge: Challenge) -> Bool {
        switch challenge.audience {
        case .grownUp: return profile.kind == .adult
        case .kid: return profile.kind == .kid
        case .family: return true
        }
    }

    private func defaultProfile(for challenge: Challenge) -> Profile? {
        switch challenge.audience {
        case .grownUp: return profiles.first { $0.kind == .adult }
        case .kid: return profiles.first { $0.kind == .kid }
        case .family: return profiles.first
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
                Text("Default \(challenge.defaultAmountLabel)")
                    .foregroundStyle(.teal)
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }

    private var categoryColor: Color {
        switch challenge.category {
        case .skip: return .orange
        case .stash: return .teal
        case .goal: return .purple
        }
    }
}
