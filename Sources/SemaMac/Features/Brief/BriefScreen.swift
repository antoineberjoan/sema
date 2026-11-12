// Rubrique Aujourd’hui : une phrase sur la séance, les repères sortis de l’habituel avec leurs chiffres, les faits du jour et ce qui est publié à l’avance.
import SemaDesign
import SwiftUI
import MarketCore

struct BriefScreen: View {
    private static let maximumWidth: CGFloat = 640
    private static let upcomingLimit = 3
    @Environment(AppStore.self) private var store
    @Environment(\.openSettings) private var openSettings
    @State private var brief: MorningBrief?
    @State private var sameDay: DayAgenda?
    @State private var upcoming: DayAgenda?
    @State private var isAgendaOpen = false
    private var sessionDay: Date { store.followedSeries.compactMap(\.latest?.date).max() ?? .now }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSpace.sectionGap) {
            if store.brief.isEnabled { schedule } else { offer }
            if let brief {
                header(brief)
                moves(brief)
                if !brief.nearThresholds.isEmpty { thresholds(brief) }
                facts
                coming
            } else { ProgressView().controlSize(.small) }
            DisclosureGroup("Agenda de la semaine", isExpanded: $isAgendaOpen) { AgendaView().padding(.top, DesignSpace.rowInset) }
                .typeRole(.small).foregroundStyle(DesignColor.textMuted)
        }
        .frame(maxWidth: Self.maximumWidth, alignment: .leading)
        // A day chosen in the ribbon unfolds the agenda; it reads and clears the request.
        .onChange(of: store.agendaDay, initial: true) { _, requested in
            if requested != nil { isAgendaOpen = true }
        }
        .task(id: sessionDay) {
            let value = await store.morningBrief()
            brief = value
            sameDay = await store.agenda(on: sessionDay)
            upcoming = await store.agenda(on: DayAgenda.nextDay(after: sessionDay))
        }
    }

    private var schedule: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Notification \(store.brief.weekdaysOnly ? "chaque jour ouvré" : "chaque jour") à \(Self.time(store.brief)).")
                .typeRole(.small).foregroundStyle(DesignColor.textMuted)
            Spacer(minLength: DesignSpace.fieldGap)
            Button("Réglages du brief") { store.settingsTab = .general; openSettings() }.buttonStyle(.borderless).typeRole(.small)
        }
    }

    private var offer: some View {
        HStack(spacing: DesignSpace.fieldGap) {
            VStack(alignment: .leading, spacing: DesignSpace.titleGap) {
                Text("Recevoir ce résumé chaque matin ?").typeRole(.heading)
                Text("Une notification à \(Self.time(store.brief)) les jours ouvrés, ou au réveil du Mac.").typeRole(.small).foregroundStyle(DesignColor.textMuted)
            }
            Spacer(minLength: DesignSpace.fieldGap)
            Button("Activer") { Task { await store.setBriefEnabled(true) } }.buttonStyle(.borderedProminent)
        }
        .padding(DesignSpace.cardInset)
        .background(DesignColor.surface, in: RoundedRectangle(cornerRadius: DesignRadius.block))
    }

    private func header(_ brief: MorningBrief) -> some View {
        VStack(alignment: .leading, spacing: DesignSpace.fieldGap) {
            Text(Self.text(sessionDay, "EEEE d MMMM").capitalized).typeRole(.title)
            Text(SessionSentence.text(moves: brief.moves) { MarketFormat.name(store.displayedSeries($0)) }).typeRole(.lede)
            Text("Phrase construite à partir de vos repères, sans modèle de langage. Aucune cause n’est affirmée.")
                .typeRole(.caption).foregroundStyle(DesignColor.textMuted)
        }
    }

    @ViewBuilder private func moves(_ brief: MorningBrief) -> some View {
        if !brief.moves.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(brief.moves) { move in
                    Button { store.show(move.series); store.section = .overview } label: {
                        VStack(alignment: .leading, spacing: DesignSpace.titleGap) {
                            HStack(spacing: DesignSpace.fieldGap) {
                                Text(MarketFormat.name(store.displayedSeries(move.series))).typeRole(.body)
                                Spacer(minLength: DesignSpace.fieldGap)
                                Text(MarketFormat.sessionChange(move.change, series: move.series)).foregroundStyle(DesignColor.textMuted)
                                if let ratio = move.ratio { Text(MarketFormat.ratio(ratio)).foregroundStyle(DesignColor.textMuted) }
                            }
                            .monospacedDigit()
                            if let rank = SessionRank(series: move.series) { Text(rank.text).typeRole(.caption).foregroundStyle(DesignColor.textMuted) }
                        }
                        .padding(.vertical, DesignSpace.rowInset)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Divider()
                }
            }
        }
    }

    private func thresholds(_ brief: MorningBrief) -> some View {
        section("seuils proches") {
            ForEach(brief.nearThresholds) { near in
                Text("\(MarketFormat.name(store.displayedSeries(near.series))) · \(AppStore.nearText(near))").typeRole(.body)
            }
        }
    }

    @ViewBuilder private var facts: some View {
        let lines = (sameDay?.items ?? []).filter(Self.isSameDayFact)
        let feedsOn = CentralBankFeed.allCases.contains { store.isSourceEnabled($0.rawValue) }
        let hasPress = lines.contains { if case .pressRelease = $0 { return true } else { return false } }
        if !lines.isEmpty || (feedsOn && sameDay != nil) {
            section("le même jour") {
                ForEach(lines) { item in
                    switch item {
                    case .pressRelease(let release): link(release.title, detail: release.feed.title, url: release.link)
                    case .headline(let headline): link(headline.title, detail: headline.publisher, url: headline.link)
                    default: EmptyView()
                    }
                }
                if feedsOn, !hasPress { Text("Aucun communiqué de la Fed ni de la BCE.").typeRole(.body).foregroundStyle(DesignColor.textMuted) }
            }
        }
    }

    @ViewBuilder private var coming: some View {
        if let upcoming {
            let releases = Self.releases(in: upcoming)
            section("à venir · calendrier publié à l’avance") {
                if releases.isEmpty {
                    Text(store.hasFREDKey ? "Rien n’est inscrit au calendrier pour \(Self.text(upcoming.day, "EEEE").lowercased())."
                         : "Connectez FRED dans Réglages, Sources, pour voir le calendrier.")
                        .typeRole(.body).foregroundStyle(DesignColor.textMuted)
                }
                ForEach(releases.prefix(Self.upcomingLimit)) { release in
                    Text(Self.text(upcoming.day, "EEEE").capitalized + " · " + release.name).typeRole(.body)
                }
            }
        }
    }

    /// Press releases and headlines of the session day; moves and releases are shown elsewhere on the page.
    private static func isSameDayFact(_ item: AgendaItem) -> Bool {
        switch item {
        case .pressRelease, .headline: true
        case .move, .release: false
        }
    }

    private static func releases(in agenda: DayAgenda) -> [EconomicRelease] {
        agenda.items.compactMap { item in
            guard case .release(let release) = item else { return nil }
            return release
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: DesignSpace.titleGap) {
            Text(title).typeRole(.small).foregroundStyle(DesignColor.textMuted)
            content()
        }
    }

    private func link(_ title: String, detail: String, url: URL) -> some View {
        Link(destination: url) {
            VStack(alignment: .leading, spacing: DesignSpace.titleGap) {
                Text(title).typeRole(.body).multilineTextAlignment(.leading).foregroundStyle(DesignColor.text)
                Text(detail).typeRole(.caption).foregroundStyle(DesignColor.textMuted)
            }
        }
        .buttonStyle(.plain).help(url.absoluteString)
    }

    static func time(_ brief: BriefPreferences) -> String { "\(brief.hour) h " + String(format: "%02d", brief.minute) }

    /// French text of a day, read on the UTC calendar the sessions are dated on.
    private static func text(_ date: Date, _ format: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = .french
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}
