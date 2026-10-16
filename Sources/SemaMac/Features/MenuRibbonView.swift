import SwiftUI
import Charts
import MarketCore

// BANDEAU
//   0 ms  Les favoris en cache sont immédiatement disponibles.
// 220 ms  Le panneau apparaît sous la barre des menus, sur 8 pt (AppKit).
// 160 ms  Un survol change seulement la profondeur de la carte.
// 280 ms  Les flèches amènent le prochain repère ; le trackpad reste natif.
enum MenuRibbonLayout {
    static let height: CGFloat = 288
    static let screenInset: CGFloat = 12
    static let topGap: CGFloat = 8
    static let padding: CGFloat = 18
    static let spacing: CGFloat = 12
    static let minimumCardWidth: CGFloat = 248
    static let maximumCardWidth: CGFloat = 600
    static let cardHeight: CGFloat = 184
    static let revealDuration = 0.22
    static let dismissDuration = 0.13
    static let hoverDuration = 0.16
    static let scrollDuration = 0.28
    static let revealOffset: CGFloat = 8
}

struct MenuRibbonView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let openWorkspace: () -> Void
    let openSettings: () -> Void
    let dismiss: () -> Void
    @State private var period: HistoryPeriod = .year
    @State private var leadingID: String?

    private var items: [MarketSeries] { store.favorites }

    var body: some View {
        VStack(spacing: MenuRibbonLayout.spacing) {
            header.frame(height: 30)
            GeometryReader { geometry in
                let capacity = max(1, Int((geometry.size.width + MenuRibbonLayout.spacing)
                                         / (MenuRibbonLayout.minimumCardWidth + MenuRibbonLayout.spacing)))
                let visibleCount = max(1, min(items.count, capacity))
                let cardWidth = min(MenuRibbonLayout.maximumCardWidth,
                    (geometry.size.width - CGFloat(visibleCount - 1) * MenuRibbonLayout.spacing) / CGFloat(visibleCount))
                if items.isEmpty {
                    emptyState.frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollViewReader { proxy in
                        VStack(spacing: 0) {
                            ScrollView(.horizontal) {
                                LazyHStack(spacing: MenuRibbonLayout.spacing) {
                                    ForEach(items) { item in
                                        RibbonCard(series: item, period: period) { open(item) }
                                            .frame(width: cardWidth, height: MenuRibbonLayout.cardHeight).id(item.id)
                                    }
                                }
                                .scrollTargetLayout()
                            }
                            .scrollIndicators(.hidden)
                            .scrollClipDisabled()
                            .scrollTargetBehavior(.viewAligned)
                            .scrollPosition(id: $leadingID, anchor: .leading)
                            .frame(height: MenuRibbonLayout.cardHeight)
                            HStack(spacing: 8) {
                                Text(items.count == 1 ? "1 favori" : "\(items.count) favoris")
                                Text("·").accessibilityHidden(true)
                                Text("Comparaison sur " + period.title)
                                Spacer()
                                if items.contains(where: \.isDemo) { Text("Démo · valeurs fictives") }
                                else { Text("Publications Webstat · données en cache") }
                                if items.count > capacity {
                                    Button { scroll(-1, proxy: proxy) } label: { Image(systemName: "chevron.left") }
                                        .help("Favoris précédents").accessibilityLabel("Favoris précédents")
                                        .disabled(leadingIndex == 0)
                                    Button { scroll(1, proxy: proxy) } label: { Image(systemName: "chevron.right") }
                                        .help("Favoris suivants").accessibilityLabel("Favoris suivants")
                                        .disabled(leadingIndex >= items.count - visibleCount)
                                }
                            }
                            .font(.system(size: 11)).foregroundStyle(.secondary)
                            .buttonStyle(.borderless).padding(.top, 12)
                        }
                    }
                }
            }
        }
        .padding(MenuRibbonLayout.padding)
        .background(SemaTheme.background.opacity(0.92), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .environment(\.semaAccent, store.palette.accent).tint(store.palette.controlAccent)
        .environment(\.locale, Locale(identifier: "fr_FR"))
        .onChange(of: items.map(\.id)) { _, ids in
            if let leadingID, !ids.contains(leadingID) { self.leadingID = ids.first }
        }
        .task { await store.checkWebstatKey() }
    }

    private var header: some View {
        HStack(spacing: 12) {
            SemaMark(size: 26)
            Text("Vos favoris").font(.system(size: 15, weight: .semibold)).tracking(-0.3).foregroundStyle(.primary)
            Spacer()
            if !items.isEmpty {
                Picker("Période de comparaison", selection: $period) {
                    Text("1 mois").tag(HistoryPeriod.month)
                    Text("3 mois").tag(HistoryPeriod.quarter)
                    Text("1 an").tag(HistoryPeriod.year)
                }
                .pickerStyle(.segmented).labelsHidden().controlSize(.small).frame(width: 185)
            }
            Button { Task { await store.refreshWebstat() } } label: {
                Image(systemName: "arrow.clockwise")
            }
            .disabled(store.isLoading || !store.hasWebstatKey)
            .help(store.hasWebstatKey ? "Actualiser Webstat" : "Connectez votre clé Webstat dans les réglages")
            .accessibilityLabel(store.isLoading ? "Actualisation en cours" : "Actualiser Webstat")
            Button {
                openWorkspace()
                store.isSearchPresented = true
            } label: { Image(systemName: "magnifyingglass") }
                .help("Rechercher un repère · ⌘K").accessibilityLabel("Rechercher un repère")
            Button(action: openSettings) { Image(systemName: "slider.horizontal.3") }
                .help("Réglages de Sema").accessibilityLabel("Réglages de Sema")
            Button(action: openWorkspace) { Label("Ouvrir Sema", systemImage: "arrow.up.right") }
                .font(.system(size: 12)).foregroundStyle(store.palette.accent)
            Button(action: dismiss) { Image(systemName: "xmark").frame(width: 24, height: 24) }
                .help("Fermer · Échap").accessibilityLabel("Fermer le bandeau")
        }
        .buttonStyle(.plain).foregroundStyle(.secondary)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "star").font(.system(size: 24, weight: .light)).foregroundStyle(store.palette.accent)
            Text("Vos repères, en un coup d’œil.").font(.system(size: 17, weight: .medium))
            Text("Épinglez les repères à retrouver dans ce bandeau.").font(.system(size: 12)).foregroundStyle(.secondary)
            Button("Choisir mes favoris") { store.section = .overview; openWorkspace() }
                .buttonStyle(.borderedProminent).controlSize(.small).padding(.top, 4)
        }
    }

    private var leadingIndex: Int { items.firstIndex { $0.id == leadingID } ?? 0 }
    private func scroll(_ direction: Int, proxy: ScrollViewProxy) {
        let index = min(max(0, leadingIndex + direction), items.count - 1)
        withAnimation(reduceMotion ? nil : .smooth(duration: MenuRibbonLayout.scrollDuration)) {
            leadingID = items[index].id
            proxy.scrollTo(items[index].id, anchor: .leading)
        }
    }
    private func open(_ item: MarketSeries) { store.show(item); store.section = .overview; openWorkspace() }
}

