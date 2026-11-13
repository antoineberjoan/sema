// Résultat d'une vérification des règles : règles avancées, points de départ consommés et événements nés.
import Foundation

public struct AlertCheck: Equatable, Sendable {
    public var rules: [AlertRule]
    public var baselineIDs: Set<UUID>?
    public var events: [AlertEvent]
    /// Vrai si au moins un point de contrôle a bougé : il faut alors enregistrer avant d'envoyer.
    public var hasAdvanced: Bool
}
