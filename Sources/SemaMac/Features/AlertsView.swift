// Liste les règles de seuil avec leurs actions de pause, suppression et test.
import SwiftUI
import MarketCore

struct AlertsView: View {
    private static let sectionSpacing: CGFloat = 20
    private static let emptyMinHeight: CGFloat = 350
    @Environment(AppStore.self) private var store
    var body: some View {
        VStack(alignment: .leading, spacing: Self.sectionSpacing) {
            Label("Vérification à chaque actualisation des repères. Aucun contrôle quand l’app est quittée ou le Mac en veille.", systemImage: "info.circle")
                .font(.callout).foregroundStyle(.secondary)
            if store.macroAlerts.isEmpty {
                ContentUnavailableView {
                    Label("Un signal au bon seuil.", systemImage: "bell")
                } description: {
                    Text("Suivez le franchissement d’un seuil sur les taux, l’inflation ou les devises.")
                } actions: {
                    if store.alertableSeries.isEmpty {
                        Button("Explorer les repères") { store.section = .explorer }.buttonStyle(.borderedProminent)
                    } else {
                        Button("Créer une alerte") { store.isAlertSheetPresented = true }.buttonStyle(.borderedProminent)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: Self.emptyMinHeight)
            } else {
                VStack(spacing: 0) {
                    ForEach(store.macroAlerts) { rule in
                        AlertRow(rule: rule)
                        if rule.id != store.macroAlerts.last?.id { Divider() }
                    }
                }
            }
        }
    }
}

private struct AlertRow: View {
    private static let titleFont = Font.system(size: 14, weight: .medium)
    private static let iconSpacing: CGFloat = 14
    private static let iconSize: CGFloat = 30
    private static let textSpacing: CGFloat = 9
    private static let actionSpacing: CGFloat = 16
    private static let verticalPadding: CGFloat = 18
    @Environment(AppStore.self) private var store
    @Environment(\.semaAccent) private var accent
    let rule: AlertRule
    private var item: MarketSeries? { store.series.first { $0.id == rule.seriesID } }
    private var lastEvent: AlertEvent? { store.recentAlertEvents.last { $0.ruleID == rule.id } }

    var body: some View {
        HStack(alignment: .top, spacing: Self.iconSpacing) {
            Image(systemName: rule.isEnabled ? "bell" : "bell.slash").foregroundStyle(accent)
                .frame(width: Self.iconSize, height: Self.iconSize)
            VStack(alignment: .leading, spacing: Self.textSpacing) {
                Text(item?.name ?? "Repère indisponible").font(Self.titleFont)
                Text("\(rule.direction.crossingTitle) \(MarketFormat.number(rule.threshold, digits: item?.fractionDigits ?? 2)) \(item?.displayUnit ?? "").")
                    .font(.callout).foregroundStyle(.secondary)
                if let event = lastEvent, let value = event.observedValue {
                    Text("Dernier signal : \(MarketFormat.number(value, digits: item?.fractionDigits ?? 2)) \(item?.displayUnit ?? "") · \(MarketFormat.date(event.observedAt))")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                HStack(spacing: Self.actionSpacing) {
                    Button("Tester la notification") { store.simulate(rule) }.disabled(!store.isSourceEnabled(for: rule.seriesID))
                    Button(rule.isEnabled ? "Mettre en pause" : "Réactiver") { store.toggleAlert(rule.id) }
                        .disabled(!store.isSourceEnabled(for: rule.seriesID) || (!rule.isEnabled && (!store.isFollowing(rule.seriesID) || item?.canAlert != true)))
                    Button(role: .destructive) { store.deleteAlert(rule.id) } label: { Image(systemName: "trash") }
                        .help("Supprimer cette alerte").accessibilityLabel("Supprimer l’alerte sur \(item?.name ?? "ce repère")")
                }
                .buttonStyle(.borderless).font(.subheadline)
            }
            Spacer(minLength: 0)
            Text(!store.isFollowing(rule.seriesID) ? "Repère retiré · en pause" : !store.isSourceEnabled(for: rule.seriesID) ? "Source désactivée · en pause" : !rule.isEnabled ? "En pause" : item?.canAlert == false ? "Unité à vérifier" : item?.isDemo == true ? "Démo · connexion requise" : "À l’actualisation")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .padding(.vertical, Self.verticalPadding)
    }
}
