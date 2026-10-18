// Jeu du catalogue Webstat et ses filtres de découverte.
import Foundation

public struct WebstatDataset: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let detail: String
    public let raw: [String: WebstatValue]
    public var dimensionCodelists: [String: String] { WebstatSeriesDescriptor.dictionary(raw["dimensions_and_codelists"]?.text) }
    public var attributeCodelists: [String: String] { WebstatSeriesDescriptor.dictionary(raw["series_attributes_and_codelists"]?.text) }
    public var areaField: String? { ["REF_AREA", "AME_REF_AREA", "ZONE_GEO"].first { dimensionCodelists[$0] != nil }?.lowercased() }
    public var areaCodelist: String? { areaField.flatMap { dimensionCodelists[$0.uppercased()] } }
    public init(raw: [String: WebstatValue]) throws {
        guard let id = raw["dataset_id"]?.text else { throw WebstatClient.ClientError.invalidData }
        self.id = id
        title = raw["title_fr"]?.text ?? raw["name_fr"]?.text ?? id
        detail = raw["description_fr"]?.text ?? ""
        self.raw = raw
    }
}
