// Aperçu dans l’app d’une notification de seuil simulée.
import SwiftUI
import MarketCore

struct DemoNotificationView: View {
    private static let markSize: CGFloat = 30
    private static let bannerWidth: CGFloat = 345
    private static let contentPadding: CGFloat = 17
    private static let markSpacing: CGFloat = 12
    private static let textSpacing: CGFloat = 6
    private static let eyebrowTracking: CGFloat = 0.5
    private static let eyebrowFont = Font.system(size: 9, weight: .medium)
    @Environment(AppStore.self) private var store
    let event: AlertEvent
    private var item: MarketSeries? { store.series.first { $0.id == event.seriesID } }
    var body: some View {
        HStack(alignment: .top, spacing: Self.markSpacing) {
            SemaMark(size: Self.markSize)
            VStack(alignment: .leading, spacing: Self.textSpacing) {
                Text("sema · TEST DE NOTIFICATION").font(Self.eyebrowFont).tracking(Self.eyebrowTracking).foregroundStyle(.secondary)
                Text(item.map(MarketFormat.name) ?? "Repère de démonstration").font(.body.weight(.medium))
                Text("Valeur simulée : \(MarketFormat.number(event.observedValue ?? 0, digits: item?.fractionDigits ?? 2)) \(item.map(MarketFormat.unit) ?? "").")
                    .font(.callout).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Button { store.simulatedEvent = nil } label: { Image(systemName: "xmark").font(.subheadline).foregroundStyle(.secondary) }
                .buttonStyle(.plain).accessibilityLabel("Fermer la notification")
        }
        .padding(Self.contentPadding).frame(width: Self.bannerWidth)
        .background(SemaTheme.surface, in: RoundedRectangle(cornerRadius: SemaTheme.cardCorner))
        .modifier(SemaElevation())
        .accessibilityElement(children: .contain)
    }
}
