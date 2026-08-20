import SwiftUI
import SwiftData
import os

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [AppSettings]
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]

    @State private var loadFailed = false
    @State private var didBootstrap = false

    private var settings: AppSettings? { settingsList.first }

    private var needsOnboarding: Bool {
        guard let settings else { return true }
        // Treat “onboarded but no profiles” as broken setup so the user can create one.
        return !settings.hasCompletedOnboarding || profiles.isEmpty
    }

    var body: some View {
        Group {
            if let settings {
                if needsOnboarding {
                    OnboardingView(settings: settings)
                        .transition(.opacity)
                } else {
                    MainTabView(settings: settings)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            } else if loadFailed {
                recoveryView
            } else {
                ProgressView("Loading…")
                    .task { bootstrap() }
            }
        }
        .preferredColorScheme(settings?.appearance.colorScheme)
        .animation(AppAnimations.smooth, value: needsOnboarding)
        .onChange(of: settingsList.count) { _, count in
            if count == 0 && didBootstrap {
                bootstrap()
            }
        }
    }

    private var recoveryView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text("Couldn't load your data")
                .font(.title3.bold())
            Text("This can happen after an app update. You can reset and start fresh, or try again.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            Button("Try again") {
                loadFailed = false
                didBootstrap = false
                bootstrap()
            }
            .buttonStyle(.borderedProminent)
            Button("Reset and start fresh", role: .destructive) {
                loadFailed = false
                _ = DataStoreBootstrap.resetAllData(in: modelContext)
                didBootstrap = true
            }
        }
        .padding()
    }

    @MainActor
    private func bootstrap() {
        guard !didBootstrap || settingsList.isEmpty else { return }
        didBootstrap = true
        if DataStoreBootstrap.loadOrCreateSettings(in: modelContext) == nil {
            loadFailed = true
        }
    }
}
