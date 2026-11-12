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
    private var accentText: Color { DesignColor.accentText(palette) }
    @State private var day = DayAgenda.currentDay(now: .now) ?? .now
    @State private var agenda: DayAgenda?
    let openWorkspace: () -> Void
    private var week: [Date] { DayAgenda.week(containing: .now) }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSpace.fieldGap) {
            HStack(spacing: DesignIcon.gap) {
                strip
                detailButton
            }
            lines
            Spacer(minLength: 0)
        }
        .padding(MenuRibbonLayout.cardPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: DesignRadius.card))
        .modifier(RibbonSurface())
        .task(id: day) { agenda = await store.agenda(on: day) }
        .accessibilityElement(children: .contain).accessibilityLabel("Agenda de la semaine")
    }

    private var strip: some View {
        HStack(spacing: DesignSpace.listGapDense) {
            ForEach(week, id: \.self) { value in
                let isSelected = AgendaDay.isSame(value, day)
                Button { day = value } label: {
                    VStack(spacing: 0) {
                        Text(AgendaDay.text(value, "EEE").capitalized).typeRole(.micro).foregroundStyle(.secondary)
                        Text(AgendaDay.text(value, "d")).typeRole(.small).monospacedDigit()
                    }
                    .frame(maxWidth: .infinity).frame(height: Self.dayHeight)
                    .background(isSelected ? DesignColor.selection(palette) : Color.clear, in: RoundedRectangle(cornerRadius: DesignRadius.control))
                    .contentShape(RoundedRectangle(cornerRadius: DesignRadius.control))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AgendaDay.text(value, "EEEE d MMMM") + (store.hasUnusualMove(on: value) ? ", mouvement inhabituel" : ""))
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
        .padding(DesignSpace.listGapDense).background(DesignColor.text.opacity(DesignOpacity.glassRest), in: RoundedRectangle(cornerRadius: DesignRadius.block))
    }

    private var detailButton: some View {
        Button { store.openAgenda(on: day); openWorkspace() } label: {
            Image(systemName: "arrow.up.right").frame(width: DesignIcon.buttonSize, height: DesignIcon.buttonSize).contentShape(Circle())
        }
        .buttonStyle(.plain).foregroundStyle(accentText)
        .help("Voir le détail du jour dans sema").accessibilityLabel("Voir le détail du jour dans sema")
    }

    @ViewBuilder private var lines: some View {
        if let agenda {
            VStack(alignment: .leading, spacing: DesignSpace.markInset) {
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
        HStack(spacing: DesignSpace.rowInset) {
            Rectangle().fill(line.bar(palette: palette)).frame(width: AgendaLine.barWidth)
            VStack(alignment: .leading, spacing: 0) {
                Text(line.title).typeRole(.small).lineLimit(1)
                Text(line.subtitle).typeRole(.micro).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.trailing, DesignSpace.rowInset)
        .frame(height: Self.lineHeight)
        .background(line.tint(palette: palette), in: RoundedRectangle(cornerRadius: DesignRadius.control))
        .clipShape(RoundedRectangle(cornerRadius: DesignRadius.control))
        .contentShape(RoundedRectangle(cornerRadius: DesignRadius.control))
    }
}
