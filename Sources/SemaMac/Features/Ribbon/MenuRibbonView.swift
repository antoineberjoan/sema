// Présente les favoris et leurs historiques dans le bandeau partagé avec le hub.
import AppKit
import SwiftUI
import MarketCore

struct MenuRibbonView: View {
    private static let cardsVerticalPadding: CGFloat = 2
    private static let periodSpacing: CGFloat = 2
    private static let periodLabelSpacing: CGFloat = 7
    private static let indicatorWidth: CGFloat = 3
    private static let indicatorHeight: CGFloat = 12
    private static let periodPadding: CGFloat = 6
    private static let verticalPickerWidth: CGFloat = 278
    private static let pickerWidth: CGFloat = 350
    private static let pickerHorizontalPadding: CGFloat = 10
    private static let pickerVerticalPadding: CGFloat = 3
    private static let emptySpacing: CGFloat = 10
    private static let emptyButtonTopPadding: CGFloat = 4
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
                        }.padding(.vertical, Self.cardsVerticalPadding)
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
        .environment(\.locale, .french)
        .task { await store.checkWebstatKey() }
    }

    private var horizontalFavorites: some View {
        GeometryReader { geometry in
            // Reserve a slot outside the scroll view so feedback is always visible.
            let capacity = max(1, Int((geometry.size.width + MenuRibbonLayout.spacing)
                                     / (MenuRibbonLayout.minimumCardWidth + MenuRibbonLayout.spacing)) - 1)
            let visibleCount = max(1, min(items.count, capacity, MenuRibbonLayout.preferredVisibleCards))
            let cardWidth = (geometry.size.width - CGFloat(visibleCount) * MenuRibbonLayout.spacing)
                / CGFloat(visibleCount + 1)
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
        VStack(spacing: Self.periodSpacing) {
            if !items.isEmpty {
                ForEach(HistoryPeriod.visible) { candidate in
                    Button { period = candidate } label: {
                        HStack(spacing: Self.periodLabelSpacing) {
                            Capsule().fill(period == candidate ? store.palette.accent : .clear)
                                .frame(width: Self.indicatorWidth, height: Self.indicatorHeight)
                            Text(candidate.title).font(.subheadline.weight(period == candidate ? .semibold : .regular))
                                .fixedSize(horizontal: true, vertical: false)
                                .foregroundStyle(.primary)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, Self.periodPadding)
                        .frame(maxWidth: .infinity).frame(height: MenuRibbonLayout.periodRowHeight)
                        .background(.regularMaterial, in: Capsule())
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PressStyle())
                    .accessibilityAddTraits(period == candidate ? .isSelected : [])
                    .help(candidate.title + " · Historique disponible sur ce Mac")
                }
            }
            Spacer(minLength: Self.periodSpacing)
            settingsButton
        }
        .padding(MenuRibbonLayout.controlColumnPadding)
        .frame(width: MenuRibbonLayout.controlColumnWidth, height: MenuRibbonLayout.cardHeight)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Période de comparaison et réglages")
    }

    private var settingsButton: some View {
        Button(action: openSettings) {
            Image(systemName: "gearshape").frame(width: Theme.iconButtonSize, height: Theme.iconButtonSize).contentShape(Circle())
        }
        .buttonStyle(.plain)
        .background(.regularMaterial, in: Circle())
        .help("Réglages de sema").accessibilityLabel("Réglages de sema")
    }

    private var header: some View {
        HStack(spacing: 0) {
            Spacer()
            HStack(spacing: Theme.minorSpacing) {
                if !items.isEmpty {
                    RibbonPeriodPicker(selection: $period, accent: store.palette.controlAccent)
                        .frame(width: isVertical ? Self.verticalPickerWidth : Self.pickerWidth)
                        .help("Historique disponible sur ce Mac · Tout utilise le cache chargé")
                }
                settingsButton
            }
            .padding(.horizontal, Self.pickerHorizontalPadding).padding(.vertical, Self.pickerVerticalPadding)
            .modifier(RibbonSurface())
        }
        .foregroundStyle(.primary).frame(height: MenuRibbonLayout.headerHeight)
    }

    private var emptyState: some View {
        VStack(spacing: Self.emptySpacing) {
            Image(systemName: "star").font(MenuRibbonLayout.emptySymbolFont).foregroundStyle(store.palette.accent)
            Text("Vos repères, en un coup d’œil.").font(.title2.weight(.medium))
            Text("Épinglez les repères à retrouver dans ce bandeau.").font(.callout).foregroundStyle(.secondary)
            Button("Choisir mes favoris") { store.section = .overview; openWorkspace() }
                .buttonStyle(.borderedProminent).controlSize(.small).padding(.top, Self.emptyButtonTopPadding)
        }
        .padding(MenuRibbonLayout.cardPadding).modifier(RibbonSurface())
    }

    private func open(_ item: MarketSeries) { store.show(item); store.section = .overview; openWorkspace() }
}

/// Les cinq horizons restent directement disponibles dans un contrôle natif.
private struct RibbonPeriodPicker: NSViewRepresentable {
    @Binding var selection: HistoryPeriod
    let accent: Color
    private let periods = HistoryPeriod.visible

    func makeCoordinator() -> Coordinator { Coordinator(selection: $selection, periods: periods) }

    func makeNSView(context: Context) -> NSSegmentedControl {
        let control = NSSegmentedControl(labels: periods.map(\.title), trackingMode: .selectOne,
            target: context.coordinator, action: #selector(Coordinator.selectPeriod(_:)))
        control.controlSize = .small
        control.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
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
