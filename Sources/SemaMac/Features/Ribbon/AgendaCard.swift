// Carte Agenda du bandeau : la bande des jours de la semaine, jusqu’à trois lignes du jour choisi, et une flèche vers son détail dans le hub.
import SemaDesign
import SwiftUI
import MarketCore

struct AgendaCard: View {
    private static let dayHeight: CGFloat = 34
    private static let lineHeight: CGFloat = 42
    private static let emptyLines = 4
    @Environment(AppStore.self) private var store
    @Environment(\.palette) private var palette
    private var accent: Color { DesignColor.accent(palette) }
    @State private var day = DayAgenda.currentDay(now: .now) ?? .now
    @State private var agenda: DayAgenda?
    let openWorkspace: () -> Void
    private var week: [Date] { DayAgenda.week(containing: .now) }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            HStack(spacing: Spacing.s6) {
                strip
                detailButton
            }
            lines
            Spacer(minLength: 0)
        }
        .padding(MenuRibbonLayout.cardPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: Theme.surfaceCorner))
        .modifier(RibbonSurface())
        .task(id: day) { agenda = await store.agenda(on: day) }
        .accessibilityElement(children: .contain).accessibilityLabel("Agenda de la semaine")
    }

    private var strip: some View {
        HStack(spacing: Spacing.s2) {
            ForEach(week, id: \.self) { value in
                let selected = AgendaDay.isSame(value, day)
                Button { day = value } label: {
                    VStack(spacing: 0) {
                        Text(AgendaDay.text(value, "EEE").capitalized).typeRole(.micro).foregroundStyle(.secondary)
                        Text(AgendaDay.text(value, "d")).typeRole(.small).monospacedDigit()
                    }
                    .frame(maxWidth: .infinity).frame(height: Self.dayHeight)
                    .background(selected ? Theme.surface : Color.clear, in: RoundedRectangle(cornerRadius: Radius.control))
                    .contentShape(RoundedRectangle(cornerRadius: Radius.control))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AgendaDay.text(value, "EEEE d MMMM") + (store.hasUnusualMove(on: value) ? ", mouvement inhabituel" : ""))
                .accessibilityAddTraits(selected ? [.isSelected] : [])
            }
        }
        .padding(Spacing.s2).background(Theme.quietFill, in: RoundedRectangle(cornerRadius: Radius.block))
    }

    private var detailButton: some View {
        Button { store.openAgenda(on: day); openWorkspace() } label: {
            Image(systemName: "arrow.up.right").frame(width: Theme.iconButtonSize, height: Theme.iconButtonSize).contentShape(Circle())
        }
        .buttonStyle(.plain).foregroundStyle(accent)
        .help("Voir le détail du jour dans sema").accessibilityLabel("Voir le détail du jour dans sema")
    }

    @ViewBuilder private var lines: some View {
        if let agenda {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                if agenda.items.isEmpty {
                    Text(AgendaLine.emptyText(hasFREDKey: store.hasFREDKey)).typeRole(.small).foregroundStyle(.secondary)
                        .lineLimit(Self.emptyLines)
                }
                ForEach(agenda.shown.map { AgendaLine($0, store: store) }) { line in
                    switch line.destination {
                    case .series(let series):
                        Button { store.show(series); store.section = .overview; openWorkspace() } label: { row(line) }.buttonStyle(.plain)
                    case .link(let url):
                        Link(destination: url) { row(line) }.buttonStyle(.plain).help(url.absoluteString)
                    case nil:
                        EmptyView()
                    }
                }
            }
        } else {
            ProgressView().controlSize(.small)
        }
    }

    private func row(_ line: AgendaLine) -> some View {
        HStack(spacing: Spacing.s8) {
            Rectangle().fill(line.bar(accent: accent)).frame(width: AgendaLine.barWidth)
            VStack(alignment: .leading, spacing: 0) {
                Text(line.title).typeRole(.small).lineLimit(1)
                Text(line.subtitle).typeRole(.micro).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.trailing, Spacing.s8)
        .frame(height: Self.lineHeight)
        .background(line.tint(accent: accent), in: RoundedRectangle(cornerRadius: Radius.control))
        .clipShape(RoundedRectangle(cornerRadius: Radius.control))
        .contentShape(RoundedRectangle(cornerRadius: Radius.control))
    }
}
