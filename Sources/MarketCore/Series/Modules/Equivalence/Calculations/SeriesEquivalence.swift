// Relie uniquement les séries dont la correspondance entre fournisseurs a été vérifiée.
import Foundation

/// Correspondance explicite et vérifiée seulement. Les titres et les valeurs d’observation identiques
/// ne prouvent jamais que deux indicateurs publiés indépendamment sont équivalents.
public enum SeriesEquivalence {
    public static func matches(_ lhs: MarketSeries, _ rhs: MarketSeries) -> Bool {
        if lhs.id == rhs.id { return true }
        guard let key = referenceExchangeRateKey(lhs) else { return false }
        return key == referenceExchangeRateKey(rhs)
    }

    public static func unique(_ values: [MarketSeries]) -> [MarketSeries] {
        values.reduce(into: []) { result, value in
            if !result.contains(where: { matches($0, value) }) { result.append(value) }
        }
    }

    public static func accessPoints(for value: MarketSeries) -> [(sourceID: String, url: URL)] {
        guard let identity = referenceExchangeRateKey(value) else { return [] }
        let key = String(identity.dropFirst(referencePrefix.count))
        return [
            ("webstat", URL(string: WebstatSite.catalogueURL + "exr/\(webstatPrefix)\(key)")!),
            ("ecb", URL(string: ecbDatasetURL + key)!)
        ]
    }

    static func referenceExchangeRateKey(_ value: MarketSeries) -> String? {
        let key: String
        let unit: String?
        let multiplier: Int?
        let frequency: String?
        if let descriptor = value.statisticalDescriptor {
            guard descriptor.dataset.source == .ecb, descriptor.dataset.agency == "ECB",
                  descriptor.dataset.code == "EXR", descriptor.dataset.version == "1.0",
                  descriptor.dimensionIDs == ["FREQ", "CURRENCY", "CURRENCY_DENOM", "EXR_TYPE", "EXR_SUFFIX"],
                  descriptor.fields["SOURCE_AGENCY"] == "4F0" else { return nil }
            key = descriptor.key; unit = descriptor.unitCode
            multiplier = descriptor.multiplier; frequency = descriptor.fields["FREQ"]
        } else if let descriptor = value.descriptor {
            guard descriptor.datasetID == "EXR", descriptor.raw["source_agency"]?.text == "4F0",
                  descriptor.key.hasPrefix(webstatPrefix) else { return nil }
            key = String(descriptor.key.dropFirst(webstatPrefix.count)); unit = descriptor.unitCode
            multiplier = descriptor.multiplier; frequency = descriptor.frequencyCode
        } else { return nil }
        // La clé complète garde la fréquence et la devise du numérateur. Les séries d’indice ou rebasées diffèrent.
        guard let parts = spotRateParts(key), parts[0] == frequency, parts[1] == unit, multiplier == 0 else { return nil }
        return referencePrefix + key
    }

    /// Webstat répète le jeu de données devant la clé BCE ; une référence vérifiée porte sa source.
    static let webstatPrefix = "EXR."
    static let referencePrefix = "ECB:EXR:"
    static let ecbDatasetURL = "https://data.ecb.europa.eu/data/datasets/EXR/"

    /// Parties d’une référence de change au comptant BCE contre l’euro, observation moyenne : fréquence, devise, EUR, SP00, A.
    static func spotRateParts(_ key: String) -> [String]? {
        let parts = key.split(separator: ".").map(String.init)
        guard parts.count == 5, parts[2] == "EUR", parts[3] == "SP00", parts[4] == "A" else { return nil }
        return parts
    }
}
