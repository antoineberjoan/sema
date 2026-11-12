// Propre à sema : les tailles de fenêtre, de colonne et de composant, un rôle par usage.
// fabriqué depuis tokens.json par sophos/outils/jetons.mjs ; ne pas modifier à la main (patron 1.1.0).
import SwiftUI

public enum DesignLayout {
    /// Propre à sema : default width, MacApp (taille).
    public static let macAppDefaultWidth: CGFloat = 1120
    /// Propre à sema : default height, MacApp (taille).
    public static let macAppDefaultHeight: CGFloat = 760
    /// Propre à sema : empty min height, Overview (taille).
    public static let overviewEmptyMinHeight: CGFloat = 450
    /// Propre à sema : empty min height, Alerts (taille).
    public static let alertsEmptyMinHeight: CGFloat = 350
    /// Propre à sema : name width, WatchRow (taille).
    public static let watchRowNameWidth: CGFloat = 220
    /// Propre à sema : icon size, AlertRow (taille).
    public static let alertRowIconSize: CGFloat = 30
    /// Propre à sema : minimum height, Explorer (taille).
    public static let explorerMinimumHeight: CGFloat = 510
    /// Propre à sema : minimum width, Workspace (taille).
    public static let workspaceMinimumWidth: CGFloat = 980
    /// Propre à sema : minimum height, Workspace (taille).
    public static let workspaceMinimumHeight: CGFloat = 680
    /// Propre à sema : icon width, SidebarItem (taille).
    public static let iconWidth: CGFloat = 16
    /// Propre à sema : sidebar min width, FocusMotion (taille).
    public static let focusMotionSidebarMinWidth: CGFloat = 220
    /// Propre à sema : sidebar max width, FocusMotion (taille).
    public static let focusMotionSidebarMaxWidth: CGFloat = 280
    /// Propre à sema : sidebar width, FocusMotion (taille).
    public static let focusMotionSidebarWidth: CGFloat = 240
    /// Propre à sema : window width, Welcome (taille).
    public static let welcomeWindowWidth: CGFloat = 640
    /// Propre à sema : window height, Welcome (taille).
    public static let welcomeWindowHeight: CGFloat = 700
    /// Propre à sema : signal size, Welcome (taille).
    public static let welcomeSignalSize: CGFloat = 44
    /// Propre à sema : hero signal size, Welcome (taille).
    public static let welcomeHeroSignalSize: CGFloat = 88
    /// Propre à sema : dot size, Welcome (taille).
    public static let dotSize: CGFloat = 6
    /// Propre à sema : active dot width, Welcome (taille).
    public static let welcomeActiveDotWidth: CGFloat = 18
    /// Propre à sema : feature column width, Welcome (taille).
    public static let welcomeFeatureColumnWidth: CGFloat = 420
    /// Propre à sema : feature symbol width, Welcome (taille).
    public static let welcomeFeatureSymbolWidth: CGFloat = 32
    /// Propre à sema : tile min height, Welcome (taille).
    public static let welcomeTileMinHeight: CGFloat = 64
    /// Propre à sema : preview card width, Welcome (taille).
    public static let welcomePreviewCardWidth: CGFloat = 176
    /// Propre à sema : maximum width, Brief (taille).
    public static let briefMaximumWidth: CGFloat = 640
    /// Propre à sema : sidebar width, Settings (taille).
    public static let settingsSidebarWidth: CGFloat = 230
    /// Propre à sema : profile avatar size, Settings (taille).
    public static let settingsProfileAvatarSize: CGFloat = 28
    /// Propre à sema : minimum width, Settings (taille).
    public static let settingsMinimumWidth: CGFloat = 880
    /// Propre à sema : ideal width, Settings (taille).
    public static let settingsIdealWidth: CGFloat = 980
    /// Propre à sema : minimum height, Settings (taille).
    public static let settingsMinimumHeight: CGFloat = 660
    /// Propre à sema : ideal height, Settings (taille).
    public static let settingsIdealHeight: CGFloat = 740
    /// Propre à sema : swatch height, Settings (taille).
    public static let settingsSwatchHeight: CGFloat = 58
    /// Propre à sema : selected stroke, Settings (taille).
    public static let selectedStroke: CGFloat = 2
    /// Propre à sema : palette title height, Settings (taille).
    public static let settingsPaletteTitleHeight: CGFloat = 28
    /// Propre à sema : mark size, Settings (taille).
    public static let settingsMarkSize: CGFloat = 48
    /// Propre à sema : tile height, SettingsChoice (taille).
    public static let settingsChoiceTileHeight: CGFloat = 48
    /// Propre à sema : width, SettingsChoice (taille).
    public static let settingsChoiceWidth: CGFloat = 76
    /// Propre à sema : empty min height, Favorites (taille).
    public static let favoritesEmptyMinHeight: CGFloat = 380
    /// Propre à sema : tile min width, Favorites (taille).
    public static let favoritesTileMinWidth: CGFloat = 250
    /// Propre à sema : results height, Search (taille).
    public static let searchResultsHeight: CGFloat = 280
    /// Propre à sema : chart height, RibbonCard (taille).
    public static let ribbonCardChartHeight: CGFloat = 80
    /// Propre à sema : selection point size, RibbonCard (taille).
    public static let ribbonCardSelectionPointSize: CGFloat = 36
    /// Propre à sema : mark size, SignatureMotion (taille).
    public static let signatureMotionMarkSize: CGFloat = 72
    /// Propre à sema : mark area height, RibbonSignature (taille).
    public static let ribbonSignatureMarkAreaHeight: CGFloat = 48
    /// Propre à sema : feedback height, RibbonSignature (taille).
    public static let ribbonSignatureFeedbackHeight: CGFloat = 26
    /// Propre à sema : day height, AgendaCard (taille).
    public static let agendaCardDayHeight: CGFloat = 34
    /// Propre à sema : line height, AgendaCard (taille).
    public static let agendaCardLineHeight: CGFloat = 42
    /// Propre à sema : vertical width, MenuRibbon (taille).
    public static let menuRibbonVerticalWidth: CGFloat = 368
    /// Propre à sema : header height, MenuRibbon (taille).
    public static let menuRibbonHeaderHeight: CGFloat = 32
    /// Propre à sema : minimum card width, MenuRibbon (taille).
    public static let menuRibbonMinimumCardWidth: CGFloat = 208
    /// Propre à sema : card height, MenuRibbon (taille).
    public static let menuRibbonCardHeight: CGFloat = 216
    /// Propre à sema : sparkline width, MenuRibbon (taille).
    public static let menuRibbonSparklineWidth: CGFloat = 1.8
    /// Propre à sema : sheet width, SeriesSearch (taille).
    public static let seriesSearchSheetWidth: CGFloat = 880
    /// Propre à sema : sheet height, SeriesSearch (taille).
    public static let seriesSearchSheetHeight: CGFloat = 560
    /// Propre à sema : mode picker width, SeriesSearch (taille).
    public static let seriesSearchModePickerWidth: CGFloat = 300
    /// Propre à sema : catalogue height, SeriesSearch (taille).
    public static let seriesSearchCatalogueHeight: CGFloat = 420
    /// Propre à sema : results height, SeriesSearch (taille).
    public static let seriesSearchResultsHeight: CGFloat = 320
    /// Propre à sema : label width, RibbonGlassSettings (taille).
    public static let ribbonGlassSettingsLabelWidth: CGFloat = 136
    /// Propre à sema : value width, RibbonGlassSettings (taille).
    public static let ribbonGlassSettingsValueWidth: CGFloat = 38
    /// Propre à sema : avatar size, ProfileSettings (taille).
    public static let profileSettingsAvatarSize: CGFloat = 56
    /// Propre à sema : recorder width, ShortcutSettings (taille).
    public static let shortcutSettingsRecorderWidth: CGFloat = 142
    /// Propre à sema : recorder height, ShortcutSettings (taille).
    public static let shortcutSettingsRecorderHeight: CGFloat = 30
    /// Propre à sema : maximum width, Agenda (taille).
    public static let agendaMaximumWidth: CGFloat = 520
    /// Propre à sema : bar width, AgendaLine (taille).
    public static let agendaLineBarWidth: CGFloat = 3
    /// Propre à sema : picker width, SourceExplorer (taille).
    public static let sourceExplorerPickerWidth: CGFloat = 190
    /// Propre à sema : compact card min width, SourceExplorer (taille).
    public static let sourceExplorerCompactCardMinWidth: CGFloat = 240
    /// Propre à sema : card min width, SourceExplorer (taille).
    public static let sourceExplorerCardMinWidth: CGFloat = 270
    /// Propre à sema : card min height, SourceExplorer (taille).
    public static let sourceExplorerCardMinHeight: CGFloat = 66
    /// Propre à sema : datasets min width, StatisticalExplorer (taille).
    public static let statisticalExplorerDatasetsMinWidth: CGFloat = 230
    /// Propre à sema : datasets ideal width, StatisticalExplorer (taille).
    public static let statisticalExplorerDatasetsIdealWidth: CGFloat = 280
    /// Propre à sema : datasets max width, StatisticalExplorer (taille).
    public static let statisticalExplorerDatasetsMaxWidth: CGFloat = 310
    /// Propre à sema : compact series min width, StatisticalExplorer (taille).
    public static let statisticalExplorerCompactSeriesMinWidth: CGFloat = 340
    /// Propre à sema : series min width, StatisticalExplorer (taille).
    public static let statisticalExplorerSeriesMinWidth: CGFloat = 350
    /// Propre à sema : advanced label max width, StatisticalExplorer (taille).
    public static let statisticalExplorerAdvancedLabelMaxWidth: CGFloat = 140
    /// Propre à sema : advanced max height, StatisticalExplorer (taille).
    public static let statisticalExplorerAdvancedMaxHeight: CGFloat = 250
    /// Propre à sema : compact results min width, CatalogueBrowser (taille).
    public static let catalogueBrowserCompactResultsMinWidth: CGFloat = 260
    /// Propre à sema : results min width, CatalogueBrowser (taille).
    public static let catalogueBrowserResultsMinWidth: CGFloat = 300
    /// Propre à sema : results max width, CatalogueBrowser (taille).
    public static let catalogueBrowserResultsMaxWidth: CGFloat = 350
    /// Propre à sema : compact preview min width, CatalogueBrowser (taille).
    public static let catalogueBrowserCompactPreviewMinWidth: CGFloat = 330
    /// Propre à sema : preview min width, CatalogueBrowser (taille).
    public static let catalogueBrowserPreviewMinWidth: CGFloat = 360
    /// Propre à sema : loading min height, CatalogueBrowser (taille).
    public static let catalogueBrowserLoadingMinHeight: CGFloat = 280
    /// Propre à sema : list width, MarketExplorer (taille).
    public static let marketExplorerListWidth: CGFloat = 310
    /// Propre à sema : sheet width, AlertEditor (taille).
    public static let alertEditorSheetWidth: CGFloat = 480
    /// Propre à sema : inspector min width, SeriesDetail (taille).
    public static let seriesDetailInspectorMinWidth: CGFloat = 280
    /// Propre à sema : inspector ideal width, SeriesDetail (taille).
    public static let seriesDetailInspectorIdealWidth: CGFloat = 320
    /// Propre à sema : inspector max width, SeriesDetail (taille).
    public static let seriesDetailInspectorMaxWidth: CGFloat = 420
    /// Propre à sema : preview chart height, SeriesDetail (taille).
    public static let seriesDetailPreviewChartHeight: CGFloat = 170
    /// Propre à sema : chart height, SeriesDetail (taille).
    public static let seriesDetailChartHeight: CGFloat = 235
    /// Propre à sema : indicator height, PeriodTabs (taille).
    public static let periodTabsIndicatorHeight: CGFloat = 2
    /// Propre à sema : panel max width, FocusSwitcher (taille).
    public static let focusSwitcherPanelMaxWidth: CGFloat = 700
    /// Propre à sema : tile width, FocusSwitcher (taille).
    public static let focusSwitcherTileWidth: CGFloat = 166
    /// Propre à sema : name height, FocusSwitcher (taille).
    public static let focusSwitcherNameHeight: CGFloat = 32
    /// Propre à sema : default height, HistoryChart (taille).
    public static let historyChartDefaultHeight: CGFloat = 190
    /// Propre à sema : axis tick count, HistoryChart (taille).
    public static let historyChartAxisTickCount: CGFloat = 3
    /// Propre à sema : plot padding, HistoryChart (taille).
    public static let historyChartPlotPadding: CGFloat = 12
    /// Propre à sema : point size, HistoryChart (taille).
    public static let historyChartPointSize: CGFloat = 35
    /// Propre à sema : content spacing, HistoryChart (taille).
    public static let historyChartContentSpacing: CGFloat = 9
    /// Propre à sema : reading spacing, HistoryChart (taille).
    public static let historyChartReadingSpacing: CGFloat = 3
    /// Propre à sema : reading horizontal padding, HistoryChart (taille).
    public static let historyChartReadingHorizontalPadding: CGFloat = 10
    /// Propre à sema : reading vertical padding, HistoryChart (taille).
    public static let historyChartReadingVerticalPadding: CGFloat = 7
    /// Propre à sema : line width, HistoryChart (taille).
    public static let historyChartLineWidth: CGFloat = 2
    /// Propre à sema : spacing, RowDisclosure (taille).
    public static let rowDisclosureSpacing: CGFloat = 6
    /// Propre à sema : chevron width, RowDisclosure (taille).
    public static let rowDisclosureChevronWidth: CGFloat = 12
    /// Propre à sema : content spacing, RowDisclosure (taille).
    public static let rowDisclosureContentSpacing: CGFloat = 8
    /// Propre à sema : la taille d'un avatar de profil quand l'appelant n'en donne pas.
    public static let profileAvatarDefaultSize: CGFloat = 32
    /// Propre à sema : la taille du texte du bouton d'enregistrement d'un raccourci, un contrôle natif d'AppKit.
    public static let shortcutRecorderFontSize: CGFloat = 12
}
