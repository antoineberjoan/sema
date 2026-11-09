// Charge l’agenda d’un jour de la semaine : mouvements locaux, publications FRED, communiqués et titres, chaque partie indépendamment.
import Foundation
import MarketCore

extension AppStore {
    /// A part that cannot load is left out; the day still shows the others.
    func agenda(on day: Date) async -> DayAgenda {
        if let cached = agendas[day] { return cached }
        let window = DayContext.window(for: day)
        async let releases = economicReleases(on: day)
        async let press = pressReleases(from: window.start, to: window.end)
        // Headlines exist only for days that have started; GDELT is not asked about the future.
        async let headlines = day <= .now ? headlines(from: window.start, to: window.end) : []
        let value = DayAgenda(day: day, series: followedSeries, sensitivity: moveSensitivity,
                              releases: await releases ?? [], pressReleases: await press ?? [], headlines: await headlines ?? [])
        agendas[day] = value
        return value
    }

    func hasUnusualMove(on day: Date) -> Bool {
        DayAgenda.hasUnusualMove(on: day, series: followedSeries, sensitivity: moveSensitivity)
    }
}
