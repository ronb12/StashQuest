import SwiftUI
import SwiftData

struct LogSaveSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let profile: Profile
    let profiles: [Profile]
    let settings: AppSettings
    var initialChallengeId: String? = nil
    let onSaved: (SaveEntry, String) -> Void

    @Query(filter: #Predicate<ActiveChallenge> { $0.statusRaw == "active" })
    private var activeChallenges: [ActiveChallenge]

    @State private var kind: SaveKind = .stashed
    @State private var amountText = ""
    @State private var note = ""
    @State private var selectedChallengeId: String?

    private var activeForProfile: [ActiveChallenge] {
        activeChallenges.filter { $0.profileId == profile.id }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Who") {
                    HStack {
                        Circle().fill(profile.color).frame(width: 12, height: 12)
                        Text(profile.name)
                        Spacer()
                        Text(profile.kind.label)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Type") {
                    Picker("Kind", selection: $kind) {
                        ForEach(SaveKind.allCases, id: \.self) { saveKind in
                            Text(saveKind.label).tag(saveKind)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Amount") {
                    TextField("0.00", text: $amountText)
                        .keyboardType(.decimalPad)
                    if let challengeId = selectedChallengeId,
                       let challenge = ChallengeCatalog.challenge(id: challengeId) {
                        Button("Use \(challenge.defaultAmountLabel)") {
                            amountText = String(format: "%.2f", challenge.defaultAmount)
                        }
                        .font(.caption)
                    }
                }

                if !activeForProfile.isEmpty {
                    Section("Challenge (optional)") {
                        Picker("Challenge", selection: $selectedChallengeId) {
                            Text("None").tag(String?.none)
                            ForEach(activeForProfile, id: \.id) { active in
                                if let challenge = ChallengeCatalog.challenge(id: active.challengeId) {
                                    Text(challenge.name).tag(Optional(challenge.id))
                                }
                            }
                        }
                    }
                }

                Section("Note") {
                    TextField("What did you skip or stash?", text: $note)
                }
            }
            .navigationTitle("Log a save")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(parsedAmount == nil || parsedAmount! <= 0)
                }
            }
            .onAppear {
                if selectedChallengeId == nil {
                    selectedChallengeId = initialChallengeId
                }
                if amountText.isEmpty, let id = initialChallengeId,
                   let challenge = ChallengeCatalog.challenge(id: id) {
                    amountText = String(format: "%.2f", challenge.defaultAmount)
                }
            }
        }
    }

    private var parsedAmount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: "."))
    }

    private func save() {
        guard let amount = parsedAmount, amount > 0 else { return }

        let entry = SaveEntry(
            profileId: profile.id,
            amount: amount,
            kind: kind,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            challengeId: selectedChallengeId
        )
        modelContext.insert(entry)

        checkChallengeCompletion(for: selectedChallengeId, profileId: profile.id, amount: amount)

        let message: String
        switch kind {
        case .skipped:
            message = profile.kind == .kid ? "You kept it!" : "You kept \(SavingsCalculator.formatCurrency(amount))!"
        case .stashed:
            message = profile.kind == .kid ? "In the piggy: \(SavingsCalculator.formatCurrency(amount))" : "Stashed \(SavingsCalculator.formatCurrency(amount))!"
        case .gave:
            message = "Gave \(SavingsCalculator.formatCurrency(amount))"
        }

        onSaved(entry, message)
        dismiss()
    }

    private func checkChallengeCompletion(for challengeId: String?, profileId: UUID, amount: Double) {
        guard let challengeId,
              let challenge = ChallengeCatalog.challenge(id: challengeId),
              let goal = activeChallenges.first(where: { $0.profileId == profileId && $0.challengeId == challengeId })?.targetAmount ?? challenge.goalAmount else { return }

        let descriptor = FetchDescriptor<SaveEntry>()
        guard let allEntries = try? modelContext.fetch(descriptor) else { return }
        let saved = SavingsCalculator.challengeProgress(entries: allEntries, profileId: profileId, challengeId: challengeId, goal: goal)

        if saved >= 1.0 {
            if let active = activeChallenges.first(where: { $0.profileId == profileId && $0.challengeId == challengeId }) {
                active.status = .completed
            }
            let stamp = CompletedStamp(profileId: profileId, challengeId: challengeId)
            modelContext.insert(stamp)
        }
    }
}
