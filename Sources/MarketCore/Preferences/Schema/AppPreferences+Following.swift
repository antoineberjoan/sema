// Règles de la sélection suivie : ce que deviennent favoris et alertes quand on suit, retire ou remplace un repère.
import Foundation

extension AppPreferences {
    /// Rejoue le choix de départ : garde l'ordre choisi, les repères personnels hors départ, met en pause les alertes des départs retirés
    /// et ne garde en favoris que les départs choisis.
    public mutating func followStarters(_ ids: [String], allowed: Set<String>) {
        var seen: Set<String> = []
        let chosen = ids.filter { allowed.contains($0) && seen.insert($0).inserted }
        followedSeriesIDs = chosen + followedSeriesIDs.filter { !allowed.contains($0) }
        for index in alerts.indices where allowed.contains(alerts[index].seriesID) && !chosen.contains(alerts[index].seriesID) {
            alerts[index].isEnabled = false
        }
        favoriteIDs = favoriteIDs.filter { chosen.contains($0) || !allowed.contains($0) }
    }

    /// Retire des repères : ils quittent la sélection et les favoris, leurs alertes sont mises en pause avec leur règle.
    public mutating func unfollow(_ ids: Set<String>) {
        followedSeriesIDs.removeAll { ids.contains($0) }
        favoriteIDs.subtract(ids)
        for index in alerts.indices where ids.contains(alerts[index].seriesID) { alerts[index].isEnabled = false }
    }

    /// Remplace des repères équivalents par `id` : une seule place dans la sélection, favori et règles conservés,
    /// chaque règle reprenant à la plus récente de ses observations déjà évaluées et de `latest`.
    public mutating func replacing(_ ids: Set<String>, with id: String, latest: Date?) {
        var hasInserted = false
        followedSeriesIDs = followedSeriesIDs.compactMap { followed in
            guard ids.contains(followed) else { return followed }
            if hasInserted { return nil }
            hasInserted = true
            return id
        }
        if !favoriteIDs.isDisjoint(with: ids) { favoriteIDs.subtract(ids); favoriteIDs.insert(id) }
        alerts = alerts.map { rule in
            guard ids.contains(rule.seriesID) else { return rule }
            return AlertRule(id: rule.id, seriesID: id, direction: rule.direction, threshold: rule.threshold,
                             isEnabled: rule.isEnabled, condition: rule.effectiveCondition,
                             lastEvaluatedAt: max(rule.lastEvaluatedAt ?? .distantPast, latest ?? .distantPast))
        }
    }
}
