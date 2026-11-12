// Séquence et ressorts du sélecteur Focus, partagés avec l’espace de travail.
import SemaDesign
import SwiftUI

// SÉLECTEUR
//   0 ms  ⌘ + flèche révèle les repères, le prochain est mis en évidence.
// 180 ms  Le défilement centre la sélection avec un ressort sans rebond.
// Relâcher ⌘ / Entrée → ouverture ; Échap / sortie de fenêtre → annulation.
enum FocusSwitcherMotion {
    static let selection = Animation.timingCurve(DesignEase.out, duration: DesignDuration.standard)
    static let presentation = Animation.timingCurve(DesignEase.out, duration: DesignDuration.standard)
}
