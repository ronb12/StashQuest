import SwiftUI
import SwiftData

@main
struct StashQuestApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [
            Profile.self,
            SaveEntry.self,
            ActiveChallenge.self,
            AppSettings.self,
            CompletedStamp.self
        ])
    }
}
