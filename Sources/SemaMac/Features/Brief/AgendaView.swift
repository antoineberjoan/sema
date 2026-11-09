// Agenda de la semaine : une bande de cinq jours, et pour le jour choisi ses trois lignes les plus importantes, chacune avec son lien.
import SwiftUI
import MarketCore

struct AgendaView: View {
    private static let maximumWidth: CGFloat = 520
    private static let titleLines = 2
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
        // A day chosen in the ribbon opens here; the request is consumed once read.
        .onChange(of: store.agendaDay, initial: true) { _, requested in
            guard let requested else { return }
            day = requested
            store.agendaDay = nil
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text(AgendaDay.text(day, "EEEE").capitalized).typeRole(.title)
            Text(subtitle).typeRole(.caption).foregroundStyle(.secondary)
        }
    }

    private var subtitle: String {
        let date = AgendaDay.text(day, "d MMMM")
        guard let agenda else { return date }
        let total = agenda.items.count
        if total == 0 { return date + " · rien à signaler" }
        let count = total == 1 ? "1 élément" : "\(total) éléments"
        return date + " · " + (agenda.hiddenCount > 0 && !showsAll ? "\(count), \(DayAgenda.shownLimit) affichés" : count)
    }

    private var strip: some View {
        HStack(spacing: Spacing.s4) {
            ForEach(week, id: \.self) { value in
                let selected = AgendaDay.isSame(value, day)
                Button { day = value } label: {
                    VStack(spacing: Spacing.s2) {
                        Text(AgendaDay.text(value, "EEE").capitalized).typeRole(.caption).foregroundStyle(.secondary)
                        Text(AgendaDay.text(value, "d")).typeRole(.subheading).monospacedDigit()
                        Circle().fill(store.hasUnusualMove(on: value) ? accent : Color.clear).frame(width: Spacing.s6, height: Spacing.s6)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, Spacing.s8)
                    .background(selected ? Theme.surface : Color.clear, in: RoundedRectangle(cornerRadius: Radius.block))
                    .contentShape(RoundedRectangle(cornerRadius: Radius.block))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AgendaDay.text(value, "EEEE d MMMM") + (store.hasUnusualMove(on: value) ? ", mouvement inhabituel" : ""))
                .accessibilityAddTraits(selected ? [.isSelected] : [])
            }
        }
        .padding(Spacing.s4).background(Theme.quietFill, in: RoundedRectangle(cornerRadius: Radius.block + Spacing.s4))
    }

    @ViewBuilder private var lines: some View {
        if let agenda {
            VStack(alignment: .leading, spacing: Spacing.s8) {
                if agenda.items.isEmpty {
                    Text(AgendaLine.emptyText(hasFREDKey: store.hasFREDKey))
                        .typeRole(.small).foregroundStyle(.secondary)
                }
                ForEach((showsAll ? agenda.items : agenda.shown).map { AgendaLine($0, store: store) }) { line($0) }
                if agenda.hiddenCount > 0 {
                    Button(showsAll ? "Réduire" : "Tout voir · \(agenda.hiddenCount) autre\(agenda.hiddenCount > 1 ? "s" : "")") { showsAll.toggle() }
                        .buttonStyle(.borderless).typeRole(.small)
                }
            }
        } else {
            ProgressView().controlSize(.small)
        }
    }

    @ViewBuilder private func line(_ line: AgendaLine) -> some View {
        switch line.destination {
        case .series(let series):
            Button { store.show(series); store.section = .overview } label: { rowBody(line, action: "Voir") }.buttonStyle(.plain)
        case .link(let url):
            Link(destination: url) { rowBody(line, action: "Ouvrir") }.buttonStyle(.plain).help(url.absoluteString)
        case nil:
            EmptyView()
        }
    }

    private func rowBody(_ line: AgendaLine, action: String) -> some View {
        HStack(spacing: Spacing.s12) {
            Rectangle().fill(line.bar(accent: accent)).frame(width: AgendaLine.barWidth)
            VStack(alignment: .leading, spacing: Spacing.s2) {
                Text(line.kind).typeRole(.overline).foregroundStyle(.secondary)
                Text(line.title).typeRole(.label).multilineTextAlignment(.leading).lineLimit(Self.titleLines)
                if !line.detail.isEmpty { Text(line.detail).typeRole(.caption).foregroundStyle(.secondary) }
            }
            Spacer(minLength: Spacing.s8)
            Text(action).typeRole(.small).foregroundStyle(accent)
        }
        .padding(.trailing, Spacing.s12)
        .background(line.tint(accent: accent), in: RoundedRectangle(cornerRadius: Radius.block))
        .clipShape(RoundedRectangle(cornerRadius: Radius.block))
    }
}
