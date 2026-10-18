// Guide la première connexion et le choix des repères sans remplacer la sélection personnelle.
import SwiftUI
import MarketCore

// ACCUEIL
//   0 ms  Les actions sont déjà disponibles.
// 360 ms  Le signe termine son dessin ; le contenu reste stable.
// 220 ms  Une étape remplace la précédente, sans attente imposée.
// 180 ms  Une sélection change de teinte, sans déplacer les autres repères.
private enum WelcomeMotion {
    static let drawDuration = 0.36
    static let stepDuration = 0.22
    static let contentOffset: CGFloat = 6
    static let selectionDuration = 0.18
}

private enum WelcomeLayout {
    static let windowWidth: CGFloat = 720
    static let windowHeight: CGFloat = 660
    static let windowPadding: CGFloat = 36
    static let signalSize: CGFloat = 44
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
    static let gridSpacing: CGFloat = 14
    static let noteOffset: CGFloat = -10
    static let collectionSpacing: CGFloat = 17
    static let collectionHeaderSpacing: CGFloat = 12
    static let collectionTitleSpacing: CGFloat = 3
    static let collectionSymbolWidth: CGFloat = 32
    static let collectionSymbolHeight: CGFloat = 36
    static let collectionPadding: CGFloat = 18
    static let collectionMinHeight: CGFloat = 157
    static let choiceSpacing: CGFloat = 6
    static let choiceSymbolWidth: CGFloat = 10
    static let choicePadding: CGFloat = 10
    static let choiceHeight: CGFloat = 30
    static let choiceMinimumScale: CGFloat = 0.9
    static let footerSpacing: CGFloat = 12
    static let wordmarkFont = Font.system(size: 16, weight: .semibold)
    static let titleFont = Font.system(size: 30, weight: .semibold)
    static let collectionSymbolFont = Font.system(size: 20)
    static let collectionTitleFont = Font.system(size: 14, weight: .semibold)
    static let choiceSymbolFont = Font.system(size: 9, weight: .semibold)
    static let signalWidth: CGFloat = 2.3
}

