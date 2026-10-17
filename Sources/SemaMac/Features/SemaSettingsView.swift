// Organise les réglages en rubriques recherchables, avec un contenu natif et un profil fixé en bas.
import SwiftUI

private extension SemaSettingsTab {
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

struct SemaSettingsView: View {
    @Environment(AppStore.self) private var store
    @State private var search = ""
    @FocusState private var searchFocused: Bool

    private var matches: [SemaSettingsTab] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return SemaSettingsTab.ordered.filter {
            query.isEmpty || ($0.title + " " + $0.searchTerms).localizedStandardContains(query)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
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
                .font(.system(size: 13)).padding(10)
                .background(.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 14).padding(.top, 18).padding(.bottom, 12)

                List(selection: Binding<SemaSettingsTab?>(get: { store.settingsTab }, set: {
                    if let tab = $0 { store.settingsTab = tab }
                })) {
                    ForEach(matches.filter { $0 != .profile }, id: \.self) { tab in
                        Label(tab.title, systemImage: tab.symbol)
                            .font(.system(size: 13, weight: .medium))
                            .padding(.vertical, 7).tag(tab)
                    }
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
                .overlay {
                    if matches.isEmpty {
                        Text("Aucun réglage trouvé").font(.system(size: 12)).foregroundStyle(.secondary)
                    }
                }

                Button { store.settingsTab = .profile; searchFocused = false } label: {
                    HStack(spacing: 10) {
                        ProfileAvatar(profile: store.profile, size: 28)
                        Text("Mon espace").font(.system(size: 13, weight: .medium))
                        Spacer()
                    }
                    .padding(10)
                    .background(store.settingsTab == .profile ? SemaTheme.sidebarSelection : .clear,
                                in: RoundedRectangle(cornerRadius: 10))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain).padding(12)
                .accessibilityAddTraits(store.settingsTab == .profile ? .isSelected : [])
            }
            .frame(width: 230)
            .background(SemaTheme.surface)
            Divider()
            VStack(alignment: .leading, spacing: 0) {
                Text(store.settingsTab.title).font(.system(size: 25, weight: .semibold))
                    .padding(.horizontal, 28).padding(.top, 26).padding(.bottom, 10)
                    .accessibilityAddTraits(.isHeader)
                settingsContent
                    .scrollContentBackground(.hidden)
                    .buttonStyle(.bordered)
                    .tint(store.palette.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(SemaTheme.background)
        }
        .navigationTitle("Réglages")
        .frame(minWidth: 880, idealWidth: 980, minHeight: 660, idealHeight: 740)
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
                    Text("Mode").padding(.top, 17)
                    Spacer(minLength: 20)
                    ForEach(SemaAppearance.allCases) { mode in
                        SettingsChoice(title: mode.title, symbol: appearanceSymbol(mode), selected: store.appearance == mode) {
                            store.setAppearance(mode)
                        }
                    }
                }.padding(.vertical, 8)
            }
            Section("Palette") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: SemaPalette.allCases.count), spacing: 8) {
                    ForEach(SemaPalette.allCases) { palette in
                        Button { store.setPalette(palette) } label: {
                            VStack(spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8).fill(SemaPalette.swatch(palette.swatches[0]))
                                    RoundedRectangle(cornerRadius: 5).fill(SemaPalette.swatch(palette.swatches[1]))
                                        .padding(12)
                                }
                                .padding(4).frame(height: 58)
                                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(
                                    store.palette == palette ? store.palette.accent : .clear, lineWidth: 2))
                                Text(palette.title).font(.system(size: 11)).lineLimit(2)
                                    .frame(maxWidth: .infinity, minHeight: 28, alignment: .top)
                            }.contentShape(Rectangle())
                        }
                        .buttonStyle(.plain).accessibilityLabel("Palette " + palette.title)
                        .accessibilityAddTraits(store.palette == palette ? .isSelected : [])
                    }
                }.padding(.vertical, 8)
            }
            Section("Bandeau") {
                HStack(alignment: .top) {
                    Text("Position").padding(.top, 17)
                    Spacer(minLength: 16)
                    ForEach(MenuRibbonPosition.allCases) { position in
                        SettingsChoice(title: position.title, symbol: position.symbol, selected: store.ribbonPosition == position) {
                            store.setRibbonPosition(position)
                        }
                    }
                }.padding(.vertical, 8)
            }
            RibbonGlassSettingsView()
        }.formStyle(.grouped)
    }

    private var aboutSettings: some View {
        Form {
            Section {
                HStack(spacing: 18) {
                    SemaMark(size: 48)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("sema").font(.system(size: 24, weight: .medium))
                        Text("Gardez vos repères.").foregroundStyle(.secondary)
                        Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—")")
                            .font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                }.padding(.vertical, 12)
            }
            Section {
                HStack {
                    Text("sema est gratuite.")
                    Spacer()
                    Link("Soutenir sur Ko-fi", destination: SemaSupport.url)
                }
            }
        }.formStyle(.grouped)
    }

    private func appearanceSymbol(_ mode: SemaAppearance) -> String {
        switch mode { case .system: "desktopcomputer"; case .light: "sun.max"; case .dark: "moon" }
    }
}

private struct SettingsChoice: View {
    @Environment(\.semaAccent) private var accent
    let title: String
    let symbol: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: symbol).font(.system(size: 18))
                    .frame(maxWidth: .infinity).frame(height: 48)
                    .background(selected ? accent.opacity(0.12) : .primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(selected ? accent : .clear, lineWidth: 2))
                Text(title).font(.system(size: 11)).lineLimit(1)
            }
            .frame(width: 76).contentShape(Rectangle())
        }
        .buttonStyle(.plain).accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
