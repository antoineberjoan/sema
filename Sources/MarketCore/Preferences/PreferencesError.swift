// Dit pourquoi un document de réglages ou un cache n'est pas lu : sa version n'est pas connue.
import Foundation

public enum PreferencesError: Error, LocalizedError {
    case unsupportedVersion(Int)
    public var errorDescription: String? {
        switch self { case .unsupportedVersion(let version): "Version de réglages non prise en charge : \(version)." }
    }
}
