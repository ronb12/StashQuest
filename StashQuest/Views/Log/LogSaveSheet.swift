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
    @Query private var stamps: [CompletedStamp]

    @FocusState private var focusedField: Field?

    @State private var kind: SaveKind = .stashed
    @State private var amountText = ""
    @State private var note = ""
    @State private var selectedChallengeId: String?
    @State private var saveError: String?
    @State private var isSaving = false

    private enum Field {
        case amount
        case note
    }

    /// Personal actives plus any shared family challenges so every profile can log toward Trip Jar, etc.
    private var selectableChallenges: [ActiveChallenge] {
        var seen = Set<String>()
        var result: [ActiveChallenge] = []
        for active in activeChallenges {
            let isPersonal = active.profileId == profile.id
            let isFamily = ChallengeCatalog.challenge(id: active.challengeId)?.audience == .family
            guard isPersonal || isFamily else { continue }
            guard seen.insert(active.challengeId).inserted else { continue }
            result.append(active)
        }
        return result
    }

    private var quickAmounts: [Double] {
        profile.kind == .kid ? [0.50, 1, 2, 5] : [1, 5, 10, 20]
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
                                .accessibilityIdentifier("logKind_\(saveKind.rawValue)")
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                    .onChange(of: kind) { _, _ in
                        applySuggestedAmount()
                    }

                    Text(kindNoteHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Amount") {
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .amount)
                        .accessibilityIdentifier("amountField")

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(quickAmounts, id: \.self) { amount in
                                Button(SavingsCalculator.formatCurrency(amount)) {
                                    amountText = CurrencyParser.formatEntry(amount)
                                    focusedField = nil
                                    HapticFeedback.light()
                                }
                                .buttonStyle(.bordered)
                                .font(.caption)
                            }
                            if let challengeId = selectedChallengeId,
                               let challenge = ChallengeCatalog.challenge(id: challengeId) {
                                Button("Default \(challenge.defaultAmountLabel)") {
                                    amountText = CurrencyParser.formatEntry(challenge.defaultAmount)
                                    focusedField = nil
                                }
                                .buttonStyle(.bordered)
                                .font(.caption)
                            }
                        }
                    }
                }

                if !selectableChallenges.isEmpty {
                    Section("Challenge (optional)") {
                        Picker("Challenge", selection: $selectedChallengeId) {
                            Text("None").tag(String?.none)
                            ForEach(selectableChallenges, id: \.id) { active in
                                if let challenge = ChallengeCatalog.challenge(id: active.challengeId) {
                                    Text(challenge.name).tag(Optional(challenge.id))
                                }
                            }
                        }
                        .onChange(of: selectedChallengeId) { _, newValue in
                            if let id = newValue,
                               let challenge = ChallengeCatalog.challenge(id: id),
                               amountText.isEmpty {
                                amountText = CurrencyParser.formatEntry(challenge.defaultAmount)
                            }
                        }
                    }
                }

                Section("Note") {
                    TextField(kind.notePlaceholder, text: $note, axis: .vertical)
                        .lineLimit(1...3)
                        .focused($focusedField, equals: .note)
                }
            }
            .navigationTitle("Log money")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(parsedAmount == nil || isSaving)
                        .accessibilityIdentifier("logSaveButton")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
            .onAppear {
                kind = profile.lastLogKind
                if selectedChallengeId == nil {
                    selectedChallengeId = initialChallengeId
                }
                if amountText.isEmpty {
                    applySuggestedAmount()
                }
            }
            .alert("Couldn't save", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveError ?? "Please try again.")
            }
        }
    }

    private var kindNoteHint: String {
        switch kind {
        case .skipped: return "Money you kept by not buying something."
        case .stashed: return "Money moved into savings."
        case .spent: return "Money used from savings — lowers your vault."
        case .gave: return "Money given away — lowers your vault."
        }
    }

    private var parsedAmount: Double? {
        CurrencyParser.parse(amountText)
    }

    private func applySuggestedAmount() {
        if let id = selectedChallengeId ?? initialChallengeId,
           let challenge = ChallengeCatalog.challenge(id: id) {
            amountText = CurrencyParser.formatEntry(challenge.defaultAmount)
            return
        }
        let fallback = profile.kind == .kid ? 1.0 : 5.0
        amountText = CurrencyParser.formatEntry(fallback)
    }

    private func save() {
        guard let amount = parsedAmount, !isSaving else { return }
        isSaving = true

        let entry = SaveEntry(
            profileId: profile.id,
            amount: amount,
            kind: kind,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            challengeId: selectedChallengeId
        )
        modelContext.insert(entry)
        profile.lastLogKind = kind

        checkChallengeCompletion(for: selectedChallengeId, profileId: profile.id)

        guard modelContext.commitSave() else {
            modelContext.rollback()
            isSaving = false
            saveError = "Your log couldn't be saved. Please try again."
            return
        }

        let message: String
        switch kind {
        case .skipped:
            message = profile.kind == .kid ? "You kept it!" : "You kept \(SavingsCalculator.formatCurrency(amount))!"
        case .stashed:
            message = profile.kind == .kid ? "In the piggy: \(SavingsCalculator.formatCurrency(amount))" : "Stashed \(SavingsCalculator.formatCurrency(amount))!"
        case .spent:
            message = profile.kind == .kid
                ? "Spent \(SavingsCalculator.formatCurrency(amount)) from the piggy"
                : "Spent \(SavingsCalculator.formatCurrency(amount)) from savings"
        case .gave:
            message = "Gave \(SavingsCalculator.formatCurrency(amount))"
        }

        onSaved(entry, message)
        if kind.reducesVault {
            HapticFeedback.warning()
        } else {
            HapticFeedback.success()
        }
        dismiss()
    }

    private func checkChallengeCompletion(for challengeId: String?, profileId: UUID) {
        guard let challengeId,
              let challenge = ChallengeCatalog.challenge(id: challengeId) else { return }

        let relatedActives = activeChallenges.filter { $0.challengeId == challengeId }
        let goal = relatedActives.first?.targetAmount ?? challenge.goalAmount
        guard let goal, goal > 0 else { return }

        let descriptor = FetchDescriptor<SaveEntry>()
        guard let allEntries = try? modelContext.fetch(descriptor) else { return }

        let progress: Double
        if challenge.isFamilyGoal {
            progress = SavingsCalculator.familyChallengeProgress(
                entries: allEntries,
                challengeId: challengeId,
                goal: goal
            )
        } else {
            progress = SavingsCalculator.challengeProgress(
                entries: allEntries,
                profileId: profileId,
                challengeId: challengeId,
                goal: goal
            )
        }

        guard progress >= 1.0 else { return }

        for active in relatedActives {
            active.status = .completed
        }

        if challenge.isFamilyGoal || challenge.audience == .family {
            for member in profiles {
                StampHelper.awardStampIfNeeded(
                    context: modelContext,
                    profileId: member.id,
                    challengeId: challengeId,
                    existingStamps: stamps
                )
            }
        } else {
            StampHelper.awardStampIfNeeded(
                context: modelContext,
                profileId: profileId,
                challengeId: challengeId,
                existingStamps: stamps
            )
        }
    }
}
