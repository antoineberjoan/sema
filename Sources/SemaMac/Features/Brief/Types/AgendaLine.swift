// Une ligne d’agenda prête à afficher (titre, détail, ton, destination) : le hub et le bandeau la dessinent chacun à leur taille.
import SemaDesign
import SwiftUI
import MarketCore

struct AgendaLine: Identifiable {
    enum Tone { case move, release, quiet }
    enum Destination {
        case series(MarketSeries)
        case link(URL)
    }

    private static let releaseURL = "https://fred.stlouisfed.org/release?rid="

    let id: String
    let kind: String
    let title: String
    let detail: String
    let tone: Tone
    let destination: Destination?

    @MainActor init(_ item: AgendaItem, store: AppStore) {
        id = item.id
        switch item {
        case .move(let move):
            kind = "Mouvement inhabituel"
            title = MarketFormat.name(store.displayedSeries(move.series)) + " · " + MarketFormat.sessionChange(move.change, series: move.series)
            detail = move.ratio.map { MarketFormat.ratio($0) + " l’habituel" } ?? ""
            tone = .move
            destination = .series(move.series)
        case .release(let release):
            kind = "Publication"
            title = release.name
            detail = "Calendrier FRED"
            tone = .release
            destination = URL(string: Self.releaseURL + release.releaseID).map(Destination.link)
        case .pressRelease(let release):
            kind = "Communiqué · " + release.feed.title
            title = release.title
            detail = ""
            tone = .quiet
            destination = Destination.link(release.link)
        case .headline(let headline):
            kind = "Titre"
            title = headline.title
            detail = headline.publisher
            tone = .quiet
            destination = Destination.link(headline.link)
        }
    }

    /// What the line says under its title: the figure or source, else its kind.
    var subtitle: String { detail.isEmpty ? kind : detail }

    func bar(palette: DesignPalette) -> Color {
        switch tone {
        case .move: DesignColor.accent(palette)
        case .release: DesignColor.textMuted
        case .quiet: DesignColor.ruleHover
        }
    }

    /// The same fill on an opaque page and on a glass card: the quiet tint is the glass-rest opacity of the text color.
    func tint(palette: DesignPalette) -> Color {
        tone == .move ? DesignColor.selection(palette) : DesignColor.text.opacity(DesignOpacity.glassRest)
    }

    /// Said when a day has no line; the FRED key is the only way to get releases.
    static func emptyText(hasFREDKey: Bool) -> String {
        hasFREDKey ? "Aucun mouvement inhabituel, publication ni communiqué ce jour."
            : "Aucun mouvement inhabituel ni communiqué ce jour. Connectez FRED dans Réglages, Sources, pour voir les publications."
    }
}
