// Organise les réglages en rubriques recherchables, avec un contenu natif et un profil fixé en bas.
import SwiftUI

private extension SettingsTab {
    static let ordered: [Self] = [.general, .appearance, .shortcuts, .sources, .about, .profile]
    var title: String {
        switch self {
        case .general: "Général"
        case .appearance: "Apparence"
        case .shortcuts: "Raccourcis"
        case .sources: "Sources"
        case .about: "À propos"
        case .profile: "Mon espace"
        }
    }
    var symbol: String {
        switch self {
        case .general: "slider.horizontal.3"
        case .appearance: "circle.lefthalf.filled"
        case .shortcuts: "keyboard"
        case .sources: "globe.europe.africa"
        case .about: "info.circle"
        case .profile: "person.crop.circle"
        }
    }
    var searchTerms: String {
        switch self {
        case .general: "notifications seuils démarrage session lancement automatique arrière-plan"
        case .appearance: "thème palette couleurs système clair sombre position bandeau verre transparence teinte grain"
        case .shortcuts: "clavier touches hub navigation"
        case .sources: "connexion clé api webstat banque france insee bce eurostat bis ocde fed banque mondiale"
        case .about: "version soutien ko-fi aide"
        case .profile: "profil prénom nom photo identité"
        }
    }
}

struct SettingsView: View {
    private static let sidebarWidth: CGFloat = 230
    private static let searchSpacing: CGFloat = 8
    private static let searchPadding: CGFloat = 10
    private static let searchFill = Color.primary.opacity(0.06)
    private static let fieldCorner: CGFloat = 10
    private static let searchInsets = EdgeInsets(top: 18, leading: 14, bottom: 12, trailing: 14)
    private static let tabPadding: CGFloat = 7
    private static let profileSpacing: CGFloat = 10
    private static let profileAvatarSize: CGFloat = 28
    private static let profilePadding: CGFloat = 10
    private static let profileInset: CGFloat = 12
    private static let titleFont = Font.system(size: 25, weight: .semibold)
    private static let titleInsets = EdgeInsets(top: 26, leading: 28, bottom: 10, trailing: 28)
    private static let minimumWidth: CGFloat = 880
    private static let idealWidth: CGFloat = 980
    private static let minimumHeight: CGFloat = 660
    private static let idealHeight: CGFloat = 740
    private static let choiceLabelTop: CGFloat = 17
    private static let modeSpacing: CGFloat = 20
    private static let positionSpacing: CGFloat = 16
    private static let swatchCorner: CGFloat = 8
    private static let innerSwatchCorner: CGFloat = 5
    private static let innerSwatchInset: CGFloat = 12
    private static let swatchPadding: CGFloat = 4
    private static let swatchHeight: CGFloat = 58
    private static let selectedStroke: CGFloat = 2
    private static let paletteTitleLines = 2
    private static let paletteTitleHeight: CGFloat = 28
    private static let aboutSpacing: CGFloat = 18
    private static let markSize: CGFloat = 48
    private static let aboutTextSpacing: CGFloat = 5
    private static let nameFont = Font.system(size: 24, weight: .medium)
    private static let aboutPadding: CGFloat = 12
    @Environment(AppStore.self) private var store
    @State private var search = ""
    @FocusState private var searchFocused: Bool

