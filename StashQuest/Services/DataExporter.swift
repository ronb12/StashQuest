import Foundation
import SwiftData

enum DataExporter {
    struct ExportPayload: Codable {
        let exportedAt: Date
        let familyName: String
        let profiles: [ProfileExport]
        let entries: [EntryExport]
        let activeChallenges: [ChallengeExport]
        let stamps: [StampExport]
    }

    struct ProfileExport: Codable {
        let id: UUID
        let name: String
        let kind: String
        let colorHex: String
        let createdAt: Date
    }

    struct EntryExport: Codable {
        let id: UUID
        let profileId: UUID
        let amount: Double
        let kind: String
        let date: Date
        let note: String
        let challengeId: String?
        let isParentMatch: Bool
    }

    struct ChallengeExport: Codable {
        let id: UUID
        let profileId: UUID
        let challengeId: String
        let status: String
        let startedAt: Date
        let targetAmount: Double?
    }

    struct StampExport: Codable {
        let profileId: UUID
        let challengeId: String
        let completedAt: Date
    }

    static func makeJSON(context: ModelContext, settings: AppSettings) throws -> Data {
        let profiles = try context.fetch(FetchDescriptor<Profile>(sortBy: [SortDescriptor(\.createdAt)]))
        let entries = try context.fetch(FetchDescriptor<SaveEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)]))
        let active = try context.fetch(FetchDescriptor<ActiveChallenge>())
        let stamps = try context.fetch(FetchDescriptor<CompletedStamp>(sortBy: [SortDescriptor(\.completedAt, order: .reverse)]))

        let payload = ExportPayload(
            exportedAt: Date(),
            familyName: settings.familyDisplayName,
            profiles: profiles.map {
                ProfileExport(id: $0.id, name: $0.name, kind: $0.kindRaw, colorHex: $0.colorHex, createdAt: $0.createdAt)
            },
            entries: entries.map {
                EntryExport(
                    id: $0.id,
                    profileId: $0.profileId,
                    amount: $0.amount,
                    kind: $0.kindRaw,
                    date: $0.date,
                    note: $0.note,
                    challengeId: $0.challengeId,
                    isParentMatch: $0.isParentMatch ?? false
                )
            },
            activeChallenges: active.map {
                ChallengeExport(
                    id: $0.id,
                    profileId: $0.profileId,
                    challengeId: $0.challengeId,
                    status: $0.statusRaw,
                    startedAt: $0.startedAt,
                    targetAmount: $0.targetAmount
                )
            },
            stamps: stamps.map {
                StampExport(profileId: $0.profileId, challengeId: $0.challengeId, completedAt: $0.completedAt)
            }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(payload)
    }

    static func writeExportFile(context: ModelContext, settings: AppSettings) throws -> URL {
        let data = try makeJSON(context: context, settings: settings)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        let stamp = formatter.string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("StashQuest-export-\(stamp).json")
        try data.write(to: url, options: .atomic)
        return url
    }
}
