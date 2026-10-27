// Formulaire de création d’une règle de seuil sur une série suivie.
import SwiftUI
import MarketCore

struct AlertEditorView: View {
    private static let sheetWidth: CGFloat = 480
    private static let inset: CGFloat = 24
    private static let rowSpacing: CGFloat = 16
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var seriesID = ""
    @State private var direction: AlertDirection = .rise
    @State private var thresholdText = "3,0"
    private var threshold: Decimal? { AlertThreshold.parseLevel(thresholdText) }
    private var item: MarketSeries? { store.macroSeries.first { $0.id == seriesID } }

    var body: some View {
        VStack(alignment: .leading, spacing: Self.inset) {
            Text("Créer une alerte").font(.title2.weight(.semibold))
            Grid(alignment: .leading, horizontalSpacing: Self.rowSpacing, verticalSpacing: Self.rowSpacing) {
                GridRow {
                    Text("Repère").gridColumnAlignment(.trailing)
                    Picker("Repère", selection: $seriesID) {
                        ForEach(store.alertableSeries) { Text(MarketFormat.name($0)).tag($0.id) }
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
                    HStack(spacing: Theme.minorSpacing) {
                        TextField("Seuil", text: $thresholdText)
                            .textFieldStyle(.roundedBorder).accessibilityLabel("Seuil")
                        Text(item.map(MarketFormat.unit) ?? "").foregroundStyle(.secondary)
                    }
                }
            }
            if threshold == nil {
                Text("Saisissez un nombre valide, par exemple 3,5.")
                    .font(.callout).foregroundStyle(.red)
            }
            if let item {
                VStack(alignment: .leading, spacing: Theme.minorSpacing) {
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
