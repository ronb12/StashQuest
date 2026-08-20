import Foundation

enum SavingsCalculator {
    static func totalSaved(entries: [SaveEntry], profileId: UUID? = nil) -> Double {
        let filtered = profileId.map { id in entries.filter { $0.profileId == id } } ?? entries
        return filtered.reduce(0) { $0 + $1.signedAmount }
    }

    static func familyTotal(entries: [SaveEntry]) -> Double {
        totalSaved(entries: entries)
    }

    static func weekTotal(entries: [SaveEntry], profileId: UUID? = nil, reference: Date = Date()) -> Double {
        let calendar = Calendar.current
        guard let start = calendar.dateInterval(of: .weekOfYear, for: reference)?.start else { return 0 }
        let filtered = entries.filter { $0.date >= start }
        return totalSaved(entries: filtered, profileId: profileId)
    }

    static func lastWeekTotal(entries: [SaveEntry], profileId: UUID? = nil, reference: Date = Date()) -> Double {
        let calendar = Calendar.current
        guard let thisWeekStart = calendar.dateInterval(of: .weekOfYear, for: reference)?.start,
              let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart),
              let lastWeekEnd = calendar.date(byAdding: .second, value: -1, to: thisWeekStart) else { return 0 }
        let filtered = entries.filter { $0.date >= lastWeekStart && $0.date <= lastWeekEnd }
        return totalSaved(entries: filtered, profileId: profileId)
    }

    static func streakDays(entries: [SaveEntry], profileId: UUID) -> Int {
        let calendar = Calendar.current
        let profileEntries = entries.filter {
            $0.profileId == profileId && ($0.kind == .skipped || $0.kind == .stashed)
        }
        let days = Set(profileEntries.map { calendar.startOfDay(for: $0.date) })
        guard !days.isEmpty else { return 0 }

        var streak = 0
        var cursor = calendar.startOfDay(for: Date())

        while days.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    static func familyChallengeTotal(entries: [SaveEntry], challengeId: String) -> Double {
        entries
            .filter { $0.challengeId == challengeId }
            .reduce(0) { $0 + $1.signedAmount }
    }

    static func familyChallengeProgress(entries: [SaveEntry], challengeId: String, goal: Double?) -> Double {
        let saved = familyChallengeTotal(entries: entries, challengeId: challengeId)
        guard let goal, goal > 0 else { return saved }
        return min(1, max(0, saved / goal))
    }

    static func activeFamilyGoalSummaries(
        activeChallenges: [ActiveChallenge],
        entries: [SaveEntry]
    ) -> [(challenge: Challenge, goal: Double, logged: Double, progress: Double)] {
        var seen = Set<String>()
        var results: [(Challenge, Double, Double, Double)] = []

        for active in activeChallenges where active.status == .active {
            guard !seen.contains(active.challengeId),
                  let challenge = ChallengeCatalog.challenge(id: active.challengeId),
                  challenge.audience == .family,
                  let goal = active.targetAmount ?? challenge.goalAmount,
                  goal > 0 else { continue }
            seen.insert(active.challengeId)
            let logged = familyChallengeTotal(entries: entries, challengeId: challenge.id)
            let progress = min(1, max(0, logged / goal))
            results.append((challenge, goal, logged, progress))
        }
        return results
    }

    static func isGiveALittleActive(activeChallenges: [ActiveChallenge]) -> Bool {
        activeChallenges.contains { $0.status == .active && $0.challengeId == "family-give-little" }
    }

    static func vaultProgress(total: Double, isKid: Bool) -> (current: Double, nextMilestone: Double, progress: Double) {
        let milestones = isKid
            ? [10.0, 25.0, 50.0, 100.0, 250.0]
            : [50.0, 100.0, 500.0, 1000.0, 2500.0, 3000.0, 4000.0, 5000.0]
        let clampedTotal = max(0, total)
        let next = milestones.first(where: { $0 > clampedTotal }) ?? (milestones.last ?? 100) * 2
        let previous = milestones.last(where: { $0 <= clampedTotal }) ?? 0
        let span = next - previous
        let progress = span > 0 ? min(1, (clampedTotal - previous) / span) : 1
        return (clampedTotal, next, progress)
    }

    static func challengeProgress(entries: [SaveEntry], profileId: UUID, challengeId: String, goal: Double?) -> Double {
        let challengeEntries = entries.filter { $0.profileId == profileId && $0.challengeId == challengeId }
        let saved = challengeEntries.reduce(0) { $0 + $1.signedAmount }
        guard let goal, goal > 0 else { return saved }
        return min(1, max(0, saved / goal))
    }

    static func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? String(format: "$%.2f", amount)
    }
}
