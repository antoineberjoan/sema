// Rassemble les faits datés d’une séance (repères liés, calendrier FRED, communiqués, titres) sans en déduire de cause.
import Foundation
import MarketCore

extension AppStore {
    static func contextKey(_ series: MarketSeries) -> String? {
        series.latest.map { "\(series.id)@\($0.date.timeIntervalSince1970)" }
    }

    /// Loads every part independently: a missing source is named, the others still show.
    func dayContext(for series: MarketSeries) async -> DayContext? {
        guard let latest = series.latest, let key = Self.contextKey(series) else { return nil }
        if let cached = dayContexts[key] { return cached }
        var context = DayContext(day: latest.date)
        context.peers = PeerMove.moves(on: latest.date, among: followedSeries, excluding: series.id)
        let window = DayContext.window(for: latest.date)
        async let releases = economicReleases(on: latest.date)
        async let press = pressReleases(from: window.start, to: window.end)
        async let headlines = headlines(from: window.start, to: window.end)
        if let value = await releases { context.releases = value } else { context.unavailable.append("Calendrier FRED") }
        if let value = await press { context.pressReleases = value } else { context.unavailable.append("Communiqués") }
        if let value = await headlines { context.headlines = value } else { context.unavailable.append("Titres") }
        dayContexts[key] = context
        return context
    }

    func economicReleases(on day: Date) async -> [EconomicRelease]? {
        guard hasFREDKey, isSourceEnabled(StatisticalSource.fred.rawValue) else { return nil }
        return try? await statisticalClient().releaseDates(on: day)
    }

    func pressReleases(from start: Date, to end: Date) async -> [PressRelease]? {
        let feeds = CentralBankFeed.allCases.filter { isSourceEnabled($0.rawValue) }
        var result: [PressRelease] = []
        var failed = false
        for feed in feeds {
            do { result += try await PressReleaseClient().releases(feed).filter { (start...end).contains($0.publishedAt) } }
            catch { failed = true }
        }
        return failed && result.isEmpty ? nil : result.sorted { $0.publishedAt > $1.publishedAt }
    }

    func headlines(from start: Date, to end: Date) async -> [Headline]? {
        switch headlineSource {
        case .none: return []
        case .gdelt: return try? await GdeltClient().headlines(from: start, to: end)
        case .alphaVantage:
            guard connectedMarkets.contains(.alphaVantage), let client = marketClients[.alphaVantage],
                  let key = try? await marketKeychains[.alphaVantage]?.read() else { return nil }
            return try? await client.news(from: start, to: end, key: key)
        }
    }
}
