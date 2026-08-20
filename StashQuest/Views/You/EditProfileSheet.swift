import SwiftUI

struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var profile: Profile

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $profile.name)
                    .textContentType(.name)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("editProfileNameField")

                Picker("Color", selection: $profile.colorHex) {
                    ForEach(ProfileColors.palette, id: \.self) { hex in
                        HStack {
                            Circle().fill(Color(hex: hex) ?? .gray).frame(width: 16, height: 16)
                            Text(hex)
                        }
                        .tag(hex)
                    }
                }

                Text(profile.kind.label)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .disabled(profile.name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .accessibilityIdentifier("editProfileDoneButton")
                }
            }
        }
        .presentationDetents([.medium])
    }
}
