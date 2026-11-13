// Inspecteur « Pourquoi ce mouvement ? » : faits datés de la séance et, à la demande, leur synthèse vérifiée.
import SemaDesign
import SwiftUI
import MarketCore

struct MoveContextView: View {
    private enum Tab: String, CaseIterable, Identifiable {
        case facts = "Faits", summary = "Synthèse"
        var id: String { rawValue }
    }

    @Environment(AppStore.self) private var store
    @Environment(\.openSettings) private var openSettings
    let series: MarketSeries
    @State private var context: DayContext?
    @State private var isLoading = false
    @State private var tab = Tab.facts
    @State private var isWriting = false
    @State private var summaryError: String?
    /// Lu dans le store, pour qu’un changement de rédacteur dans Réglages montre la synthèse correspondante ou aucune.
    private var summary: SummaryCheck? { store.cachedSummary(for: series) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSpace.groupGap) {
                VStack(alignment: .leading, spacing: DesignSpace.titleGap) {
                    Text("Pourquoi ce mouvement ?").typeRole(.heading)
                    Text(MarketFormat.date(series.latest?.date)).typeRole(.caption).foregroundStyle(DesignColor.textMuted)
                }
                Picker("Affichage", selection: $tab) {
                    ForEach(Tab.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented).labelsHidden()
                if let context {
                    switch tab {
                    case .facts: facts(context)
                    case .summary: summarySection(context)
                    }
                } else if isLoading { ProgressView().controlSize(.small) }
                Text(tab == .facts ? "sema rassemble des faits datés et leurs liens. Il n’affirme pas de cause."
                     : "Chaque phrase cite ses faits. Vérifiez-la avant de la partager.")
                    .typeRole(.caption).foregroundStyle(DesignColor.textMuted).fixedSize(horizontal: false, vertical: true)
            }
            .padding(DesignSpace.pageInsetNarrow)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task(id: AppStore.contextKey(series)) {
            isLoading = true; context = nil; summaryError = nil
            context = await store.dayContext(for: series)
            isLoading = false
        }
    }

    @ViewBuilder private func summarySection(_ context: DayContext) -> some View {
        if let blocker = store.summaryBlocker {
            VStack(alignment: .leading, spacing: DesignSpace.fieldGap) {
                empty(blocker)
                Button("Ouvrir les réglages") { store.settingsTab = .sources; openSettings() }.controlSize(.small)
            }
        } else if let summary {
            sentences(summary, facts: store.contextFacts(for: series, context: context))
        } else if isWriting {
            ProgressView().controlSize(.small).accessibilityLabel("Rédaction en cours")
        } else {
            VStack(alignment: .leading, spacing: DesignSpace.fieldGap) {
                Button("Rédiger la synthèse") { Task { await write(context) } }
                Text(store.summaryWriter == .claude ? "Un appel payant à votre compte Anthropic." : "Rédigée sur ce Mac, sans réseau.")
                    .typeRole(.caption).foregroundStyle(DesignColor.textMuted)
            }
        }
        if let summaryError { Text(summaryError).typeRole(.small).foregroundStyle(DesignColor.danger).textSelection(.enabled) }
    }

    private func sentences(_ summary: SummaryCheck, facts: [ContextFact]) -> some View {
        VStack(alignment: .leading, spacing: DesignSpace.itemGap) {
            if summary.kept.isEmpty { empty("Aucune phrase ne correspond aux faits. Consultez l’onglet Faits.") }
            ForEach(Array(summary.kept.enumerated()), id: \.offset) { _, sentence in
                VStack(alignment: .leading, spacing: DesignSpace.titleGap) {
                    Text(sentence.text).typeRole(.body).textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
                    Text("D’après " + sources(of: sentence, in: facts)).typeRole(.caption).foregroundStyle(DesignColor.textMuted)
                }
            }
            VStack(alignment: .leading, spacing: DesignSpace.listGapDense) {
                Text("Rédigée par \(store.summaryWriter.signature).").typeRole(.micro).foregroundStyle(DesignColor.textMuted)
                if summary.hiddenCount > 0 {
                    Text(summary.hiddenCount == 1 ? "1 phrase masquée : ses chiffres ou son sens ne figurent pas dans les faits."
                         : "\(summary.hiddenCount) phrases masquées : leurs chiffres ou leur sens ne figurent pas dans les faits.")
                        .typeRole(.micro).foregroundStyle(DesignColor.textMuted)
                }
            }
        }
    }

    private func sources(of sentence: SummarySentence, in facts: [ContextFact]) -> String {
        var seen: Set<String> = []
        return sentence.factIDs.compactMap { id in facts.first { $0.id == id }?.label }
            .filter { seen.insert($0).inserted }.joined(separator: " · ")
    }

    private func write(_ context: DayContext) async {
        guard !isWriting else { return }
        isWriting = true; summaryError = nil
        defer { isWriting = false }
        do { _ = try await store.summary(for: series, context: context) }
        catch { summaryError = error.localizedDescription }
    }

    @ViewBuilder private func facts(_ context: DayContext) -> some View {
        group("Vos repères ce jour") {
            if context.peers.isEmpty { empty("Aucun autre repère suivi n’a publié ce jour.") }
            ForEach(context.peers.prefix(6)) { peer in
                HStack(spacing: DesignSpace.fieldGap) {
                    Text(MarketFormat.name(store.displayedSeries(peer.series))).typeRole(.small).lineLimit(1)
                    Spacer(minLength: DesignSpace.fieldGap)
                    Text(MarketFormat.sessionChange(peer.change, series: peer.series)).typeRole(.caption).monospacedDigit().foregroundStyle(DesignColor.textMuted)
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
        VStack(alignment: .leading, spacing: DesignSpace.titleGap) {
            Text(title).typeRole(.overline).foregroundStyle(DesignColor.textMuted)
            content()
        }
    }

    private func empty(_ text: String) -> some View { Text(text).typeRole(.small).foregroundStyle(DesignColor.textMuted) }

    private func link(_ title: String, url: URL, detail: String) -> some View {
        Link(destination: url) {
            VStack(alignment: .leading, spacing: DesignSpace.titleGap) {
                Text(title).typeRole(.small).multilineTextAlignment(.leading).foregroundStyle(DesignColor.text)
                Text(detail).typeRole(.caption).foregroundStyle(DesignColor.textMuted)
            }
        }
        .buttonStyle(.plain).help(url.absoluteString)
    }
}
