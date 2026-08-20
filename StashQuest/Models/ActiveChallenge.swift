import Foundation
import SwiftData

enum ChallengeStatus: String, Codable {
    case active
    case completed
    case paused
}

@Model
final class ActiveChallenge {
    var id: UUID
    var profileId: UUID
    var challengeId: String
    var startedAt: Date
    var targetAmount: Double?
    var statusRaw: String
    var checkedSlotsRaw: String

    init(profileId: UUID, challengeId: String, targetAmount: Double? = nil) {
        self.id = UUID()
        self.profileId = profileId
        self.challengeId = challengeId
        self.startedAt = Date()
        self.targetAmount = targetAmount
        self.statusRaw = ChallengeStatus.active.rawValue
        self.checkedSlotsRaw = ""
    }

    var status: ChallengeStatus {
        get { ChallengeStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    var checkedSlots: Set<Int> {
        get { ChallengeChecklistHelper.parseSlots(checkedSlotsRaw) }
        set { checkedSlotsRaw = ChallengeChecklistHelper.serializeSlots(newValue) }
    }
}

@Model
final class CompletedStamp {
    var id: UUID
    var profileId: UUID
    var challengeId: String
    var completedAt: Date

    init(profileId: UUID, challengeId: String, completedAt: Date = Date()) {
        self.id = UUID()
        self.profileId = profileId
        self.challengeId = challengeId
        self.completedAt = completedAt
    }
}
