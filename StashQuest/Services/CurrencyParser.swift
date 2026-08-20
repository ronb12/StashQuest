import Foundation
import SwiftData

enum CurrencyParser {
    static func parse(_ text: String) -> Double? {
        let cleaned = text
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, let value = Double(cleaned), value > 0 else { return nil }
        return value
    }

    static func formatEntry(_ amount: Double) -> String {
        String(format: "%.2f", amount)
    }
}

enum StampHelper {
    static func awardStampIfNeeded(
        context: ModelContext,
        profileId: UUID,
        challengeId: String,
        existingStamps: [CompletedStamp]
    ) {
        guard !existingStamps.contains(where: { $0.profileId == profileId && $0.challengeId == challengeId }) else {
            return
        }
        context.insert(CompletedStamp(profileId: profileId, challengeId: challengeId))
    }
}
