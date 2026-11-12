// Rédacteur de la synthèse choisi dans les réglages : aucun par défaut, Apple Intelligence sur le Mac ou Claude avec une clé.
import Foundation

public enum SummaryWriter: String, CaseIterable, Codable, Identifiable, Sendable {
    case off, appleIntelligence = "apple-intelligence", claude
    public static let standard = SummaryWriter.off
    public var id: String { rawValue }
    public var title: String {
        switch self { case .off: "Désactivée"; case .appleIntelligence: "Apple Intelligence · sur ce Mac"; case .claude: "Claude · votre clé API" }
    }
    public var signature: String {
        switch self { case .off: ""; case .appleIntelligence: "Apple Intelligence, sur ce Mac"; case .claude: "Claude, avec votre clé" }
    }
}
