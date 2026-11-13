// Vérifie le message groupé des alertes : titre, sous-titre, une ligne par repère et cible du clic.
import Foundation
import Testing
import MarketCore
@testable import SemaMac

struct NotificationTextTests {
    private let day = Date(timeIntervalSince1970: 1_792_022_400)

    private func series(_ id: String) -> MarketSeries {
        MarketSeries(id: id, name: id, subtitle: "", category: .savings, unit: .percent, source: "Test",
                     observations: [MarketObservation(date: day, value: 3)])
    }

    private func level(_ id: String) -> AlertEvent {
        AlertEvent(ruleID: UUID(), seriesID: id, observedAt: day, changePercent: 0, observedValue: 3)
    }

    private func move(_ id: String) -> AlertEvent {
        AlertEvent(ruleID: UUID(), seriesID: id, observedAt: day, changePercent: 2, ratio: 4)
    }

    @Test func oneThresholdOpensItsSeries() {
        let summary = NotificationText.summary(events: [level("a")], series: [series("a")]) { _ in true }
        #expect(summary?.subtitle == "Seuil franchi")
        #expect(summary?.target == .series("a"))
        #expect(summary?.body.contains("seuil franchi") == true)
    }

    @Test func severalEventsShareOneMessageThatOpensAlerts() {
        let summary = NotificationText.summary(events: [level("a"), move("b")], series: [series("a"), series("b")]) { _ in true }
        #expect(summary?.title == "2 repères")
        #expect(summary?.subtitle == "Alertes")
        #expect(summary?.body.split(separator: "\n").count == 2)
        #expect(summary?.target == .section(.alerts))
    }

    @Test func moveOnlyEventsAreCalledUnusualMoves() {
        let summary = NotificationText.summary(events: [move("a")], series: [series("a")]) { _ in true }
        #expect(summary?.subtitle == "Mouvement inhabituel")
    }

    @Test func suspendedSourcesProduceNoMessage() {
        #expect(NotificationText.summary(events: [level("a")], series: [series("a")]) { _ in false } == nil)
    }
}