private struct RibbonCard: View {
    @Environment(\.semaAccent) private var accent
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hovered = false
    let series: MarketSeries
    let period: HistoryPeriod
    let action: () -> Void
    private var points: [MarketObservation] { series.history(for: period) }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 9) {
                heading
                value
                sparkline
                publication
            }
            .foregroundStyle(.primary).padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(SemaTheme.surface.opacity(hovered ? 0.98 : 0.82),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(hovered ? 0.12 : 0.06), radius: hovered ? 9 : 4, x: 0, y: 3)
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(SemaPressStyle())
        .onHover { hovered = $0 }
        .animation(reduceMotion ? nil : .easeOut(duration: MenuRibbonLayout.hoverDuration), value: hovered)
        .help(series.name + " · Ouvrir le détail dans Sema")
        .accessibilityLabel(accessibilityDescription)
    }

    private var heading: some View {
        HStack(spacing: 10) {
            Text(series.name).font(.system(size: 13, weight: .medium)).lineLimit(1)
            Spacer(minLength: 0)
            OriginBadge(series: series)
            Image(systemName: "arrow.up.right").font(.system(size: 10)).foregroundStyle(.tertiary)
        }
    }
    private var value: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(series.latest.map { MarketFormat.number($0.value, digits: series.fractionDigits) } ?? "—")
                .font(.system(size: 32, weight: .medium)).tracking(-0.9).monospacedDigit()
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(series.displayUnit).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(2)
            Spacer(minLength: 0)
        }
    }
    @ViewBuilder private var sparkline: some View {
        if points.count > 1 {
            Chart(points) { point in
                LineMark(x: .value("Date", point.date), y: .value(series.displayUnit, MarketFormat.double(point.value)))
                    .foregroundStyle(accent)
                    .lineStyle(StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
            }
            .chartXAxis(.hidden).chartYAxis(.hidden)
            .chartYScale(domain: .automatic(includesZero: false))
            .frame(height: 45).accessibilityHidden(true)
        } else {
            Text(points.isEmpty ? "Historique indisponible" : "Une observation disponible")
                .font(.system(size: 11)).foregroundStyle(.tertiary).frame(height: 45)
        }
    }
    private var publication: some View {
        HStack(spacing: 8) {
            Text(MarketFormat.change(series, period: period)).lineLimit(1)
            Spacer(minLength: 0)
            Text(series.latest.map { MarketFormat.date($0.date) } ?? "Aucune publication").lineLimit(1)
        }
        .font(.system(size: 11)).monospacedDigit().foregroundStyle(.secondary)
    }
    private var accessibilityDescription: String {
        series.name + ", " + MarketFormat.value(series)
            + (series.isDemo ? ", démonstration" : "") + ", " + MarketFormat.change(series, period: period)
            + " sur " + period.title + ", publication du " + MarketFormat.date(series.latest?.date)
    }
}
