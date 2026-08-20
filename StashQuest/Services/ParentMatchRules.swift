import Foundation

enum ParentMatchRules {
    static let weeklyMatchCap = 7

    static func isParentMatchProgramActive(
        activeChallenges: [ActiveChallenge],
        profiles: [Profile]
    ) -> Bool {
        activeChallenges.contains { active in
            guard active.status == .active else { return false }
            if active.challengeId == "family-parent-match" { return true }
            guard let challenge = ChallengeCatalog.challenge(id: active.challengeId) else { return false }
            return challenge.supportsParentMatch
        }
    }

    static func entryEligibleForMatch(
        _ entry: SaveEntry,
        entries: [SaveEntry],
        activeChallenges: [ActiveChallenge],
        profiles: [Profile]
    ) -> Bool {
        guard entry.kind == .stashed, !(entry.isParentMatch ?? false) else { return false }
        guard let kid = profiles.first(where: { $0.id == entry.profileId }), kid.kind == .kid else { return false }
        guard !entries.contains(where: { $0.matchedFromEntryId == entry.id }) else { return false }
        guard isParentMatchProgramActive(activeChallenges: activeChallenges, profiles: profiles) else { return false }

        if let challengeId = entry.challengeId,
           let challenge = ChallengeCatalog.challenge(id: challengeId),
           !challenge.supportsParentMatch {
            return false
        }

        return weeklyMatchCount(for: kid.id, entries: entries) < weeklyMatchCap
    }

    static func weeklyMatchCount(for kidId: UUID, entries: [SaveEntry], reference: Date = Date()) -> Int {
        let calendar = Calendar.current
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: reference)?.start else { return 0 }
        return entries.filter {
            ( $0.isParentMatch ?? false ) &&
            $0.profileId == kidId &&
            $0.date >= weekStart
        }.count
    }

    static func remainingWeeklyMatches(for kidId: UUID, entries: [SaveEntry]) -> Int {
        max(0, weeklyMatchCap - weeklyMatchCount(for: kidId, entries: entries))
    }
}
