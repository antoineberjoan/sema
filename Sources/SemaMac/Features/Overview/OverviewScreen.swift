// Rubrique Panorama : le repère sélectionné en mode Focus et le passage rapide aux autres.
import SemaDesign
import SwiftUI

struct OverviewScreen: View {
    private static let sectionSpacing = DesignSpace.sectionGap
    private static let switcherSpacing = DesignSpace.groupGap
    private static let switcherBottomPadding = DesignSpace.frameInset
    private static let switcherInset = DesignSpace.markInset
    private static let emptyMinHeight: CGFloat = 450
    @Environment(AppStore.self) private var store
    @Environment(\.openSettings) private var openSettings
    var isQuickSwitcherShown = false

    var body: some View {
        if let selected = store.selectedSeries {
            VStack(spacing: Self.sectionSpacing) {
                SeriesDetailView(series: selected, isFocus: true)
                if isQuickSwitcherShown {
                    ScrollView(.horizontal) {
                        HStack(spacing: Self.switcherSpacing) {
                            ForEach(store.followedSeries) { item in
                                let isCurrent = item.id == selected.id
                                Button { store.show(item) } label: {
                                    Text(MarketFormat.name(store.displayedSeries(item)))
                                        .typeRole(.small).foregroundStyle(isCurrent ? DesignColor.text : DesignColor.textMuted)
                                        .padding(.bottom, Self.switcherBottomPadding)
                                        .overlay(alignment: .bottom) {
                                            if isCurrent { Rectangle().frame(height: DesignBorder.width).foregroundStyle(DesignColor.text) }
                                        }
                                }
                                .buttonStyle(.plain).accessibilityAddTraits(isCurrent ? [.isSelected] : [])
                            }
                        }.padding(.horizontal, Self.switcherInset)
                    }
                    .scrollIndicators(.hidden).fixedSize(horizontal: false, vertical: true)
                }
            }
        } else if !store.storedFollowedSeries.isEmpty && !store.hasWebstatKey {
            ContentUnavailableView {
                Label("Vos repères attendent leurs données", systemImage: "key")
            } description: {
                Text("Connectez votre clé Webstat pour afficher vos repères.")
            } actions: {
                Button("Connecter Webstat") { store.settingsTab = .sources; openSettings() }.buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, minHeight: Self.emptyMinHeight, maxHeight: .infinity)
        } else {
            ContentUnavailableView {
                Label("Vos repères, à votre façon.", systemImage: "chart.xyaxis.line")
            } description: {
                Text("Explorez les catalogues pour composer votre sélection.")
            } actions: {
                Button("Explorer les repères") { store.section = .explorer }.buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, minHeight: Self.emptyMinHeight, maxHeight: .infinity)
        }
    }
}
