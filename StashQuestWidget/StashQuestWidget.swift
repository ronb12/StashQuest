import WidgetKit
import SwiftUI

struct StashQuestWidgetEntry: TimelineEntry {
    let date: Date
    let familyName: String
    let familyTotal: Double
    let topStreak: Int
    let topStreakName: String
}

struct StashQuestWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> StashQuestWidgetEntry {
        StashQuestWidgetEntry(date: Date(), familyName: "Family", familyTotal: 125, topStreak: 3, topStreakName: "Alex")
    }

    func getSnapshot(in context: Context, completion: @escaping (StashQuestWidgetEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StashQuestWidgetEntry>) -> Void) {
        let entry = loadEntry()
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadEntry() -> StashQuestWidgetEntry {
        let defaults = UserDefaults(suiteName: "group.com.bradley.stashquest")
        let familyName = defaults?.string(forKey: "widget.familyName") ?? "Family"
        let familyTotal = defaults?.double(forKey: "widget.familyTotal") ?? 0
        let topStreak = defaults?.integer(forKey: "widget.topStreak") ?? 0
        let topStreakName = defaults?.string(forKey: "widget.topStreakName") ?? "Family"
        return StashQuestWidgetEntry(
            date: Date(),
            familyName: familyName,
            familyTotal: familyTotal,
            topStreak: topStreak,
            topStreakName: topStreakName
        )
    }
}

struct StashQuestWidgetView: View {
    let entry: StashQuestWidgetEntry

    private var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: entry.familyTotal)) ?? "$0.00"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(entry.familyName) Stash Quest")
                .font(.caption.bold())
                .foregroundStyle(.teal)
            Text(formattedTotal)
                .font(.title2.bold())
            if entry.topStreak > 0 {
                Label("\(entry.topStreakName): \(entry.topStreak) day streak", systemImage: "flame.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            } else {
                Text("Log money to grow your vault")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct StashQuestWidget: Widget {
    let kind = "StashQuestWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StashQuestWidgetProvider()) { entry in
            StashQuestWidgetView(entry: entry)
        }
        .configurationDisplayName("Stash Quest")
        .description("Family total and top savings streak.")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}
