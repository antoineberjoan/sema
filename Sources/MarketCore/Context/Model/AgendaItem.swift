// Ligne de l’agenda d’un jour : un mouvement inhabituel, une publication, un communiqué ou un titre, chacun avec sa source.
import Foundation

public enum AgendaItem: Equatable, Identifiable, Sendable {
    case move(PeerMove)
    case release(EconomicRelease)
    case pressRelease(PressRelease)
    case headline(Headline)

    public var id: String {
        switch self {
        case .move(let value): "move:\(value.id)"
        case .release(let value): "release:\(value.id)"
        case .pressRelease(let value): "press:\(value.id)"
        case .headline(let value): "headline:\(value.id)"
        }
    }
}
