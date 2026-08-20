import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Bindable var settings: AppSettings
    @Environment(\.modelContext) private var modelContext

    @FocusState private var focusedField: Field?

    @State private var familyName = "Bradley's"
    @State private var adultName = ""
    @State private var kidName = ""
    @State private var setupMode: SetupMode = .solo
    @State private var step = 0
    @State private var iconBounce = false
    @State private var saveError: String?

    private enum SetupMode: String, CaseIterable {
        case solo = "Just me"
        case family = "With kids"
    }

    private enum Field {
        case familyName
        case adultName
        case kidName
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    Image(systemName: "banknote.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.teal)
                        .symbolEffect(.bounce, value: iconBounce)
                        .scaleEffect(iconBounce ? 1.05 : 0.95)
                        .animation(
                            .easeInOut(duration: 1.4).repeatForever(autoreverses: true),
                            value: iconBounce
                        )

                    Text("Stash Quest")
                        .font(.largeTitle.bold())

                    Text("Real money. Real savings. Solo or with your family.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 24)

                    Group {
                        if step == 0 {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Family name")
                                    .font(.headline)
                                TextField("Bradley's", text: $familyName)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(.familyName)
                                    .textInputAutocapitalization(.words)
                                    .autocorrectionDisabled()
                                    .focused($focusedField, equals: .familyName)
                                    .submitLabel(.continue)
                                    .accessibilityIdentifier("onboardingFamilyNameField")
                                    .onSubmit { advanceToStep(1) }
                                Text("Shows on Home as \"\(familyName) Stash Quest\"")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                        } else {
                            VStack(alignment: .leading, spacing: 16) {
                                Text(setupMode == .solo ? "About you" : "Add your family")
                                    .font(.headline)

                                Picker("Setup", selection: $setupMode) {
                                    ForEach(SetupMode.allCases, id: \.self) { mode in
                                        Text(mode.rawValue).tag(mode)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .onChange(of: setupMode) { _, mode in
                                    if mode == .solo {
                                        kidName = ""
                                        focusedField = .adultName
                                    }
                                }

                                TextField(setupMode == .solo ? "Your name" : "Grown-up name", text: $adultName)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(.name)
                                    .textInputAutocapitalization(.words)
                                    .autocorrectionDisabled()
                                    .focused($focusedField, equals: .adultName)
                                    .submitLabel(setupMode == .solo ? .done : .next)
                                    .accessibilityIdentifier("onboardingAdultNameField")
                                    .onSubmit {
                                        if setupMode == .solo {
                                            if canCompleteOnboarding { completeOnboarding() }
                                        } else {
                                            focusedField = .kidName
                                        }
                                    }

                                if setupMode == .family {
                                    TextField("Kid name", text: $kidName)
                                        .textFieldStyle(.roundedBorder)
                                        .textContentType(.name)
                                        .textInputAutocapitalization(.words)
                                        .autocorrectionDisabled()
                                        .focused($focusedField, equals: .kidName)
                                        .submitLabel(.done)
                                        .accessibilityIdentifier("onboardingKidNameField")
                                        .onSubmit {
                                            if canCompleteOnboarding {
                                                completeOnboarding()
                                            }
                                        }
                                    Text("Add more kids later from the You tab.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("You can add family members anytime from the You tab.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                    .animation(AppAnimations.smooth, value: step)

                    Button(step == 0 ? "Continue" : "Start saving") {
                        focusedField = nil
                        if step == 0 {
                            advanceToStep(1)
                        } else {
                            completeOnboarding()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)
                    .disabled(step == 1 && !canCompleteOnboarding)
                    .accessibilityIdentifier(step == 0 ? "onboardingContinueButton" : "onboardingStartButton")
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            }
            .scrollDismissesKeyboard(.interactively)
            .onAppear {
                focusedField = step == 0 ? .familyName : .adultName
                iconBounce = true
            }
            .onChange(of: step) { _, newStep in
                focusedField = newStep == 0 ? .familyName : .adultName
            }
            .alert("Couldn't save your profile", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "Please try again.")
            }
        }
    }

    private func advanceToStep(_ newStep: Int) {
        HapticFeedback.light()
        withAnimation(AppAnimations.smooth) {
            step = newStep
        }
        focusedField = newStep == 0 ? .familyName : .adultName
    }

    private var canCompleteOnboarding: Bool {
        let adultReady = !adultName.trimmingCharacters(in: .whitespaces).isEmpty
        switch setupMode {
        case .solo:
            return adultReady
        case .family:
            return adultReady && !kidName.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    private func completeOnboarding() {
        guard canCompleteOnboarding else { return }

        focusedField = nil

        settings.familyDisplayName = familyName.trimmingCharacters(in: .whitespaces).isEmpty
            ? "Bradley's"
            : familyName.trimmingCharacters(in: .whitespaces)

        let adult = Profile(
            name: adultName.trimmingCharacters(in: .whitespaces),
            kind: .adult,
            colorHex: ProfileColors.palette[0]
        )
        modelContext.insert(adult)

        if setupMode == .family {
            let kid = Profile(
                name: kidName.trimmingCharacters(in: .whitespaces),
                kind: .kid,
                colorHex: ProfileColors.palette[1]
            )
            modelContext.insert(kid)
        }

        settings.selectedProfileId = adult.id
        settings.hasCompletedOnboarding = true

        do {
            try modelContext.save()
            WidgetDataSync.updateFromContext(modelContext)
            HapticFeedback.success()
        } catch {
            modelContext.rollback()
            saveError = error.localizedDescription
        }
    }
}
