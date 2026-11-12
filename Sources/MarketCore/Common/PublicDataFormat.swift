// Lecture commune des nombres et des périodes que publient les sources statistiques.
import Foundation

enum PublicDataFormat {
    static func decimal(_ text: String) -> Decimal? {
        guard text.range(of: "^-?(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)(?:[eE][+-]?[0-9]+)?$", options: .regularExpression) != nil,
              let value = Decimal(string: text, locale: .posix), !value.isNaN else { return nil }
        return value
    }
    static func period(_ text: String) -> (start: Date, end: Date)? {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let formatter = ISO8601DateFormatter(); formatter.formatOptions = [.withFullDate]
        if text.count == 10, let date = formatter.date(from: text), formatter.string(from: date) == text { return (date, date) }
        guard let year = Int(text.prefix(4)), year >= 1, text.count >= 4 else { return nil }
        var month = 1; var length = 12
        if text.count == 7, text.dropFirst(4).first == "-" {
            let suffix = String(text.suffix(2))
            if ["Q", "T"].contains(String(suffix.prefix(1))), let quarter = Int(suffix.suffix(1)), (1...4).contains(quarter) { month = (quarter - 1) * 3 + 1; length = 3 }
            else if ["S", "H"].contains(String(suffix.prefix(1))), let half = Int(suffix.suffix(1)), (1...2).contains(half) { month = (half - 1) * 6 + 1; length = 6 }
            else if let number = Int(suffix), (1...12).contains(number) { month = number; length = 1 }
            else { return nil }
        } else if text.count == 8, text.contains("-W"), let week = Int(text.suffix(2)), (1...53).contains(week) {
            var iso = Calendar(identifier: .iso8601); iso.timeZone = calendar.timeZone
            guard let start = iso.date(from: DateComponents(weekday: 2, weekOfYear: week, yearForWeekOfYear: year)),
                  iso.component(.weekOfYear, from: start) == week, iso.component(.yearForWeekOfYear, from: start) == year else { return nil }
            return (start, start.addingTimeInterval(6 * .day))
        } else if text.count != 4 { return nil }
        guard let start = calendar.date(from: DateComponents(year: year, month: month, day: 1)), let next = calendar.date(byAdding: .month, value: length, to: start) else { return nil }
        return (start, next.addingTimeInterval(-.day))
    }
}
