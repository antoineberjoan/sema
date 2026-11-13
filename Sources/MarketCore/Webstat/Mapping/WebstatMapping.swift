// Traduit les réponses JSON de Webstat en séries, observations et libellés du cœur.
import Foundation

enum WebstatMapping {
    static func rows(_ data: Data) throws -> [[String: WebstatValue]] {
        do { return try JSONDecoder().decode([[String: WebstatValue]].self, from: data) } catch { throw PublicDataError.invalidData }
    }

    static func summaryExport(_ data: Data) throws -> [WebstatSeriesDescriptor] {
        let items = try rows(data).map { try WebstatSeriesDescriptor(raw: $0) }
        guard Set(items.map(\.key)).count == items.count else { throw PublicDataError.invalidData }
        // Garde le classement de texte du fournisseur : les exports et les enregistrements utilisent le même order_by.
        return items
    }


    static func seriesPage(_ data: Data, offset: Int = 0) throws -> WebstatPage<WebstatSeriesDescriptor> {
        let page = try Self.page(data)
        return WebstatPage(items: try page.results.map { try WebstatSeriesDescriptor(raw: $0) }, total: page.totalCount, offset: offset)
    }


    static func codeLabels(_ rows: [[String: WebstatValue]]) -> [String: [String: String]] {
        var labels: [String: [String: String]] = [:]
        for row in rows {
            if let list = row["codelist_id"]?.text, let code = row["code"]?.text,
               let label = row["label_fr"]?.text ?? row["label_en"]?.text { labels[list, default: [:]][code] = label }
        }
        return labels
    }


    static func observations(_ data: Data, expectedKey: String, now: Date = .now) throws -> [MarketObservation] {
        let rows: [Row]
        do { rows = try JSONDecoder().decode([Row].self, from: data) } catch { throw PublicDataError.invalidData }
        let timestamp = ISO8601DateFormatter(); timestamp.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallback = ISO8601DateFormatter()
        return rows.sorted { ($0.updatedAt ?? "") < ($1.updatedAt ?? "") }.compactMap { row in
            guard row.key == expectedKey, let value = row.value, !value.isNaN,
                  let date = WebstatSeriesDescriptor.date(row.start), date <= now,
                  let end = WebstatSeriesDescriptor.date(row.end), end >= date,
                  row.status != "M", row.status != "Q" else { return nil }
            return MarketObservation(date: date, value: value, periodEnd: end,
                updatedAt: row.updatedAt.flatMap { timestamp.date(from: $0) ?? fallback.date(from: $0) }, status: row.status)
        }
    }


    struct Page: Decodable {
        let totalCount: Int
        let results: [[String: WebstatValue]]
        enum CodingKeys: String, CodingKey { case totalCount = "total_count", results }
    }
    static func page(_ data: Data) throws -> Page {
        do { return try JSONDecoder().decode(Page.self, from: data) } catch { throw PublicDataError.invalidData }
    }

    static func starterHistory(_ data: Data, statusCode: Int = 200, now: Date = .now) throws -> [MarketSeries] {
        switch statusCode {
        case 200: break
        // Webstat renvoie aussi 404 quand la clé API ne peut pas accéder à une table technique.
        case 401, 403, 404: throw WebstatError.accessDenied
        case 429: throw PublicDataError.quotaReached
        default: throw PublicDataError.unavailable
        }
        let rows: [Row]
        do { rows = try JSONDecoder().decode([Row].self, from: data) }
        catch { throw PublicDataError.invalidData }
        let day = ISO8601DateFormatter()
        day.formatOptions = [.withFullDate]
        let timestamp = ISO8601DateFormatter()
        timestamp.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestampWithoutFraction = ISO8601DateFormatter()
        var grouped: [String: [MarketObservation]] = [:]
        // La dernière révision l’emporte, indépendamment de l’ordre d’export pour les dates en double.
        for row in rows.sorted(by: { ($0.updatedAt ?? "") < ($1.updatedAt ?? "") }) {
            guard let value = row.value, !value.isNaN,
                  let date = day.date(from: row.start), date <= now,
                  let end = day.date(from: row.end), end >= date,
                  row.status != "M", row.status != "Q" else { continue }
            let updated = row.updatedAt.flatMap { timestamp.date(from: $0) ?? timestampWithoutFraction.date(from: $0) }
            grouped[row.key, default: []].append(.init(date: date, value: value,
                periodEnd: end, updatedAt: updated, status: row.status))
        }
        return try WebstatStarter.definitions.map { definition in
            let observations = (grouped[definition.seriesCode] ?? []).filter {
                definition.unit == .percent || $0.value > 0
            }
            guard !observations.isEmpty else { throw WebstatError.incompleteData }
            return MarketSeries(id: definition.seriesCode, name: definition.name, subtitle: definition.subtitle,
                category: definition.category, unit: definition.unit, fractionDigits: definition.digits,
                source: definition.producer,
                sourceURL: URL(string: WebstatSite.catalogueURL + "\(definition.seriesCode.split(separator: ".")[0].lowercased())/\(definition.seriesCode)"),
                frequency: definition.frequency, observations: observations)
        }
    }


    private struct Row: Decodable {
        let key: String
        let start: String
        let end: String
        let value: Decimal?
        let status: String?
        let updatedAt: String?

        enum CodingKeys: String, CodingKey {
            case key = "series_key", start = "time_period_start", end = "time_period_end"
            case value = "obs_value", status = "obs_status", updatedAt = "updated_at"
        }
    }
}
}
