// Séquence et ressorts du sélecteur Focus, partagés avec l’espace de travail.
import SwiftUI

// SÉLECTEUR
//   0 ms  ⌘ + flèche révèle les repères, le prochain est mis en évidence.
// 180 ms  Le défilement centre la sélection avec un ressort sans rebond.
// Relâcher ⌘ / Entrée → ouverture ; Échap / sortie de fenêtre → annulation.
enum FocusSwitcherMotion {
    static let selection = Animation.snappy(duration: 0.18, extraBounce: 0)
    static let presentation = Animation.snappy(duration: 0.20, extraBounce: 0)
}
