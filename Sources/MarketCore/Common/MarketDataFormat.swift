// Lecture commune des clôtures et des erreurs des fournisseurs de cours à clé personnelle.
import Foundation

enum MarketDataFormat {
    private static let numberLocale = Locale(identifier: "en_US_POSIX")
    private static let priceDigits = 2
    private static let smallPriceDigits = 6

    /// Transforme des couples (date, clôture) en série, avec les nombres décimaux exacts et le nombre de chiffres publié.
    static func series(rows: [(String, String)], instrument: MarketInstrument, now: Date) throws -> MarketSeries {
        let formatter = DateFormatter()
        formatter.locale = numberLocale; formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"; formatter.isLenient = false
        var precision = 0
        let points = try rows.map { date, close -> MarketObservation in
            guard date.count == 10, let day = formatter.date(from: date), formatter.string(from: day) == date,
                  close.range(of: #"^[0-9]+(?:\.[0-9]+)?$"#, options: .regularExpression) != nil,
                  let value = Decimal(string: close, locale: numberLocale), !value.isNaN,
                  value >= 0 else { throw MarketDataError.invalidData }
            precision = max(precision, close.split(separator: ".").dropFirst().first?.count ?? 0)
            return MarketObservation(date: day, value: value)
        }
        guard !points.isEmpty, !instrument.displayUnit.isEmpty else { throw MarketDataError.unavailable }
        let latest = points.max { $0.date < $1.date }!.value
        let detailed = instrument.kind.lowercased().contains("currency") || instrument.kind.lowercased().contains("crypto") || (latest > 0 && latest < 1)
        let displayDigits = min(precision, detailed ? smallPriceDigits : priceDigits)
        return MarketSeries(id: instrument.id, name: instrument.name,
            subtitle: instrument.summary + " · cours non ajustés",
            category: .markets, unit: .number, fractionDigits: displayDigits, source: instrument.provider.title,
            sourceURL: instrument.provider.website, frequency: instrument.isWeekly ? .weekly : .businessDaily,
            observations: points, syncedAt: now, hasCompleteHistory: false, marketInstrument: instrument)
    }

    /// Un fournisseur peut répondre 200 avec une erreur dans le corps : on la lit aussi.
    static func checkError(_ data: [String: Any]) throws {
        let message = [data["message"], data["Information"], data["Note"], data["Error Message"]]
            .compactMap { $0 as? String }.joined(separator: " ").lowercased()
        let code = data["code"] as? Int
        if code == 401 || message.contains("invalid api key") || message.contains("apikey is invalid") { throw MarketDataError.invalidKey }
        if code == 429 || message.contains("rate limit") || message.contains("call frequency") || message.contains("requests per day") { throw MarketDataError.quota }
        if code == 403 || message.contains("premium") || message.contains("upgrade") || message.contains("subscription") || message.contains("not yet entitled") { throw MarketDataError.entitlement }
        if data["status"] as? String == "error" || !message.isEmpty { throw MarketDataError.unavailable }
    }
}
