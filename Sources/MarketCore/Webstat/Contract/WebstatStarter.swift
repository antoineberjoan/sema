// Repères de départ de Webstat : valeurs écrites dans le code, dont les valeurs viennent toujours de Webstat.
import Foundation

public enum WebstatStarter {
    struct Definition: Sendable {
        let id: String
        let seriesCode: String
        let name: String
        let subtitle: String
        let category: SeriesCategory
        let unit: ValueUnit
        let digits: Int
        let frequency: ObservationFrequency
        let producer: String
    }

    static let definitions: [Definition] = [
        .init(id: "fr10", seriesCode: "FM.M.FR.EUR.FR2.BB.FR10YT_RR.YLD", name: "OAT France · 10 ans",
              subtitle: "Rendement · série mensuelle", category: .markets, unit: .percent,
              digits: 2, frequency: .monthly, producer: "Banque de France"),
        .init(id: "ecb", seriesCode: "FM.D.U2.EUR.4F.KR.DFR.LEV", name: "Taux de dépôt BCE",
              subtitle: "Facilité de dépôt · politique monétaire", category: .savings, unit: .percent,
              digits: 2, frequency: .daily, producer: "BCE · via Banque de France"),
        .init(id: "eurusd", seriesCode: "EXR.D.USD.EUR.SP00.A", name: "Euro / Dollar",
              subtitle: "USD pour 1 EUR · taux de référence", category: .markets, unit: .usd,
              digits: 4, frequency: .daily, producer: "BCE · via Banque de France"),
        .init(id: "eurjpy", seriesCode: "EXR.D.JPY.EUR.SP00.A", name: "Euro / Yen",
              subtitle: "JPY pour 1 EUR · taux de référence", category: .markets, unit: .jpy,
              digits: 2, frequency: .daily, producer: "BCE · via Banque de France"),
        .init(id: "eurchf", seriesCode: "EXR.D.CHF.EUR.SP00.A", name: "Euro / Franc suisse",
              subtitle: "CHF pour 1 EUR · taux de référence", category: .markets, unit: .chf,
              digits: 4, frequency: .daily, producer: "BCE · via Banque de France"),
        .init(id: "livreta", seriesCode: "MIR1.M.FR.B.L23FRLA.D.R.A.2230U6.EUR.O", name: "Livret A",
              subtitle: "Épargne réglementée", category: .savings, unit: .percent,
              digits: 2, frequency: .monthly, producer: "Banque de France"),
        .init(id: "lep", seriesCode: "MIR1.M.FR.B.L23FRLP.H.R.A.2250U6.EUR.O", name: "LEP",
              subtitle: "Épargne réglementée", category: .savings, unit: .percent,
              digits: 2, frequency: .monthly, producer: "Banque de France"),
        .init(id: "inflation", seriesCode: "HICP.M.FR.N.000000.4D0.ANR", name: "Inflation · France",
              subtitle: "IPCH · variation annuelle · données brutes", category: .savings, unit: .percent,
              digits: 1, frequency: .monthly, producer: "Eurostat · via Banque de France"),
        .init(id: "ldds", seriesCode: "MIR1.M.FR.B.L23FRLD.D.R.A.2254U6.EUR.O", name: "LDDS",
              subtitle: "Épargne réglementée", category: .savings, unit: .percent,
              digits: 2, frequency: .monthly, producer: "Banque de France"),
        .init(id: "estr", seriesCode: "ESTR.B.EU000A2X2A25.WT", name: "€STR",
              subtitle: "Marché monétaire au jour le jour", category: .savings, unit: .percent,
              digits: 3, frequency: .daily, producer: "BCE · via Banque de France"),
        .init(id: "inflation-euro", key: "HICP.M.U2.N.000000.4D0.ANR", name: "Inflation · Zone euro",
              subtitle: "IPCH · variation annuelle · données brutes", category: .savings, unit: .percent,
              digits: 1, frequency: .monthly, producer: "Eurostat · via Banque de France"),
        .init(id: "eurgbp", seriesCode: "EXR.D.GBP.EUR.SP00.A", name: "Euro / Livre sterling",
              subtitle: "GBP pour 1 EUR · taux de référence", category: .markets, unit: .gbp,
              digits: 4, frequency: .daily, producer: "BCE · via Banque de France"),
        .init(id: "mortgage-fr", key: "MIR1.M.FR.B.A22HR.A.R.A.2254U6.EUR.N", name: "Crédit immobilier",
              subtitle: "Nouveaux crédits à l’habitat · hors renégociations", category: .savings, unit: .percent,
              digits: 2, frequency: .monthly, producer: "Banque de France"),
        .init(id: "de10", seriesCode: "FM.M.DE.EUR.FR2.BB.DE10YT_RR.YLD", name: "Bund · 10 ans",
              subtitle: "Rendement · série mensuelle", category: .markets, unit: .percent,
              digits: 2, frequency: .monthly, producer: "Banque de France"),
        .init(id: "us10", seriesCode: "FM.M.US.USD.FR2.BB.US10YT_RR.YLD", name: "Treasury US · 10 ans",
              subtitle: "Rendement · série mensuelle", category: .markets, unit: .percent,
              digits: 2, frequency: .monthly, producer: "Banque de France"),
        .init(id: "mro", seriesCode: "FM.D.U2.EUR.4F.KR.MRR_FR.LEV", name: "Taux de refinancement BCE",
              subtitle: "Opérations principales · politique monétaire", category: .savings, unit: .percent,
              digits: 2, frequency: .daily, producer: "BCE · via Banque de France")
    ]

    public static var legacyIDs: [String: String] {
        Dictionary(uniqueKeysWithValues: definitions.map { ($0.id, $0.seriesCode) })
    }
    public static func canonicalID(_ id: String) -> String { legacyIDs[id] ?? id }
    public static var ids: [String] { definitions.map(\.seriesCode) }
    /// Repères sans observation : leurs valeurs viennent de Webstat, jamais d’un exemple.
    public static var series: [MarketSeries] {
        definitions.map { definition in
            MarketSeries(id: definition.seriesCode, name: definition.name, subtitle: definition.subtitle,
                category: definition.category, unit: definition.unit, fractionDigits: definition.digits,
                source: definition.producer, frequency: definition.frequency, observations: [])
        }
    }
}
