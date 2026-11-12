// Sensibilité globale des alertes de mouvement inhabituel : un multiple de la variation habituelle.
import Foundation

public enum MoveSensitivity: String, CaseIterable, Codable, Identifiable, Sendable {
    case discreet, normal, attentive
    public static let standard = MoveSensitivity.normal
    public var id: String { rawValue }
    public var title: String {
        switch self { case .discreet: "Discrète"; case .normal: "Normale"; case .attentive: "Attentive" }
    }
    /// A move is unusual when its absolute change reaches this multiple of the usual variation.
    public var multiplier: Double {
        switch self { case .discreet: 3; case .normal: 2; case .attentive: 1.5 }
    }
    /// Expected alerts per series and per year if daily changes were normally distributed (252 sessions);
    /// real markets usually produce more.
    public var expectedAlertsPerYear: Double {
        switch self { case .discreet: 0.7; case .normal: 11.5; case .attentive: 33.7 }
    }
}
