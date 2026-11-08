// Rôles typographiques de Typographie 1.1 : chaque rôle réunit taille, graisse, interligne et approche, en police système.
import SwiftUI

enum TypeRole {
    case hero, title, figure, section, subheading, heading, body, lede, label, small, caption, overline, tag, micro, wordmark

    /// SwiftUI adds line spacing on top of the font's natural line height, about 1.2 times its size.
    private static let naturalLeading: CGFloat = 1.2

    private var metrics: (size: CGFloat, weight: Font.Weight, leading: CGFloat, tracking: CGFloat) {
        switch self {
        case .hero: (44, .semibold, 46, -0.03)
        case .title: (28, .medium, 34, -0.02)
        case .figure: (24, .semibold, 28, -0.02)
        case .section: (19, .medium, 24, -0.01)
        case .subheading: (16, .medium, 24, -0.01)
        case .heading: (15, .medium, 20, 0)
        case .body: (15, .regular, 26.25, 0)
        case .lede: (17, .regular, 28, -0.01)
        case .label: (14, .medium, 20, -0.01)
        case .small: (13, .regular, 18, 0)
        case .caption: (13, .regular, 18, 0.01)
        case .overline: (12, .medium, 18, 0.05)
        case .tag: (12, .regular, 16, 0)
        case .micro: (11.52, .regular, 14, 0.01)
        case .wordmark: (17, .semibold, 20, -0.03)
        }
    }

    /// Hero and figure values change and line up, so their digits share one width.
    var font: Font {
        let font = Font.system(size: metrics.size, weight: metrics.weight)
        return self == .hero || self == .figure ? font.monospacedDigit() : font
    }
    var tracking: CGFloat { metrics.size * metrics.tracking }
    var lineSpacing: CGFloat { max(0, metrics.leading - metrics.size * Self.naturalLeading) }
}

extension View {
    /// Applies a whole role; a screen never recomposes size, weight, leading and tracking by hand.
    func typeRole(_ role: TypeRole) -> some View {
        font(role.font).tracking(role.tracking).lineSpacing(role.lineSpacing)
    }
}
