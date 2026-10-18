// Lit et valide un seuil saisi, en niveau libre ou en variation bornée.
import Foundation

public enum AlertThreshold {
    /// `Decimal` keeps at most 38 significant digits.
    static let maximumDigits = 38
    /// A relative change threshold stays within 100 %.
    public static let maximumRelativeChange: Decimal = 100
    /// A level may be zero or negative (inflation and policy rates), or exceed 100 (JPY).
    public static func parseLevel(_ text: String) -> Decimal? {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.range(of: "^-?[0-9]+([,.][0-9]{1,18})?$", options: .regularExpression) != nil,
              normalized.filter(\.isNumber).count <= Self.maximumDigits,
              let value = Decimal(string: normalized.replacingOccurrences(of: ",", with: "."),
                                  locale: .posix), !value.isNaN else { return nil }
        return value
    }

    /// Accepts a French decimal comma or a decimal point, with no partial parsing.
    public static func parse(_ text: String) -> Decimal? {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.range(of: "^[0-9]+([,.][0-9]{1,4})?$", options: .regularExpression) != nil,
              let value = Decimal(string: normalized.replacingOccurrences(of: ",", with: "."),
                                  locale: .posix),
              value > 0, value <= Self.maximumRelativeChange else { return nil }
        return value
    }
}
