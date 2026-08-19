import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [AppSettings]

    @State private var familyName = "Bradley's"
    @State private var adultName = ""
    @State private var kidName = ""
    @State private var step = 0

    private var settings: AppSettings? { settingsList.first }

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Image(systemName: "banknote.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.teal)

                Text("Stash Quest")
                    .font(.largeTitle.bold())

                Text("Real money. Real savings. Fun for the whole family.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                if step == 0 {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Family name")
                            .font(.headline)
                        TextField("Bradley's", text: $familyName)
                            .textFieldStyle(.roundedBorder)
                        Text("Shows on Home as \"\(familyName) Stash Quest\"")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Add your family")
                            .font(.headline)
                        TextField("Grown-up name", text: $adultName)
                            .textFieldStyle(.roundedBorder)
                        TextField("Kid name", text: $kidName)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.horizontal)
                }

                Spacer()

                Button(step == 0 ? "Continue" : "Start saving") {
                    if step == 0 {
                        step = 1
                    } else {
                        completeOnboarding()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
                .disabled(step == 1 && (adultName.trimmingCharacters(in: .whitespaces).isEmpty || kidName.trimmingCharacters(in: .whitespaces).isEmpty))
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .padding(.top, 40)
        }
    }

    private func completeOnboarding() {
        let appSettings = settings ?? AppSettings()
        if settings == nil { modelContext.insert(appSettings) }

        appSettings.familyDisplayName = familyName.trimmingCharacters(in: .whitespaces).isEmpty ? "Bradley's" : familyName.trimmingCharacters(in: .whitespaces)

        let adult = Profile(name: adultName.trimmingCharacters(in: .whitespaces), kind: .adult, colorHex: ProfileColors.palette[0])
        let kid = Profile(name: kidName.trimmingCharacters(in: .whitespaces), kind: .kid, colorHex: ProfileColors.palette[1])
        modelContext.insert(adult)
        modelContext.insert(kid)

        appSettings.selectedProfileId = adult.id
        appSettings.hasCompletedOnboarding = true
    }
}
