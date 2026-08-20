import SwiftUI

struct LegalDocumentView: View {
    enum Document {
        case privacyPolicy
        case termsOfService
        case support

        var title: String {
            switch self {
            case .privacyPolicy: return "Privacy Policy"
            case .termsOfService: return "Terms of Service"
            case .support: return "Support"
            }
        }

        var sections: [(title: String, body: String)] {
            switch self {
            case .privacyPolicy: return LegalDocuments.privacyPolicySections
            case .termsOfService: return LegalDocuments.termsOfServiceSections
            case .support: return LegalDocuments.supportSections
            }
        }
    }

    let document: Document

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(LegalDocuments.appName)
                        .font(.headline)
                    Text("Last updated: \(LegalDocuments.lastUpdated)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ForEach(Array(document.sections.enumerated()), id: \.offset) { _, section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.title)
                            .font(.title3.bold())
                        Text(section.body)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if document == .support {
                    Link(destination: URL(string: "mailto:\(LegalDocuments.contactEmail)")!) {
                        Label("Email \(LegalDocuments.contactEmail)", systemImage: "envelope.fill")
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
