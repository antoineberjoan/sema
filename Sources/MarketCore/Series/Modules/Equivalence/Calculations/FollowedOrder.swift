// Calcule l'ordre des repères suivis : un déplacement, puis la liste d'identifiants qui garde les équivalents côte à côte.
import Foundation

public enum FollowedOrder {
    /// Échange un repère avec son voisin à `offset` places ; nil si l'identifiant ou la place n'existe pas.
    public static func moving(_ ordered: [MarketSeries], id: String, by offset: Int) -> [MarketSeries]? {
        var ordered = ordered
        guard let index = ordered.firstIndex(where: { $0.id == id }) else { return nil }
        let target = index + offset
        guard ordered.indices.contains(target) else { return nil }
        ordered.swapAt(index, target)
        return ordered
    }

    /// Déplace un groupe de repères vers `destination` (convention de `onMove` de SwiftUI) ; nil si une place n'existe pas.
    public static func moving(_ ordered: [MarketSeries], from offsets: IndexSet, to destination: Int) -> [MarketSeries]? {
        var ordered = ordered
        guard offsets.allSatisfy({ ordered.indices.contains($0) }) else { return nil }
        let moved = offsets.sorted().map { ordered[$0] }
        for index in offsets.sorted(by: >) { ordered.remove(at: index) }
        let target = destination - offsets.filter { $0 < destination }.count
        ordered.insert(contentsOf: moved, at: min(max(0, target), ordered.count))
        return ordered
    }

    /// Identifiants dans l'ordre voulu, chaque repère suivi de ses équivalents ; les identifiants inconnus du tri restent à la fin.
    public static func ids(ordered: [MarketSeries], stored: [MarketSeries], followedIDs: [String]) -> [String] {
        let groups = ordered.flatMap { item in stored.filter { SeriesEquivalence.matches(item, $0) }.map(\.id) }
        return groups + followedIDs.filter { id in !groups.contains(id) }
    }

    /// Identifiants des repères suivis équivalents à `item`, lui compris s'il est suivi.
    public static func equivalentIDs(of item: MarketSeries?, among stored: [MarketSeries]) -> Set<String> {
        guard let item else { return [] }
        return Set(stored.filter { SeriesEquivalence.matches(item, $0) }.map(\.id))
    }
}
