// The text roles as one modifier: a screen applies a whole role and never recomposes size, weight, leading and tracking.
// fabriqué depuis tokens.json par sophos/outils/jetons.mjs ; ne pas modifier à la main (patron 1.1.0).
import SwiftUI

public enum DesignTypeRole: CaseIterable, Sendable {
    case hero
    case title
    case figure
    case section
    case wordmark
    case lede
    case subheading
    case heading
    case body
    case label
    case small
    case caption
    case code
    case overline
    case tag
    case micro

    /// SwiftUI adds line spacing on top of the font's natural line height, about 1.2 times its size.
    private static let naturalLeading: CGFloat = 1.2

    private var metrics: (size: CGFloat, weight: Font.Weight, leading: CGFloat, tracking: Double) {
        switch self {
        case .hero: return (DesignType.heroSize, DesignType.heroWeight, DesignType.heroLeading, DesignType.heroTracking)
        case .title: return (DesignType.titleSize, DesignType.titleWeight, DesignType.titleLeading, DesignType.titleTracking)
        case .figure: return (DesignType.figureSize, DesignType.figureWeight, DesignType.figureLeading, DesignType.figureTracking)
        case .section: return (DesignType.sectionSize, DesignType.sectionWeight, DesignType.sectionLeading, DesignType.sectionTracking)
        case .wordmark: return (DesignType.wordmarkSize, DesignType.wordmarkWeight, DesignType.wordmarkLeading, DesignType.wordmarkTracking)
        case .lede: return (DesignType.ledeSize, DesignType.ledeWeight, DesignType.ledeLeading, DesignType.ledeTracking)
        case .subheading: return (DesignType.subheadingSize, DesignType.subheadingWeight, DesignType.subheadingLeading, DesignType.subheadingTracking)
        case .heading: return (DesignType.headingSize, DesignType.headingWeight, DesignType.headingLeading, DesignType.headingTracking)
        case .body: return (DesignType.bodySize, DesignType.bodyWeight, DesignType.bodySize * CGFloat(DesignType.bodyLeading), DesignType.bodyTracking)
        case .label: return (DesignType.labelSize, DesignType.labelWeight, DesignType.labelLeading, DesignType.labelTracking)
        case .small: return (DesignType.smallSize, DesignType.smallWeight, DesignType.smallLeading, DesignType.smallTracking)
        case .caption: return (DesignType.captionSize, DesignType.captionWeight, DesignType.captionLeading, DesignType.captionTracking)
        case .code: return (DesignType.codeSize, DesignType.codeWeight, DesignType.codeLeading, DesignType.codeTracking)
        case .overline: return (DesignType.overlineSize, DesignType.overlineWeight, DesignType.overlineLeading, DesignType.overlineTracking)
        case .tag: return (DesignType.tagSize, DesignType.tagWeight, DesignType.tagLeading, DesignType.tagTracking)
        case .micro: return (DesignType.microSize, DesignType.microWeight, DesignType.microLeading, DesignType.microTracking)
        }
    }

    private var isMonospaced: Bool { [DesignTypeRole.code].contains(self) }
    private var hasTabularDigits: Bool { [DesignTypeRole.hero, DesignTypeRole.figure].contains(self) }

    /// The role's font, in the system family. A monospaced role uses a monospaced design; a numeric role keeps one digit width.
    public var font: Font {
        let font = Font.system(size: metrics.size, weight: metrics.weight, design: isMonospaced ? .monospaced : .default)
        return hasTabularDigits ? font.monospacedDigit() : font
    }

    /// The tracking in points: the role's tracking is a fraction of its size.
    public var tracking: CGFloat { metrics.size * CGFloat(metrics.tracking) }

    /// The line spacing SwiftUI adds, so that the line height reaches the role's leading.
    public var lineSpacing: CGFloat { max(0, metrics.leading - metrics.size * Self.naturalLeading) }
}

extension View {
    /// Applies a whole text role.
    public func typeRole(_ role: DesignTypeRole) -> some View {
        font(role.font).tracking(role.tracking).lineSpacing(role.lineSpacing)
    }
}