private struct WelcomeCollection: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    let items: [(id: String, title: String)]

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
    private static let stepCount = 2
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

    private var suggestions: [MarketSeries] { WebstatClient.starterSeries }
    private var selectedCount: Int { selection.intersection(Set(suggestions.map(\.id))).count }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                HStack(spacing: SemaTheme.minorSpacing) {
                    WelcomeSignal(progress: reduceMotion ? 1 : drawProgress)
                        .foregroundStyle(accent).frame(width: WelcomeLayout.signalSize, height: WelcomeLayout.signalSize)
                    Text("sema").font(WelcomeLayout.wordmarkFont).tracking(WelcomeLayout.wordmarkTracking)
                }
                Spacer()
                HStack(spacing: WelcomeLayout.dotSpacing) {
                    ForEach(0..<Self.stepCount) { index in
                        Capsule().fill(index == step ? accent : Color.secondary.opacity(WelcomeLayout.dotOpacity))
                            .frame(width: index == step ? WelcomeLayout.activeDotWidth : WelcomeLayout.dotSize, height: WelcomeLayout.dotSize)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Étape \(step + 1) sur 2")
            }
            .padding(.bottom, SemaTheme.majorSpacing)

            VStack(alignment: .leading, spacing: WelcomeLayout.titleSpacing) {
                Text(step == 0 ? "Vos premiers repères." : "Vos données, sur votre Mac.")
                    .font(WelcomeLayout.titleFont).tracking(WelcomeLayout.titleTracking)
                    .accessibilityAddTraits(.isHeader)
                Text(step == 0
                     ? "Un espace à votre image. Choisissez ce que vous souhaitez garder à l’œil."
                     : "Connectez votre clé personnelle Webstat pour retrouver les données de la Banque de France.")
                    .font(.body).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, SemaTheme.majorSpacing)

            Group {
                if step == 0 { selectionStep }
                else { connectionStep }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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

    private var selectionStep: some View {
        VStack(alignment: .leading, spacing: WelcomeLayout.stepSpacing) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: WelcomeLayout.gridSpacing) {
                ForEach(WelcomeCollection.all) { collection in
                    collectionView(collection)
                }
            }
            HStack(alignment: .firstTextBaseline) {
                Text(selectedCount == 1 ? "1 repère choisi" : "\(selectedCount) repères choisis")
                    .font(.callout.weight(.medium)).monospacedDigit()
                    .contentTransition(.numericText())
                Spacer()
                Button(selection.isSuperset(of: Set(suggestions.map(\.id))) ? "Tout retirer" : "Tout choisir") {
                    withAnimation(reduceMotion ? nil : .easeOut(duration: WelcomeMotion.selectionDuration)) {
                        let ids = Set(suggestions.map(\.id))
                        if selection.isSuperset(of: ids) { selection.subtract(ids) }
                        else { selection.formUnion(ids) }
                    }
                }
                .buttonStyle(.borderless).font(.subheadline)
            }
            Text("Vous pourrez ajouter d’autres repères depuis le catalogue Webstat.")
                .font(.subheadline).foregroundStyle(.secondary).padding(.top, WelcomeLayout.noteOffset)
        }
    }

    private func collectionView(_ collection: WelcomeCollection) -> some View {
        VStack(alignment: .leading, spacing: WelcomeLayout.collectionSpacing) {
            HStack(spacing: WelcomeLayout.collectionHeaderSpacing) {
                Image(systemName: collection.symbol)
                    .font(WelcomeLayout.collectionSymbolFont).foregroundStyle(accent)
                    .frame(width: WelcomeLayout.collectionSymbolWidth, height: WelcomeLayout.collectionSymbolHeight).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: WelcomeLayout.collectionTitleSpacing) {
                    Text(collection.title).font(WelcomeLayout.collectionTitleFont)
                        .accessibilityAddTraits(.isHeader)
                    Text(collection.subtitle).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: SemaTheme.minorSpacing) {
                ForEach(collection.items, id: \.id) { item in
                    choice(id: WebstatClient.canonicalID(item.id), title: item.title)
                }
            }
        }
        .padding(WelcomeLayout.collectionPadding).frame(maxWidth: .infinity, minHeight: WelcomeLayout.collectionMinHeight, alignment: .topLeading)
        .background(SemaTheme.surface, in: RoundedRectangle(cornerRadius: SemaTheme.cardCorner))
        .modifier(SemaElevation())
    }

    private func choice(id: String, title: String) -> some View {
        let selected = selection.contains(id)
        return Button {
            withAnimation(reduceMotion ? nil : .easeOut(duration: WelcomeMotion.selectionDuration)) {
                if selected { selection.remove(id) }
                else { selection.insert(id) }
            }
        } label: {
            HStack(spacing: WelcomeLayout.choiceSpacing) {
                Image(systemName: selected ? "checkmark" : "plus")
                    .font(WelcomeLayout.choiceSymbolFont).frame(width: WelcomeLayout.choiceSymbolWidth)
                Text(title).font(.subheadline.weight(.medium)).lineLimit(1)
                    .minimumScaleFactor(WelcomeLayout.choiceMinimumScale)
                Spacer(minLength: 0)
            }
            .foregroundStyle(selected ? accent : Color.secondary)
            .padding(.horizontal, WelcomeLayout.choicePadding).frame(height: WelcomeLayout.choiceHeight)
            .background(selected ? accent.opacity(SemaTheme.selectionOpacity) : SemaTheme.quietFill, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(SemaPressStyle())
        .accessibilityLabel(suggestions.first { $0.id == id }?.name ?? title)
        .accessibilityValue(selected ? "Choisi" : "Non choisi")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityHint("Ajouter ou retirer ce repère de votre espace")
        .help(suggestions.first { $0.id == id }?.subtitle ?? title)
    }

    private var connectionStep: some View {
        WebstatConnectionView(didConnect: complete)
    }

    private var footer: some View {
        HStack(spacing: WelcomeLayout.footerSpacing) {
            if step == 0 {
                Button("Passer", action: complete).keyboardShortcut(.cancelAction)
                    .buttonStyle(.borderless).foregroundStyle(.secondary)
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
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: WelcomeMotion.stepDuration)) { step = 1 }
                }
                .keyboardShortcut(.defaultAction).buttonStyle(.borderedProminent)
            } else {
                Button("Retour") {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: WelcomeMotion.stepDuration)) { step = 0 }
                }
                .buttonStyle(.borderless).disabled(store.isLoading)
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
    var body: some View {
        SemaSignalPath().trim(from: 0, to: progress)
            .stroke(style: StrokeStyle(lineWidth: WelcomeLayout.signalWidth, lineCap: .round, lineJoin: .round))
            .accessibilityHidden(true)
    }
}
