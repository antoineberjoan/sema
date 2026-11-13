// Préférences persistées de l’app, au format de schéma 2.
import Foundation

public struct AppPreferences: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 2
    public var schemaVersion = AppPreferences.currentSchemaVersion
    public var favoriteIDs: Set<String>
    public var followedSeriesIDs: [String]
    public var alerts: [AlertRule]
    public var canNotify: Bool
    public var themeID: String?
    public var appearanceID: String?
    public var ribbonPositionID: String?
    public var isOnboardingCompleted: Bool?
    public var disabledSourceIDs: Set<String>?
    public var profile: LocalProfile?
    public var alertBaselineIDs: Set<UUID>?
    public var invertedCurrencyPairs: Set<String>?
    public var ribbonGlass: RibbonGlassPreferences?
    public var shortcuts: ShortcutPreferences?
    /// Période d’historique partagée par le hub et le bandeau ; absente signifie un an.
    public var periodID: String?
    /// Sensibilité globale des alertes de mouvement inhabituel ; absente signifie normale (2×).
    public var moveSensitivityID: String?
    /// Source des titres du jour ; absente signifie GDELT.
    public var headlineSourceID: String?
    /// Rédacteur de la synthèse d’une séance ; absent signifie désactivé.
    public var summaryWriterID: String?
    /// Réglages du brief du matin ; absents signifie désactivé à 8:00 les jours ouvrés.
    public var brief: BriefPreferences?

    public init(favoriteIDs: Set<String> = ["FM.M.FR.EUR.FR2.BB.FR10YT_RR.YLD", "FM.D.U2.EUR.4F.KR.DFR.LEV", "EXR.D.USD.EUR.SP00.A", "MIR1.M.FR.B.L23FRLA.D.R.A.2230U6.EUR.O"],
                alerts: [AlertRule] = [], canNotify: Bool = false, themeID: String? = "brand", appearanceID: String? = nil,
                followedSeriesIDs: [String] = [], isOnboardingCompleted: Bool? = nil,
                ribbonPositionID: String? = "top", disabledSourceIDs: Set<String>? = StatisticalSource.inactiveByDefault,
                profile: LocalProfile? = nil, invertedCurrencyPairs: Set<String>? = nil,
                ribbonGlass: RibbonGlassPreferences? = nil, shortcuts: ShortcutPreferences? = nil) {
        self.favoriteIDs = favoriteIDs
        self.followedSeriesIDs = followedSeriesIDs
        self.alerts = alerts
        self.canNotify = canNotify
        self.themeID = themeID
        self.appearanceID = appearanceID
        self.ribbonPositionID = ribbonPositionID
        self.isOnboardingCompleted = isOnboardingCompleted
        self.disabledSourceIDs = disabledSourceIDs
        self.profile = profile
        self.invertedCurrencyPairs = invertedCurrencyPairs
        self.ribbonGlass = ribbonGlass
        self.shortcuts = shortcuts
    }

    enum CodingKeys: String, CodingKey {
        case schemaVersion, favoriteIDs, followedSeriesIDs, alerts, themeID, appearanceID, ribbonPositionID
        case canNotify = "notificationsEnabled"
        case isOnboardingCompleted = "onboardingCompleted"
        case disabledSourceIDs, profile, alertBaselineIDs, invertedCurrencyPairs, ribbonGlass, shortcuts, periodID, moveSensitivityID, headlineSourceID, summaryWriterID, brief
    }
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try values.decode(Int.self, forKey: .schemaVersion)
        favoriteIDs = try values.decode(Set<String>.self, forKey: .favoriteIDs)
        alerts = try values.decode([AlertRule].self, forKey: .alerts)
        canNotify = try values.decode(Bool.self, forKey: .canNotify)
        themeID = try values.decodeIfPresent(String.self, forKey: .themeID)
        appearanceID = try values.decodeIfPresent(String.self, forKey: .appearanceID)
        ribbonPositionID = try values.decodeIfPresent(String.self, forKey: .ribbonPositionID)
        isOnboardingCompleted = try values.decodeIfPresent(Bool.self, forKey: .isOnboardingCompleted)
        disabledSourceIDs = try values.decodeIfPresent(Set<String>.self, forKey: .disabledSourceIDs)
        profile = try values.decodeIfPresent(LocalProfile.self, forKey: .profile)
        alertBaselineIDs = try values.decodeIfPresent(Set<UUID>.self, forKey: .alertBaselineIDs)
        invertedCurrencyPairs = try values.decodeIfPresent(Set<String>.self, forKey: .invertedCurrencyPairs)
        ribbonGlass = try values.decodeIfPresent(RibbonGlassPreferences.self, forKey: .ribbonGlass)
        shortcuts = try values.decodeIfPresent(ShortcutPreferences.self, forKey: .shortcuts)
        periodID = try values.decodeIfPresent(String.self, forKey: .periodID)
        moveSensitivityID = try values.decodeIfPresent(String.self, forKey: .moveSensitivityID)
        headlineSourceID = try values.decodeIfPresent(String.self, forKey: .headlineSourceID)
        summaryWriterID = try values.decodeIfPresent(String.self, forKey: .summaryWriterID)
        brief = try values.decodeIfPresent(BriefPreferences.self, forKey: .brief)
        // Schéma 2 : la liste peut être vide. Schéma 1 : elle est absente et la sélection de départ s’applique (`PreferencesMigration`).
        if schemaVersion > 1 { followedSeriesIDs = try values.decode([String].self, forKey: .followedSeriesIDs) }
        else { followedSeriesIDs = WebstatStarter.ids }
    }

    public func isSourceEnabled(_ id: String) -> Bool { !(disabledSourceIDs ?? []).contains(id) }
}
