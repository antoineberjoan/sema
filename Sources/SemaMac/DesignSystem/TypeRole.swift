// Rôles typographiques : chaque rôle lit sa taille, sa graisse, son interligne et son approche dans les jetons, en police système.
import SemaDesign
import SwiftUI

enum TypeRole {
    case hero, title, figure, section, subheading, heading, body, lede, label, small, caption, overline, tag, micro, wordmark

    /// SwiftUI adds line spacing on top of the font's natural line height, about 1.2 times its size.
    private static let naturalLeading: CGFloat = 1.2

    private typealias Metrics = (size: CGFloat, weight: Font.Weight, leading: CGFloat, tracking: CGFloat)

    private static func make(_ size: CGFloat, _ weight: Font.Weight, leading: CGFloat, tracking: Double) -> Metrics {
        (size, weight, leading, CGFloat(tracking))
    }

    private var metrics: Metrics {
        switch self {
        case .hero: Self.make(DesignType.heroSize, DesignType.heroWeight, leading: DesignType.heroLeading, tracking: DesignType.heroTracking)
        case .title: Self.make(DesignType.titleSize, DesignType.titleWeight, leading: DesignType.titleLeading, tracking: DesignType.titleTracking)
        case .figure: Self.make(DesignType.figureSize, DesignType.figureWeight, leading: DesignType.figureLeading, tracking: DesignType.figureTracking)
        case .section: Self.make(DesignType.sectionSize, DesignType.sectionWeight, leading: DesignType.sectionLeading, tracking: DesignType.sectionTracking)
        case .subheading: Self.make(DesignType.subheadingSize, DesignType.subheadingWeight, leading: DesignType.subheadingLeading, tracking: DesignType.subheadingTracking)
        case .heading: Self.make(DesignType.headingSize, DesignType.headingWeight, leading: DesignType.headingLeading, tracking: DesignType.headingTracking)
        // The body leading is a ratio of its size, not points.
        case .body: Self.make(DesignType.bodySize, DesignType.bodyWeight, leading: DesignType.bodySize * CGFloat(DesignType.bodyLeading), tracking: DesignType.bodyTracking)
        case .lede: Self.make(DesignType.ledeSize, DesignType.ledeWeight, leading: DesignType.ledeLeading, tracking: DesignType.ledeTracking)
        case .label: Self.make(DesignType.labelSize, DesignType.labelWeight, leading: DesignType.labelLeading, tracking: DesignType.labelTracking)
        case .small: Self.make(DesignType.smallSize, DesignType.smallWeight, leading: DesignType.smallLeading, tracking: DesignType.smallTracking)
        case .caption: Self.make(DesignType.captionSize, DesignType.captionWeight, leading: DesignType.captionLeading, tracking: DesignType.captionTracking)
        case .overline: Self.make(DesignType.overlineSize, DesignType.overlineWeight, leading: DesignType.overlineLeading, tracking: DesignType.overlineTracking)
        case .tag: Self.make(DesignType.tagSize, DesignType.tagWeight, leading: DesignType.tagLeading, tracking: DesignType.tagTracking)
        case .micro: Self.make(DesignType.microSize, DesignType.microWeight, leading: DesignType.microLeading, tracking: DesignType.microTracking)
        case .wordmark: Self.make(DesignType.wordmarkSize, DesignType.wordmarkWeight, leading: DesignType.wordmarkLeading, tracking: DesignType.wordmarkTracking)
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
