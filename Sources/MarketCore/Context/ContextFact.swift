// Fait numéroté d’une séance, seul matériau qu’une phrase de synthèse a le droit de citer.
import Foundation

public struct ContextFact: Equatable, Identifiable, Sendable {
    public enum Kind: String, Sendable { case move, peer, release, pressRelease, headline }

    /// Number of facts of each part, the same as the inspector shows.
    static let peerLimit = 6, releaseLimit = 6, pressLimit = 4, headlineLimit = 5

    public let id: String
    public let kind: Kind
    /// Short name of the source of the fact; its digits (« S&P 500 ») are names, never claims.
    public let label: String
    /// Sentence given to the writer, with the figures shown in sema.
    public let text: String
    public let direction: AlertDirection?
    public let link: URL?

    public init(id: String, kind: Kind, label: String, text: String, direction: AlertDirection? = nil, link: URL? = nil) {
        self.id = id; self.kind = kind; self.label = label; self.text = text; self.direction = direction; self.link = link
    }

    /// Numbered facts of the session of `series`: its own move first, then the parts of `context`.
    public static func facts(for series: MarketSeries, context: DayContext, name: (MarketSeries) -> String) -> [ContextFact] {
        var drafts: [(Kind, String, String, AlertDirection?, URL?)] = []
        if let move = PeerMove.moves(on: context.day, among: [series], excluding: "").first {
            drafts.append((.move, name(series), "\(name(series)) : \(change(move)) sur la séance du \(longDate(context.day))\(usual(move)).",
                           direction(move.change), nil))
        }
        for peer in context.peers.prefix(peerLimit) {
            drafts.append((.peer, name(peer.series), "\(name(peer.series)) : \(change(peer)) le même jour\(usual(peer)).", direction(peer.change), nil))
        }
        for release in context.releases.prefix(releaseLimit) {
            drafts.append((.release, release.name, "Publication inscrite au calendrier ce jour : \(release.name).", nil, nil))
        }
        for release in context.pressReleases.prefix(pressLimit) {
            drafts.append((.pressRelease, release.feed.title, "Communiqué \(release.feed.title) : « \(release.title) ».", nil, release.link))
        }
        for headline in context.headlines.prefix(headlineLimit) {
            drafts.append((.headline, headline.publisher, "Titre publié par \(headline.publisher) : « \(headline.title) ».", nil, headline.link))
        }
        return drafts.enumerated().map { index, draft in
            ContextFact(id: "f\(index + 1)", kind: draft.0, label: draft.1, text: draft.2, direction: draft.3, link: draft.4)
        }
    }

    /// Date of a session in French, for example « 5 novembre 2026 », on the UTC calendar used by every source.
    static func longDate(_ day: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .french
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: day)
    }

    private static func direction(_ change: Decimal) -> AlertDirection? { change > 0 ? .rise : change < 0 ? .fall : nil }

    private static func change(_ move: PeerMove) -> String {
        let points = move.series.unit == .percent
        let sign = move.change > 0 ? "+" : move.change < 0 ? "−" : ""
        return sign + number(abs(move.change), digits: points ? 2 : 1) + (points ? " pt" : " %")
    }

    private static func usual(_ move: PeerMove) -> String {
        guard let ratio = move.ratio else { return "" }
        return ", soit \(number(Decimal(ratio), digits: 1)) fois sa variation habituelle"
    }

    private static func number(_ value: Decimal, digits: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = .french
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = digits
        formatter.maximumFractionDigits = digits
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "\(value)"
    }
}
