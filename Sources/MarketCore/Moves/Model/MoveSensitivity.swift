// Sensibilité globale des alertes de mouvement inhabituel : un multiple de la variation habituelle.
import Foundation

public enum MoveSensitivity: String, CaseIterable, Codable, Identifiable, Sendable {
    case discreet, normal, attentive
    public static let standard = MoveSensitivity.normal
    public var id: String { rawValue }
    public var title: String {
        switch self { case .discreet: "Discrète"; case .normal: "Normale"; case .attentive: "Attentive" }
    }
    /// Un mouvement est inhabituel quand sa variation absolue atteint ce multiple de la variation habituelle.
    public var multiplier: Double {
        switch self { case .discreet: 3; case .normal: 2; case .attentive: 1.5 }
    }
    /// Alertes attendues par série et par an si les variations quotidiennes suivaient une loi normale (252 séances) ;
    /// les vrais marchés en produisent d’ordinaire plus.
    public var expectedAlertsPerYear: Double {
        switch self { case .discreet: 0.7; case .normal: 11.5; case .attentive: 33.7 }
    }
}
