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

    /// Ce que la ligne dit sous son titre : le chiffre ou la source, sinon son genre.
    var subtitle: String { detail.isEmpty ? kind : detail }

    func bar(palette: DesignPalette) -> Color {
        switch tone {
        case .move: DesignColor.accent(palette)
        case .release: DesignColor.textMuted
        case .quiet: DesignColor.ruleHover
        }
    }

    /// Le même remplissage sur une page opaque et sur une carte de verre : la teinte discrète est l’opacité « verre au repos » de la couleur du texte.
    func tint(palette: DesignPalette) -> Color {
        tone == .move ? DesignColor.selection(palette) : DesignColor.text.opacity(DesignOpacity.glassRest)
    }

    /// Dit quand un jour n’a aucune ligne ; la clé FRED est le seul moyen d’obtenir des publications.
    static func emptyText(hasFREDKey: Bool) -> String {
        hasFREDKey ? "Aucun mouvement inhabituel, publication ni communiqué ce jour."
            : "Aucun mouvement inhabituel ni communiqué ce jour. Connectez FRED dans Réglages, Sources, pour voir les publications."
    }
}
