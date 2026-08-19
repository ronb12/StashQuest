import Foundation
import SwiftData

enum SaveKind: String, Codable, CaseIterable {
    case skipped
    case stashed
    case gave

    var label: String {
        switch self {
        case .skipped: return "Skipped"
        case .stashed: return "Stashed"
        case .gave: return "Gave"
        }
    }

    var verb: String {
        switch self {
        case .skipped: return "kept"
        case .stashed: return "stashed"
        case .gave: return "gave"
        }
    }
}

@Model
final class SaveEntry {
    var id: UUID
    var profileId: UUID
    var amount: Double
    var kindRaw: String
    var date: Date
    var note: String
    var challengeId: String?
    var matchedFromEntryId: UUID?
    var isParentMatch: Bool

    init(
        profileId: UUID,
        amount: Double,
        kind: SaveKind,
        date: Date = Date(),
        note: String = "",
        challengeId: String? = nil,
        matchedFromEntryId: UUID? = nil,
        isParentMatch: Bool = false
    ) {
        self.id = UUID()
        self.profileId = profileId
        self.amount = amount
        self.kindRaw = kind.rawValue
        self.date = date
        self.note = note
        self.challengeId = challengeId
        self.matchedFromEntryId = matchedFromEntryId
        self.isParentMatch = isParentMatch
    }

    var kind: SaveKind {
        get { SaveKind(rawValue: kindRaw) ?? .stashed }
        set { kindRaw = newValue.rawValue }
    }

    var signedAmount: Double {
        kind == .gave ? -abs(amount) : abs(amount)
    }
}
