import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [AppSettings]

    var body: some View {
        Group {
            if let settings = settingsList.first, settings.hasCompletedOnboarding {
                MainTabView(settings: settings)
            } else {
                OnboardingView()
            }
        }
        .onAppear {
            ensureSettings()
        }
    }

    private func ensureSettings() {
        guard settingsList.isEmpty else { return }
        modelContext.insert(AppSettings())
    }
}
