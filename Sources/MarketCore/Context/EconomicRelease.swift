// Publication économique inscrite au calendrier FRED pour une journée.
import Foundation

public struct EconomicRelease: Codable, Equatable, Identifiable, Sendable {
    public let releaseID: String
    public let name: String
    public let date: Date
    public var id: String { "\(releaseID):\(date.timeIntervalSince1970)" }

    public init(releaseID: String, name: String, date: Date) {
        self.releaseID = releaseID; self.name = name; self.date = date
    }
}
