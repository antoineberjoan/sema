// Traduit les réponses JSON de la Fed de New York en jeux et en séries du cœur.
import Foundation

enum NewYorkFedMapping {
    static func datasets(_ data: Data) throws -> [StatisticalDataset] {
        let rows = try rows(data)
        return rows.compactMap { row in
            guard let type = row["type"]?.text else { return nil }
            var metadata: [String: String] = [:]
            for (key, value) in row {
                if case .number = value { metadata["\(NewYorkFedClient.measurePrefix)\(key)"] = label(key) }
            }
            // Unknown future types remain accessible through the documented all-rates endpoint.
            metadata["ROUTE"] = ["EFFR", "OBFR"].contains(type) ? "unsecured/\(type.lowercased())" : ["SOFR", "SOFRAI", "BGCR", "TGCR"].contains(type) ? "secured/\(type.lowercased())" : "all"
            return .init(source: .newYorkFed, code: type, agency: "NYFED", version: "1", title: type,
                detail: "Taux de référence et mesures publiées · choisir la mesure, sans confondre taux effectif et cible.", metadata: metadata)
        }.sorted { $0.code < $1.code }
    }

    private static func rows(_ data: Data) throws -> [[String: WebstatValue]] {
        guard let root = try? JSONDecoder().decode([String: WebstatValue].self, from: data),
              case .array(let values) = root["refRates"] else { throw PublicDataError.invalidData }
        return values.compactMap { if case .object(let row) = $0 { row } else { nil } }
    }

    private static func label(_ key: String) -> String {
        switch key {
        case "percentRate": "Taux effectif"
        case "targetRateFrom": "Cible Fed · borne basse"
        case "targetRateTo": "Cible Fed · borne haute"
        case "volumeInBillions": "Volume · milliards de dollars"
        case "average30day": "Moyenne composée · 30 jours"
        case "average90day": "Moyenne composée · 90 jours"
        case "average180day": "Moyenne composée · 180 jours"
        case "index": "Indice SOFR"
        default: key.hasPrefix("percentPercentile") ? "Percentile \(key.dropFirst(17))" : key
        }
    }

    static func series(_ data: Data, dataset: StatisticalDataset, key: String, fullHistory: Bool, now: Date) throws -> MarketSeries {
        let rows = try rows(data).filter { $0["type"]?.text == dataset.code }
        let points = rows.compactMap { row -> MarketObservation? in
            guard let dateText = row["effectiveDate"]?.text, let period = PublicDataFormat.period(dateText), period.start <= now,
                  let raw = row[key]?.text, let value = PublicDataFormat.decimal(raw) else { return nil }
            return .init(date: period.start, value: value, status: row["revisionIndicator"]?.text.flatMap { $0.isEmpty ? nil : "Révisée (\($0))" })
        }
        guard !points.isEmpty else { throw PublicDataError.noData }
        var fields = ["TITLE": "\(dataset.code) · \(label(key))", "FREQ": "B", "DECIMALS": key == "index" ? "8" : "2"]
        if key.hasPrefix("percent") || key.hasPrefix("average") || ["targetRateFrom", "targetRateTo"].contains(key) { fields["UNIT"] = "PC"; fields["UNIT_MULT"] = "0" }
        if key == "index" { fields["UNIT"] = "IX"; fields["UNIT_MULT"] = "0" }
        if key == "volumeInBillions" { fields["UNIT"] = "USD"; fields["UNIT_MULT"] = "9" }
        let descriptor = StatisticalSeriesDescriptor(dataset: dataset, key: key, dimensionIDs: ["MEASURE"], fields: fields, labels: [:])
        return descriptor.series(observations: points, syncedAt: now, completeHistory: fullHistory)
    }
}
