import Foundation
import SwiftUI
import SwiftData
import UIKit

enum ProfileKind: String, Codable, CaseIterable {
    case adult
    case kid

    var label: String {
        switch self {
        case .adult: return "Grown-up"
        case .kid: return "Kid"
        }
    }
}

@Model
final class Profile {
    var id: UUID
    var name: String
    var kindRaw: String
    var colorHex: String
    var createdAt: Date
    var lastLogKindRaw: String?

    init(name: String, kind: ProfileKind, colorHex: String) {
        self.id = UUID()
        self.name = name
        self.kindRaw = kind.rawValue
        self.colorHex = colorHex
        self.createdAt = Date()
        self.lastLogKindRaw = SaveKind.stashed.rawValue
    }

    var kind: ProfileKind {
        get { ProfileKind(rawValue: kindRaw) ?? .adult }
        set { kindRaw = newValue.rawValue }
    }

    var lastLogKind: SaveKind {
        get { SaveKind(rawValue: lastLogKindRaw ?? "") ?? .stashed }
        set { lastLogKindRaw = newValue.rawValue }
    }

    var color: Color {
        Color(hex: colorHex) ?? .accentColor
    }
}

extension Color {
    init?(hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }
        guard cleaned.count == 6, let value = UInt64(cleaned, radix: 16) else { return nil }
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return "4A90D9"
        }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "%02X%02X%02X", r, g, b)
    }
}

enum ProfileColors {
    static let palette = ["4A90D9", "E85D75", "50C878", "F5A623", "9B59B6", "1ABC9C", "E67E22", "3498DB"]
}
