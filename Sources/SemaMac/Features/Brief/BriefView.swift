// Rubrique Brief : l’essentiel de la dernière séance, les seuils proches et l’agenda du jour, tel que la notification du matin le résume.
import SwiftUI
import MarketCore

struct BriefView: View {
    private static let nameWidth: CGFloat = 220
    @Environment(AppStore.self) private var store
    @Environment(\.openSettings) private var openSettings
    @State private var brief: MorningBrief?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s24) {
            if store.brief.isEnabled { schedule } else { offer }
            if let brief { content(brief) } else { ProgressView().controlSize(.small) }
        }
        .task(id: store.followedSeries.compactMap(\.latest?.date).max()) { brief = await store.morningBrief() }
    }

    private var schedule: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Notification \(store.brief.weekdaysOnly ? "chaque jour ouvré" : "chaque jour") à \(Self.time(store.brief)).")
                .typeRole(.small).foregroundStyle(.secondary)
            Spacer(minLength: Spacing.s8)
            Button("Réglages du brief") { store.settingsTab = .general; openSettings() }.buttonStyle(.borderless).typeRole(.small)
        }
    }

    private var offer: some View {
        HStack(spacing: Spacing.s16) {
            VStack(alignment: .leading, spacing: Spacing.s2) {
                Text("Recevoir ce brief chaque matin ?").typeRole(.heading)
                Text("Une notification à \(Self.time(store.brief)) les jours ouvrés, ou au réveil du Mac.").typeRole(.small).foregroundStyle(.secondary)
            }
            Spacer(minLength: Spacing.s8)
            Button("Activer") { Task { await store.setBriefEnabled(true) } }.buttonStyle(.borderedProminent)
        }
        .padding(Spacing.s16)
        .background(Theme.quietFill, in: RoundedRectangle(cornerRadius: Radius.block))
    }

    @ViewBuilder private func content(_ brief: MorningBrief) -> some View {
        section("Dernière séance") {
            if brief.moves.isEmpty { empty("Aucun mouvement inhabituel à la sensibilité \(store.moveSensitivity.title.lowercased()).") }
            ForEach(brief.moves) { move in
                HStack(spacing: Spacing.s16) {
                    Text(MarketFormat.name(store.displayedSeries(move.series))).typeRole(.small).lineLimit(1)
                        .frame(width: Self.nameWidth, alignment: .leading)
                    Text(MarketFormat.sessionChange(move.change, series: move.series)).typeRole(.caption).monospacedDigit().foregroundStyle(.secondary)
                    if let ratio = move.ratio { MoveBadge(ratio: ratio) }
                    Spacer(minLength: Spacing.s8)
                    Button("Voir") { store.show(move.series); store.section = .overview }.buttonStyle(.borderless).typeRole(.small)
                }
                .padding(.vertical, Spacing.s10)
            }
        }
        if !brief.nearThresholds.isEmpty {
            section("Seuils proches") {
                ForEach(brief.nearThresholds) { near in
                    HStack(spacing: Spacing.s16) {
                        Text(MarketFormat.name(store.displayedSeries(near.series))).typeRole(.small).lineLimit(1)
                            .frame(width: Self.nameWidth, alignment: .leading)
                        Text(AppStore.nearText(near)).typeRole(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, Spacing.s10)
                }
            }
        }
        section("Agenda du jour") {
            if brief.agenda.isEmpty { empty(store.hasFREDKey ? "Aucune publication inscrite aujourd’hui." : "Connectez FRED dans Réglages, Sources, pour voir l’agenda.") }
            ForEach(brief.agenda) { Text($0.name).typeRole(.small).padding(.vertical, Spacing.s6) }
        }
        if !brief.headlines.isEmpty {
            section("Titres de la séance") {
                ForEach(brief.headlines) { headline in
                    Link(destination: headline.link) {
                        VStack(alignment: .leading, spacing: Spacing.s2) {
                            Text(headline.title).typeRole(.small).multilineTextAlignment(.leading).foregroundStyle(.primary)
                            Text(headline.publisher).typeRole(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain).padding(.vertical, Spacing.s6).help(headline.link.absoluteString)
                }
            }
        }
        if !brief.pressReleases.isEmpty {
            section("Banques centrales") {
                ForEach(brief.pressReleases.prefix(4)) { release in
                    Link(destination: release.link) {
                        VStack(alignment: .leading, spacing: Spacing.s2) {
                            Text(release.title).typeRole(.small).multilineTextAlignment(.leading).foregroundStyle(.primary)
                            Text(release.feed.title).typeRole(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain).padding(.vertical, Spacing.s6).help(release.link.absoluteString)
                }
            }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title).typeRole(.heading).padding(.bottom, Spacing.s8)
            Divider()
            content()
        }
    }

    private func empty(_ text: String) -> some View { Text(text).typeRole(.small).foregroundStyle(.secondary).padding(.vertical, Spacing.s10) }

    static func time(_ brief: BriefPreferences) -> String { "\(brief.hour) h " + String(format: "%02d", brief.minute) }
}
