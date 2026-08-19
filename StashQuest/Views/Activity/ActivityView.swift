import SwiftUI
import SwiftData

struct ActivityView: View {
    @Bindable var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]
    @Query(sort: \SaveEntry.date, order: .reverse) private var entries: [SaveEntry]

    @State private var filterProfileId: UUID?

    private var filteredEntries: [SaveEntry] {
        guard let filterProfileId else { return entries }
        return entries.filter { $0.profileId == filterProfileId }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "Everyone", isSelected: filterProfileId == nil) {
                            filterProfileId = nil
                        }
                        ForEach(profiles, id: \.id) { profile in
                            FilterChip(title: profile.name, isSelected: filterProfileId == profile.id) {
                                filterProfileId = profile.id
                            }
                        }
                    }
                    .padding()
                }

                if filteredEntries.isEmpty {
                    ContentUnavailableView("No activity yet", systemImage: "tray", description: Text("Log a skip or stash to see it here."))
                } else {
                    List {
                        ForEach(filteredEntries, id: \.id) { entry in
                            ActivityRow(entry: entry, profile: profiles.first { $0.id == entry.profileId })
                        }
                        .onDelete(perform: deleteEntries)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Activity")
        }
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            let entry = filteredEntries[index]
            modelContext.delete(entry)
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.teal.opacity(0.25) : Color.secondary.opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct ActivityRow: View {
    let entry: SaveEntry
    let profile: Profile?

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(profile?.color ?? .gray)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(profile?.name ?? "Unknown")
                        .font(.subheadline.bold())
                    Text(entry.kind.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let challengeId = entry.challengeId,
                   let challenge = ChallengeCatalog.challenge(id: challengeId) {
                    Text(challenge.name)
                        .font(.caption2)
                        .foregroundStyle(.teal)
                }
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(SavingsCalculator.formatCurrency(entry.signedAmount))
                .font(.subheadline.bold())
                .foregroundStyle(entry.kind == .gave ? .red : .primary)
        }
        .padding(.vertical, 4)
    }
}
