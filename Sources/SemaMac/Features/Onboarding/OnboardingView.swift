// Guide la première ouverture : bienvenue, thèmes avec aperçu du bandeau, puis connexion des données.
import SwiftUI
import MarketCore

// ACCUEIL
//   0 ms  Les actions sont déjà disponibles.
// 360 ms  Le signe termine son dessin ; le contenu reste stable.
// 220 ms  Une étape remplace la précédente, sans attente imposée.
// 180 ms  Un thème change de teinte et l’aperçu du bandeau suit, sans déplacer les tuiles.

private enum WelcomeMotion {
    static let drawDuration = 0.36
    static let stepDuration = 0.22
    static let contentOffset: CGFloat = 6
    static let selectionDuration = 0.18
    static let previewScale: CGFloat = 0.96
}

private enum WelcomeLayout {
    static let windowWidth: CGFloat = 640
    static let windowHeight: CGFloat = 700
    static let windowPadding: CGFloat = 36
    static let signalSize: CGFloat = 44
    static let heroSignalSize: CGFloat = 88
    static let heroSpacing: CGFloat = 28
    static let wordmarkTracking: CGFloat = -0.5
    static let dotSize: CGFloat = 6
    static let activeDotWidth: CGFloat = 18
    static let dotSpacing: CGFloat = 6
    static let dotOpacity = 0.2
    static let titleSpacing: CGFloat = 10
    static let titleTracking: CGFloat = -0.9
    static let errorSpacing: CGFloat = 12
    static let errorTopPadding: CGFloat = 12
    static let stepSpacing: CGFloat = 20
    static let gridSpacing: CGFloat = 12
    static let featureColumnWidth: CGFloat = 420
    static let featureSpacing: CGFloat = 20
    static let featureRowSpacing: CGFloat = 16
    static let featureTextSpacing: CGFloat = 3
    static let featureSymbolWidth: CGFloat = 32
    static let tileSpacing: CGFloat = 12
    static let tileTextSpacing: CGFloat = 3
    static let tilePadding: CGFloat = 16
    static let tileMinHeight: CGFloat = 64
    static let tileBorder: CGFloat = 1.5
    static let previewSpacing: CGFloat = 12
    static let previewCardWidth: CGFloat = 176
    static let footerSpacing: CGFloat = 12
    static let wordmarkFont = Font.system(size: 16, weight: .semibold)
    static let titleFont = Font.system(size: 30, weight: .semibold)
    static let featureSymbolFont = Font.system(size: 20)
    static let tileSymbolFont = Font.system(size: 20)
    static let tileTitleFont = Font.system(size: 14, weight: .semibold)
    static let tileCheckFont = Font.system(size: 18)
    static let signalWidth: CGFloat = 2.3
    static let heroSignalWidth: CGFloat = 3.6
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
    var seriesIDs: [String] { items.map { WebstatClient.canonicalID($0.id) } }

    static let all: [Self] = [
        .init(id: "rates", title: "Taux & marchés", subtitle: "Le coût de l’argent", symbol: "chart.xyaxis.line",
              items: [("fr10", "France · 10 ans"), ("ecb", "Dépôt BCE"), ("estr", "€STR")]),
        .init(id: "economy", title: "Économie réelle", subtitle: "Prix et financement", symbol: "building.2",
              items: [("inflation", "Inflation France"), ("inflation-euro", "Inflation euro"), ("mortgage-fr", "Crédit immobilier")]),
        .init(id: "savings", title: "Épargne", subtitle: "Les repères du quotidien", symbol: "leaf",
              items: [("livreta", "Livret A"), ("ldds", "LDDS"), ("lep", "LEP")]),
        .init(id: "currencies", title: "Devises", subtitle: "L’euro dans le monde", symbol: "globe.europe.africa",
              items: [("eurusd", "EUR / USD"), ("eurjpy", "EUR / JPY"), ("eurchf", "EUR / CHF"), ("eurgbp", "EUR / GBP")])
    ]
}

struct OnboardingView: View {
    private static let stepCount = 3
    private static let previewCardCount = 3
    private static let minimumPreviewObservations = 1
    @Environment(AppStore.self) private var store
    @Environment(\.semaAccent) private var accent
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

    private static let previewExamples = DemoCatalog.series()
    private var suggestions: [MarketSeries] { WebstatClient.starterSeries }
    private var selectedCount: Int { selection.intersection(Set(suggestions.map(\.id))).count }

