// Copie locale du catalogue Webstat, versionnée pour rester lisible hors connexion.
import Foundation
import MarketCore

struct WebstatCatalogueCache: Codable {
    var schemaVersion = 1
    let datasets: [WebstatDataset]
    let labels: [String: [String: String]]
}
