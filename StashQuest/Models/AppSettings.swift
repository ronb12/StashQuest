import Foundation
import SwiftData
import SwiftUI

enum AppearanceMode: String, Codable, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

@Model
final class AppSettings {
    var id: UUID
    var familyDisplayName: String
    var hasCompletedOnboarding: Bool
    var selectedProfileId: UUID?
    var remindersEnabled: Bool
    var reminderHour: Int
    var reminderMinute: Int
    var appearanceRaw: String?

    init(
        familyDisplayName: String = "Bradley's",
        hasCompletedOnboarding: Bool = false,
        selectedProfileId: UUID? = nil,
        remindersEnabled: Bool = false,
        reminderHour: Int = 9,
        reminderMinute: Int = 0,
        appearanceRaw: String? = AppearanceMode.system.rawValue
    ) {
        self.id = UUID()
        self.familyDisplayName = familyDisplayName
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.selectedProfileId = selectedProfileId
        self.remindersEnabled = remindersEnabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.appearanceRaw = appearanceRaw
    }

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw ?? "") ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }
}
