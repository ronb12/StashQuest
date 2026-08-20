import SwiftUI
import SwiftData

struct YouView: View {
    @Bindable var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]
    @Query(sort: \SaveEntry.date, order: .reverse) private var entries: [SaveEntry]
    @Query(sort: \CompletedStamp.completedAt, order: .reverse) private var stamps: [CompletedStamp]
    @Query private var activeChallenges: [ActiveChallenge]

    @State private var showAddProfile = false
    @State private var newProfileName = ""
    @State private var newProfileKind: ProfileKind = .adult
    @State private var editingProfile: Profile?
    @State private var remindersDenied = false
    @State private var exportURL: URL?
    @State private var showExportSheet = false
    @State private var exportError: String?

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
                        Button {
                            editingProfile = profile
                        } label: {
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
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("profileRow_\(profile.id.uuidString)")
                    }
                    .onDelete(perform: deleteProfiles)

                    Button("Add profile") {
                        newProfileKind = profiles.contains(where: { $0.kind == .kid }) ? .adult : .kid
                        showAddProfile = true
                    }
                    .accessibilityIdentifier("addProfileOpenButton")
                }

                Section("This week") {
                    let familyWeek = SavingsCalculator.weekTotal(entries: entries)
                    Text("Family net \(SavingsCalculator.formatCurrency(familyWeek)) this week.")
                }

                Section("Data") {
                    Button("Export backup (JSON)") {
                        exportData()
                    }
                    .accessibilityIdentifier("exportDataButton")
                    Text("Saves a JSON file you can keep outside the app. Deleting Stash Quest removes on-device data.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Stamps") {
                    if stamps.isEmpty {
                        Text("Complete a challenge to earn a stamp.")
                            .foregroundStyle(.secondary)
                    } else {
                        StampGridView(stamps: stamps, profiles: profiles)
                    }
                }

                Section("Appearance") {
                    Picker("Theme", selection: Binding(
                        get: { settings.appearanceRaw ?? AppearanceMode.system.rawValue },
                        set: { settings.appearanceRaw = $0 }
                    )) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.label).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("appearancePicker")

                    Text(appearanceHelpText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Reminders") {
                    Toggle("Savings reminders", isOn: $settings.remindersEnabled)
                        .accessibilityIdentifier("remindersToggle")
                        .onChange(of: settings.remindersEnabled) { _, enabled in
                            Task {
                                let result = await NotificationManager.scheduleReminders(
                                    enabled: enabled,
                                    hour: settings.reminderHour,
                                    minute: settings.reminderMinute
                                )
                                await MainActor.run {
                                    remindersDenied = enabled && result == .denied
                                    if result == .denied {
                                        settings.remindersEnabled = false
                                    }
                                    modelContext.commitSave()
                                }
                            }
                        }
                    Stepper("Time: \(formattedReminderTime)", value: $settings.reminderHour, in: 6...21)
                        .onChange(of: settings.reminderHour) { _, _ in
                            if settings.remindersEnabled {
                                Task {
                                    _ = await NotificationManager.scheduleReminders(
                                        enabled: true,
                                        hour: settings.reminderHour,
                                        minute: settings.reminderMinute
                                    )
                                }
                            }
                        }
                    if remindersDenied {
                        Text("Notifications are off. Open Settings → Stash Quest → Notifications to allow alerts.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    Text("Allowance day, Coin Friday, and $5 Friday")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Legal & Support") {
                    NavigationLink {
                        LegalDocumentView(document: .privacyPolicy)
                    } label: {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }

                    NavigationLink {
                        LegalDocumentView(document: .termsOfService)
                    } label: {
                        Label("Terms of Service", systemImage: "doc.text.fill")
                    }

                    NavigationLink {
                        LegalDocumentView(document: .support)
                    } label: {
                        Label("Support", systemImage: "questionmark.circle.fill")
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Created by Ronell Bradley")
                            .font(.subheadline)
                        Text("Property of Bradley Virtual Solutions, LLC")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
            .navigationTitle("You")
            .sheet(isPresented: $showAddProfile) {
                NavigationStack {
                    Form {
                        TextField("Name", text: $newProfileName)
                            .textContentType(.name)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .accessibilityIdentifier("profileNameField")
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
                                .accessibilityIdentifier("addProfileButton")
                        }
                    }
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: Binding(
                get: { editingProfile != nil },
                set: { if !$0 { editingProfile = nil } }
            )) {
                if let profile = editingProfile {
                    EditProfileSheet(profile: profile)
                        .onDisappear { modelContext.commitSave() }
                }
            }
            .sheet(isPresented: $showExportSheet, onDismiss: { exportURL = nil }) {
                if let exportURL {
                    ShareLink(item: exportURL) {
                        Label("Share export file", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .padding()
                    .presentationDetents([.medium])
                }
            }
            .alert("Export failed", isPresented: Binding(
                get: { exportError != nil },
                set: { if !$0 { exportError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(exportError ?? "")
            }
        }
    }

    private var formattedReminderTime: String {
        String(format: "%d:00", settings.reminderHour)
    }

    private var appearanceHelpText: String {
        switch settings.appearance {
        case .system:
            return "Matches your iPhone light or dark setting."
        case .light:
            return "Always use light mode."
        case .dark:
            return "Always use dark mode."
        }
    }

    private func addProfile() {
        let name = newProfileName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let colorIndex = profiles.count % ProfileColors.palette.count
        let profile = Profile(name: name, kind: newProfileKind, colorHex: ProfileColors.palette[colorIndex])
        modelContext.insert(profile)
        if settings.selectedProfileId == nil {
            settings.selectedProfileId = profile.id
        }
        newProfileName = ""
        showAddProfile = false
        modelContext.commitSave()
    }

    private func deleteProfiles(at offsets: IndexSet) {
        for index in offsets {
            let profile = profiles[index]
            let profileId = profile.id

            entries.filter { $0.profileId == profileId }.forEach { modelContext.delete($0) }
            activeChallenges.filter { $0.profileId == profileId }.forEach { modelContext.delete($0) }
            stamps.filter { $0.profileId == profileId }.forEach { modelContext.delete($0) }

            if settings.selectedProfileId == profileId {
                settings.selectedProfileId = profiles.first(where: { $0.id != profileId })?.id
            }
            modelContext.delete(profile)
        }
        modelContext.commitSave()
    }

    private func exportData() {
        do {
            exportURL = try DataExporter.writeExportFile(context: modelContext, settings: settings)
            showExportSheet = true
        } catch {
            exportError = error.localizedDescription
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
