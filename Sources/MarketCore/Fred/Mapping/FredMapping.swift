// Traduit les réponses JSON de FRED en publications, séries et unités du cœur.
import Foundation

enum FredMapping {
    private static func object(_ data: Data) throws -> [String: WebstatValue] {
        guard let root = try? JSONDecoder().decode([String: WebstatValue].self, from: data) else { throw PublicDataError.invalidData }
        return root
    }

    private static func rows(_ data: Data, key: String) throws -> [[String: WebstatValue]] {
        guard case .array(let values) = try object(data)[key] else { throw PublicDataError.invalidData }
        return values.compactMap { if case .object(let row) = $0 { row } else { nil } }
    }

    static func releaseDates(_ data: Data) throws -> [EconomicRelease] {
        try rows(data, key: "release_dates").compactMap { row in
            guard let id = row["release_id"]?.text, let name = row["release_name"]?.text,
                  let text = row["date"]?.text, let period = PublicDataFormat.period(text) else { return nil }
            return EconomicRelease(releaseID: id, name: name, date: period.start)
        }
    }

    static func datasets(_ data: Data) throws -> [StatisticalDataset] {
        try rows(data, key: "releases").compactMap { row in
            guard let id = row["id"]?.text, let name = row["name"]?.text else { return nil }
            return .init(source: .fred, code: id, agency: "FRED", version: "1", title: name, detail: row["notes"]?.text ?? "")
        }.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }

    static func seriesCodes(_ data: Data) throws -> [StatisticalCode] {
        try rows(data, key: "seriess").compactMap { row in
            guard let id = row["id"]?.text, let title = row["title"]?.text else { return nil }
            let detail = [row["units_short"]?.text, row["frequency_short"]?.text].compactMap { $0 }.joined(separator: " · ")
            return .init(id: id, title: detail.isEmpty ? title : "\(title) · \(detail)")
        }
    }

    /// FRED units become the same unit codes as the other sources, so alerts and variations follow one contract.
    static func unit(_ units: String) -> (code: String, multiplier: String) {
        let text = units.lowercased()
        if text.hasPrefix("percent") { return ("PC", "0") }
        if text.hasPrefix("index") { return ("IX", "0") }
        if text.hasPrefix("billions of u.s. dollars") || text.hasPrefix("billions of dollars") { return ("USD", "9") }
        if text.hasPrefix("millions of u.s. dollars") || text.hasPrefix("millions of dollars") { return ("USD", "6") }
        if text.hasPrefix("u.s. dollars") { return ("USD", "0") }
        return (units, "0")
    }

    static func series(observations: Data, metadata: Data, dataset: StatisticalDataset, key: String,
                       fullHistory: Bool = false, now: Date = .now) throws -> MarketSeries {
        guard let info = try rows(metadata, key: "seriess").first, info["id"]?.text?.caseInsensitiveCompare(key) == .orderedSame,
              let title = info["title"]?.text else { throw PublicDataError.invalidData }
        let points = try rows(observations, key: "observations").compactMap { row -> MarketObservation? in
            // FRED marks a missing value with ".", for example on a market holiday.
            guard let dateText = row["date"]?.text, let period = PublicDataFormat.period(dateText), period.start <= now,
                  let raw = row["value"]?.text, raw != ".", let value = PublicDataFormat.decimal(raw) else { return nil }
            return .init(date: period.start, value: value)
        }
        guard !points.isEmpty else { throw PublicDataError.noData }
        let units = info["units"]?.text ?? ""
        let converted = unit(units)
        let frequency = info["frequency_short"]?.text ?? ""
        let fields = ["TITLE": title, "FREQ": frequency == "D" ? "B" : frequency, "UNIT": converted.code, "UNIT_MULT": converted.multiplier,
                      "DECIMALS": "2", "TITLE_COMPL": info["notes"]?.text ?? dataset.detail]
        let canonical = info["id"]?.text ?? key
        let descriptor = StatisticalSeriesDescriptor(dataset: dataset, key: canonical, dimensionIDs: ["SERIES"], fields: fields,
                                                     labels: ["UNIT": units])
        return descriptor.series(observations: points, syncedAt: now, completeHistory: fullHistory)
    }
}
