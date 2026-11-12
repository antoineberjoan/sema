// Traduit les réponses de Twelve Data en instruments et en cotations du cœur.
import Foundation

enum TwelveDataMapping {
    static func instruments(_ data: [String: Any], plan: String, kind: String?) throws -> [MarketInstrument] {
        guard let rows = data["data"] as? [[String: Any]], let count = data["count"] as? Int,
              count == rows.count, recognizes(plan) else { throw MarketDataError.invalidData }
        var seen: Set<String> = []
        return rows.compactMap { row in
            guard let access = row["access"] as? [String: String], permits(access: access, plan: plan),
                  let symbol = row["symbol"] as? String, !symbol.isEmpty,
                  let name = row["name"] as? String, !name.isEmpty,
                  let currency = row["currency"] as? String, !currency.isEmpty else { return nil }
            let item = MarketInstrument(provider: .twelveData, symbol: symbol, name: name,
                exchange: row["exchange"] as? String ?? "", currency: currency,
                kind: kind ?? (row["type"] as? String ?? ""))
            guard !item.kind.isEmpty else { return nil }
            return seen.insert(item.id).inserted ? item : nil
        }
    }

    // Les familles personnelles et Business restent distinctes : aucun droit n’est déduit du quota.
    static func recognizes(_ plan: String) -> Bool {
        ["basic", "grow", "pro", "ultra", "venture", "enterprise", "enterprise+"].contains(plan.lowercased())
    }
    static func permits(access: [String: String], plan: String) -> Bool {
        let plan = plan.lowercased()
        let business = ["venture", "enterprise", "enterprise+"]
        let family = business.contains(plan) ? ["basic"] + business : ["basic", "grow", "pro", "ultra"]
        let field = business.contains(plan) ? "plan_business" : "plan"
        guard let required = access[field]?.lowercased(), let requiredRank = family.firstIndex(of: required),
              let rank = family.firstIndex(of: plan) else { return false }
        return rank >= requiredRank
    }

    /// Les clôtures publiées, après contrôle que la réponse parle bien de l'instrument demandé.
    static func rows(_ data: [String: Any], instrument: MarketInstrument) throws -> [(String, String)] {
        guard let values = data["values"] as? [[String: String]],
              let meta = data["meta"] as? [String: Any],
              meta["symbol"] as? String == instrument.symbol,
              meta["interval"] as? String == (instrument.weekly ? "1week" : "1day") else { throw MarketDataError.invalidData }
        if let currency = meta["currency"] as? String, currency != instrument.currency { throw MarketDataError.invalidData }
        if !instrument.exchange.isEmpty, let exchange = meta["exchange"] as? String,
           exchange != instrument.exchange { throw MarketDataError.invalidData }
        return try values.map { row in
            guard let date = row["datetime"], let close = row["close"] else { throw MarketDataError.invalidData }
            return (date, close)
        }
    }

    static func series(_ data: [String: Any], instrument: MarketInstrument, now: Date) throws -> MarketSeries {
        try MarketDataFormat.series(rows: rows(data, instrument: instrument), instrument: instrument, now: now)
    }
}
