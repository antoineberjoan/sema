// Rubrique Panorama : le repère sélectionné en mode Focus et le passage rapide aux autres.
import SwiftUI

struct OverviewView: View {
    private static let sectionSpacing: CGFloat = 32
    private static let switcherSpacing: CGFloat = 28
    private static let switcherBottomPadding: CGFloat = 10
    private static let switcherInset: CGFloat = 2
    private static let emptyMinHeight: CGFloat = 450
    @Environment(AppStore.self) private var store
    var showsQuickSwitcher = false

    var body: some View {
        if let selected = store.selectedSeries {
            VStack(spacing: Self.sectionSpacing) {
                SeriesDetailView(series: selected, focus: true)
                if showsQuickSwitcher {
                    ScrollView(.horizontal) {
                        HStack(spacing: Self.switcherSpacing) {
                            ForEach(store.followedSeries) { item in
                                let current = item.id == selected.id
                                Button { store.show(item) } label: {
                                    Text(store.displayedSeries(item).name)
                                        .font(.callout).foregroundStyle(current ? .primary : .secondary)
                                        .padding(.bottom, Self.switcherBottomPadding)
                                        .overlay(alignment: .bottom) {
                                            if current { Rectangle().frame(height: 1).foregroundStyle(.primary) }
                                        }
                                }
                                .buttonStyle(.plain).accessibilityAddTraits(current ? .isSelected : [])
                            }
                        }.padding(.horizontal, Self.switcherInset)
                    }
                    .scrollIndicators(.hidden).fixedSize(horizontal: false, vertical: true)
                }
            }
        } else {
            ContentUnavailableView {
                Label("Vos repères, à votre façon.", systemImage: "chart.xyaxis.line")
            } description: {
                Text("Explorez les catalogues pour composer votre sélection.")
            } actions: {
                Button("Explorer les repères") { store.section = .explorer }.buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, minHeight: Self.emptyMinHeight)
        }
    }
}
