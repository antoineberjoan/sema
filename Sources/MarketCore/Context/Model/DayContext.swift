// Faits datés d’une séance autour d’un mouvement : repères liés, publications, communiqués et titres, sans cause affirmée.
import Foundation

public struct DayContext: Equatable, Sendable {
    public let day: Date
    public var peers: [PeerMove] = []
    public var releases: [EconomicRelease] = []
    public var pressReleases: [PressRelease] = []
    public var headlines: [Headline] = []
    /// Parties qui n’ont pas pu se charger, nommées pour le lecteur (par exemple « Titres »), pour qu’une liste vide ne passe jamais pour « rien ».
    public var unavailable: [String] = []

    public init(day: Date) { self.day = day }

    /// Début et fin du jour calendaire UTC d’une séance, utilisés pour interroger chaque source sur la même fenêtre.
    public static func window(for day: Date) -> (start: Date, end: Date) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = calendar.startOfDay(for: day)
        return (start, start.addingTimeInterval(.day - 1))
    }
}
