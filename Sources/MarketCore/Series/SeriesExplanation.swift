// Explique uniquement les mesures vérifiées à partir de leurs valeurs, sans génération ni recherche réseau.
import Foundation

public struct SeriesExplanation: Equatable, Sendable {
    private enum Reference {
        static let ecbExchangeRates = URL(string: "https://data.ecb.europa.eu/methodology/exchange-rates")
        static let ecbInflation = URL(string: "https://www.ecb.europa.eu/ecb-and-you/explainers/tell-me-more/html/what_is_inflation.en.html")
        static let amfBondPrices = URL(string: "https://www.amf-france.org/fr/espace-epargnants/comprendre-les-produits-financiers/actions-obligations/obligations/pourquoi-le-prix-des-obligations-baisse-lorsque-les-taux-montent")
        static let ecbInterestRates = URL(string: "https://data.ecb.europa.eu/methodology/what-are-interest-rates")
        static let ecbShortTermRate = URL(string: "https://www.ecb.europa.eu/stats/financial_markets_and_interest_rates/euro_short-term_rate/html/index.en.html")
    }

    public let definition: String
    public let reading: String?
    public let implication: String?
    public let referenceURL: URL?

    public init?(series: MarketSeries, period: HistoryPeriod, inverted: Bool = false,
                 formatNumber: (Decimal, Int) -> String) {
        if let pair = series.exchangeRatePair {
            self = Self.exchangeRate(series, pair: pair, period: period,
                inverted: inverted && series.canInvertExchangeRate, format: formatNumber)
            return
        }
        if let id = Self.knownRateID(series) {
            if id == "inflation" || id == "inflation-euro" {
                self = Self.inflation(series, period: period, format: formatNumber)
                return
            }
            if let rule = Self.rateRule(id) {
                var reading = series.latest.flatMap { point in
                    point.value.isNaN ? nil : "Le taux publié est de \(formatNumber(point.value, series.fractionDigits)) %."
                }
                if let delta = Self.comparisonChange(series, period: period) {
                    reading = (reading ?? "") + " " + Self.rateMovement(delta)
                }
                self.init(definition: rule.definition, reading: Self.identifyingDemo(reading, series: series),
                    implication: rule.implication, referenceURL: rule.referenceURL ?? series.sourceURL)
                return
            }
        }
        // A title or a percent unit alone never establishes the economic meaning of a series.
        let official = (series.descriptor?.definition ?? series.statisticalDescriptor?.definition ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !official.isEmpty, official.localizedCaseInsensitiveCompare(series.name) != .orderedSame else { return nil }
        self.init(definition: official, reading: nil, implication: nil, referenceURL: series.sourceURL)
    }

    private init(definition: String, reading: String?, implication: String?, referenceURL: URL?) {
        self.definition = definition; self.reading = reading
        self.implication = implication; self.referenceURL = referenceURL
    }

    private static func knownRateID(_ series: MarketSeries) -> String? {
        guard series.unit == .percent else { return nil }
        let key: String
        if series.isDemo, series.descriptor == nil, series.statisticalDescriptor == nil {
            key = WebstatClient.canonicalID(series.id)
        } else if let descriptor = series.descriptor,
                  descriptor.unit == .percent, descriptor.multiplier == 0,
                  descriptor.datasetID == descriptor.key.split(separator: ".").first.map(String.init),
                  descriptor.frequencyCode == descriptor.key.split(separator: ".").dropFirst().first.map(String.init) {
            key = descriptor.key
        } else { return nil }
        return WebstatClient.legacyIDs.first { $0.value == key }?.key
    }

    private static func comparisonChange(_ series: MarketSeries, period: HistoryPeriod) -> Decimal? {
        guard series.supports(period), let first = series.history(for: period).first,
              !first.value.isNaN, let latest = series.latest, !latest.value.isNaN,
              let change = series.change(for: period), !change.isNaN else { return nil }
        return change
    }

    private static func identifyingDemo(_ reading: String?, series: MarketSeries) -> String? {
        reading.map { (series.isDemo ? "Exemple fictif. " : "") + $0 }
    }

    private static func exchangeRate(_ series: MarketSeries, pair: ExchangeRatePair, period: HistoryPeriod,
                                     inverted: Bool, format: (Decimal, Int) -> String) -> Self {
        let displayed = inverted ? series.invertedExchangeRateForDisplay() ?? series : series
        let base = inverted ? pair.currency : "EUR"
        let quote = inverted ? "EUR" : pair.currency
        var reading: String?
        var implication: String?
        if let value = displayed.latest?.value, !value.isNaN, value > 0 {
            var text = "1 \(base) vaut \(format(value, displayed.fractionDigits)) \(quote)."
            if series.canInvertExchangeRate, let delta = comparisonChange(displayed, period: period) {
                if delta > 0 {
                    text += " Sur la période affichée, \(base) s’est apprécié face à \(quote)."
                    implication = "À prix fixe en \(quote), le coût en \(base) diminue, hors frais de change."
                } else if delta < 0 {
                    text += " Sur la période affichée, \(base) s’est déprécié face à \(quote)."
                    implication = "À prix fixe en \(quote), le coût en \(base) augmente, hors frais de change."
                } else {
                    text += " La cotation est inchangée sur la période affichée."
                    implication = "À prix fixe en \(quote), le coût en \(base) reste identique, hors frais de change."
                }
            } else {
                implication = "Le niveau de la cotation seul ne permet pas de conclure qu’une devise est forte ou faible."
            }
            reading = text
        }
        return Self(definition: "Ce taux de référence indique combien de \(quote) correspondent à 1 \(base).",
            reading: identifyingDemo(reading, series: series), implication: implication,
            referenceURL: Reference.ecbExchangeRates)
    }

    private static func inflation(_ series: MarketSeries, period: HistoryPeriod,
                                  format: (Decimal, Int) -> String) -> Self {
        var reading: String?
        var implication: String?
        if let value = series.latest?.value, !value.isNaN {
            let amount = format(abs(value), series.fractionDigits)
            var text: String
            if value > 0 {
                text = "Le panier de consommation coûte \(amount) % de plus qu’un an auparavant."
                implication = "Si les revenus ne suivent pas cette hausse des prix, le pouvoir d’achat diminue."
            } else if value < 0 {
                text = "Le panier de consommation coûte \(amount) % de moins qu’un an auparavant."
                implication = "À revenu nominal inchangé, une même somme permet d’acheter davantage de ce panier."
            } else {
                text = "Le niveau de prix du panier est inchangé par rapport à un an auparavant."
                implication = "Les prix des produits pris séparément peuvent pourtant avoir évolué."
            }
            if let delta = comparisonChange(series, period: period) {
                if delta == 0 {
                    text += " Le taux annuel est inchangé sur la période affichée."
                } else if let previous = series.history(for: period).first?.value {
                    if value > 0 && previous > 0 {
                        text += delta < 0 ? " La hausse annuelle des prix ralentit ; leur niveau reste plus élevé qu’un an auparavant."
                            : " La hausse annuelle des prix s’accélère."
                    } else if value < 0 && previous < 0 {
                        text += delta < 0 ? " Le recul annuel des prix s’accentue." : " Le recul annuel des prix ralentit."
                    } else {
                        text += " " + rateMovement(delta)
                    }
                }
            }
            reading = text
        }
        return Self(definition: "Ce taux d’inflation mesure la variation sur douze mois de l’indice des prix à la consommation harmonisé (IPCH).",
            reading: identifyingDemo(reading, series: series), implication: implication,
            referenceURL: Reference.ecbInflation)
    }

    private static func rateMovement(_ delta: Decimal) -> String {
        if delta > 0 { return "Le taux a augmenté sur la période affichée." }
        if delta < 0 { return "Le taux a diminué sur la période affichée." }
        return "Le taux est inchangé sur la période affichée."
    }

    private static func rateRule(_ id: String) -> (definition: String, implication: String, referenceURL: URL?)? {
        switch id {
        case "fr10":
            return ("Ce taux est le rendement publié de l’OAT française à dix ans (l’emprunt phare), pas son coupon ni son prix.",
                "À caractéristiques comparables, une hausse des rendements tend à faire baisser le prix des obligations à taux fixe existantes, et inversement.",
                Reference.amfBondPrices)
        case "ecb":
            return ("Ce taux s’applique aux dépôts des banques au jour le jour auprès de l’Eurosystème.",
                "Il influence les conditions de financement et d’épargne, sans fixer à lui seul le taux de chaque crédit ou livret.",
                Reference.ecbInterestRates)
        case "estr":
            return ("L’€STR reflète le coût des emprunts en euros au jour le jour, non garantis, des banques de la zone euro.",
                "Il sert de référence à des contrats financiers. Ce taux n’est pas le rendement net d’un fonds monétaire.",
                Reference.ecbShortTermRate)
        case "livreta", "ldds", "lep":
            return ("Cette série indique le taux annuel publié du livret réglementé.",
                "À solde et durée identiques, un taux plus élevé augmente la rémunération, selon les règles du livret.", nil)
        case "mortgage-fr":
            return ("Ce taux porte sur les nouveaux crédits à l’habitat en France, hors renégociations. Ce n’est ni un TAEG ni une offre bancaire.",
                "À montant et durée identiques, un taux plus élevé renchérit un nouveau crédit. Il ne modifie pas automatiquement un prêt existant à taux fixe.", nil)
        default: return nil
        }
    }
}
