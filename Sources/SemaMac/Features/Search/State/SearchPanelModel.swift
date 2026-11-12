// État partagé entre le panneau de recherche rapide et son contrôleur : le repère affiché en détail.
import Observation
import MarketCore

@MainActor
@Observable
final class SearchPanelModel {
    /// The series shown in the panel after Return; Escape goes back to the list before closing.
    var detail: MarketSeries?
}
