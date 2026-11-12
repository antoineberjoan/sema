// Locales fixes de l’app : français pour l’affichage et la recherche, POSIX pour lire les nombres publiés.
import Foundation

extension Locale {
    public static let french = Locale(identifier: "fr_FR")
    public static let posix = Locale(identifier: "en_US_POSIX")
}
