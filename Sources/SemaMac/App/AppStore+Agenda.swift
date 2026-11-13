// Charge l’agenda d’un jour de la semaine : mouvements locaux, publications FRED, communiqués et titres, chaque partie indépendamment.
import Foundation
import MarketCore

extension AppStore {
    /// Une partie qui ne se charge pas est omise ; le jour montre quand même les autres.
    func agenda(on day: Date) async -> DayAgenda {
        if let cached = agendas[day] { return cached }
        let window = DayContext.window(for: day)
        async let releases = economicReleases(on: day)
        async let press = pressReleases(from: window.start, to: window.end)
        // Les titres existent seulement pour les jours déjà commencés ; GDELT n’est pas interrogé sur l’avenir.
        async let headlines = day <= .now ? headlines(from: window.start, to: window.end) : []
        let value = DayAgenda(day: day, series: followedSeries, sensitivity: moveSensitivity,
                              releases: await releases ?? [], pressReleases: await press ?? [], headlines: await headlines ?? [])
        agendas[day] = value
        return value
    }

    /// Ouvre l’agenda du hub sur un jour choisi dans le bandeau.
    func openAgenda(on day: Date) {
        agendaDay = day
        section = .brief
    }

    func hasUnusualMove(on day: Date) -> Bool {
        DayAgenda.hasUnusualMove(on: day, series: followedSeries, sensitivity: moveSensitivity)
    }
}
