// Présente les favoris et leurs historiques dans le bandeau partagé avec le hub.
import AppKit
import SwiftUI
import Charts
import MarketCore

// BANDEAU
//   0 ms  Les favoris en cache sont immédiatement disponibles.
// 220 ms  Le panneau apparaît depuis le bord choisi, sur 8 pt (AppKit).
// 160 ms  Un survol change seulement la profondeur de la carte.
// Le défilement des cartes reste natif, au trackpad et au clavier.
enum MenuRibbonLayout {
    static let height = topPadding + cardHeight + bottomPadding
    static let verticalWidth: CGFloat = 368
    static let signatureHeight = cardHeight
    static let cardCornerRadius: CGFloat = 22
    static let screenInset: CGFloat = 6
    static let padding: CGFloat = 18
    static let topPadding: CGFloat = 6
    static let bottomPadding: CGFloat = 12
    static let headerHeight: CGFloat = 32
    static let headerSpacing: CGFloat = 6
    static let spacing: CGFloat = 12
    static let minimumCardWidth: CGFloat = 208
    static let maximumCardWidth: CGFloat = 232
    static let preferredVisibleCards = 4
    static let cardHeight: CGFloat = 216
    static let controlColumnWidth: CGFloat = 84
    static let periodRowHeight: CGFloat = 24
    static let controlColumnPadding: CGFloat = 8
    static let revealDuration = 0.22
    static let dismissDuration = 0.13
    static let hoverDuration = 0.16
    static let revealOffset: CGFloat = 8
}

struct MenuRibbonView: View {
    @Environment(AppStore.self) private var store
    let presentationID: UUID?
    let openWorkspace: () -> Void
    let openSettings: () -> Void
    @State private var period: HistoryPeriod = .year

    private var items: [MarketSeries] { store.favorites }
    private var isVertical: Bool { store.ribbonPosition.isVertical }

    var body: some View {
        VStack(spacing: MenuRibbonLayout.headerSpacing) {
            if isVertical {
                if items.isEmpty { emptyState.frame(maxWidth: .infinity, maxHeight: .infinity) }
                else {
                    ScrollView(.vertical) {
                        LazyVStack(spacing: MenuRibbonLayout.spacing) {
                            ForEach(items) { item in
                                RibbonCard(series: store.displayedSeries(item), period: period) { open(item) }
                                    .frame(height: MenuRibbonLayout.cardHeight)
                            }
                        }.padding(.vertical, 2)
                    }.scrollIndicators(.automatic).scrollClipDisabled()
                }
                RibbonSignatureView(presentationID: presentationID).frame(height: MenuRibbonLayout.signatureHeight)
                header
            } else {
                HStack(alignment: .top, spacing: MenuRibbonLayout.spacing) {
                    controlColumn
                    horizontalFavorites
                }
                .frame(height: MenuRibbonLayout.cardHeight)
            }
        }
        .padding(.horizontal, MenuRibbonLayout.padding)
        .padding(.top, MenuRibbonLayout.topPadding)
        .padding(.bottom, MenuRibbonLayout.bottomPadding)
        .environment(\.semaAccent, store.palette.accent).tint(store.palette.controlAccent)
        .environment(\.semaGlassTint, store.palette.glassTint)
        .environment(\.semaGlassSettings, store.ribbonGlass)
        .preferredColorScheme(store.appearance.colorScheme)
        .environment(\.locale, Locale(identifier: "fr_FR"))
        .task { await store.checkWebstatKey() }
    }

    private var horizontalFavorites: some View {
        GeometryReader { geometry in
            // Reserve a slot outside the scroll view so feedback is always visible.
            let capacity = max(1, Int((geometry.size.width + MenuRibbonLayout.spacing)
                                     / (MenuRibbonLayout.minimumCardWidth + MenuRibbonLayout.spacing)) - 1)
            let visibleCount = max(1, min(items.count, capacity, MenuRibbonLayout.preferredVisibleCards))
            let cardWidth = min(MenuRibbonLayout.maximumCardWidth,
                (geometry.size.width - CGFloat(visibleCount) * MenuRibbonLayout.spacing) / CGFloat(visibleCount + 1))
            HStack(spacing: MenuRibbonLayout.spacing) {
                if items.isEmpty {
                    emptyState.frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: MenuRibbonLayout.spacing) {
                            ForEach(items) { item in
                                RibbonCard(series: store.displayedSeries(item), period: period) { open(item) }
                                    .frame(width: cardWidth, height: MenuRibbonLayout.cardHeight)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollIndicators(.automatic)
                    .scrollTargetBehavior(.viewAligned)
                    .frame(width: CGFloat(visibleCount) * cardWidth + CGFloat(visibleCount - 1) * MenuRibbonLayout.spacing)
                }
                RibbonSignatureView(presentationID: presentationID)
                    .frame(width: cardWidth, height: MenuRibbonLayout.signatureHeight)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: MenuRibbonLayout.cardHeight)
        }
    }

    private var controlColumn: some View {
        VStack(spacing: 2) {
            if !items.isEmpty {
                ForEach(HistoryPeriods.visible) { candidate in
                    Button { period = candidate } label: {
                        HStack(spacing: 7) {
                            Capsule().fill(period == candidate ? store.palette.accent : .clear)
                                .frame(width: 3, height: 12)
                            Text(candidate.title).font(.system(size: 11, weight: period == candidate ? .semibold : .regular))
                                .fixedSize(horizontal: true, vertical: false)
                                .foregroundStyle(.primary)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 6)
                        .frame(maxWidth: .infinity).frame(height: MenuRibbonLayout.periodRowHeight)
                        .background(.regularMaterial, in: Capsule())
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(SemaPressStyle())
                    .accessibilityAddTraits(period == candidate ? .isSelected : [])
                    .help(candidate.title + " · Historique disponible sur ce Mac")
                }
            }
            Spacer(minLength: 2)
            settingsButton
        }
        .padding(MenuRibbonLayout.controlColumnPadding)
        .frame(width: MenuRibbonLayout.controlColumnWidth, height: MenuRibbonLayout.cardHeight)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Période de comparaison et réglages")
    }

    private var settingsButton: some View {
        Button(action: openSettings) {
            Image(systemName: "gearshape").frame(width: 26, height: 26).contentShape(Circle())
        }
        .buttonStyle(.plain)
        .background(.regularMaterial, in: Circle())
        .help("Réglages de sema").accessibilityLabel("Réglages de sema")
    }

    private var header: some View {
        HStack(spacing: 0) {
            Spacer()
            HStack(spacing: 8) {
                if !items.isEmpty {
                    RibbonPeriodPicker(selection: $period, accent: store.palette.controlAccent)
                        .frame(width: isVertical ? 278 : 350)
                        .help("Historique disponible sur ce Mac · Tout utilise le cache chargé")
                }
                settingsButton
            }
            .padding(.horizontal, 10).padding(.vertical, 3)
            .modifier(RibbonSurface())
        }
        .foregroundStyle(.primary).frame(height: MenuRibbonLayout.headerHeight)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "star").font(.system(size: 24, weight: .light)).foregroundStyle(store.palette.accent)
            Text("Vos repères, en un coup d’œil.").font(.system(size: 17, weight: .medium))
            Text("Épinglez les repères à retrouver dans ce bandeau.").font(.system(size: 12)).foregroundStyle(.secondary)
            Button("Choisir mes favoris") { store.section = .overview; openWorkspace() }
                .buttonStyle(.borderedProminent).controlSize(.small).padding(.top, 4)
        }
        .padding(16).modifier(RibbonSurface())
    }

