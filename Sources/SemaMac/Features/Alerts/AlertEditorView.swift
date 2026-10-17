// Formulaire de création d’une règle de seuil sur une série suivie.
import SwiftUI
import MarketCore

struct AlertEditorView: View {
    private static let sheetWidth: CGFloat = 530
    private static let sheetPadding: CGFloat = 30
    private static let sectionSpacing: CGFloat = 22
    private static let thresholdWidth: CGFloat = 190
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var seriesID = ""
    @State private var direction: AlertDirection = .rise
    @State private var thresholdText = "3,0"
    private var threshold: Decimal? { AlertThreshold.parseLevel(thresholdText) }
    private var item: MarketSeries? { store.macroSeries.first { $0.id == seriesID } }

    var body: some View {
        VStack(alignment: .leading, spacing: Self.sectionSpacing) {
            Text("Créer une alerte").font(.title2)
            Form {
                Picker("Repère", selection: $seriesID) {
                    ForEach(store.alertableSeries) { Text($0.name).tag($0.id) }
                }
                Picker("Me prévenir quand la valeur", selection: $direction) {
                    ForEach(AlertDirection.allCases, id: \.self) { Text($0.crossingTitle.lowercased()).tag($0) }
                }
                HStack {
                    TextField("Seuil", text: $thresholdText).textFieldStyle(.roundedBorder).frame(width: Self.thresholdWidth)
                    Text(item?.displayUnit ?? "").foregroundStyle(.secondary)
                }
                if threshold == nil {
                    Text("Saisissez un nombre, par exemple 3,5. Zéro et les valeurs négatives sont acceptés.")
                        .font(.subheadline).foregroundStyle(.red)
                }
                if let item {
                    LabeledContent("Dernière valeur") { Text(MarketFormat.value(item)) }
                    Text(item.isDemo ? "Valeurs fictives : connectez Webstat pour activer la vérification réelle."
                         : item.frequency == .monthly ? "Publication mensuelle : l’alerte suit les nouveaux mois publiés."
                         : "L’alerte suit les nouvelles observations publiées par la source.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            }
            Label("Un nouveau franchissement strict est nécessaire. Vérification à l’actualisation des repères ; aucune surveillance en arrière-plan.", systemImage: "info.circle")
                .font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            HStack {
                Button("Annuler") { dismiss() }.keyboardShortcut(.cancelAction)
                Spacer()
                Button("Créer l’alerte") {
                    if let threshold, store.addAlert(seriesID: seriesID, direction: direction, threshold: threshold) { dismiss() }
                }
                .buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction).disabled(threshold == nil || item?.canAlert != true)
            }
        }
        .padding(Self.sheetPadding).frame(width: Self.sheetWidth)
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
