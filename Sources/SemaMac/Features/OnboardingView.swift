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
    @Environment(AppStore.self) private var store
    @Environment(\.semaAccent) private var accent
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let initialSelection: [String]
    let selectSeries: ([String]) -> Bool
    let finish: () -> Bool
    @State private var selection: Set<String>
    @State private var step = 0
    @State private var drawProgress: CGFloat = 0
    @State private var apiKey = ""
    @State private var selectionError: String?
    @FocusState private var keyFocused: Bool

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
                HStack(spacing: 8) {
                    WelcomeSignal(progress: reduceMotion ? 1 : drawProgress)
                        .foregroundStyle(accent).frame(width: 44, height: 44)
                    Text("Sema").font(.system(size: 16, weight: .semibold)).tracking(-0.5)
                }
                Spacer()
                HStack(spacing: 6) {
                    ForEach(0..<2) { index in
                        Capsule().fill(index == step ? accent : Color.secondary.opacity(0.2))
                            .frame(width: index == step ? 18 : 6, height: 6)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Étape \(step + 1) sur 2")
            }
            .padding(.bottom, 24)

            VStack(alignment: .leading, spacing: 10) {
                Text(step == 0 ? "Vos premiers repères." : "Vos données, sur votre Mac.")
                    .font(.system(size: 30, weight: .semibold)).tracking(-0.9)
                    .accessibilityAddTraits(.isHeader)
                Text(step == 0
                     ? "Un espace à votre image. Choisissez ce que vous souhaitez garder à l’œil."
                     : "Connectez votre clé personnelle Webstat pour retrouver les données de la Banque de France.")
                    .font(.system(size: 13)).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, 24)

            Group {
                if step == 0 { selectionStep }
                else { connectionStep }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .transition(reduceMotion ? .identity : .opacity.combined(with: .offset(y: WelcomeMotion.contentOffset)))
            .id(step)

            if let selectionError {
                Text(selectionError).font(.system(size: 11)).foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true).padding(.top, 12)
            }
            footer.padding(.top, 24)
        }
        .padding(36).frame(width: 720, height: 660)
        .background(SemaTheme.background)
        .interactiveDismissDisabled()
        .task {
            await store.checkWebstatKey()
            withAnimation(reduceMotion ? nil : .easeOut(duration: WelcomeMotion.drawDuration)) { drawProgress = 1 }
        }
        .onDisappear { apiKey = "" }
    }

    private var selectionStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(WelcomeCollection.all) { collection in
                    collectionView(collection)
                }
            }
            HStack(alignment: .firstTextBaseline) {
                Text(selectedCount == 1 ? "1 repère choisi" : "\(selectedCount) repères choisis")
                    .font(.system(size: 12, weight: .medium)).monospacedDigit()
                    .contentTransition(.numericText())
                Spacer()
                Button(selection.isSuperset(of: Set(suggestions.map(\.id))) ? "Tout retirer" : "Tout choisir") {
                    withAnimation(reduceMotion ? nil : .easeOut(duration: WelcomeMotion.selectionDuration)) {
                        let ids = Set(suggestions.map(\.id))
                        if selection.isSuperset(of: ids) { selection.subtract(ids) }
                        else { selection.formUnion(ids) }
                    }
                }
                .buttonStyle(.borderless).font(.system(size: 11))
            }
            Text("Vous pourrez ajouter d’autres repères depuis le catalogue Webstat.")
                .font(.system(size: 11)).foregroundStyle(.secondary).padding(.top, -10)
        }
    }

    private func collectionView(_ collection: WelcomeCollection) -> some View {
        VStack(alignment: .leading, spacing: 17) {
            HStack(spacing: 12) {
                Image(systemName: collection.symbol)
                    .font(.system(size: 20, weight: .regular)).foregroundStyle(accent)
                    .frame(width: 32, height: 36).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(collection.title).font(.system(size: 14, weight: .semibold))
                        .accessibilityAddTraits(.isHeader)
                    Text(collection.subtitle).font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 8) {
                ForEach(collection.items, id: \.id) { item in
                    choice(id: WebstatClient.canonicalID(item.id), title: item.title)
                }
            }
        }
        .padding(18).frame(maxWidth: .infinity, minHeight: 157, alignment: .topLeading)
        .background(SemaTheme.surface, in: RoundedRectangle(cornerRadius: 18))
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
            HStack(spacing: 6) {
                Image(systemName: selected ? "checkmark" : "plus")
                    .font(.system(size: 9, weight: .semibold)).frame(width: 10)
                Text(title).font(.system(size: 11, weight: .medium)).lineLimit(1)
                    .minimumScaleFactor(0.9)
                Spacer(minLength: 0)
            }
            .foregroundStyle(selected ? accent : Color.secondary)
            .padding(.horizontal, 10).frame(height: 30)
            .background(selected ? accent.opacity(0.12) : Color.primary.opacity(0.035), in: Capsule())
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
        VStack(alignment: .leading, spacing: 18) {
            if store.hasWebstatKey {
                Label("Votre clé est déjà enregistrée dans le Trousseau.", systemImage: "checkmark.circle")
                    .font(.system(size: 13)).foregroundStyle(accent)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Clé API Webstat").font(.system(size: 12, weight: .medium))
                    SecureField("Votre clé personnelle", text: $apiKey)
                        .textFieldStyle(.roundedBorder).textContentType(.password)
                        .privacySensitive().focused($keyFocused)
                        .accessibilityLabel("Clé API Webstat")
                        .onSubmit { connect() }
                    Link("Obtenir une clé sur Webstat ↗", destination: URL(string: "https://webstat.banque-france.fr/login/")!)
                        .font(.system(size: 11))
                }
                Text("Elle reste dans le Trousseau de ce Mac et est transmise uniquement à Webstat. Vous pourrez la retirer dans les réglages.")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let error = store.webstatError {
                    Text(error).font(.system(size: 12)).foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 6) {
                Label("À votre rythme", systemImage: "leaf")
                    .font(.system(size: 12, weight: .medium))
                Text("Vous pouvez découvrir Sema en démonstration et connecter vos données plus tard.")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
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
                    keyFocused = true
                }
                .keyboardShortcut(.defaultAction).buttonStyle(.borderedProminent)
            } else {
                Button("Retour") {
                    apiKey = ""
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: WelcomeMotion.stepDuration)) { step = 0 }
                }
                .buttonStyle(.borderless).disabled(store.isLoading)
                Spacer(minLength: 0)
                if store.hasWebstatKey {
                    Button("Ouvrir Sema", action: complete)
                        .keyboardShortcut(.defaultAction).buttonStyle(.borderedProminent)
                } else {
                    Button("Découvrir la démo", action: complete)
                        .buttonStyle(.borderless).disabled(store.isLoading)
                    Button(store.isLoading ? "Connexion…" : "Connecter") { connect() }
                        .keyboardShortcut(.defaultAction).buttonStyle(.borderedProminent)
                        .disabled(store.isLoading || apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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

    private func connect() {
        guard !store.isLoading, !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        Task {
            if await store.connectWebstat(apiKey: apiKey) {
                apiKey = ""
                complete()
            }
        }
    }
}

private struct WelcomeSignal: View {
    let progress: CGFloat
    var body: some View {
        SemaSignalPath().trim(from: 0, to: progress)
            .stroke(style: StrokeStyle(lineWidth: 2.3, lineCap: .round, lineJoin: .round))
            .accessibilityHidden(true)
    }
}
