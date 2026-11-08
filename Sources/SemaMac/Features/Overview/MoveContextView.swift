// Inspecteur « Pourquoi ce mouvement ? » : faits datés de la séance et leurs liens, chargés à la demande.
import SwiftUI
import MarketCore

struct MoveContextView: View {
    @Environment(AppStore.self) private var store
    let series: MarketSeries
    @State private var context: DayContext?
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s24) {
                VStack(alignment: .leading, spacing: Spacing.s2) {
                    Text("Pourquoi ce mouvement ?").typeRole(.heading)
                    Text(MarketFormat.date(series.latest?.date)).typeRole(.caption).foregroundStyle(.secondary)
                }
                if let context { facts(context) }
                else if isLoading { ProgressView().controlSize(.small) }
                Text("sema rassemble des faits datés et leurs liens. Il n’affirme pas de cause.")
                    .typeRole(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            .padding(Spacing.s24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task(id: AppStore.contextKey(series)) {
            isLoading = true; context = nil
            context = await store.dayContext(for: series)
            isLoading = false
        }
    }

    @ViewBuilder private func facts(_ context: DayContext) -> some View {
        group("Vos repères ce jour") {
            if context.peers.isEmpty { empty("Aucun autre repère suivi n’a publié ce jour.") }
            ForEach(context.peers.prefix(6)) { peer in
                HStack(spacing: Spacing.s8) {
                    Text(MarketFormat.name(store.displayedSeries(peer.series))).typeRole(.small).lineLimit(1)
                    Spacer(minLength: Spacing.s8)
                    Text(MarketFormat.sessionChange(peer.change, series: peer.series)).typeRole(.caption).monospacedDigit().foregroundStyle(.secondary)
                    if let ratio = peer.ratio { MoveBadge(ratio: ratio) }
                }
            }
        }
        group("Agenda") {
            if context.releases.isEmpty { empty(context.unavailable.contains("Calendrier FRED") ? "Connectez FRED pour voir le calendrier." : "Aucune publication inscrite.") }
            ForEach(context.releases.prefix(6)) { Text($0.name).typeRole(.small) }
        }
        group("Banques centrales") {
            if context.pressReleases.isEmpty { empty(context.unavailable.contains("Communiqués") ? "Flux indisponibles pour l’instant." : "Aucun communiqué ce jour.") }
            ForEach(context.pressReleases.prefix(4)) { release in
                link(release.title, url: release.link, detail: release.feed.title)
            }
        }
        group("Titres") {
            if context.headlines.isEmpty { empty(context.unavailable.contains("Titres") ? "Titres indisponibles pour l’instant." : "Aucun titre retenu.") }
            ForEach(context.headlines.prefix(5)) { headline in
                link(headline.title, url: headline.link, detail: headline.publisher)
            }
        }
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text(title).typeRole(.overline).foregroundStyle(.secondary)
            content()
        }
    }

    private func empty(_ text: String) -> some View { Text(text).typeRole(.small).foregroundStyle(.secondary) }

    private func link(_ title: String, url: URL, detail: String) -> some View {
        Link(destination: url) {
            VStack(alignment: .leading, spacing: Spacing.s2) {
                Text(title).typeRole(.small).multilineTextAlignment(.leading).foregroundStyle(.primary)
                Text(detail).typeRole(.caption).foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain).help(url.absoluteString)
    }
}
