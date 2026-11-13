// Écrit le texte des notifications d'alerte et du brief : une ligne par repère, regroupées dans un seul message.
import Foundation
import MarketCore

enum NotificationText {
    /// Message groupé d'une vérification : titre, sous-titre, corps et cible du clic.
    struct Summary: Equatable {
        let title: String
        let subtitle: String
        let body: String
        let target: NotificationTarget
    }

    /// Une ligne par événement : « S&P 500 · −4,40 % · 4,0× l’habituel ».
    static func line(for event: AlertEvent, series: MarketSeries) -> String {
        let name = MarketFormat.name(series)
        if let ratio = event.ratio {
            return "\(name) · \(MarketFormat.sessionChange(event.changePercent, series: series)) · \(MarketFormat.ratio(ratio)) l’habituel"
        }
        let value = event.observedValue.map { MarketFormat.number($0, digits: series.fractionDigits) } ?? "—"
        return "\(name) · seuil franchi : \(value) \(MarketFormat.unit(series)) · \(MarketFormat.date(event.observedAt))"
    }

    /// Regroupe les événements d'une même vérification, du repère qui peut être affiché ; nil s'il n'en reste aucun.
    static func summary(events: [AlertEvent], series values: [MarketSeries], isSourceEnabled: (String) -> Bool) -> Summary? {
        let entries = events.compactMap { event -> (name: String, line: String)? in
            guard isSourceEnabled(event.seriesID), let item = values.first(where: { $0.id == event.seriesID }) else { return nil }
            return (MarketFormat.name(item), line(for: event, series: item))
        }
        guard let first = entries.first else { return nil }
        let moves = events.filter { $0.ratio != nil }.count
        return Summary(
            title: entries.count == 1 ? first.name : "\(entries.count) repères",
            subtitle: moves == events.count ? "Mouvement inhabituel" : moves == 0 ? "Seuil franchi" : "Alertes",
            body: entries.map(\.line).joined(separator: "\n"),
            target: entries.count == 1 ? .series(events[0].seriesID) : .section(.alerts))
    }

    static func briefLines(_ brief: MorningBrief) -> [String] {
        var lines = brief.moves.map { move in
            "\(MarketFormat.name(move.series)) · \(MarketFormat.sessionChange(move.change, series: move.series))"
                + (move.ratio.map { " · \(MarketFormat.ratio($0)) l’habituel" } ?? "")
        }
        lines += brief.nearThresholds.map { near in "\(MarketFormat.name(near.series)) · \(nearText(near))" }
        if brief.isQuiet { lines.append("Aucun mouvement inhabituel ni seuil proche sur la dernière séance.") }
        if !brief.agenda.isEmpty { lines.append("Agenda : " + brief.agenda.prefix(3).map(\.name).joined(separator: ", ")) }
        if let release = brief.pressReleases.first { lines.append("\(release.feed.title) : \(release.title)") }
        return lines
    }

    static func nearText(_ near: MorningBrief.NearThreshold) -> String {
        let gap = near.series.unit == .percent ? MarketFormat.number(near.gap, digits: 2) + " pt" : MarketFormat.number(near.gap, digits: 1) + " %"
        let threshold = MarketFormat.number(near.rule.threshold, digits: near.series.fractionDigits) + " " + MarketFormat.unit(near.series)
        return "à \(gap) du seuil de \(threshold)"
    }
}
