import Foundation
import SwiftData

@Model
final class AppSettings {
    var id: UUID
    var familyDisplayName: String
    var hasCompletedOnboarding: Bool
    var selectedProfileId: UUID?
    var remindersEnabled: Bool
    var reminderHour: Int
    var reminderMinute: Int

    init(
        familyDisplayName: String = "Bradley's",
        hasCompletedOnboarding: Bool = false,
        selectedProfileId: UUID? = nil,
        remindersEnabled: Bool = false,
        reminderHour: Int = 9,
        reminderMinute: Int = 0
    ) {
        self.id = UUID()
        self.familyDisplayName = familyDisplayName
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.selectedProfileId = selectedProfileId
        self.remindersEnabled = remindersEnabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
    }
}
