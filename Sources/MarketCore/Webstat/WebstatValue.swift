// Valeur brute Webstat conservée telle quelle, même lorsqu’elle n’est pas interprétée.
import Foundation

/// Source values are kept verbatim, including fields that Sema does not interpret yet.
public enum WebstatValue: Codable, Equatable, Sendable {
    case string(String), number(Decimal), bool(Bool), array([WebstatValue]), object([String: WebstatValue]), null

    public init(from decoder: any Decoder) throws {
        let value = try decoder.singleValueContainer()
        if value.decodeNil() { self = .null }
        else if let text = try? value.decode(String.self) { self = .string(text) }
        else if let boolean = try? value.decode(Bool.self) { self = .bool(boolean) }
        else if let number = try? value.decode(Decimal.self) { self = .number(number) }
        else if let array = try? value.decode([WebstatValue].self) { self = .array(array) }
        else { self = .object(try value.decode([String: WebstatValue].self)) }
    }
    public func encode(to encoder: any Encoder) throws {
        var value = encoder.singleValueContainer()
        switch self {
        case .string(let text): try value.encode(text)
        case .number(let number): try value.encode(number)
        case .bool(let boolean): try value.encode(boolean)
        case .array(let array): try value.encode(array)
        case .object(let object): try value.encode(object)
        case .null: try value.encodeNil()
        }
    }
    public var text: String? {
        switch self {
        case .string(let value): value
        case .number(let value): NSDecimalNumber(decimal: value).stringValue
        case .bool(let value): String(value)
        case .array(let values): values.compactMap(\.text).joined(separator: ", ")
        case .object, .null: nil
        }
    }
}
