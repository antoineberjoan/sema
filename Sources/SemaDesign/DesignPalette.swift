// The palettes a person can choose; the color roles that depend on the choice take one.
// fabriqué depuis tokens.json par sophos/outils/jetons.mjs ; ne pas modifier à la main (patron 1.1.0).

public enum DesignPalette: String, CaseIterable, Sendable {
    /// The brand palette, the default one.
    case brand = "brand"
    /// The graphite palette.
    case graphite = "graphite"
    /// The teal palette.
    case teal = "teal"
    /// The mint palette.
    case mint = "mint"
    /// The lavender palette.
    case lavender = "lavender"
    /// The sky palette.
    case sky = "sky"
    /// The polar palette.
    case polar = "polar"
}