    /// Une carte d’exemple fictif par thème choisi : le seul endroit où sema montre des valeurs inventées.
    private var previewSeries: [MarketSeries] {
        WelcomeCollection.all.compactMap { collection in
            collection.items.lazy
                .filter { selection.contains(WebstatClient.canonicalID($0.id)) }
                .compactMap { item in Self.previewExamples.first { $0.id == item.id } }
                .first { $0.observations.count > Self.minimumPreviewObservations }
        }
        .prefix(Self.previewCardCount).map { $0 }
    }

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
            header.padding(.bottom, SemaTheme.majorSpacing)

            if step > 0 {
                VStack(alignment: .leading, spacing: WelcomeLayout.titleSpacing) {
                    Text(title).font(WelcomeLayout.titleFont).tracking(WelcomeLayout.titleTracking)
                        .accessibilityAddTraits(.isHeader)
                    Text(detail).font(.body).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom, SemaTheme.majorSpacing)
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
                    Text(selectionError).font(.subheadline).foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Button("Fermer") { store.isOnboardingPresented = false }
                        .buttonStyle(.borderless).font(.subheadline)
                        .help("Fermer l’accueil sans le marquer comme terminé")
                }
                .padding(.top, WelcomeLayout.errorTopPadding)
            }
            footer.padding(.top, SemaTheme.majorSpacing)
        }
        .padding(WelcomeLayout.windowPadding).frame(width: WelcomeLayout.windowWidth, height: WelcomeLayout.windowHeight)
        .background(SemaTheme.background)
        .interactiveDismissDisabled()
        .task {
            await store.checkWebstatKey()
            withAnimation(reduceMotion ? nil : .easeOut(duration: WelcomeMotion.drawDuration)) { drawProgress = 1 }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            HStack(spacing: SemaTheme.minorSpacing) {
                WelcomeSignal(progress: reduceMotion ? 1 : drawProgress, lineWidth: WelcomeLayout.signalWidth)
                    .foregroundStyle(accent).frame(width: WelcomeLayout.signalSize, height: WelcomeLayout.signalSize)
                Text("sema").font(WelcomeLayout.wordmarkFont).tracking(WelcomeLayout.wordmarkTracking)
            }
            .opacity(step == 0 ? 0 : 1).accessibilityHidden(step == 0)
            Spacer()
            HStack(spacing: WelcomeLayout.dotSpacing) {
                ForEach(0..<Self.stepCount, id: \.self) { index in
                    Capsule().fill(index == step ? accent : Color.secondary.opacity(WelcomeLayout.dotOpacity))
                        .frame(width: index == step ? WelcomeLayout.activeDotWidth : WelcomeLayout.dotSize, height: WelcomeLayout.dotSize)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Étape \(step + 1) sur \(Self.stepCount)")
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: WelcomeLayout.heroSpacing) {
            WelcomeSignal(progress: reduceMotion ? 1 : drawProgress, lineWidth: WelcomeLayout.heroSignalWidth)
                .foregroundStyle(accent).frame(width: WelcomeLayout.heroSignalSize, height: WelcomeLayout.heroSignalSize)
            VStack(spacing: WelcomeLayout.titleSpacing) {
                Text("Bienvenue dans sema.").font(WelcomeLayout.titleFont).tracking(WelcomeLayout.titleTracking)
                    .accessibilityAddTraits(.isHeader)
                Text("L’économie bouge. Gardez vos repères.").font(.body).foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: WelcomeLayout.featureSpacing) {
                ForEach(WelcomeFeature.all) { feature in
                    HStack(alignment: .top, spacing: WelcomeLayout.featureRowSpacing) {
                        Image(systemName: feature.symbol).font(WelcomeLayout.featureSymbolFont).foregroundStyle(accent)
                            .frame(width: WelcomeLayout.featureSymbolWidth).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: WelcomeLayout.featureTextSpacing) {
                            Text(feature.title).font(.headline)
                            Text(feature.detail).font(.subheadline).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .frame(maxWidth: WelcomeLayout.featureColumnWidth, alignment: .leading)
        }
    }

    private var themeStep: some View {
        VStack(alignment: .leading, spacing: WelcomeLayout.stepSpacing) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: WelcomeLayout.gridSpacing), GridItem(.flexible())],
                      spacing: WelcomeLayout.gridSpacing) {
                ForEach(WelcomeCollection.all) { collection in themeTile(collection) }
            }
            VStack(alignment: .leading, spacing: WelcomeLayout.previewSpacing) {
                Text("Aperçu du bandeau, avec des exemples fictifs.")
                    .font(.subheadline).foregroundStyle(.secondary)
                preview
            }
        }
    }

    private var preview: some View {
        HStack(spacing: WelcomeLayout.previewSpacing) {
            ForEach(previewSeries) { series in
                RibbonCard(series: store.displayedSeries(series), period: .year, action: {})
                    .frame(width: WelcomeLayout.previewCardWidth, height: MenuRibbonLayout.cardHeight)
                    .transition(reduceMotion ? .identity : .opacity.combined(with: .scale(scale: WelcomeMotion.previewScale)))
            }
            if previewSeries.isEmpty {
                Text("Choisissez un thème pour composer votre bandeau.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(SemaTheme.quietFill, in: RoundedRectangle(cornerRadius: SemaTheme.surfaceCorner))
            }
        }
        .frame(maxWidth: .infinity, minHeight: MenuRibbonLayout.cardHeight, maxHeight: MenuRibbonLayout.cardHeight, alignment: .leading)
        .environment(\.semaGlassTint, store.palette.glassTint)
        .environment(\.semaGlassSettings, store.ribbonGlass)
        .animation(reduceMotion ? nil : .easeOut(duration: WelcomeMotion.selectionDuration), value: previewSeries.map(\.id))
        .allowsHitTesting(false).accessibilityHidden(true)
    }

    private func isSelected(_ collection: WelcomeCollection) -> Bool {
        selection.isSuperset(of: Set(collection.seriesIDs))
    }

    private func toggle(_ collection: WelcomeCollection) {
        withAnimation(reduceMotion ? nil : .easeOut(duration: WelcomeMotion.selectionDuration)) {
            if isSelected(collection) { selection.subtract(collection.seriesIDs) }
            else { selection.formUnion(collection.seriesIDs) }
        }
    }

    private func themeTile(_ collection: WelcomeCollection) -> some View {
        let selected = isSelected(collection)
        return Button { toggle(collection) } label: {
            HStack(spacing: WelcomeLayout.tileSpacing) {
                Image(systemName: collection.symbol).font(WelcomeLayout.tileSymbolFont).foregroundStyle(accent)
                    .frame(width: WelcomeLayout.featureSymbolWidth).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: WelcomeLayout.tileTextSpacing) {
                    Text(collection.title).font(WelcomeLayout.tileTitleFont)
                    Text(collection.subtitle).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle").font(WelcomeLayout.tileCheckFont)
                    .foregroundStyle(selected ? accent : Color.secondary.opacity(WelcomeLayout.dotOpacity))
                    .accessibilityHidden(true)
            }
            .padding(WelcomeLayout.tilePadding)
            .frame(maxWidth: .infinity, minHeight: WelcomeLayout.tileMinHeight, alignment: .leading)
            .background(selected ? accent.opacity(SemaTheme.selectionOpacity) : SemaTheme.surface,
                        in: RoundedRectangle(cornerRadius: SemaTheme.cardCorner))
            .overlay {
                RoundedRectangle(cornerRadius: SemaTheme.cardCorner)
                    .strokeBorder(selected ? accent : Color.clear, lineWidth: WelcomeLayout.tileBorder)
            }
            .modifier(SemaElevation())
            .contentShape(RoundedRectangle(cornerRadius: SemaTheme.cardCorner))
        }
        .buttonStyle(SemaPressStyle())
        .accessibilityLabel(collection.title)
        .accessibilityValue(selected ? "Choisi" : "Non choisi")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityHint("Ajouter ou retirer ces repères de votre espace")
        .help(collection.items.map(\.title).joined(separator: ", "))
    }

    private var connectionStep: some View {
        SourceKeyView(source: "webstat", didConnect: complete)
    }

    private func go(to next: Int) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: WelcomeMotion.stepDuration)) { step = next }
    }

    private var footer: some View {
        HStack(spacing: WelcomeLayout.footerSpacing) {
            switch step {
            case 0:
                Button("Passer", action: complete).keyboardShortcut(.cancelAction)
                    .buttonStyle(.borderless).foregroundStyle(.secondary)
                Spacer()
                Button("Continuer") { go(to: 1) }
                    .keyboardShortcut(.defaultAction).buttonStyle(.borderedProminent)
            case 1:
                Button("Retour") { go(to: 0) }.buttonStyle(.borderless)
                Text(selectedCount == 1 ? "1 repère choisi" : "\(selectedCount) repères choisis")
                    .font(.callout).foregroundStyle(.secondary).monospacedDigit()
                    .contentTransition(.numericText())
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
        SemaSignalPath().trim(from: 0, to: progress)
            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            .accessibilityHidden(true)
    }
}
