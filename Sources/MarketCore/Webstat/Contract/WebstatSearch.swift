// Critères d’une recherche dans le catalogue Webstat.
import Foundation

public struct WebstatSearch: Equatable, Sendable {
    public var query: String
    public var datasetID: String
    public var area: String
    public var frequency: String
    public var areaField: String
    public init(query: String = "", datasetID: String = "", area: String = "", frequency: String = "", areaField: String = "ref_area") {
        self.query = query; self.datasetID = datasetID; self.area = area; self.frequency = frequency; self.areaField = areaField
    }
}
