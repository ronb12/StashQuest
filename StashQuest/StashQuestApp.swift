import SwiftUI
import SwiftData
import os

@main
struct StashQuestApp: App {
    private static let logger = Logger(subsystem: "com.bradley.stashquest", category: "App")

    private let container: ModelContainer

    init() {
        container = Self.makeContainer()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }

    private static func makeContainer() -> ModelContainer {
        let schema = Schema([
            Profile.self,
            SaveEntry.self,
            ActiveChallenge.self,
            AppSettings.self,
            CompletedStamp.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            logger.error("ModelContainer failed: \(error.localizedDescription, privacy: .public). Recreating store.")
            Self.deleteDefaultStoreFiles()
            do {
                return try ModelContainer(for: schema, configurations: [configuration])
            } catch {
                logger.error("ModelContainer recreate failed: \(error.localizedDescription, privacy: .public). Using in-memory store.")
                let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                return try! ModelContainer(for: schema, configurations: [memory])
            }
        }
    }

    private static func deleteDefaultStoreFiles() {
        let fm = FileManager.default
        guard let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return
        }
        let known = [
            appSupport.appendingPathComponent("default.store"),
            appSupport.appendingPathComponent("default.store-wal"),
            appSupport.appendingPathComponent("default.store-shm")
        ]
        for url in known {
            try? fm.removeItem(at: url)
        }
        if let items = try? fm.contentsOfDirectory(at: appSupport, includingPropertiesForKeys: nil) {
            for item in items {
                let name = item.lastPathComponent.lowercased()
                if name.contains("swiftdata")
                    || name.hasSuffix(".store")
                    || name.hasSuffix(".sqlite")
                    || name.hasSuffix(".sqlite-wal")
                    || name.hasSuffix(".sqlite-shm") {
                    try? fm.removeItem(at: item)
                }
            }
        }
    }
}
