// Recherche dans les séries locales avec normalisation et synonymes des repères connus.
import Foundation

public enum SeriesSearch {
    /// Local search only. Aliases name the integrated series, never a different benchmark.
    public static func results(in series: [MarketSeries], query: String) -> [MarketSeries] {
        let tokens = normalize(query).split(separator: " ")
        return series.filter { item in
            guard item.category != .funds else { return false }
            let text = normalize([item.name, item.subtitle, item.id, item.displayUnit, item.descriptor?.definition ?? "", aliases[item.id] ?? ""].joined(separator: " "))
            return tokens.allSatisfy { text.contains($0) }
        }
    }

    private static let aliases = [
        "FM.M.FR.EUR.FR2.BB.FR10YT_RR.YLD": "OAT France français dix ans emprunt phare obligataire rendement mensuel",
        "FM.M.DE.EUR.FR2.BB.DE10YT_RR.YLD": "Bund allemand Allemagne dix ans obligataire rendement mensuel",
        "FM.M.US.USD.FR2.BB.US10YT_RR.YLD": "Treasury américain États-Unis US dix ans obligataire rendement mensuel",
        "FM.D.U2.EUR.4F.KR.MRR_FR.LEV": "BCE refinancement principal MRO taux directeur",
        "FM.D.U2.EUR.4F.KR.DFR.LEV": "BCE Banque centrale européenne facilité dépôt taux directeur",
        "ESTR.B.EU000A2X2A25.WT": "ESTR euro short term monétaire",
        "MIR1.M.FR.B.A22HR.A.R.A.2254U6.EUR.N": "crédit immobilier immo emprunt prêt habitat logement",
        "HICP.M.FR.N.000000.4D0.ANR": "inflation France prix IPCH",
        "HICP.M.U2.N.000000.4D0.ANR": "inflation zone euro prix IPCH",
        "EXR.D.USD.EUR.SP00.A": "change dollar américain USD",
        "EXR.D.JPY.EUR.SP00.A": "change yen japonais JPY",
        "EXR.D.CHF.EUR.SP00.A": "change franc suisse CHF",
        "EXR.D.GBP.EUR.SP00.A": "change livre sterling GBP",
        "MIR1.M.FR.B.L23FRLA.D.R.A.2230U6.EUR.O": "livret A épargne réglementée",
        "MIR1.M.FR.B.L23FRLD.D.R.A.2254U6.EUR.O": "livret développement durable solidaire épargne",
        "MIR1.M.FR.B.L23FRLP.H.R.A.2250U6.EUR.O": "livret épargne populaire"
    ]

    private static func normalize(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .french)
            .components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }.joined(separator: " ")
    }
}
