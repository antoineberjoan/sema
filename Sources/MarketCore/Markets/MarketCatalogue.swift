// Porte le catalogue navigable, filtré par forfait quand le fournisseur publie ce contrat.
import Foundation

public struct MarketCatalogue: Equatable, Sendable {
    public let instruments: [MarketInstrument]
    public let scope: String
    // Actions largement reconnues, suivies de deux ETF indiciels connus, selon le catalogue réel.
    private static let starterSymbols = [
        "AAPL", "MSFT", "NVDA", "TSLA", "SPY", "QQQ", "GOOGL", "AMZN", "META", "JPM",
        "V", "MA", "WMT", "COST", "NFLX", "AVGO", "AMD", "ORCL", "LLY", "XOM"
    ]
    private static let starterETFs: Set<String> = ["SPY", "QQQ"]

    public var starters: [MarketInstrument] {
        guard let provider = instruments.first?.provider else { return [] }
        return Self.starterSymbols.compactMap { symbol in
            instruments.filter { item in
                let isExpectedType = Self.starterETFs.contains(symbol)
                    ? item.kind.caseInsensitiveCompare("ETF") == .orderedSame
                    : ["Stock", "Common Stock"].contains { item.kind.caseInsensitiveCompare($0) == .orderedSame }
                return item.provider == provider && item.symbol == symbol && item.currency == "USD" && isExpectedType
            }
            .sorted {
                let exchangeOrder = $0.exchange.localizedStandardCompare($1.exchange)
                if exchangeOrder != .orderedSame { return exchangeOrder == .orderedAscending }
                return $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
            .first
        }
    }

    static func twelve(_ data: [String: Any], plan: String, kind: String?) throws -> [MarketInstrument] {
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

    static func alpha(_ body: Data) throws -> [MarketInstrument] {
        guard let text = String(data: body, encoding: .utf8) else { throw MarketDataError.invalidData }
        let rows = try csv(text)
        guard let header = rows.first,
              let symbolIndex = header.firstIndex(of: "symbol"), let nameIndex = header.firstIndex(of: "name"),
              let exchangeIndex = header.firstIndex(of: "exchange"), let typeIndex = header.firstIndex(of: "assetType"),
              let statusIndex = header.firstIndex(of: "status") else { throw MarketDataError.invalidData }
        var seen: Set<String> = []
        return try rows.dropFirst().compactMap { row in
            guard row.count == header.count else { throw MarketDataError.invalidData }
            guard row[statusIndex] == "Active", ["Stock", "ETF"].contains(row[typeIndex]),
                  !row[symbolIndex].isEmpty, !row[nameIndex].isEmpty else { return nil }
            // LISTING_STATUS est explicitement le catalogue des cotations américaines.
            let item = MarketInstrument(provider: .alphaVantage, symbol: row[symbolIndex], name: row[nameIndex],
                exchange: row[exchangeIndex], currency: "USD", kind: row[typeIndex])
            return seen.insert(item.id).inserted ? item : nil
        }
    }

    private static func csv(_ text: String) throws -> [[String]] {
        let characters = Array(text.hasPrefix("\u{FEFF}") ? String(text.dropFirst()) : text)
        var rows: [[String]] = [], row: [String] = [], field = ""
        var quoted = false, closed = false, index = 0
        while index < characters.count {
            let value = characters[index]
            if quoted {
                if value == "\"" {
                    if index + 1 < characters.count, characters[index + 1] == "\"" { field.append("\""); index += 1 }
                    else { quoted = false; closed = true }
                } else { field.append(value) }
            } else if value == "," {
                row.append(field); field = ""; closed = false
            } else if value == "\n" || value == "\r" || value == "\r\n" {
                row.append(field)
                if row != [""] { rows.append(row) }
                row = []; field = ""; closed = false
                if value == "\r", index + 1 < characters.count, characters[index + 1] == "\n" { index += 1 }
            } else if value == "\"", field.isEmpty, !closed { quoted = true }
            else {
                guard !closed, value != "\"" else { throw MarketDataError.invalidData }
                field.append(value)
            }
            index += 1
        }
        guard !quoted else { throw MarketDataError.invalidData }
        if !field.isEmpty || !row.isEmpty || closed { row.append(field); rows.append(row) }
        return rows
    }
}
