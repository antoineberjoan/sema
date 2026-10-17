// Six palettes et leurs accents adaptés au mode clair ou sombre.
import AppKit
import SwiftUI

enum SemaPalette: String, CaseIterable, Identifiable, Sendable {
    case graphite, teal, mint, lavender, sky, polar
    var id: String { rawValue }
    var title: String {
        switch self {
        case .teal: "Sarcelle"
        case .mint: "Menthe"
        case .lavender: "Lavande"
        case .sky: "Bleu ciel"
        case .polar: "Bleu polaire"
        case .graphite: "Graphite"
        }
    }
    var swatches: [UInt32] {
        switch self {
        case .teal: [0x265073, 0x2D9596, 0x9AD0C2, 0xECF4D6]
        case .mint: [0x8EC3B0, 0x9ED5C5, 0xBCEAD5, 0xDEF5E5]
        case .lavender: [0xD0A2F7, 0xDCBFFF, 0xE5D4FF, 0xF1EAFF]
        case .sky: [0x00A9FF, 0x89CFF3, 0xA0E9FF, 0xCDF5FD]
        case .polar: [0x053F56, 0x21A5EC, 0x90D2F5, 0xF2F3F7]
        case .graphite: [0x333333, 0x707070, 0xD6D6D6, 0xFAFAFA]
        }
    }
    private var lightAccent: UInt32 {
        switch self {
        case .teal: 0x1F6F73
        case .mint: 0x32755E
        case .lavender: 0x78499E
        case .sky: 0x007AB8
        case .polar: 0x097BAF
        case .graphite: 0x474747
        }
    }
    private var darkAccent: UInt32 {
        switch self {
        case .teal: 0x9AD0C2
        case .mint: 0x9ED5C5
        case .lavender: 0xD0A2F7
        case .sky: 0x89CFF3
        case .polar: 0x90D2F5
        case .graphite: 0xD6D6D6
        }
    }
    var accent: Color {
        Color(nsColor: NSColor(name: "SemaAccent-" + rawValue) { appearance in
            Self.nsColor(appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? darkAccent : lightAccent)
        })
    }
    // Native selected controls use white labels, so pastel swatches need a deeper tint.
    var controlAccent: Color { Color(nsColor: Self.nsColor(lightAccent)) }
    // The signature is the one coloured editorial surface in the Graphite ribbon.
    var signatureAccent: Color { self == .graphite ? Self.swatch(0x355A80) : controlAccent }
    var glassTint: Color {
        switch self {
        case .graphite: .clear
        case .teal: Self.swatch(0x2D9596)
        case .mint: Self.swatch(0x8EC3B0)
        case .lavender: Self.swatch(0xD0A2F7)
        case .sky: Self.swatch(0x00A9FF)
        case .polar: Self.swatch(0x21A5EC)
        }
    }
    static func swatch(_ hex: UInt32) -> Color { Color(nsColor: nsColor(hex)) }
    private static func nsColor(_ hex: UInt32) -> NSColor {
        NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255,
                green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: 1)
    }
}
