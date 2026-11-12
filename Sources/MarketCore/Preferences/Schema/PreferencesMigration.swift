// Fait passer des préférences lues d'une version antérieure du fichier à la version courante.
import Foundation

/// Relit les fichiers de préférences écrits par les versions publiées : schéma 1, et raccourci d'espace de travail d'origine.
/// Retrait : voir `docs/decisions/2026-11-12-relecture-des-versions-de-fichiers.md`.
public enum PreferencesMigration {
    /// Raccourci d'espace de travail d'origine (⌃⌥H) : seul celui-là est remplacé par la valeur standard.
    private static let originalWorkspace = AppShortcut(keyCode: ShortcutPreferences.keyH, modifiers: [.control, .option], key: "H")

    public static func upgrade(_ preferences: AppPreferences) throws -> AppPreferences {
        guard (1...AppPreferences.currentSchemaVersion).contains(preferences.schemaVersion) else {
            throw PreferencesError.unsupportedVersion(preferences.schemaVersion)
        }
        var value = preferences
        value.schemaVersion = AppPreferences.currentSchemaVersion
        value.favoriteIDs = Set(preferences.favoriteIDs.map(WebstatStarter.canonicalID))
        var seen: Set<String> = []
        value.followedSeriesIDs = preferences.followedSeriesIDs.map(WebstatStarter.canonicalID).filter { seen.insert($0).inserted }
        value.alerts = preferences.alerts.map { rule in
            AlertRule(id: rule.id, seriesID: WebstatStarter.canonicalID(rule.seriesID), direction: rule.direction,
                threshold: rule.threshold, isEnabled: rule.isEnabled, condition: rule.effectiveCondition,
                lastEvaluatedAt: rule.lastEvaluatedAt)
        }
        value.shortcuts = preferences.shortcuts.map(upgrade)
        if preferences.schemaVersion == 1 { value.isOnboardingCompleted = true }
        return value
    }

    /// Les choix personnels et les actions désactivées restent intacts.
    public static func upgrade(_ shortcuts: ShortcutPreferences) -> ShortcutPreferences {
        guard shortcuts.workspace?.matches(originalWorkspace) == true else { return shortcuts }
        var result = shortcuts
        result.workspace = ShortcutPreferences.standard.workspace
        return result
    }
}
