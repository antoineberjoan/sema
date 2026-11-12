// Les noms français des palettes, tels que le sélecteur de réglages les affiche.
import SemaDesign

extension DesignPalette {
    var title: String {
        switch self {
        case .brand: "sema"
        case .graphite: "Graphite"
        case .teal: "Sarcelle"
        case .mint: "Menthe"
        case .lavender: "Lavande"
        case .sky: "Bleu ciel"
        case .polar: "Bleu polaire"
        }
    }
}
