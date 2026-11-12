// Présente les favoris et leurs historiques dans le bandeau partagé avec le hub.
import SemaDesign
import SwiftUI
import MarketCore

struct MenuRibbonView: View {
    private static let cardsVerticalPadding = DesignSpace.listGapDense
    private static let headerHorizontalPadding = DesignSpace.frameInset
    private static let headerVerticalPadding = DesignSpace.markInset
    private static let emptySpacing = DesignSpace.fieldGap
    private static let emptyButtonTopPadding = DesignSpace.markInset
    @Environment(AppStore.self) private var store
    let presentationID: UUID?
    let openWorkspace: () -> Void
    let openSettings: () -> Void

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
                                RibbonCard(series: store.displayedSeries(item), period: store.period(for: item)) { open(item) }
                                    .frame(height: MenuRibbonLayout.cardHeight)
                            }
                            AgendaCard(openWorkspace: openWorkspace).frame(height: MenuRibbonLayout.cardHeight)
                        }.padding(.vertical, Self.cardsVerticalPadding)
                    }.scrollIndicators(.automatic).scrollClipDisabled()
                }
                RibbonSignatureView(presentationID: presentationID).frame(height: MenuRibbonLayout.signatureHeight)
                header
            } else {
                // The ribbon follows the period chosen in the hub: no rail, the cards take the whole width.
                horizontalFavorites.frame(height: MenuRibbonLayout.cardHeight)
            }
        }
        .padding(.horizontal, MenuRibbonLayout.padding)
        .padding(.top, MenuRibbonLayout.topPadding)
        .padding(.bottom, MenuRibbonLayout.bottomPadding)
        .modifier(RibbonEnvironment(store: store))
        .task { await store.checkWebstatKey() }
    }

    private var horizontalFavorites: some View {
        GeometryReader { geometry in
            // Two slots stay outside the scroll view: the agenda and the signature, always visible.
            let capacity = max(1, Int((geometry.size.width + MenuRibbonLayout.spacing)
                                     / (MenuRibbonLayout.minimumCardWidth + MenuRibbonLayout.spacing)) - MenuRibbonLayout.fixedCards)
            let visibleCount = max(1, min(items.count, capacity, MenuRibbonLayout.preferredVisibleCards))
            let cardWidth = (geometry.size.width - CGFloat(visibleCount + MenuRibbonLayout.fixedCards - 1) * MenuRibbonLayout.spacing)
                / CGFloat(visibleCount + MenuRibbonLayout.fixedCards)
            HStack(spacing: MenuRibbonLayout.spacing) {
                if items.isEmpty {
                    emptyState.frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: MenuRibbonLayout.spacing) {
                            ForEach(items) { item in
                                RibbonCard(series: store.displayedSeries(item), period: store.period(for: item)) { open(item) }
                                    .frame(width: cardWidth, height: MenuRibbonLayout.cardHeight)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollIndicators(.automatic)
                    .scrollTargetBehavior(.viewAligned)
                    .frame(width: CGFloat(visibleCount) * cardWidth + CGFloat(visibleCount - 1) * MenuRibbonLayout.spacing)
                }
                AgendaCard(openWorkspace: openWorkspace).frame(width: cardWidth, height: MenuRibbonLayout.cardHeight)
                RibbonSignatureView(presentationID: presentationID)
                    .frame(width: cardWidth, height: MenuRibbonLayout.signatureHeight)
                    .overlay(alignment: .topTrailing) { settingsButton.padding(DesignSpace.rowInset) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: MenuRibbonLayout.cardHeight)
        }
    }

    private var settingsButton: some View {
        Button(action: openSettings) {
            Image(systemName: "gearshape").frame(width: DesignIcon.buttonSize, height: DesignIcon.buttonSize).contentShape(Circle())
        }
        .buttonStyle(.plain)
        .background(.regularMaterial, in: Circle())
        .help("Réglages de sema").accessibilityLabel("Réglages de sema")
    }

    private var header: some View {
        HStack(spacing: 0) {
            Spacer()
            HStack(spacing: DesignIcon.gap) {
                Text(store.period.title).typeRole(.caption).foregroundStyle(.secondary)
                    .help("Période choisie dans le hub")
                settingsButton
            }
            .padding(.horizontal, Self.headerHorizontalPadding).padding(.vertical, Self.headerVerticalPadding)
            .modifier(RibbonSurface())
        }
        .foregroundStyle(DesignColor.text).frame(height: MenuRibbonLayout.headerHeight)
    }

    private var emptyState: some View {
        VStack(spacing: Self.emptySpacing) {
            Image(systemName: "star").typeRole(.figure).foregroundStyle(DesignColor.accentText(store.palette))
            Text("Vos repères, en un coup d’œil.").typeRole(.section)
            Text("Épinglez les repères à retrouver dans ce bandeau.").typeRole(.small).foregroundStyle(.secondary)
            Button("Choisir mes favoris") { store.section = .overview; openWorkspace() }
                .buttonStyle(.borderedProminent).controlSize(.small).padding(.top, Self.emptyButtonTopPadding)
        }
        .padding(MenuRibbonLayout.cardPadding).modifier(RibbonSurface())
    }

    private func open(_ item: MarketSeries) { store.show(item); store.section = .overview; openWorkspace() }
}
