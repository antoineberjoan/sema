// Fait passer un identifiant enregistré dans un fichier de la personne vers le code de série Webstat.
import Foundation

/// Un fichier écrit par une version publiée peut porter un nom de départ (« fr10 ») à la place du code de série.
/// Appelée seulement au chargement d'un fichier. Retrait : voir `docs/decisions/2026-11-12-relecture-des-versions-de-fichiers.md`.
public enum IdentifierMigration {
    public static func upgrade(_ savedID: String) -> String { WebstatStarter.starterKey(savedID) }
}
