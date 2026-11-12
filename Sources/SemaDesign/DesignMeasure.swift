// Les jetons measure.
// fabriqué depuis tokens.json par sophos/outils/jetons.mjs ; ne pas modifier à la main (patron 1.1.0).
import SwiftUI

public enum DesignMeasure {
    /// Largeur maximale d'une colonne de lecture, en caractères.
    public static let reading: Double = 65
    /// Propre à sema : le facteur qui étend l'opacité du voile du verre sur toute la plage du réglage Transparence.
    public static let glassVeilRange: Double = 4
    /// Propre à sema : le facteur qui étend l'opacité de la teinte du verre sur toute la plage du réglage Teinte.
    public static let glassTintRange: Double = 2
    /// Propre à sema : l'échelle de la tuile de grain du verre, en pixels de l'image par point.
    public static let glassGrainScale: Double = 2
    /// Propre à sema : la taille des initiales d'un avatar, en fraction de sa taille.
    public static let avatarInitialsScale: Double = 0.34
    /// Propre à sema : la taille du symbole d'un avatar sans photo ni initiales, en fraction de sa taille.
    public static let avatarSymbolScale: Double = 0.4
    /// Propre à sema : value minimum scale, RibbonCard (mesure).
    public static let ribbonCardValueMinimumScale: Double = 0.7
    /// Propre à sema : top inset, SearchPanelController (mesure).
    public static let searchPanelControllerTopInset: Double = 0.18
    /// Propre à sema : value minimum scale, IndicatorTile (mesure).
    public static let indicatorTileValueMinimumScale: Double = 0.85
    /// Propre à sema : value minimum scale, SeriesDetail (mesure).
    public static let seriesDetailValueMinimumScale: Double = 0.55
    /// Propre à sema : value minimum scale, FocusSwitcher (mesure).
    public static let focusSwitcherValueMinimumScale: Double = 0.75
    /// Propre à sema : domain margin, HistoryChart (mesure).
    public static let historyChartDomainMargin: Double = 0.2
    /// Propre à sema : relative margin floor, HistoryChart (mesure).
    public static let historyChartRelativeMarginFloor: Double = 0.002
    /// Propre à sema : margin floor, HistoryChart (mesure).
    public static let historyChartMarginFloor: Double = 0.0001
    /// Propre à sema : status lines, Workspace (taille).
    public static let workspaceStatusLines: Double = 2
    /// Propre à sema : name lines, Workspace (taille).
    public static let nameLines: Double = 2
    /// Propre à sema : palette title lines, Settings (taille).
    public static let settingsPaletteTitleLines: Double = 2
    /// Propre à sema : heading lines, RibbonCard (taille).
    public static let ribbonCardHeadingLines: Double = 2
    /// Propre à sema : empty lines, AgendaCard (taille).
    public static let agendaCardEmptyLines: Double = 4
    /// Propre à sema : preferred visible cards, MenuRibbon (taille).
    public static let menuRibbonPreferredVisibleCards: Double = 4
    /// Propre à sema : fixed cards, MenuRibbon (taille).
    public static let menuRibbonFixedCards: Double = 2
    /// Propre à sema : title lines, Agenda (taille).
    public static let agendaTitleLines: Double = 2
    /// Propre à sema : topic lines, SourceExplorer (taille).
    public static let sourceExplorerTopicLines: Double = 2
    /// Propre à sema : series title lines, StatisticalExplorer (taille).
    public static let statisticalExplorerSeriesTitleLines: Double = 4
    /// Propre à sema : value lines, StatisticalExplorer (taille).
    public static let statisticalExplorerValueLines: Double = 2
    /// Propre à sema : detail lines, CatalogueBrowser (taille).
    public static let catalogueBrowserDetailLines: Double = 2
    /// Propre à sema : row title lines, Explorer (taille).
    public static let explorerRowTitleLines: Double = 3
    /// Propre à sema : definition lines, SeriesExplanation (taille).
    public static let seriesExplanationDefinitionLines: Double = 4
    /// Propre à sema : le côté en pixels de la photo de profil enregistrée.
    public static let profilePhotoPixelSize: Double = 384
    /// Propre à sema : le côté maximal en pixels de la vignette lue avant le recadrage de la photo de profil.
    public static let profilePhotoThumbnailPixelSize: Double = 768
    /// Propre à sema : la qualité de compression JPEG de la photo de profil, de 0 à 1.
    public static let profilePhotoJpegQuality: Double = 0.85
}
