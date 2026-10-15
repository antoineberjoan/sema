import SwiftUI
import MarketCore

struct AlertsView: View {
    @Environment(AppStore.self) private var store
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("Les alertes de cette version fonctionnent en démonstration. Aucune surveillance automatique des fonds n’est active.", systemImage: "info.circle")
                .font(.system(size: 12)).foregroundStyle(.secondary)
            if store.preferences.alerts.isEmpty {
                ContentUnavailableView {
                    Label("Un œil sur vos fonds.", systemImage: "bell")
                } description: {
                    Text("Choisissez une part de fonds et le seuil de variation qui vous intéresse.")
                } actions: {
                    Button("Créer une alerte") { store.isAlertSheetPresented = true }.buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, minHeight: 350)
            } else {
                VStack(spacing: 0) {
                    ForEach(store.preferences.alerts) { rule in
                        AlertRow(rule: rule)
                        if rule.id != store.preferences.alerts.last?.id { Divider().padding(.leading, 62) }
                    }
                }
                .background(SemaTheme.surface, in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }
}

private struct AlertRow: View {
    @Environment(AppStore.self) private var store
    let rule: AlertRule
    private var fund: MarketSeries? { store.funds.first { $0.id == rule.seriesID } }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: rule.isEnabled ? "bell" : "bell.slash")
                .foregroundStyle(SemaTheme.accent).frame(width: 33, height: 33)
                .background(SemaTheme.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 9) {
                Text(fund?.name ?? "Fonds indisponible").font(.system(size: 14, weight: .medium))
                Text(fund?.subtitle ?? rule.seriesID).font(.system(size: 11)).foregroundStyle(.secondary)
                Text("\(rule.direction.title) supérieure à \(MarketFormat.number(rule.threshold, digits: 1)) % entre deux publications.")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
                HStack(spacing: 16) {
                    Button("Tester la notification") { store.simulate(rule) }
                    Button(rule.isEnabled ? "Mettre en pause" : "Réactiver") { store.toggleAlert(rule.id) }
                    Button(role: .destructive) { store.deleteAlert(rule.id) } label: { Image(systemName: "trash") }
                        .help("Supprimer cette alerte").accessibilityLabel("Supprimer l’alerte sur \(fund?.name ?? "ce fonds")")
                }
                .buttonStyle(.borderless).font(.system(size: 11))
            }
            Spacer(minLength: 0)
            Text(rule.isEnabled ? "Active · démo" : "En pause").font(.system(size: 10)).foregroundStyle(.secondary)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 6))
        }
        .padding(20)
    }
}

struct AlertEditorView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var fundID = ""
    @State private var direction: AlertDirection = .fall
    @State private var thresholdText = "3,0"
    private var threshold: Decimal? { AlertThreshold.parse(thresholdText) }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 12) {
                SemaMark(size: 38)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Un œil sur vos fonds.").font(.system(size: 23, weight: .medium)).tracking(-0.7)
                    Text("Choisissez une part et un seuil à suivre.").font(.system(size: 12)).foregroundStyle(.secondary)
                }
            }
            Form {
                Picker("Fonds et part", selection: $fundID) {
                    ForEach(store.funds) { fund in Text(fund.name + " · " + fund.subtitle).tag(fund.id) }
                }
                Picker("Me prévenir en cas de", selection: $direction) {
                    ForEach(AlertDirection.allCases, id: \.self) { Text($0.title.lowercased()).tag($0) }
                }
                HStack {
                    TextField("Seuil supérieur à", text: $thresholdText).textFieldStyle(.roundedBorder).frame(width: 190)
                    Text("%").foregroundStyle(.secondary)
                }
                if threshold == nil {
                    Text("Saisissez un nombre supérieur à 0 et inférieur ou égal à 100, par exemple 2,5.")
                        .font(.system(size: 11)).foregroundStyle(.red)
                }
            }
            Label("Fonds fictifs · règle sauvegardée localement. Vous pourrez tester la notification après sa création.", systemImage: "info.circle")
                .font(.system(size: 11)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            HStack {
                Button("Annuler") { dismiss() }.keyboardShortcut(.cancelAction)
                Spacer()
                Button("Créer l’alerte") {
                    if let threshold, store.addAlert(seriesID: fundID, direction: direction, threshold: threshold) { dismiss() }
                }
                .buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction).disabled(threshold == nil || fundID.isEmpty)
            }
        }
        .padding(30).frame(width: 510)
        .onAppear { fundID = store.selectedFundID }
    }
}

struct DemoNotificationView: View {
    @Environment(AppStore.self) private var store
    let event: AlertEvent
    private var fund: MarketSeries? { store.funds.first { $0.id == event.seriesID } }
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            SemaMark(size: 30)
            VStack(alignment: .leading, spacing: 6) {
                Text("SEMA · TEST DE NOTIFICATION").font(.system(size: 9, weight: .medium)).tracking(0.5).foregroundStyle(.secondary)
                Text(fund?.name ?? "Fonds de démonstration").font(.system(size: 13, weight: .medium))
                Text("Variation simulée : \(MarketFormat.number(event.changePercent, digits: 1, signed: true)) %.")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Button { store.simulatedEvent = nil } label: { Image(systemName: "xmark").font(.system(size: 11)).foregroundStyle(.secondary) }
                .buttonStyle(.plain).accessibilityLabel("Fermer la notification")
        }
        .padding(17).frame(width: 345)
        .background(SemaTheme.surface, in: RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(SemaTheme.separator, lineWidth: 0.5))
        .shadow(color: .black.opacity(0.14), radius: 20, y: 8)
        .accessibilityElement(children: .contain)
    }
}