    private var matches: [SettingsTab] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return SettingsTab.ordered.filter {
            query.isEmpty || ($0.title + " " + $0.searchTerms).localizedStandardContains(query)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack(spacing: Self.searchSpacing) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Rechercher", text: $search).textFieldStyle(.plain)
                        .focused($searchFocused).accessibilityLabel("Rechercher un réglage")
                        .onSubmit { if let first = matches.first { store.settingsTab = first; searchFocused = false } }
                        .onKeyPress(.escape) { search = ""; searchFocused = false; return .handled }
                    if !search.isEmpty {
                        Button { search = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                            .buttonStyle(.plain).accessibilityLabel("Effacer la recherche de réglages")
                    }
                }
                .font(.body).padding(Self.searchPadding)
                .background(Self.searchFill, in: RoundedRectangle(cornerRadius: Self.fieldCorner))
                .padding(Self.searchInsets)

                List(selection: Binding<SettingsTab?>(get: { store.settingsTab }, set: {
                    if let tab = $0 { store.settingsTab = tab }
                })) {
                    ForEach(matches.filter { $0 != .profile }, id: \.self) { tab in
                        Label(tab.title, systemImage: tab.symbol)
                            .font(.body.weight(.medium))
                            .padding(.vertical, Self.tabPadding).tag(tab)
                    }
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
                .overlay {
                    if matches.isEmpty {
                        Text("Aucun réglage trouvé").font(.callout).foregroundStyle(.secondary)
                    }
                }

                Button { store.settingsTab = .profile; searchFocused = false } label: {
                    HStack(spacing: Self.profileSpacing) {
                        ProfileAvatar(profile: store.profile, size: Self.profileAvatarSize)
                        Text("Mon espace").font(.body.weight(.medium))
                        Spacer()
                    }
                    .padding(Self.profilePadding)
                    .background(store.settingsTab == .profile ? Theme.sidebarSelection : .clear,
                                in: RoundedRectangle(cornerRadius: Self.fieldCorner))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain).padding(Self.profileInset)
                .accessibilityAddTraits(store.settingsTab == .profile ? [.isSelected] : [])
            }
            .frame(width: Self.sidebarWidth)
            .background(Theme.surface)
            Divider()
            VStack(alignment: .leading, spacing: 0) {
                Text(store.settingsTab.title).font(Self.titleFont)
                    .padding(Self.titleInsets)
                    .accessibilityAddTraits(.isHeader)
                settingsContent
                    .scrollContentBackground(.hidden)
                    .buttonStyle(.bordered)
                    .tint(store.palette.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Theme.background)
        }
        .navigationTitle("Réglages")
        .frame(minWidth: Self.minimumWidth, idealWidth: Self.idealWidth, minHeight: Self.minimumHeight, idealHeight: Self.idealHeight)
        .task { await store.checkWebstatKey() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            store.loginItem.refresh()
        }
    }

    @ViewBuilder private var settingsContent: some View {
        switch store.settingsTab {
        case .general: generalSettings
        case .appearance: appearanceSettings
        case .sources: SourceSettingsView()
        case .profile: ProfileSettingsView()
        case .shortcuts: ShortcutSettingsView()
        case .about: aboutSettings
        }
    }

    private var generalSettings: some View {
        Form {
            Section("Démarrage") {
                Toggle("Lancer à l’ouverture de session", isOn: Binding(
                    get: { store.loginItem.isEnabled }, set: { store.loginItem.setEnabled($0) }
                )).toggleStyle(.switch)
                if store.loginItem.needsApproval {
                    Button("Autoriser dans les réglages macOS…") { store.loginItem.openSettings() }
                        .buttonStyle(.borderless)
                }
                if let error = store.loginItem.error {
                    Text(error).font(.callout).foregroundStyle(.secondary)
                }
            }
            Section {
                Toggle("Notifications de seuil", isOn: Binding(
                    get: { store.preferences.notificationsEnabled },
                    set: { value in Task { await store.setNotificationsEnabled(value) } }
                )).toggleStyle(.switch)
            } header: { Text("Notifications") }
            .help("Actualisation quotidienne tant que sema tourne, même avec le hub fermé. Aucun suivi quand sema est quittée ou le Mac en veille.")
        }.formStyle(.grouped).onAppear { store.loginItem.refresh() }
    }

