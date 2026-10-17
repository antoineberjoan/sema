// Présente, édite et teste les règles de seuil sur les séries suivies.
import SwiftUI
import MarketCore

struct AlertsView: View {
    @Environment(AppStore.self) private var store
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("Vérification à chaque actualisation des repères. Aucun contrôle quand l’app est quittée ou le Mac en veille.", systemImage: "info.circle")
                .font(.system(size: 12)).foregroundStyle(.secondary)
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
                .frame(maxWidth: .infinity, minHeight: 350)
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
    @Environment(AppStore.self) private var store
    @Environment(\.semaAccent) private var accent
    let rule: AlertRule
    private var item: MarketSeries? { store.series.first { $0.id == rule.seriesID } }
    private var lastEvent: AlertEvent? { store.recentAlertEvents.last { $0.ruleID == rule.id } }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: rule.isEnabled ? "bell" : "bell.slash").foregroundStyle(accent)
                .frame(width: 30, height: 30)
            VStack(alignment: .leading, spacing: 9) {
                Text(item?.name ?? "Repère indisponible").font(.system(size: 14, weight: .medium))
                Text("\(rule.direction.crossingTitle) \(MarketFormat.number(rule.threshold, digits: item?.fractionDigits ?? 2)) \(item?.displayUnit ?? "").")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
                if let event = lastEvent, let value = event.observedValue {
                    Text("Dernier signal : \(MarketFormat.number(value, digits: item?.fractionDigits ?? 2)) \(item?.displayUnit ?? "") · \(MarketFormat.date(event.observedAt))")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
                HStack(spacing: 16) {
                    Button("Tester la notification") { store.simulate(rule) }.disabled(!store.isSourceEnabled(for: rule.seriesID))
                    Button(rule.isEnabled ? "Mettre en pause" : "Réactiver") { store.toggleAlert(rule.id) }
                        .disabled(!store.isSourceEnabled(for: rule.seriesID) || (!rule.isEnabled && (!store.isFollowing(rule.seriesID) || item?.canAlert != true)))
                    Button(role: .destructive) { store.deleteAlert(rule.id) } label: { Image(systemName: "trash") }
                        .help("Supprimer cette alerte").accessibilityLabel("Supprimer l’alerte sur \(item?.name ?? "ce repère")")
                }
                .buttonStyle(.borderless).font(.system(size: 11))
            }
            Spacer(minLength: 0)
            Text(!store.isFollowing(rule.seriesID) ? "Repère retiré · en pause" : !store.isSourceEnabled(for: rule.seriesID) ? "Source désactivée · en pause" : !rule.isEnabled ? "En pause" : item?.canAlert == false ? "Unité à vérifier" : item?.isDemo == true ? "Démo · connexion requise" : "À l’actualisation")
                .font(.system(size: 11)).foregroundStyle(.secondary)
        }
        .padding(.vertical, 18)
    }
}

struct AlertEditorView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var seriesID = ""
    @State private var direction: AlertDirection = .rise
    @State private var thresholdText = "3,0"
    private var threshold: Decimal? { AlertThreshold.parseLevel(thresholdText) }
    private var item: MarketSeries? { store.macroSeries.first { $0.id == seriesID } }

    private static let sheetWidth: CGFloat = 480
    private static let inset: CGFloat = 24
    private static let rowSpacing: CGFloat = 16

    var body: some View {
        VStack(alignment: .leading, spacing: Self.inset) {
            Text("Créer une alerte").font(.title2.weight(.semibold))
            Grid(alignment: .leading, horizontalSpacing: Self.rowSpacing, verticalSpacing: Self.rowSpacing) {
                GridRow {
                    Text("Repère").gridColumnAlignment(.trailing)
                    Picker("Repère", selection: $seriesID) {
                        ForEach(store.alertableSeries) { Text($0.name).tag($0.id) }
                    }.labelsHidden().frame(maxWidth: .infinity, alignment: .leading)
                }
                GridRow {
                    Text("Franchissement")
                    Picker("Franchissement", selection: $direction) {
                        ForEach(AlertDirection.allCases, id: \.self) { Text($0.crossingTitle.lowercased()).tag($0) }
                    }.labelsHidden().frame(maxWidth: .infinity, alignment: .leading)
                        .help("Un nouveau passage strict au-dessus ou au-dessous du seuil est nécessaire.")
                }
                GridRow {
                    Text("Seuil")
                    HStack(spacing: SemaTheme.minorSpacing) {
                        TextField("Seuil", text: $thresholdText)
                            .textFieldStyle(.roundedBorder).accessibilityLabel("Seuil")
                        Text(item?.displayUnit ?? "").foregroundStyle(.secondary)
                    }
                }
            }
            if threshold == nil {
                Text("Saisissez un nombre valide, par exemple 3,5.")
                    .font(.callout).foregroundStyle(.red)
            }
            if let item {
                VStack(alignment: .leading, spacing: SemaTheme.minorSpacing) {
                    HStack {
                        Text("Dernière valeur").foregroundStyle(.secondary)
                        Spacer()
                        Text(MarketFormat.value(item)).monospacedDigit()
                    }
                    Text(item.isDemo
                         ? "Données fictives · vérification après connexion."
                         : "Vérification à l’actualisation des repères.")
                        .font(.callout).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .help("Aucun contrôle quand sema est quittée ou le Mac en veille. La règle suit les nouvelles observations publiées.")
                }
            }
            HStack {
                Spacer()
                Button("Annuler") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Créer l’alerte") {
                    if let threshold, store.addAlert(seriesID: seriesID, direction: direction, threshold: threshold) { dismiss() }
                }
                .buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction).disabled(threshold == nil || item?.canAlert != true)
            }
        }
        .padding(Self.inset).frame(width: Self.sheetWidth)
        .onAppear {
            seriesID = store.alertableSeries.first(where: { $0.id == store.selectedSeriesID })?.id ?? store.alertableSeries.first?.id ?? ""
            thresholdText = item?.latest.map { NSDecimalNumber(decimal: $0.value).stringValue.replacingOccurrences(of: ".", with: ",") } ?? "3,0"
        }
        .onChange(of: seriesID) { _, _ in
            if let value = item?.latest?.value {
                thresholdText = NSDecimalNumber(decimal: value).stringValue.replacingOccurrences(of: ".", with: ",")
            }
        }
    }
}

struct DemoNotificationView: View {
    @Environment(AppStore.self) private var store
    let event: AlertEvent
    private var item: MarketSeries? { store.series.first { $0.id == event.seriesID } }
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            SemaMark(size: 30)
            VStack(alignment: .leading, spacing: 6) {
                Text("sema · TEST DE NOTIFICATION").font(.system(size: 9, weight: .medium)).tracking(0.5).foregroundStyle(.secondary)
                Text(item?.name ?? "Repère de démonstration").font(.system(size: 13, weight: .medium))
                Text("Valeur simulée : \(MarketFormat.number(event.observedValue ?? 0, digits: item?.fractionDigits ?? 2)) \(item?.displayUnit ?? "").")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Button { store.simulatedEvent = nil } label: { Image(systemName: "xmark").font(.system(size: 11)).foregroundStyle(.secondary) }
                .buttonStyle(.plain).accessibilityLabel("Fermer la notification")
        }
        .padding(17).frame(width: 345)
        .background(SemaTheme.surface, in: RoundedRectangle(cornerRadius: 15))
        .modifier(SemaElevation())
        .accessibilityElement(children: .contain)
    }
}
