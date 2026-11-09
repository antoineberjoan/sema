// Lecture des jours de l’agenda : ils sont construits à midi UTC, donc nommés et comparés sur le calendrier UTC.
import Foundation

enum AgendaDay {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    /// French text of a day, for example « EEE » gives « jeu. ».
    static func text(_ date: Date, _ format: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = .french
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = format
        return formatter.string(from: date)
    }

    static func isSame(_ first: Date, _ second: Date) -> Bool { calendar.isDate(first, inSameDayAs: second) }
}
