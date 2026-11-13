// État partagé entre le panneau de recherche rapide et son contrôleur : le repère affiché en détail.
import Observation
import MarketCore

@MainActor
@Observable
final class SearchPanelModel {
    /// La série montrée dans le panneau après Retour ; Échap revient à la liste avant de fermer.
    var detail: MarketSeries?
}
