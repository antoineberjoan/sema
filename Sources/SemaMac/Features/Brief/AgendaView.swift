// Agenda de la semaine : une bande de cinq jours, et pour le jour choisi ses trois lignes les plus importantes, chacune avec son lien.
import SwiftUI
import MarketCore

struct AgendaView: View {
    private static let maximumWidth: CGFloat = 520
    private static let barWidth: CGFloat = 3
    private static let tintOpacity = 0.08
    private static let quietTintOpacity = 0.04
    private static let quietBar = Color.secondary.opacity(0.5)
    private static let titleLines = 2
    private static let releaseURL = "https://fred.stlouisfed.org/release?rid="
    @Environment(AppStore.self) private var store
    @Environment(\.semaAccent) private var accent
    @State private var day = DayAgenda.currentDay(now: .now) ?? .now
    @State private var agenda: DayAgenda?
    @State private var showsAll = false
    private var week: [Date] { DayAgenda.week(containing: .now) }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s16) {
            header
            strip
            lines
        }
        .padding(Spacing.s24)
        .frame(maxWidth: Self.maximumWidth, alignment: .leading)
        .background(Theme.quietFill, in: RoundedRectangle(cornerRadius: Radius.card))
        .task(id: day) {
            showsAll = false
            agenda = await store.agenda(on: day)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text(Self.text(day, "EEEE").capitalized).typeRole(.title)
            Text(subtitle).typeRole(.caption).foregroundStyle(.secondary)
        }
    }

    private var subtitle: String {
        let date = Self.text(day, "d MMMM")
        guard let agenda else { return date }
        let total = agenda.items.count
        if total == 0 { return date + " · rien à signaler" }
        let count = total == 1 ? "1 élément" : "\(total) éléments"
        return date + " · " + (agenda.hiddenCount > 0 && !showsAll ? "\(count), \(DayAgenda.shownLimit) affichés" : count)
    }

    private var strip: some View {
        HStack(spacing: Spacing.s4) {
            ForEach(week, id: \.self) { value in
                let selected = Calendar.utc.isDate(value, inSameDayAs: day)
                Button { day = value } label: {
                    VStack(spacing: Spacing.s2) {
                        Text(Self.text(value, "EEE").capitalized).typeRole(.caption).foregroundStyle(.secondary)
                        Text(Self.text(value, "d")).typeRole(.subheading).monospacedDigit()
                        Circle().fill(store.hasUnusualMove(on: value) ? accent : Color.clear).frame(width: Spacing.s6, height: Spacing.s6)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, Spacing.s8)
                    .background(selected ? Theme.surface : Color.clear, in: RoundedRectangle(cornerRadius: Radius.block))
                    .contentShape(RoundedRectangle(cornerRadius: Radius.block))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Self.text(value, "EEEE d MMMM") + (store.hasUnusualMove(on: value) ? ", mouvement inhabituel" : ""))
                .accessibilityAddTraits(selected ? [.isSelected] : [])
            }
        }
        .padding(Spacing.s4).background(Theme.quietFill, in: RoundedRectangle(cornerRadius: Radius.block + Spacing.s4))
    }

    @ViewBuilder private var lines: some View {
        if let agenda {
            VStack(alignment: .leading, spacing: Spacing.s8) {
                if agenda.items.isEmpty {
                    Text(store.hasFREDKey ? "Aucun mouvement inhabituel, publication ni communiqué ce jour."
                         : "Aucun mouvement inhabituel ni communiqué ce jour. Connectez FRED dans Réglages, Sources, pour voir les publications.")
                        .typeRole(.small).foregroundStyle(.secondary)
                }
                ForEach(showsAll ? agenda.items : agenda.shown) { line($0) }
                if agenda.hiddenCount > 0 {
                    Button(showsAll ? "Réduire" : "Tout voir · \(agenda.hiddenCount) autre\(agenda.hiddenCount > 1 ? "s" : "")") { showsAll.toggle() }
                        .buttonStyle(.borderless).typeRole(.small)
                }
            }
        } else {
            ProgressView().controlSize(.small)
        }
    }

    @ViewBuilder private func line(_ item: AgendaItem) -> some View {
        switch item {
        case .move(let move):
            let name = MarketFormat.name(store.displayedSeries(move.series))
            row(kind: "Mouvement inhabituel", title: name + " · " + MarketFormat.sessionChange(move.change, series: move.series),
                detail: (move.ratio.map { MarketFormat.ratio($0) + " l’habituel" } ?? ""), bar: accent, tint: accent.opacity(Self.tintOpacity),
                action: "Voir") { store.show(move.series); store.section = .overview }
        case .release(let release):
            link(kind: "Publication", title: release.name, detail: "Calendrier FRED", bar: Color.secondary,
                 url: URL(string: Self.releaseURL + release.releaseID))
        case .pressRelease(let release):
            link(kind: "Communiqué · " + release.feed.title, title: release.title, detail: "", bar: Self.quietBar, url: release.link)
        case .headline(let headline):
            link(kind: "Titre", title: headline.title, detail: headline.publisher, bar: Self.quietBar, url: headline.link)
        }
    }

    @ViewBuilder private func link(kind: String, title: String, detail: String, bar: Color, url: URL?) -> some View {
        if let url {
            Link(destination: url) {
                rowBody(kind: kind, title: title, detail: detail, bar: bar, tint: Color.primary.opacity(Self.quietTintOpacity), action: "Ouvrir")
            }
            .buttonStyle(.plain).help(url.absoluteString)
        }
    }

    private func row(kind: String, title: String, detail: String, bar: Color, tint: Color, action: String, perform: @escaping () -> Void) -> some View {
        Button(action: perform) { rowBody(kind: kind, title: title, detail: detail, bar: bar, tint: tint, action: action) }
            .buttonStyle(.plain)
    }

    private func rowBody(kind: String, title: String, detail: String, bar: Color, tint: Color, action: String) -> some View {
        HStack(spacing: Spacing.s12) {
            Rectangle().fill(bar).frame(width: Self.barWidth)
            VStack(alignment: .leading, spacing: Spacing.s2) {
                Text(kind).typeRole(.overline).foregroundStyle(.secondary)
                Text(title).typeRole(.label).multilineTextAlignment(.leading).lineLimit(Self.titleLines)
                if !detail.isEmpty { Text(detail).typeRole(.caption).foregroundStyle(.secondary) }
            }
            Spacer(minLength: Spacing.s8)
            Text(action).typeRole(.small).foregroundStyle(accent)
        }
        .padding(.trailing, Spacing.s12)
        .background(tint, in: RoundedRectangle(cornerRadius: Radius.block))
        .clipShape(RoundedRectangle(cornerRadius: Radius.block))
    }

    /// French text of a day, read on the UTC calendar the agenda days are built on.
    private static func text(_ date: Date, _ format: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = .french
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}

private extension Calendar {
    static var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}
