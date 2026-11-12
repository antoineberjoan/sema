// Réunit les repères surveillés pour leurs mouvements inhabituels et les seuils, avec leurs actions.
import SemaDesign
import SwiftUI
import MarketCore

struct AlertsView: View {
    private static let sectionSpacing = DesignSpace.groupGap
    private static let emptyMinHeight: CGFloat = 350
    @Environment(AppStore.self) private var store
    @Environment(\.openSettings) private var openSettings

    private var watched: [MarketSeries] { store.followedSeries.filter { item in store.moveWatches.contains { $0.seriesID == item.id } } }
    private var unwatchedFavorites: [MarketSeries] { store.favorites.filter { store.canWatch($0) && !store.isWatched($0.id) } }

    var body: some View {
        VStack(alignment: .leading, spacing: Self.sectionSpacing) {
            HStack(alignment: .firstTextBaseline) {
                Text("Vérification après chaque clôture et à chaque actualisation, tant que sema tourne.")
                    .typeRole(.small).foregroundStyle(DesignColor.textMuted)
                Spacer(minLength: DesignSpace.fieldGap)
                Button("Sensibilité \(store.moveSensitivity.title.lowercased()) · \(MarketFormat.ratio(store.moveSensitivity.multiplier))") {
                    store.settingsTab = .general; openSettings()
                }
                .buttonStyle(.borderless).typeRole(.small)
            }
            if !unwatchedFavorites.isEmpty { favoritesOffer }
            if watched.isEmpty && store.macroAlerts.isEmpty {
                ContentUnavailableView {
                    Label("Être prévenu au bon moment.", systemImage: "bell")
                } description: {
                    Text("Cliquez sur « Me prévenir » dans un repère : sema signale les séances qui sortent de l’habituel.")
                } actions: {
                    if store.followedSeries.isEmpty {
                        Button("Explorer les repères") { store.section = .explorer }.buttonStyle(.borderedProminent)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: Self.emptyMinHeight)
            } else {
                if !watched.isEmpty {
                    section("Mouvements inhabituels") {
                        ForEach(watched) { item in
                            WatchRow(series: item)
                            if item.id != watched.last?.id { Divider() }
                        }
                    }
                }
                if !store.macroAlerts.isEmpty {
                    section("Seuils") {
                        ForEach(store.macroAlerts) { rule in
                            AlertRow(rule: rule)
                            if rule.id != store.macroAlerts.last?.id { Divider() }
                        }
                    }
                }
            }
        }
    }

    private var favoritesOffer: some View {
        HStack(spacing: DesignSpace.fieldGap) {
            VStack(alignment: .leading, spacing: DesignSpace.titleGap) {
                Text(unwatchedFavorites.count == 1 ? "Surveiller votre favori ?" : "Surveiller vos \(unwatchedFavorites.count) favoris ?").typeRole(.heading)
                Text("sema vous prévient quand l’un d’eux bouge plus que d’habitude.").typeRole(.small).foregroundStyle(DesignColor.textMuted)
            }
            Spacer(minLength: DesignSpace.fieldGap)
            Button("Activer") { Task { await store.watchFavorites() } }.buttonStyle(.borderedProminent)
        }
        .padding(DesignSpace.cardInset)
        .background(DesignColor.surface, in: RoundedRectangle(cornerRadius: DesignRadius.block))
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title).typeRole(.heading).padding(.bottom, DesignSpace.titleGap)
            Divider()
            content()
        }
    }
}

private struct WatchRow: View {
    private static let nameWidth: CGFloat = 220
    @Environment(AppStore.self) private var store
    let series: MarketSeries

    var body: some View {
        let displayed = store.displayedSeries(series)
        let move = UnusualMove(series: series)
        HStack(spacing: DesignSpace.itemGap) {
            Text(MarketFormat.name(displayed)).typeRole(.small).lineLimit(1).frame(width: Self.nameWidth, alignment: .leading)
            Text(move.map { MarketFormat.sessionChange($0.change, series: series) } ?? "Historique insuffisant")
                .typeRole(.caption).monospacedDigit().foregroundStyle(DesignColor.textMuted)
            if let move { MoveBadge(ratio: move.ratio) }
            Spacer(minLength: DesignSpace.fieldGap)
            Text(MarketFormat.date(series.latest?.date)).typeRole(.caption).foregroundStyle(DesignColor.textMuted)
            WatchButton(series: series)
        }
        .padding(.vertical, DesignSpace.frameInset)
    }
}

private struct AlertRow: View {
    private static let iconSpacing = DesignSpace.fieldGap
    private static let iconSize: CGFloat = 30
    private static let textSpacing = DesignSpace.titleGap
    private static let actionSpacing = DesignSpace.itemGap
    private static let verticalPadding = DesignSpace.cardInset
    @Environment(AppStore.self) private var store
    @Environment(\.palette) private var palette
    private var accentText: Color { DesignColor.accentText(palette) }
    let rule: AlertRule
    private var item: MarketSeries? { store.series.first { $0.id == rule.seriesID } }
    private var lastEvent: AlertEvent? { store.recentAlertEvents.last { $0.ruleID == rule.id } }

    var body: some View {
        HStack(alignment: .top, spacing: Self.iconSpacing) {
            Image(systemName: rule.isEnabled ? "bell" : "bell.slash").foregroundStyle(accentText)
                .frame(width: Self.iconSize, height: Self.iconSize)
            VStack(alignment: .leading, spacing: Self.textSpacing) {
                Text(item.map(MarketFormat.name) ?? "Repère indisponible").typeRole(.label)
                Text("\(rule.direction.crossingTitle) \(MarketFormat.number(rule.threshold, digits: item?.fractionDigits ?? 2)) \(item.map(MarketFormat.unit) ?? "").")
                    .typeRole(.small).foregroundStyle(DesignColor.textMuted)
                if let event = lastEvent, let value = event.observedValue {
                    Text("Dernier signal : \(MarketFormat.number(value, digits: item?.fractionDigits ?? 2)) \(item.map(MarketFormat.unit) ?? "") · \(MarketFormat.date(event.observedAt))")
                        .typeRole(.caption).foregroundStyle(DesignColor.textMuted)
                }
                HStack(spacing: Self.actionSpacing) {
                    Button("Tester la notification") { store.simulate(rule) }.disabled(!store.isSourceEnabled(for: rule.seriesID))
                    Button(rule.isEnabled ? "Mettre en pause" : "Réactiver") { store.toggleAlert(rule.id) }
                        .disabled(!store.isSourceEnabled(for: rule.seriesID) || (!rule.isEnabled && (!store.isFollowing(rule.seriesID) || item?.canAlert != true)))
                    Button(role: .destructive) { store.deleteAlert(rule.id) } label: { Image(systemName: "trash") }
                        .help("Supprimer cette alerte").accessibilityLabel("Supprimer l’alerte sur \(item.map(MarketFormat.name) ?? "ce repère")")
                }
                .buttonStyle(.borderless).typeRole(.caption)
            }
            Spacer(minLength: 0)
            Text(!store.isFollowing(rule.seriesID) ? "Repère retiré · en pause" : !store.isSourceEnabled(for: rule.seriesID) ? "Source désactivée · en pause" : !rule.isEnabled ? "En pause" : item?.canAlert == false ? "Unité à vérifier" : "À l’actualisation")
                .typeRole(.caption).foregroundStyle(DesignColor.textMuted)
        }
        .padding(.vertical, Self.verticalPadding)
    }
}
