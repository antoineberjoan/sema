import SwiftUI
import MarketCore

struct AlertsView: View {
    @Environment(AppStore.self) private var store
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("Vérification à chaque actualisation Webstat. Aucun contrôle quand l’app est quittée ou le Mac en veille.", systemImage: "info.circle")
                .font(.system(size: 12)).foregroundStyle(.secondary)
            if store.macroAlerts.isEmpty {
                ContentUnavailableView {
                    Label("Un signal au bon seuil.", systemImage: "bell")
                } description: {
                    Text("Suivez le franchissement d’un seuil sur les taux, l’inflation ou les devises.")
                } actions: {
                    Button("Créer une alerte") { store.isAlertSheetPresented = true }.buttonStyle(.borderedProminent)
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
                    Button("Tester la notification") { store.simulate(rule) }
                    Button(rule.isEnabled ? "Mettre en pause" : "Réactiver") { store.toggleAlert(rule.id) }
                        .disabled(!rule.isEnabled && (!store.isFollowing(rule.seriesID) || item?.canAlert != true))
                    Button(role: .destructive) { store.deleteAlert(rule.id) } label: { Image(systemName: "trash") }
                        .help("Supprimer cette alerte").accessibilityLabel("Supprimer l’alerte sur \(item?.name ?? "ce repère")")
                }
                .buttonStyle(.borderless).font(.system(size: 11))
            }
            Spacer(minLength: 0)
            Text(!store.isFollowing(rule.seriesID) ? "Repère retiré · en pause" : !rule.isEnabled ? "En pause" : item?.canAlert == false ? "Unité à vérifier" : item?.isDemo == true ? "Démo · connexion requise" : "À l’actualisation")
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

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Créer une alerte").font(.title2)
            Form {
                Picker("Repère", selection: $seriesID) {
                    ForEach(store.macroSeries.filter(\.canAlert)) { Text($0.name).tag($0.id) }
                }
                Picker("Me prévenir quand la valeur", selection: $direction) {
                    ForEach(AlertDirection.allCases, id: \.self) { Text($0.crossingTitle.lowercased()).tag($0) }
                }
                HStack {
                    TextField("Seuil", text: $thresholdText).textFieldStyle(.roundedBorder).frame(width: 190)
                    Text(item?.displayUnit ?? "").foregroundStyle(.secondary)
                }
                if threshold == nil {
                    Text("Saisissez un nombre, par exemple 3,5. Zéro et les valeurs négatives sont acceptés.")
                        .font(.system(size: 11)).foregroundStyle(.red)
                }
                if let item {
                    LabeledContent("Dernière valeur") { Text(MarketFormat.value(item) + (item.unit == .percent ? "" : " " + item.displayUnit)) }
                    Text(item.isDemo ? "Valeurs fictives : connectez Webstat pour activer la vérification réelle."
                         : item.frequency == .monthly ? "Publication mensuelle : l’alerte suit les nouveaux mois publiés."
                         : "L’alerte suit les nouvelles observations publiées par la source.")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }
            Label("Un nouveau franchissement strict est nécessaire. Vérification à l’actualisation Webstat ; aucune surveillance en arrière-plan.", systemImage: "info.circle")
                .font(.system(size: 11)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            HStack {
                Button("Annuler") { dismiss() }.keyboardShortcut(.cancelAction)
                Spacer()
                Button("Créer l’alerte") {
                    if let threshold, store.addAlert(seriesID: seriesID, direction: direction, threshold: threshold) { dismiss() }
                }
                .buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction).disabled(threshold == nil || item?.canAlert != true)
            }
        }
        .padding(30).frame(width: 530)
        .onAppear {
            seriesID = store.selectedSeriesID
            thresholdText = store.selectedSeries?.latest.map { NSDecimalNumber(decimal: $0.value).stringValue.replacingOccurrences(of: ".", with: ",") } ?? "3,0"
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
                Text("SEMA · TEST DE NOTIFICATION").font(.system(size: 9, weight: .medium)).tracking(0.5).foregroundStyle(.secondary)
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