    private var appearanceSettings: some View {
        Form {
            Section("Affichage") {
                HStack(alignment: .top) {
                    Text("Mode").padding(.top, Self.choiceLabelTop)
                    Spacer(minLength: Self.modeSpacing)
                    ForEach(Appearance.allCases) { mode in
                        SettingsChoice(title: mode.title, symbol: appearanceSymbol(mode), selected: store.appearance == mode) {
                            store.setAppearance(mode)
                        }
                    }
                }.padding(.vertical, Theme.minorSpacing)
            }
            Section("Palette") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Theme.minorSpacing), count: Palette.allCases.count), spacing: Theme.minorSpacing) {
                    ForEach(Palette.allCases) { palette in
                        Button { store.setPalette(palette) } label: {
                            VStack(spacing: Theme.minorSpacing) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: Self.swatchCorner).fill(Palette.swatch(palette.swatches[0]))
                                    RoundedRectangle(cornerRadius: Self.innerSwatchCorner).fill(Palette.swatch(palette.swatches[1]))
                                        .padding(Self.innerSwatchInset)
                                }
                                .padding(Self.swatchPadding).frame(height: Self.swatchHeight)
                                .overlay(RoundedRectangle(cornerRadius: Self.swatchCorner).strokeBorder(
                                    store.palette == palette ? store.palette.accent : .clear, lineWidth: Self.selectedStroke))
                                Text(palette.title).font(.subheadline).lineLimit(Self.paletteTitleLines)
                                    .frame(maxWidth: .infinity, minHeight: Self.paletteTitleHeight, alignment: .top)
                            }.contentShape(Rectangle())
                        }
                        .buttonStyle(.plain).accessibilityLabel("Palette " + palette.title)
                        .accessibilityAddTraits(store.palette == palette ? [.isSelected] : [])
                    }
                }.padding(.vertical, Theme.minorSpacing)
            }
            Section("Bandeau") {
                HStack(alignment: .top) {
                    Text("Position").padding(.top, Self.choiceLabelTop)
                    Spacer(minLength: Self.positionSpacing)
                    ForEach(MenuRibbonPosition.allCases) { position in
                        SettingsChoice(title: position.title, symbol: position.symbol, selected: store.ribbonPosition == position) {
                            store.setRibbonPosition(position)
                        }
                    }
                }.padding(.vertical, Theme.minorSpacing)
            }
            RibbonGlassSettingsView()
        }.formStyle(.grouped)
    }

    private var aboutSettings: some View {
        Form {
            Section {
                HStack(spacing: Self.aboutSpacing) {
                    Symbol().frame(width: Self.markSize, height: Self.markSize)
                    VStack(alignment: .leading, spacing: Self.aboutTextSpacing) {
                        Text("sema").font(Self.nameFont)
                        Text("Gardez vos repères.").foregroundStyle(.secondary)
                        Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—")")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                }.padding(.vertical, Self.aboutPadding)
            }
            Section {
                HStack {
                    Text("sema est gratuite.")
                    Spacer()
                    Link("Soutenir sur Ko-fi", destination: Support.url)
                }
            }
        }.formStyle(.grouped)
    }

    private func appearanceSymbol(_ mode: Appearance) -> String {
        switch mode { case .system: "desktopcomputer"; case .light: "sun.max"; case .dark: "moon" }
    }
}

private struct SettingsChoice: View {
    private static let spacing: CGFloat = 7
    private static let symbolFont = Font.system(size: 18)
    private static let tileHeight: CGFloat = 48
    private static let restingFill = Color.primary.opacity(0.06)
    private static let corner: CGFloat = 8
    private static let selectedStroke: CGFloat = 2
    private static let width: CGFloat = 76
    @Environment(\.semaAccent) private var accent
    let title: String
    let symbol: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Self.spacing) {
                Image(systemName: symbol).font(Self.symbolFont)
                    .frame(maxWidth: .infinity).frame(height: Self.tileHeight)
                    .background(selected ? accent.opacity(Theme.selectionOpacity) : Self.restingFill, in: RoundedRectangle(cornerRadius: Self.corner))
                    .overlay(RoundedRectangle(cornerRadius: Self.corner).strokeBorder(selected ? accent : .clear, lineWidth: Self.selectedStroke))
                Text(title).font(.subheadline).lineLimit(1)
            }
            .frame(width: Self.width).contentShape(Rectangle())
        }
        .buttonStyle(.plain).accessibilityLabel(title)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}
