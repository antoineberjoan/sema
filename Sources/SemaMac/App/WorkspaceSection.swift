// Rubriques de la fenêtre principale, leurs titres et symboles.

enum WorkspaceSection: String, CaseIterable, Identifiable {
    case overview, favorites, alerts, explorer
    var id: String { rawValue }
    var title: String {
        switch self { case .overview: "Panorama"; case .favorites: "Favoris"; case .alerts: "Alertes"; case .explorer: "Explorer" }
    }
    var symbol: String {
        switch self { case .overview: "square.grid.2x2"; case .favorites: "star"; case .alerts: "bell"; case .explorer: "globe.europe.africa" }
    }
}
