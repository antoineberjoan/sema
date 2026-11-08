// Faits datés d’une séance autour d’un mouvement : repères liés, publications, communiqués et titres, sans cause affirmée.
import Foundation

public struct DayContext: Equatable, Sendable {
    public let day: Date
    public var peers: [PeerMove] = []
    public var releases: [EconomicRelease] = []
    public var pressReleases: [PressRelease] = []
    public var headlines: [Headline] = []
    /// Parts that could not be loaded, named for the reader (for example « Titres »), so an empty list is never mistaken for « rien ».
    public var unavailable: [String] = []

    public init(day: Date) { self.day = day }

    /// Start and end of the UTC calendar day of a session, used to query every source on the same window.
    public static func window(for day: Date) -> (start: Date, end: Date) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = calendar.startOfDay(for: day)
        return (start, start.addingTimeInterval(.day - 1))
    }
}
