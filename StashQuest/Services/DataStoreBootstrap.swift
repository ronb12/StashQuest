import Foundation
import SwiftData
import os

enum DataStoreBootstrap {
    private static let logger = Logger(subsystem: "com.bradley.stashquest", category: "DataStore")

    @MainActor
    static func loadOrCreateSettings(in context: ModelContext) -> AppSettings? {
        let descriptor = FetchDescriptor<AppSettings>()
        do {
            var settings = try context.fetch(descriptor)
            if settings.isEmpty {
                let created = AppSettings()
                context.insert(created)
                try context.save()
                logger.info("Created default AppSettings")
                return created
            }
            migrateRecordsIfNeeded(in: context)
            settings = dedupeSettingsIfNeeded(settings, in: context)
            return settings.first
        } catch {
            logger.error("Failed to load settings: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    @MainActor
    static func resetAllData(in context: ModelContext) -> AppSettings? {
        do {
            try context.delete(model: SaveEntry.self)
            try context.delete(model: ActiveChallenge.self)
            try context.delete(model: CompletedStamp.self)
            try context.delete(model: Profile.self)
            try context.delete(model: AppSettings.self)
            try context.save()

            let settings = AppSettings()
            context.insert(settings)
            try context.save()
            logger.info("Reset store and created fresh AppSettings")
            return settings
        } catch {
            logger.error("Failed to reset store: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    @MainActor
    private static func migrateRecordsIfNeeded(in context: ModelContext) {
        let settingsDescriptor = FetchDescriptor<AppSettings>()
        if let settings = try? context.fetch(settingsDescriptor) {
            for item in settings where (item.appearanceRaw ?? "").isEmpty {
                item.appearanceRaw = AppearanceMode.system.rawValue
            }
        }

        let profileDescriptor = FetchDescriptor<Profile>()
        if let profiles = try? context.fetch(profileDescriptor) {
            for profile in profiles where (profile.lastLogKindRaw ?? "").isEmpty {
                profile.lastLogKindRaw = SaveKind.stashed.rawValue
            }
        }

        let entryDescriptor = FetchDescriptor<SaveEntry>()
        if let entries = try? context.fetch(entryDescriptor) {
            for entry in entries where entry.isParentMatch == nil {
                entry.isParentMatch = false
            }
        }

        try? context.save()
    }

    @MainActor
    private static func dedupeSettingsIfNeeded(_ settings: [AppSettings], in context: ModelContext) -> [AppSettings] {
        guard settings.count > 1, let keeper = settings.first else { return settings }
        for duplicate in settings.dropFirst() {
            if duplicate.hasCompletedOnboarding && !keeper.hasCompletedOnboarding {
                keeper.hasCompletedOnboarding = true
                keeper.familyDisplayName = duplicate.familyDisplayName
                keeper.selectedProfileId = duplicate.selectedProfileId
            }
            context.delete(duplicate)
        }
        try? context.save()
        return [keeper]
    }
}
