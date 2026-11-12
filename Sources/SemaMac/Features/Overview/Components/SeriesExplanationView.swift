// Affiche une définition et une lecture déterministes sans surface flottante ni calcul dans la vue.
import SemaDesign
import SwiftUI
import MarketCore

struct SeriesExplanationView: View {
    private static let leadingInset = DesignSpace.cardInset
    let explanation: SeriesExplanation

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSpace.groupGap) {
            Text(explanation.definition).lineLimit(Int(DesignMeasure.seriesExplanationDefinitionLines))
            if let reading = explanation.reading { Text(reading) }
            if let implication = explanation.implication {
                Text(implication).foregroundStyle(DesignColor.textMuted)
            }
            if let url = explanation.referenceURL {
                Link("Source", destination: url).typeRole(.micro)
            }
        }
        .typeRole(.small).textSelection(.enabled)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.leading, Self.leadingInset).padding(.top, DesignSpace.rowInset)
    }
}
