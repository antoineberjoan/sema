// Préférences persistées de l’app et migration des versions de schéma distribuées.
import Foundation

public struct AppPreferences: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 2
    public var schemaVersion = AppPreferences.currentSchemaVersion
    public var favoriteIDs: Set<String>
    public var followedSeriesIDs: [String]
    public var alerts: [AlertRule]
    public var notificationsEnabled: Bool
    public var themeID: String?
    public var appearanceID: String?
    public var ribbonPositionID: String?
    public var onboardingCompleted: Bool?
    public var disabledSourceIDs: Set<String>?
    public var profile: LocalProfile?
    public var alertBaselineIDs: Set<UUID>?
    public var invertedCurrencyPairs: Set<String>?
    public var ribbonGlass: RibbonGlassPreferences?
    public var shortcuts: ShortcutPreferences?

    public init(favoriteIDs: Set<String> = ["fr10", "ecb", "eurusd", "livreta"],
                alerts: [AlertRule] = [], notificationsEnabled: Bool = false, themeID: String? = "graphite", appearanceID: String? = nil,
                followedSeriesIDs: [String] = WebstatClient.starterIDs, onboardingCompleted: Bool? = nil,
                ribbonPositionID: String? = "top", disabledSourceIDs: Set<String>? = nil,
                profile: LocalProfile? = nil, invertedCurrencyPairs: Set<String>? = nil,
                ribbonGlass: RibbonGlassPreferences? = nil, shortcuts: ShortcutPreferences? = nil) {
        self.favoriteIDs = Set(favoriteIDs.map(WebstatClient.canonicalID))
        self.followedSeriesIDs = followedSeriesIDs.map(WebstatClient.canonicalID)
        self.alerts = alerts
        self.notificationsEnabled = notificationsEnabled
        self.themeID = themeID
        self.appearanceID = appearanceID
        self.ribbonPositionID = ribbonPositionID
        self.onboardingCompleted = onboardingCompleted
        self.disabledSourceIDs = disabledSourceIDs
        self.profile = profile
        self.invertedCurrencyPairs = invertedCurrencyPairs
        self.ribbonGlass = ribbonGlass
        self.shortcuts = shortcuts
    }

    enum CodingKeys: String, CodingKey {
        case schemaVersion, favoriteIDs, followedSeriesIDs, alerts, notificationsEnabled, themeID, appearanceID, onboardingCompleted, ribbonPositionID
        case disabledSourceIDs, profile, alertBaselineIDs, invertedCurrencyPairs, ribbonGlass, shortcuts
    }
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try values.decode(Int.self, forKey: .schemaVersion)
        favoriteIDs = try values.decode(Set<String>.self, forKey: .favoriteIDs)
        alerts = try values.decode([AlertRule].self, forKey: .alerts)
        notificationsEnabled = try values.decode(Bool.self, forKey: .notificationsEnabled)
        themeID = try values.decodeIfPresent(String.self, forKey: .themeID)
        appearanceID = try values.decodeIfPresent(String.self, forKey: .appearanceID)
        ribbonPositionID = try values.decodeIfPresent(String.self, forKey: .ribbonPositionID)
        onboardingCompleted = try values.decodeIfPresent(Bool.self, forKey: .onboardingCompleted)
        disabledSourceIDs = try values.decodeIfPresent(Set<String>.self, forKey: .disabledSourceIDs)
        profile = try values.decodeIfPresent(LocalProfile.self, forKey: .profile)
        alertBaselineIDs = try values.decodeIfPresent(Set<UUID>.self, forKey: .alertBaselineIDs)
        invertedCurrencyPairs = try values.decodeIfPresent(Set<String>.self, forKey: .invertedCurrencyPairs)
        ribbonGlass = try values.decodeIfPresent(RibbonGlassPreferences.self, forKey: .ribbonGlass)
        shortcuts = try values.decodeIfPresent(ShortcutPreferences.self, forKey: .shortcuts)
        // Empty is a valid v2 selection; absence only means legacy v1.
        if schemaVersion > 1 { followedSeriesIDs = try values.decode([String].self, forKey: .followedSeriesIDs) }
        else { followedSeriesIDs = WebstatClient.starterIDs }
    }

    public func isSourceEnabled(_ id: String) -> Bool { !(disabledSourceIDs ?? []).contains(id) }

    public func migrated() throws -> AppPreferences {
        guard (1...Self.currentSchemaVersion).contains(schemaVersion) else { throw PreferencesStore.StoreError.unsupportedVersion(schemaVersion) }
        var value = self
        value.schemaVersion = Self.currentSchemaVersion
        value.favoriteIDs = Set(favoriteIDs.map(WebstatClient.canonicalID))
        var seen: Set<String> = []
        value.followedSeriesIDs = followedSeriesIDs.map(WebstatClient.canonicalID).filter { seen.insert($0).inserted }
        value.alerts = alerts.map { rule in
            AlertRule(id: rule.id, seriesID: WebstatClient.canonicalID(rule.seriesID), direction: rule.direction,
                threshold: rule.threshold, isEnabled: rule.isEnabled, condition: rule.effectiveCondition,
                lastEvaluatedAt: rule.lastEvaluatedAt)
        }
        if schemaVersion == 1 { value.onboardingCompleted = true }
        return value
    }
}
