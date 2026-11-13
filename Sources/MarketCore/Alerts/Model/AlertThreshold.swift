// Lit et valide un seuil saisi, en niveau libre ou en variation bornée.
import Foundation

public enum AlertThreshold {
    /// `Decimal` garde au plus 38 chiffres significatifs.
    static let maximumDigits = 38
    /// Un seuil de variation relative reste dans 100 %.
    public static let maximumRelativeChange: Decimal = 100
    /// Un niveau peut être nul ou négatif (inflation et taux directeurs), ou dépasser 100 (JPY).
    public static func parseLevel(_ text: String) -> Decimal? {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.range(of: "^-?[0-9]+([,.][0-9]{1,18})?$", options: .regularExpression) != nil,
              normalized.filter(\.isNumber).count <= Self.maximumDigits,
              let value = Decimal(string: normalized.replacingOccurrences(of: ",", with: "."),
                                  locale: .posix), !value.isNaN else { return nil }
        return value
    }

    /// Accepte une virgule décimale française ou un point décimal, sans lecture partielle.
    public static func parse(_ text: String) -> Decimal? {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.range(of: "^[0-9]+([,.][0-9]{1,4})?$", options: .regularExpression) != nil,
              let value = Decimal(string: normalized.replacingOccurrences(of: ",", with: "."),
                                  locale: .posix),
              value > 0, value <= Self.maximumRelativeChange else { return nil }
        return value
    }
}
