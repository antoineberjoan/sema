// Traduit les réponses d'Alpha Vantage en instruments, cotations et titres de presse du cœur.
import Foundation

enum AlphaVantageMapping {
    static func instruments(_ body: Data) throws -> [MarketInstrument] {
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

    static func rows(_ data: [String: Any], instrument: MarketInstrument) throws -> [(String, String)] {
        let field = instrument.weekly ? "Weekly Time Series" : "Time Series (Daily)"
        guard let values = data[field] as? [String: [String: String]],
              let meta = data["Meta Data"] as? [String: String],
              meta["2. Symbol"] == instrument.symbol else { throw MarketDataError.invalidData }
        return try values.map { date, row in
            guard let close = row["4. close"] else { throw MarketDataError.invalidData }
            return (date, close)
        }
    }

    static func series(_ data: [String: Any], instrument: MarketInstrument, now: Date) throws -> MarketSeries {
        try MarketDataFormat.series(rows: rows(data, instrument: instrument), instrument: instrument, now: now)
    }

    static func news(_ body: Data) throws -> [Headline] {
        guard let root = try? JSONDecoder().decode([String: WebstatValue].self, from: body) else { throw MarketDataError.invalidData }
        guard case .array(let feed) = root["feed"] else { return [] }
        return feed.compactMap { value -> Headline? in
            guard case .object(let item) = value, let title = item["title"]?.text, !title.isEmpty,
                  let link = item["url"]?.text.flatMap(URL.init(string:)), link.scheme == "https",
                  let date = item["time_published"]?.text.flatMap(Headline.compactDate) else { return nil }
            return Headline(title: title, link: link, publisher: item["source"]?.text ?? link.host ?? "", publishedAt: date)
        }
    }
}