    private func open(_ item: MarketSeries) { store.show(item); store.section = .overview; openWorkspace() }
}

/// Les cinq horizons restent directement disponibles dans un contrôle natif.
private struct RibbonPeriodPicker: NSViewRepresentable {
    @Binding var selection: HistoryPeriod
    let accent: Color
    private let periods = HistoryPeriods.visible

    func makeCoordinator() -> Coordinator { Coordinator(selection: $selection, periods: periods) }

    func makeNSView(context: Context) -> NSSegmentedControl {
        let control = NSSegmentedControl(labels: periods.map(\.title), trackingMode: .selectOne,
            target: context.coordinator, action: #selector(Coordinator.selectPeriod(_:)))
        control.controlSize = .small
        control.font = .systemFont(ofSize: 11)
        control.segmentStyle = .rounded
        control.setAccessibilityLabel("Période de comparaison")
        return control
    }

    func updateNSView(_ control: NSSegmentedControl, context: Context) {
        context.coordinator.selection = $selection
        context.coordinator.periods = periods
        control.segmentCount = periods.count
        for (index, period) in periods.enumerated() {
            control.setLabel(period.title, forSegment: index)
            control.setToolTip(period.title, forSegment: index)
        }
        control.selectedSegmentBezelColor = NSColor(accent)
        control.selectedSegment = periods.firstIndex(of: selection) ?? -1
    }

    @MainActor final class Coordinator: NSObject {
        var selection: Binding<HistoryPeriod>
        var periods: [HistoryPeriod]
        init(selection: Binding<HistoryPeriod>, periods: [HistoryPeriod]) {
            self.selection = selection; self.periods = periods
        }

        @objc func selectPeriod(_ sender: NSSegmentedControl) {
            guard periods.indices.contains(sender.selectedSegment) else { return }
            selection.wrappedValue = periods[sender.selectedSegment]
        }
    }
}

struct RibbonCard: View {
    @Environment(\.semaAccent) private var accent
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hovered = false
    let series: MarketSeries
    let period: HistoryPeriod
    let action: () -> Void
    private var points: [MarketObservation] { series.history(for: period) }
    private var comparison: String {
        series.supports(period) ? MarketFormat.change(series, period: period) : "Historique partiel"
    }

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
            .modifier(RibbonSurface(emphasized: hovered))
            .contentShape(RoundedRectangle(cornerRadius: MenuRibbonLayout.cardCornerRadius))
        }
        .buttonStyle(SemaPressStyle())
        .onHover { hovered = $0 }
        .animation(reduceMotion ? nil : .easeOut(duration: MenuRibbonLayout.hoverDuration), value: hovered)
        .help(MarketFormat.name(series) + " · Ouvrir le détail dans sema")
        .accessibilityLabel(accessibilityDescription)
    }

    private var heading: some View {
        HStack(spacing: 10) {
            Text(MarketFormat.name(series)).font(.system(size: 13, weight: .medium)).lineLimit(2)
            Spacer(minLength: 0)
        }
    }
    private var value: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(series.latest.map { MarketFormat.number($0.value, digits: series.fractionDigits) } ?? "—")
                .font(.system(size: 32, weight: .medium)).tracking(-0.9).monospacedDigit()
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(MarketFormat.unit(series)).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(2)
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
            Text(comparison).lineLimit(1)
            Spacer(minLength: 0)
            Text(series.latest.map { MarketFormat.date($0.date) } ?? "Aucune publication").lineLimit(1)
        }
        .font(.system(size: 11)).monospacedDigit().foregroundStyle(.secondary)
    }
    private var accessibilityDescription: String {
        MarketFormat.name(series) + ", " + MarketFormat.value(series)
            + (series.isDemo ? ", démonstration" : "") + ", " + comparison
            + " sur " + period.title + ", publication du " + MarketFormat.date(series.latest?.date)
    }
}
