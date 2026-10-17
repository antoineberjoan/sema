// Résout le mode système, clair ou sombre de manière commune à SwiftUI et AppKit.
import AppKit
import SwiftUI

enum SemaAppearance: String, CaseIterable, Identifiable, Sendable {
    case system, light, dark
    var id: String { rawValue }
    var title: String {
        switch self { case .system: "Système"; case .light: "Clair"; case .dark: "Sombre" }
    }
    var colorScheme: ColorScheme? {
        switch self { case .system: nil; case .light: .light; case .dark: .dark }
    }
    @MainActor var nativeAppearance: NSAppearance? {
        switch self {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }
}
