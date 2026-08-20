import SwiftUI
import SwiftData

struct ChallengePaperChecklistView: View {
    @Environment(\.modelContext) private var modelContext
    let challenge: Challenge
    @Bindable var active: ActiveChallenge
    var accent: Color = .teal
    var onAllChecked: (() -> Void)? = nil

    private var checked: Set<Int> {
        active.checkedSlots
    }

    private var columns: [GridItem] {
        let count = challenge.checklistSlotCount
        if count <= 7 {
            return Array(repeating: GridItem(.flexible(), spacing: 10), count: count)
        }
        if count <= 12 {
            return Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)
        }
        return Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Challenge paper")
                    .font(.headline)
                Spacer()
                Text("\(checked.count)/\(challenge.checklistSlotCount)")
                    .font(.caption.bold())
                    .foregroundStyle(accent)
            }

            ProgressView(value: ChallengeChecklistHelper.progress(active: active, challenge: challenge))
                .tint(accent)
                .animation(AppAnimations.smooth, value: checked.count)

            Text("Tap each icon when you finish that day or step — just like checking off paper.")
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<challenge.checklistSlotCount, id: \.self) { index in
                    ChecklistSlotButton(
                        index: index,
                        label: challenge.checklistSlotLabel(index: index),
                        isMarked: checked.contains(index),
                        emptyIcon: challenge.checklistEmptyIcon,
                        markedIcon: challenge.checklistMarkedIcon,
                        accent: accent
                    ) {
                        toggleSlot(index)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private func toggleSlot(_ index: Int) {
        HapticFeedback.light()
        withAnimation(AppAnimations.snappy) {
            ChallengeChecklistHelper.toggle(slot: index, in: active)
        }
        if ChallengeChecklistHelper.isFullyChecked(active: active, challenge: challenge) {
            HapticFeedback.success()
            onAllChecked?()
        }
        modelContext.commitSave()
    }
}

private struct ChecklistSlotButton: View {
    let index: Int
    let label: String
    let isMarked: Bool
    let emptyIcon: String
    let markedIcon: String
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isMarked ? markedIcon : emptyIcon)
                    .font(.title2)
                    .foregroundStyle(isMarked ? accent : Color.secondary)
                    .scaleEffect(isMarked ? 1.08 : 1)
                    .animation(AppAnimations.snappy, value: isMarked)

                Text(label)
                    .font(.caption2)
                    .foregroundStyle(isMarked ? .primary : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                isMarked ? accent.opacity(0.12) : Color.secondary.opacity(0.06),
                in: RoundedRectangle(cornerRadius: 10)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isMarked ? accent.opacity(0.35) : .clear, lineWidth: 1)
            }
        }
        .buttonStyle(PopButtonStyle(scale: 0.92))
        .accessibilityLabel(isMarked ? "\(label), checked" : "\(label), not checked")
    }
}
