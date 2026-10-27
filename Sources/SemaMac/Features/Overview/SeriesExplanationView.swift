// Affiche une définition et une lecture déterministes sans surface flottante ni calcul dans la vue.
import SwiftUI
import MarketCore

struct SeriesExplanationView: View {
    private static let definitionLines = 4
    private static let leadingInset: CGFloat = 18
    let explanation: SeriesExplanation

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.majorSpacing) {
            Text(explanation.definition).lineLimit(Self.definitionLines)
            if let reading = explanation.reading { Text(reading) }
            if let implication = explanation.implication {
                Text(implication).foregroundStyle(.secondary)
            }
            if let url = explanation.referenceURL {
                Link("Source", destination: url).font(.caption)
            }
        }
        .font(.callout).textSelection(.enabled)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.leading, Self.leadingInset).padding(.top, Theme.minorSpacing)
    }
}
