import Foundation

extension Challenge {
    /// Number of checkboxes on the “challenge paper.” Ongoing challenges get 12 stamp slots.
    var checklistSlotCount: Int {
        switch id {
        case "adult-52-week": return 52
        case "kid-10-weeks": return 10
        case "adult-pantry-raid": return 5
        default:
            if let days = durationDays { return days }
            return 12
        }
    }

    var hasPaperChecklist: Bool {
        checklistSlotCount > 0
    }

    /// Empty slot icon (paper style).
    var checklistEmptyIcon: String {
        switch category {
        case .skip:
            return audience == .kid ? "star" : "circle"
        case .stash:
            return audience == .kid ? "banknote" : "dollarsign.circle"
        case .goal:
            return "flag"
        }
    }

    /// Marked-off icon.
    var checklistMarkedIcon: String {
        switch category {
        case .skip:
            return audience == .kid ? "star.fill" : "checkmark.circle.fill"
        case .stash:
            return audience == .kid ? "banknote.fill" : "dollarsign.circle.fill"
        case .goal:
            return "flag.fill"
        }
    }

    func checklistSlotLabel(index: Int) -> String {
        switch duration {
        case .oneDay:
            return "Done"
        case .weekend:
            return index == 0 ? "Sat" : "Sun"
        case .week:
            return ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][safe: index] ?? "Day \(index + 1)"
        case .tenWeeks:
            return "Wk \(index + 1)"
        case .month:
            return "D\(index + 1)"
        case .ongoing:
            if id == "adult-52-week" || id == "kid-10-weeks" {
                return "Wk \(index + 1)"
            }
            return "Stamp \(index + 1)"
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

enum ChallengeChecklistHelper {
    static func parseSlots(_ raw: String) -> Set<Int> {
        guard !raw.isEmpty else { return [] }
        return Set(raw.split(separator: ",").compactMap { Int($0) })
    }

    static func serializeSlots(_ slots: Set<Int>) -> String {
        slots.sorted().map(String.init).joined(separator: ",")
    }

    static func toggle(slot: Int, in active: ActiveChallenge) {
        var slots = parseSlots(active.checkedSlotsRaw)
        if slots.contains(slot) {
            slots.remove(slot)
        } else {
            slots.insert(slot)
        }
        active.checkedSlotsRaw = serializeSlots(slots)
    }

    static func progress(active: ActiveChallenge, challenge: Challenge) -> Double {
        let total = challenge.checklistSlotCount
        guard total > 0 else { return 0 }
        let checked = parseSlots(active.checkedSlotsRaw).count
        return min(1, Double(checked) / Double(total))
    }

    static func isFullyChecked(active: ActiveChallenge, challenge: Challenge) -> Bool {
        parseSlots(active.checkedSlotsRaw).count >= challenge.checklistSlotCount
    }
}
