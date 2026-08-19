import SwiftUI
import SwiftData

struct YouView: View {
    @Bindable var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]
    @Query(sort: \SaveEntry.date, order: .reverse) private var entries: [SaveEntry]
    @Query(sort: \CompletedStamp.completedAt, order: .reverse) private var stamps: [CompletedStamp]

    @State private var showAddProfile = false
    @State private var newProfileName = ""
    @State private var newProfileKind: ProfileKind = .kid

    var body: some View {
        NavigationStack {
            List {
                Section("Family") {
                    TextField("Family name", text: $settings.familyDisplayName)
                    Text("Home shows \"\(settings.familyDisplayName) Stash Quest\"")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Profiles") {
                    ForEach(profiles, id: \.id) { profile in
                        HStack {
                            Circle().fill(profile.color).frame(width: 12, height: 12)
                            VStack(alignment: .leading) {
                                Text(profile.name)
                                Text(profile.kind.label)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            let total = SavingsCalculator.totalSaved(entries: entries, profileId: profile.id)
                            Text(SavingsCalculator.formatCurrency(total))
                                .font(.caption.bold())
                        }
                    }
                    .onDelete(perform: deleteProfiles)

                    Button("Add profile") { showAddProfile = true }
                }

                Section("This week") {
                    let familyWeek = SavingsCalculator.weekTotal(entries: entries)
                    Text("Family saved \(SavingsCalculator.formatCurrency(familyWeek)) this week.")
                }

                Section("Stamps") {
                    if stamps.isEmpty {
                        Text("Complete a challenge to earn a stamp.")
                            .foregroundStyle(.secondary)
                    } else {
                        StampGridView(stamps: stamps, profiles: profiles)
                    }
                }

                Section("Reminders") {
                    Toggle("Savings reminders", isOn: $settings.remindersEnabled)
                        .onChange(of: settings.remindersEnabled) { _, enabled in
                            Task {
                                await NotificationManager.scheduleReminders(
                                    enabled: enabled,
                                    hour: settings.reminderHour,
                                    minute: settings.reminderMinute
                                )
                            }
                        }
                    Stepper("Time: \(formattedReminderTime)", value: $settings.reminderHour, in: 6...21)
                        .onChange(of: settings.reminderHour) { _, _ in
                            if settings.remindersEnabled {
                                Task {
                                    await NotificationManager.scheduleReminders(
                                        enabled: true,
                                        hour: settings.reminderHour,
                                        minute: settings.reminderMinute
                                    )
                                }
                            }
                        }
                    Text("Allowance day, Coin Friday, and $5 Friday")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Legal & Support") {
                    Link(destination: LegalDocuments.privacyPolicyURL) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }

                    Link(destination: LegalDocuments.termsOfServiceURL) {
                        Label("Terms of Service", systemImage: "doc.text.fill")
                    }

                    Link(destination: LegalDocuments.supportURL) {
                        Label("Support", systemImage: "questionmark.circle.fill")
                    }

                    Link(destination: URL(string: "mailto:\(LegalDocuments.contactEmail)")!) {
                        Label("Email support", systemImage: "envelope.fill")
                    }
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("You")
            .sheet(isPresented: $showAddProfile) {
                NavigationStack {
                    Form {
                        TextField("Name", text: $newProfileName)
                        Picker("Type", selection: $newProfileKind) {
                            ForEach(ProfileKind.allCases, id: \.self) { kind in
                                Text(kind.label).tag(kind)
                            }
                        }
                    }
                    .navigationTitle("Add profile")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showAddProfile = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Add") { addProfile() }
                                .disabled(newProfileName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }

    private var formattedReminderTime: String {
        String(format: "%d:00", settings.reminderHour)
    }

    private func addProfile() {
        let name = newProfileName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let colorIndex = profiles.count % ProfileColors.palette.count
        let profile = Profile(name: name, kind: newProfileKind, colorHex: ProfileColors.palette[colorIndex])
        modelContext.insert(profile)
        newProfileName = ""
        showAddProfile = false
    }

    private func deleteProfiles(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(profiles[index])
        }
    }
}

struct StampGridView: View {
    let stamps: [CompletedStamp]
    let profiles: [Profile]

    private let columns = [GridItem(.adaptive(minimum: 72), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Array(stamps.enumerated()), id: \.element.id) { index, stamp in
                VStack(spacing: 6) {
                    Image(systemName: "seal.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                        .symbolEffect(.bounce, value: stamp.id)
                    if let challenge = ChallengeCatalog.challenge(id: stamp.challengeId) {
                        Text(challenge.name)
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    if let profile = profiles.first(where: { $0.id == stamp.profileId }) {
                        Text(profile.name)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                .staggeredAppear(index: index)
            }
        }
        .padding(.vertical, 4)
    }
}
