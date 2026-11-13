// Guide la première ouverture : bienvenue, choix des thèmes, puis connexion des données.
import SemaDesign
import SwiftUI
import MarketCore

// ACCUEIL
//   0 ms  Les actions sont déjà disponibles.
// 360 ms  Le signe termine son dessin ; le contenu reste stable.
// 220 ms  Une étape remplace la précédente, sans attente imposée.
// 180 ms  Un thème change de teinte, sans déplacer les tuiles.

private enum WelcomeMotion {
    static let drawDuration = DesignDuration.explain
    static let stepDuration = DesignDuration.standard
    static let contentOffset = DesignMotion.shift
    static let selectionDuration = DesignDuration.fast
}

private enum WelcomeLayout {
    static let windowPadding = DesignSpace.pageInsetNarrow
    static let heroSpacing = DesignSpace.sectionGap
    static let dotSpacing = DesignIcon.gap
    static let titleSpacing = DesignSpace.fieldGap
    static let errorSpacing = DesignSpace.fieldGap
    static let errorTopPadding = DesignSpace.menuInset
    static let stepSpacing = DesignSpace.groupGap
    static let gridSpacing = DesignSpace.itemGap
    static let featureSpacing = DesignSpace.groupGap
    static let featureRowSpacing = DesignSpace.itemGap
    static let featureTextSpacing = DesignSpace.titleGap
    static let tileSpacing = DesignSpace.itemGap
    static let tileTextSpacing = DesignSpace.titleGap
    static let tilePadding = DesignSpace.cardInset
    static let tileBorder = DesignBorder.width
    static let footerSpacing = DesignSpace.fieldGap
    static let signalWidth = SignalPath.stroke * DesignLayout.welcomeSignalSize / SignalPath.viewBox
    static let heroSignalWidth = SignalPath.stroke * DesignLayout.welcomeHeroSignalSize / SignalPath.viewBox
}

private struct WelcomeFeature: Identifiable {
    let symbol: String
    let title: String
    let detail: String
    var id: String { symbol }

    static let all: [Self] = [
        .init(symbol: "menubar.rectangle", title: "Un bandeau dans la barre des menus",
              detail: "Vos repères favoris, d’un coup d’œil, sans ouvrir de fenêtre."),
        .init(symbol: "chart.xyaxis.line", title: "L’historique pour comprendre",
              detail: "Chaque valeur avec sa définition officielle et son évolution."),
        .init(symbol: "bell", title: "Des alertes de seuil",
              detail: "Choisissez un repère et un seuil ; sema le vérifie à chaque actualisation.")
    ]
}

private struct WelcomeCollection: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    let items: [(id: String, title: String)]
    var seriesIDs: [String] { items.map { $0.id } }

    static let all: [Self] = [
        .init(id: "rates", title: "Taux & marchés", subtitle: "Le coût de l’argent", symbol: "chart.xyaxis.line",
              items: [("FM.M.FR.EUR.FR2.BB.FR10YT_RR.YLD", "France · 10 ans"), ("FM.D.U2.EUR.4F.KR.DFR.LEV", "Dépôt BCE"), ("ESTR.B.EU000A2X2A25.WT", "€STR")]),
        .init(id: "economy", title: "Économie réelle", subtitle: "Prix et financement", symbol: "building.2",
              items: [("HICP.M.FR.N.000000.4D0.ANR", "Inflation France"), ("HICP.M.U2.N.000000.4D0.ANR", "Inflation euro"), ("MIR1.M.FR.B.A22HR.A.R.A.2254U6.EUR.N", "Crédit immobilier")]),
        .init(id: "savings", title: "Épargne", subtitle: "Les repères du quotidien", symbol: "leaf",
              items: [("MIR1.M.FR.B.L23FRLA.D.R.A.2230U6.EUR.O", "Livret A"), ("MIR1.M.FR.B.L23FRLD.D.R.A.2254U6.EUR.O", "LDDS"), ("MIR1.M.FR.B.L23FRLP.H.R.A.2250U6.EUR.O", "LEP")]),
        .init(id: "currencies", title: "Devises", subtitle: "L’euro dans le monde", symbol: "globe.europe.africa",
              items: [("EXR.D.USD.EUR.SP00.A", "EUR / USD"), ("EXR.D.JPY.EUR.SP00.A", "EUR / JPY"), ("EXR.D.CHF.EUR.SP00.A", "EUR / CHF"), ("EXR.D.GBP.EUR.SP00.A", "EUR / GBP")])
    ]
}

struct OnboardingScreen: View {
    private static let stepCount = 3
    @Environment(AppStore.self) private var store
    @Environment(\.palette) private var palette
    private var accent: Color { DesignColor.accent(palette) }
    private var accentText: Color { DesignColor.accentText(palette) }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let initialSelection: [String]
    let selectSeries: ([String]) -> Bool
    let finish: () -> Bool
    @State private var selection: Set<String>
    @State private var step = 0
    @State private var drawProgress: CGFloat = 0
    @State private var selectionError: String?

