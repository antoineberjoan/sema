// Fige les sept noms de palette que le fichier des préférences enregistre, et ce que chaque palette donne à l'accent, au contrôle et au verre.
import AppKit
import Foundation
import SemaDesign
import SwiftUI
import Testing

struct PaletteTests {
    private static let expected: [(palette: DesignPalette, accentLight: String, accentDark: String, glass: String)] = [
        (.brand, "1F6F73", "7CC2C0", "1F6F73"),
        (.graphite, "474747", "D6D6D6", "707070"),
        (.teal, "1F6F73", "9AD0C2", "2D9596"),
        (.mint, "32755E", "9ED5C5", "8EC3B0"),
        (.lavender, "78499E", "D0A2F7", "D0A2F7"),
        (.sky, "097AB6", "89CFF3", "00A9FF"),
        (.polar, "097BAF", "90D2F5", "21A5EC")
    ]

    private func hex(_ color: Color, dark: Bool) throws -> String {
        let appearance = try #require(NSAppearance(named: dark ? .darkAqua : .aqua))
        var result = ""
        appearance.performAsCurrentDrawingAppearance {
            if let rgb = NSColor(color).usingColorSpace(.sRGB) {
                result = String(format: "%02X%02X%02X", Int((rgb.redComponent * 255).rounded()),
                                Int((rgb.greenComponent * 255).rounded()), Int((rgb.blueComponent * 255).rounded()))
            }
        }
        return result
    }

    @Test func paletteNamesAreThePersistedThemeIDs() {
        #expect(DesignPalette.allCases.map(\.rawValue) == ["brand", "graphite", "teal", "mint", "lavender", "sky", "polar"])
        #expect(DesignPalette.allCases == Self.expected.map(\.palette))
    }

    @Test func eachPaletteGivesItsAccentInLightAndDark() throws {
        for row in Self.expected {
            #expect(try hex(DesignColor.accent(row.palette), dark: false) == row.accentLight)
            #expect(try hex(DesignColor.accent(row.palette), dark: true) == row.accentDark)
        }
    }

    @Test func controlAccentIsAlwaysTheLightAccent() throws {
        for row in Self.expected {
            #expect(try hex(DesignColor.accentControl(row.palette), dark: false) == row.accentLight)
            #expect(try hex(DesignColor.accentControl(row.palette), dark: true) == row.accentLight)
        }
    }

    @Test func eachPaletteGivesItsGlassTint() throws {
        for row in Self.expected {
            #expect(try hex(DesignColor.glassTint(row.palette), dark: false) == row.glass)
        }
    }
}
