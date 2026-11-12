// Traduit les réponses JSON de la Banque mondiale en indicateurs, pays et séries du cœur.
import Foundation

enum WorldBankMapping {
    static func response(_ data: Data) throws -> ([String: WebstatValue], [[String: WebstatValue]]) {
        guard let response = try? JSONDecoder().decode([WebstatValue].self, from: data), response.count == 2,
              case .object(let metadata) = response[0], case .array(let rows) = response[1] else { throw PublicDataError.invalidData }
        return (metadata, rows.compactMap { if case .object(let row) = $0 { row } else { nil } })
    }

    static func datasets(_ rows: [[String: WebstatValue]]) -> [StatisticalDataset] {
        rows.compactMap { row in
            guard let code = row["id"]?.text, let title = row["name"]?.text,
                  case .object(let source) = row["source"], let sourceID = source["id"]?.text else { return nil }
            return .init(source: .worldBank, code: code, agency: sourceID, version: "2", title: title,
                detail: row["sourceNote"]?.text ?? "", metadata: ["UNIT": row["unit"]?.text ?? "", "PRODUCER": row["sourceOrganization"]?.text ?? ""])
        }
    }

    static func countries(_ rows: [[String: WebstatValue]]) -> [StatisticalCode] {
        rows.compactMap { row -> StatisticalCode? in
            guard let id = row["id"]?.text, let name = row["name"]?.text else { return nil }
            return .init(id: id, title: name)
        }.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }

    static func series(_ data: Data, dataset: StatisticalDataset, key: String, fullHistory: Bool, now: Date) throws -> MarketSeries {
        let (metadata, rows) = try response(data)
        guard (Int(metadata["pages"]?.text ?? "1") ?? 1) <= 1 else { throw PublicDataError.invalidData }
        var frequencies: Set<String> = []
        let points = try rows.compactMap { row -> MarketObservation? in
            guard let time = row["date"]?.text, let value = row["value"]?.text.flatMap(PublicDataFormat.decimal) else { return nil }
            let normalized: String
            if time.range(of: "^[0-9]{4}M[0-9]{2}$", options: .regularExpression) != nil {
                normalized = "\(time.prefix(4))-\(time.suffix(2))"; frequencies.insert("M")
            } else if time.range(of: "^[0-9]{4}Q[1-4]$", options: .regularExpression) != nil {
                normalized = "\(time.prefix(4))-Q\(time.suffix(1))"; frequencies.insert("Q")
            } else {
                normalized = time; frequencies.insert(time.count == 4 ? "A" : time.count == 7 && time.contains("Q") ? "Q" : time.count == 7 ? "M" : "D")
            }
            guard let period = PublicDataFormat.period(normalized) else { throw PublicDataError.unsupportedPeriod }
            guard period.start <= now else { return nil }
            return .init(date: period.start, value: value, periodEnd: period.end)
        }
        guard !points.isEmpty else { throw PublicDataError.noData }
        guard frequencies.count == 1 else { throw PublicDataError.chooseOneSeries }
        let canonicalCountry = rows.compactMap { $0["countryiso3code"]?.text }.first(where: { !$0.isEmpty }) ?? key
        var fields = ["TITLE": dataset.title, "REF_AREA": canonicalCountry, "FREQ": frequencies.first!, "PRODUCER": dataset.metadata["PRODUCER"] ?? ""]
        var labels: [String: String] = [:]
        if let unit = dataset.metadata["UNIT"], !unit.isEmpty { fields["UNIT"] = unit == "%" ? "PC" : unit; fields["UNIT_MULT"] = "0"; labels["UNIT"] = unit }
        if let first = rows.first, case .object(let country) = first["country"] { labels["REF_AREA"] = country["value"]?.text }
        let descriptor = StatisticalSeriesDescriptor(dataset: dataset, key: canonicalCountry, dimensionIDs: ["REF_AREA"], fields: fields, labels: labels)
        return descriptor.series(observations: points, syncedAt: now, completeHistory: fullHistory)
    }
}