    init(initialSelection: [String], selectSeries: @escaping ([String]) -> Bool,
         finish: @escaping () -> Bool) {
        self.initialSelection = initialSelection
        self.selectSeries = selectSeries
        self.finish = finish
        _selection = State(initialValue: Set(initialSelection))
    }

    private var suggestions: [MarketSeries] { WebstatStarter.series }

    private var title: String {
        switch step {
        case 1: "Que souhaitez-vous suivre ?"
        default: "Vos données, sur votre Mac."
        }
    }
    private var detail: String {
        switch step {
        case 1: "Choisissez des thèmes : sema compose votre bandeau. Vous pourrez tout modifier ensuite."
        default: "Connectez votre clé personnelle Webstat pour retrouver les données de la Banque de France."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header.padding(.bottom, DesignSpace.groupGap)

            if step > 0 {
                VStack(alignment: .leading, spacing: WelcomeLayout.titleSpacing) {
                    Text(title).typeRole(.title)
                        .accessibilityAddTraits(.isHeader)
                    Text(detail).typeRole(.body).foregroundStyle(DesignColor.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom, DesignSpace.groupGap)
            }

            Group {
                switch step {
                case 0: welcomeStep
                case 1: themeStep
                default: connectionStep
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: step == 0 ? .center : .topLeading)
            .transition(reduceMotion ? .identity : .opacity.combined(with: .offset(y: WelcomeMotion.contentOffset)))
            .id(step)

            if let selectionError {
                HStack(alignment: .top, spacing: WelcomeLayout.errorSpacing) {
                    Text(selectionError).typeRole(.caption).foregroundStyle(DesignColor.danger)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Button("Fermer") { store.isOnboardingPresented = false }
                        .buttonStyle(.borderless).typeRole(.caption)
                        .help("Fermer l’accueil sans le marquer comme terminé")
                }
                .padding(.top, WelcomeLayout.errorTopPadding)
            }
            footer.padding(.top, DesignSpace.groupGap)
        }
        .padding(WelcomeLayout.windowPadding).frame(width: DesignLayout.welcomeWindowWidth, height: DesignLayout.welcomeWindowHeight)
        .background(DesignColor.background)
        .interactiveDismissDisabled()
        .task {
            await store.checkWebstatKey()
            withAnimation(reduceMotion ? nil : Animation.timingCurve(DesignEase.out, duration: WelcomeMotion.drawDuration)) { drawProgress = 1 }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            HStack(spacing: DesignIcon.gap) {
                WelcomeSignal(progress: reduceMotion ? 1 : drawProgress, lineWidth: WelcomeLayout.signalWidth)
                    .foregroundStyle(accent).frame(width: DesignLayout.welcomeSignalSize, height: DesignLayout.welcomeSignalSize)
                Text("sema").typeRole(.wordmark)
            }
            .opacity(step == 0 ? 0 : 1).accessibilityHidden(step == 0)
            Spacer()
            HStack(spacing: WelcomeLayout.dotSpacing) {
                ForEach(0..<Self.stepCount, id: \.self) { index in
                    Capsule().fill(index == step ? accent : DesignColor.ruleHover)
                        .frame(width: index == step ? DesignLayout.welcomeActiveDotWidth : DesignLayout.dotSize, height: DesignLayout.dotSize)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Étape \(step + 1) sur \(Self.stepCount)")
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: WelcomeLayout.heroSpacing) {
            WelcomeSignal(progress: reduceMotion ? 1 : drawProgress, lineWidth: WelcomeLayout.heroSignalWidth)
                .foregroundStyle(accent).frame(width: DesignLayout.welcomeHeroSignalSize, height: DesignLayout.welcomeHeroSignalSize)
            VStack(spacing: WelcomeLayout.titleSpacing) {
                Text("Bienvenue dans sema.").typeRole(.title)
                    .accessibilityAddTraits(.isHeader)
                Text("L’économie bouge. Gardez vos repères.").typeRole(.body).foregroundStyle(DesignColor.textMuted)
            }
            VStack(alignment: .leading, spacing: WelcomeLayout.featureSpacing) {
                ForEach(WelcomeFeature.all) { feature in
                    HStack(alignment: .top, spacing: WelcomeLayout.featureRowSpacing) {
                        Image(systemName: feature.symbol).typeRole(.section).foregroundStyle(accentText)
                            .frame(width: DesignLayout.welcomeFeatureSymbolWidth).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: WelcomeLayout.featureTextSpacing) {
                            Text(feature.title).typeRole(.heading)
                            Text(feature.detail).typeRole(.caption).foregroundStyle(DesignColor.textMuted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .frame(maxWidth: DesignLayout.welcomeFeatureColumnWidth, alignment: .leading)
        }
    }

    private var themeStep: some View {
        VStack(alignment: .leading, spacing: WelcomeLayout.stepSpacing) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: WelcomeLayout.gridSpacing), GridItem(.flexible())],
                      spacing: WelcomeLayout.gridSpacing) {
                ForEach(WelcomeCollection.all) { collection in themeTile(collection) }
            }
        }
    }

    private func isSelected(_ collection: WelcomeCollection) -> Bool {
        selection.isSuperset(of: Set(collection.seriesIDs))
    }

    private func toggle(_ collection: WelcomeCollection) {
        withAnimation(reduceMotion ? nil : Animation.timingCurve(DesignEase.out, duration: WelcomeMotion.selectionDuration)) {
            if isSelected(collection) { selection.subtract(collection.seriesIDs) }
            else { selection.formUnion(collection.seriesIDs) }
        }
    }

    private func themeTile(_ collection: WelcomeCollection) -> some View {
        let isCollectionSelected = isSelected(collection)
        return Button { toggle(collection) } label: {
            HStack(spacing: WelcomeLayout.tileSpacing) {
                Image(systemName: collection.symbol).typeRole(.section).foregroundStyle(accentText)
                    .frame(width: DesignLayout.welcomeFeatureSymbolWidth).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: WelcomeLayout.tileTextSpacing) {
                    Text(collection.title).typeRole(.label)
                    Text(collection.subtitle).typeRole(.caption).foregroundStyle(DesignColor.textMuted).lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: isCollectionSelected ? "checkmark.circle.fill" : "circle").typeRole(.section)
                    .foregroundStyle(isCollectionSelected ? accent : DesignColor.textMuted)
                    .accessibilityHidden(true)
            }
            .padding(WelcomeLayout.tilePadding)
            .frame(maxWidth: .infinity, minHeight: DesignLayout.welcomeTileMinHeight, alignment: .leading)
            .background(isCollectionSelected ? DesignColor.selection(palette) : DesignColor.surfaceRaised,
                        in: RoundedRectangle(cornerRadius: DesignRadius.block))
            .overlay {
                RoundedRectangle(cornerRadius: DesignRadius.block)
                    .strokeBorder(isCollectionSelected ? accent : Color.clear, lineWidth: WelcomeLayout.tileBorder)
            }
            .elevation(DesignElevation.raised)
            .contentShape(RoundedRectangle(cornerRadius: DesignRadius.block))
        }
        .buttonStyle(PressStyle())
        .accessibilityLabel(collection.title)
        .accessibilityValue(isCollectionSelected ? "Choisi" : "Non choisi")
        .accessibilityAddTraits(isCollectionSelected ? [.isSelected] : [])
        .accessibilityHint("Ajouter ou retirer ces repères de votre espace")
        .help(collection.items.map(\.title).joined(separator: ", "))
    }

    private var connectionStep: some View {
        SourceKeyView(source: "webstat", didConnect: complete)
    }

    private func go(to next: Int) {
        withAnimation(reduceMotion ? nil : Animation.timingCurve(DesignEase.inOut, duration: WelcomeMotion.stepDuration)) { step = next }
    }

    private var footer: some View {
        HStack(spacing: WelcomeLayout.footerSpacing) {
            switch step {
            case 0:
                Button("Passer", action: complete).keyboardShortcut(.cancelAction)
                    .buttonStyle(.borderless).foregroundStyle(DesignColor.textMuted)
                Spacer()
                Button("Continuer") { go(to: 1) }
                    .keyboardShortcut(.defaultAction).buttonStyle(.borderedProminent)
            case 1:
                Button("Retour") { go(to: 0) }.buttonStyle(.borderless)
                Spacer()
                Button("Continuer") {
                    let starterIDs = Set(suggestions.map(\.id))
                    let preserved = initialSelection.filter { !starterIDs.contains($0) }
                    let ordered = suggestions.map(\.id).filter { selection.contains($0) } + preserved
                    guard selectSeries(ordered) else {
                        selectionError = store.errorMessage ?? "Vos choix n’ont pas pu être enregistrés."
                        return
                    }
                    selectionError = nil
                    go(to: 2)
                }
                .keyboardShortcut(.defaultAction).buttonStyle(.borderedProminent)
            default:
                Button("Retour") { go(to: 1) }.buttonStyle(.borderless).disabled(store.isLoading)
                Spacer(minLength: 0)
                if store.hasWebstatKey {
                    Button("Ouvrir sema", action: complete)
                        .keyboardShortcut(.defaultAction).buttonStyle(.borderedProminent)
                } else {
                    Button("Plus tard", action: complete)
                        .buttonStyle(.borderless).disabled(store.isLoading)
                }
            }
        }
        .controlSize(.large)
    }

    private func complete() {
        guard finish() else {
            selectionError = store.errorMessage ?? "L’accueil n’a pas pu être enregistré."
            return
        }
    }
}

private struct WelcomeSignal: View {
    let progress: CGFloat
    let lineWidth: CGFloat
    var body: some View {
        ZStack {
            SignalPath().trim(from: 0, to: progress)
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            SignalDot().fill(DesignColor.accentControl(.brand)).opacity(progress >= 1 ? 1 : 0)
        }
        .accessibilityHidden(true)
    }
}
