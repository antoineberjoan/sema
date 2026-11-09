// Une ligne d’agenda prête à afficher (titre, détail, ton, destination) : le hub et le bandeau la dessinent chacun à leur taille.
import SwiftUI
import MarketCore

struct AgendaLine: Identifiable {
    enum Tone { case move, release, quiet }
    enum Destination {
        case series(MarketSeries)
        case link(URL)
    }

    static let barWidth: CGFloat = 3
    private static let tintOpacity = 0.08
    private static let quietTintOpacity = 0.04
    private static let quietBarOpacity = 0.5
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

    func bar(accent: Color) -> Color {
        switch tone {
        case .move: accent
        case .release: Color.secondary
        case .quiet: Color.secondary.opacity(Self.quietBarOpacity)
        }
    }

    func tint(accent: Color) -> Color {
        tone == .move ? accent.opacity(Self.tintOpacity) : Color.primary.opacity(Self.quietTintOpacity)
    }

    /// Said when a day has no line; the FRED key is the only way to get releases.
    static func emptyText(hasFREDKey: Bool) -> String {
        hasFREDKey ? "Aucun mouvement inhabituel, publication ni communiqué ce jour."
            : "Aucun mouvement inhabituel ni communiqué ce jour. Connectez FRED dans Réglages, Sources, pour voir les publications."
    }
}
