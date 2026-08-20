import Foundation
import SwiftData

enum SaveKind: String, Codable, CaseIterable {
    case skipped
    case stashed
    case spent
    case gave

    var label: String {
        switch self {
        case .skipped: return "Skip"
        case .stashed: return "Stash"
        case .spent: return "Spent"
        case .gave: return "Give"
        }
    }

    var verb: String {
        switch self {
        case .skipped: return "kept"
        case .stashed: return "stashed"
        case .spent: return "spent"
        case .gave: return "gave"
        }
    }

    var reducesVault: Bool {
        self == .spent || self == .gave
    }

    var notePlaceholder: String {
        switch self {
        case .skipped: return "What did you skip?"
        case .stashed: return "What did you stash?"
        case .spent: return "What did you buy from savings?"
        case .gave: return "Who or what did you give to?"
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
    var isParentMatch: Bool?

    init(
        profileId: UUID,
        amount: Double,
        kind: SaveKind,
        date: Date = Date(),
        note: String = "",
        challengeId: String? = nil,
        matchedFromEntryId: UUID? = nil,
        isParentMatch: Bool? = false
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
        kind.reducesVault ? -abs(amount) : abs(amount)
    }
}
