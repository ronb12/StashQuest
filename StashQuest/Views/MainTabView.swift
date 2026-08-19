import SwiftUI
import SwiftData

struct MainTabView: View {
    @Bindable var settings: AppSettings

    var body: some View {
        TabView {
            HomeView(settings: settings)
                .tabItem { Label("Home", systemImage: "house.fill") }

            ChallengesView(settings: settings)
                .tabItem { Label("Challenges", systemImage: "flag.fill") }

            ActivityView(settings: settings)
                .tabItem { Label("Activity", systemImage: "list.bullet.rectangle") }

            YouView(settings: settings)
                .tabItem { Label("You", systemImage: "person.2.fill") }
        }
        .tint(.teal)
    }
}
