import SwiftUI
import MarketCore

struct FundsView: View {
    @Environment(AppStore.self) private var store
    private var matches: [MarketSeries] {
        store.funds.filter { store.search.isEmpty || ($0.name + " " + $0.subtitle).localizedCaseInsensitiveContains(store.search) }
    }

    var body: some View {
        @Bindable var store = store
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Rechercher un fonds", text: $store.search).textFieldStyle(.plain)
                }
                .padding(10).background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
                HStack {
                    Text("\(store.funds.count) fonds suivis")
                    Spacer()
                    Text("VL · variation / jour")
                }
                .font(.system(size: 11)).foregroundStyle(.secondary)
                if matches.isEmpty {
                    Text("Aucun fonds correspondant.").font(.system(size: 12)).foregroundStyle(.secondary).padding(.vertical, 20)
                }
                ForEach(matches) { fund in
                    ZStack(alignment: .topTrailing) {
                        Button { store.show(fund) } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(fund.name).font(.system(size: 14, weight: .medium)).padding(.trailing, 25)
                                Text(fund.subtitle).font(.system(size: 11)).foregroundStyle(.secondary)
                                HStack {
                                    Text(MarketFormat.value(fund))
                                    Spacer()
                                    if let delta = fund.dailyChange {
                                        Text(MarketFormat.number(delta, signed: true) + " % / j").foregroundStyle(.secondary)
                                    }
                                }
                                .font(.system(size: 12)).monospacedDigit().padding(.top, 3)
                            }
                            .padding(15).frame(maxWidth: .infinity, alignment: .leading)
                            .background(store.selectedFundID == fund.id ? SemaTheme.accent.opacity(0.10) : SemaTheme.surface,
                                        in: RoundedRectangle(cornerRadius: 12))
                            .contentShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        FavoriteButton(seriesID: fund.id).padding(9)
                    }
                }
                Label("Les fonds de cette version sont fictifs.", systemImage: "info.circle")
                    .font(.system(size: 11)).foregroundStyle(.secondary).padding(.top, 9)
            }
            .frame(width: 310)
            SeriesDetailView(series: store.selectedFund).frame(maxWidth: .infinity)
        }
    }
}
