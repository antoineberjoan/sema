// Agenda de la semaine : une bande de cinq jours, et pour le jour choisi ses trois lignes les plus importantes, chacune avec son lien.
import SemaDesign
import SwiftUI
import MarketCore

struct AgendaView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.palette) private var palette
    private var accent: Color { DesignColor.accent(palette) }
    private var accentText: Color { DesignColor.accentText(palette) }
    @State private var day = DayAgenda.currentDay(now: .now) ?? .now
    @State private var agenda: DayAgenda?
    @State private var isAllShown = false
    private var week: [Date] { DayAgenda.week(containing: .now) }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSpace.itemGap) {
            header
            strip
            lines
        }
        .padding(DesignSpace.cardInset)
        .frame(maxWidth: DesignLayout.agendaMaximumWidth, alignment: .leading)
        .background(DesignColor.surface, in: RoundedRectangle(cornerRadius: DesignRadius.card))
        .task(id: day) {
            isAllShown = false
            agenda = await store.agenda(on: day)
        }
        // Un jour choisi dans le bandeau s’ouvre ici ; la demande est consommée une fois lue.
        .onChange(of: store.agendaDay, initial: true) { _, requested in
            guard let requested else { return }
            day = requested
            store.agendaDay = nil
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignSpace.titleGap) {
            Text(AgendaDay.text(day, "EEEE").capitalized).typeRole(.title)
            Text(subtitle).typeRole(.caption).foregroundStyle(DesignColor.textMuted)
        }
    }

    private var subtitle: String {
        let date = AgendaDay.text(day, "d MMMM")
        guard let agenda else { return date }
        let total = agenda.items.count
        if total == 0 { return date + " · rien à signaler" }
        let count = total == 1 ? "1 élément" : "\(total) éléments"
        return date + " · " + (agenda.hiddenCount > 0 && !isAllShown ? "\(count), \(DayAgenda.shownLimit) affichés" : count)
    }

    private var strip: some View {
        HStack(spacing: DesignSpace.markInset) {
            ForEach(week, id: \.self) { value in
                let isSelected = AgendaDay.isSame(value, day)
                Button { day = value } label: {
                    VStack(spacing: DesignSpace.listGapDense) {
                        Text(AgendaDay.text(value, "EEE").capitalized).typeRole(.caption).foregroundStyle(DesignColor.textMuted)
                        Text(AgendaDay.text(value, "d")).typeRole(.subheading).monospacedDigit()
                        Circle().fill(store.hasUnusualMove(on: value) ? accent : Color.clear).frame(width: DesignLayout.dotSize, height: DesignLayout.dotSize)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, DesignSpace.rowInset)
                    .background(isSelected ? DesignColor.selection(palette) : Color.clear, in: RoundedRectangle(cornerRadius: DesignRadius.block))
                    .contentShape(RoundedRectangle(cornerRadius: DesignRadius.block))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AgendaDay.text(value, "EEEE d MMMM") + (store.hasUnusualMove(on: value) ? ", mouvement inhabituel" : ""))
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
        .padding(DesignSpace.markInset).background(DesignColor.surfaceRaised, in: RoundedRectangle(cornerRadius: DesignRadius.block + DesignSpace.markInset))
    }

    @ViewBuilder private var lines: some View {
        if let agenda {
            VStack(alignment: .leading, spacing: DesignSpace.itemGap) {
                if agenda.items.isEmpty {
                    Text(AgendaLine.emptyText(hasFREDKey: store.hasFREDKey))
                        .typeRole(.small).foregroundStyle(DesignColor.textMuted)
                }
                ForEach((isAllShown ? agenda.items : agenda.shown).map { AgendaLine($0, store: store) }) { line($0) }
                if agenda.hiddenCount > 0 {
                    Button(isAllShown ? "Réduire" : "Tout voir · \(agenda.hiddenCount) autre\(agenda.hiddenCount > 1 ? "s" : "")") { isAllShown.toggle() }
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
        HStack(spacing: DesignSpace.fieldGap) {
            Rectangle().fill(line.bar(palette: palette)).frame(width: DesignLayout.agendaLineBarWidth)
            VStack(alignment: .leading, spacing: DesignSpace.titleGap) {
                Text(line.kind).typeRole(.overline).foregroundStyle(DesignColor.textMuted)
                Text(line.title).typeRole(.label).multilineTextAlignment(.leading).lineLimit(Int(DesignMeasure.agendaTitleLines))
                if !line.detail.isEmpty { Text(line.detail).typeRole(.caption).foregroundStyle(DesignColor.textMuted) }
            }
            Spacer(minLength: DesignSpace.fieldGap)
            Text(action).typeRole(.small).foregroundStyle(accentText)
        }
        .padding(.trailing, DesignSpace.menuInset)
        .background(line.tint(palette: palette), in: RoundedRectangle(cornerRadius: DesignRadius.block))
        .clipShape(RoundedRectangle(cornerRadius: DesignRadius.block))
    }
}
