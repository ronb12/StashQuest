import Foundation
import SwiftData

enum WidgetDataSync {
    static let appGroupID = "group.com.bradley.stashquest"

    private enum Keys {
        static let familyTotal = "widget.familyTotal"
        static let familyName = "widget.familyName"
        static let topStreak = "widget.topStreak"
        static let topStreakName = "widget.topStreakName"
        static let lastUpdated = "widget.lastUpdated"
    }

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func updateFromContext(_ context: ModelContext) {
        let profileDescriptor = FetchDescriptor<Profile>(sortBy: [SortDescriptor(\.createdAt)])
        let entryDescriptor = FetchDescriptor<SaveEntry>()
        guard
            let profiles = try? context.fetch(profileDescriptor),
            let entries = try? context.fetch(entryDescriptor)
        else { return }

        let settingsDescriptor = FetchDescriptor<AppSettings>()
        let settings = (try? context.fetch(settingsDescriptor))?.first

        let familyTotal = SavingsCalculator.familyTotal(entries: entries)
        var topStreak = 0
        var topName = profiles.first?.name ?? "Family"
        for profile in profiles {
            let streak = SavingsCalculator.streakDays(entries: entries, profileId: profile.id)
            if streak > topStreak {
                topStreak = streak
                topName = profile.name
            }
        }

        guard let defaults else { return }
        defaults.set(familyTotal, forKey: Keys.familyTotal)
        defaults.set(settings?.familyDisplayName ?? "Family", forKey: Keys.familyName)
        defaults.set(topStreak, forKey: Keys.topStreak)
        defaults.set(topName, forKey: Keys.topStreakName)
        defaults.set(Date().timeIntervalSince1970, forKey: Keys.lastUpdated)
    }
}
