// Organise les réglages en rubriques recherchables, avec un contenu natif et un profil fixé en bas.
import SemaDesign
import SwiftUI
import MarketCore

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
        case .general: "notifications alertes seuils mouvements inhabituels sensibilité brief matin heure démarrage session lancement automatique arrière-plan"
        case .appearance: "thème palette couleurs système clair sombre position bandeau verre transparence teinte grain"
        case .shortcuts: "clavier touches hub navigation"
        case .sources: "connexion clé api webstat banque france insee bce eurostat bis ocde fed banque mondiale fred titres communiqués synthèse claude apple intelligence"
        case .about: "version soutien ko-fi aide"
        case .profile: "profil prénom nom photo identité"
        }
    }
}

struct SettingsScreen: View {
    private static let searchSpacing = DesignIcon.gap
    private static let searchPadding = DesignSpace.frameInset
    private static let fieldCorner = DesignRadius.block
    private static let searchInsets = EdgeInsets(top: DesignSpace.cardInset, leading: DesignSpace.panelInsetInline, bottom: DesignSpace.menuInset, trailing: DesignSpace.panelInsetInline)
    private static let tabPadding = DesignSpace.rowInset
    private static let profileSpacing = DesignSpace.fieldGap
    private static let profilePadding = DesignSpace.frameInset
    private static let profileInset = DesignSpace.menuInset
    private static let titleInsets = EdgeInsets(top: DesignSpace.pageInsetNarrow, leading: DesignSpace.pageInsetNarrow, bottom: DesignSpace.frameInset, trailing: DesignSpace.pageInsetNarrow)
    private static let choiceLabelTop = DesignSpace.cardInset
    private static let modeSpacing = DesignSpace.groupGap
    private static let positionSpacing = DesignSpace.itemGap
    private static let swatchCorner = DesignRadius.block
    private static let innerSwatchCorner = DesignRadius.mark
    private static let innerSwatchInset = DesignSpace.menuInset
    private static let swatchPadding = DesignSpace.markInset
    private static let aboutSpacing = DesignSpace.itemGap
    private static let aboutTextSpacing = DesignSpace.titleGap
    private static let aboutPadding = DesignSpace.menuInset
    @Environment(AppStore.self) private var store
    @State private var search = ""
    @FocusState private var isSearchFocused: Bool

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
                    Image(systemName: "magnifyingglass").foregroundStyle(DesignColor.textMuted)
                    TextField("Rechercher", text: $search).textFieldStyle(.plain)
                        .focused($isSearchFocused).accessibilityLabel("Rechercher un réglage")
                        .onSubmit { if let first = matches.first { store.settingsTab = first; isSearchFocused = false } }
                        .onKeyPress(.escape) { search = ""; isSearchFocused = false; return .handled }
                    if !search.isEmpty {
                        Button { search = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(DesignColor.textMuted) }
                            .buttonStyle(.plain).accessibilityLabel("Effacer la recherche de réglages")
                    }
                }
                .typeRole(.body).padding(Self.searchPadding)
                .background(DesignColor.surfaceRaised, in: RoundedRectangle(cornerRadius: Self.fieldCorner))
                .padding(Self.searchInsets)

                List(selection: Binding<SettingsTab?>(get: { store.settingsTab }, set: {
                    if let tab = $0 { store.settingsTab = tab }
                })) {
                    ForEach(matches.filter { $0 != .profile }, id: \.self) { tab in
                        Label(tab.title, systemImage: tab.symbol)
                            .typeRole(.heading)
                            .padding(.vertical, Self.tabPadding).tag(tab)
                    }
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
                .overlay {
                    if matches.isEmpty {
                        Text("Aucun réglage trouvé").typeRole(.small).foregroundStyle(DesignColor.textMuted)
                    }
                }

                Button { store.settingsTab = .profile; isSearchFocused = false } label: {
                    HStack(spacing: Self.profileSpacing) {
                        ProfileAvatar(profile: store.profile, size: DesignLayout.settingsProfileAvatarSize)
                        Text("Mon espace").typeRole(.heading)
                        Spacer()
                    }
                    .padding(Self.profilePadding)
                    .background(store.settingsTab == .profile ? DesignColor.selection(store.palette) : .clear,
                                in: RoundedRectangle(cornerRadius: Self.fieldCorner))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain).padding(Self.profileInset)
                .accessibilityAddTraits(store.settingsTab == .profile ? [.isSelected] : [])
            }
            .frame(width: DesignLayout.settingsSidebarWidth)
            .background(DesignColor.surface)
            Divider()
            VStack(alignment: .leading, spacing: 0) {
                Text(store.settingsTab.title).typeRole(.title)
                    .padding(Self.titleInsets)
                    .accessibilityAddTraits(.isHeader)
                settingsContent
                    .scrollContentBackground(.hidden)
                    .buttonStyle(.bordered)
                    .tint(DesignColor.accentControl(store.palette))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(DesignColor.background)
        }
        .navigationTitle("Réglages")
        .frame(minWidth: DesignLayout.settingsMinimumWidth, idealWidth: DesignLayout.settingsIdealWidth, minHeight: DesignLayout.settingsMinimumHeight, idealHeight: DesignLayout.settingsIdealHeight)
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
                if store.loginItem.isApprovalRequired {
                    Button("Autoriser dans les réglages macOS…") { store.loginItem.openSettings() }
                        .buttonStyle(.borderless)
                }
                if let error = store.loginItem.error {
                    Text(error).typeRole(.small).foregroundStyle(DesignColor.textMuted)
                }
            }
            Section {
                Toggle("Notifications des alertes", isOn: Binding(
                    get: { store.preferences.canNotify },
                    set: { value in Task { await store.setNotificationsEnabled(value) } }
                )).toggleStyle(.switch)
                Picker(selection: Binding(get: { store.moveSensitivity }, set: { store.setMoveSensitivity($0) })) {
                    ForEach(MoveSensitivity.allCases) { Text($0.title).tag($0) }
                } label: {
                    VStack(alignment: .leading, spacing: DesignSpace.titleGap) {
                        Text("Mouvements inhabituels")
                        Text(sensitivityDescription).typeRole(.caption).foregroundStyle(DesignColor.textMuted)
                    }
                }
                .pickerStyle(.segmented)
            } header: { Text("Alertes") }
            .help("Actualisation quotidienne tant que sema tourne, même avec le hub fermé. Aucun suivi quand sema est quittée ou le Mac en veille.")
            Section {
                Toggle("Recevoir le brief", isOn: Binding(
                    get: { store.brief.isEnabled }, set: { value in Task { await store.setBriefEnabled(value) } }
                )).toggleStyle(.switch)
                DatePicker("Heure", selection: Binding(get: { briefTime }, set: { date in
                    let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                    store.setBrief { $0.hour = parts.hour ?? BriefPreferences.defaultHour; $0.minute = parts.minute ?? BriefPreferences.defaultMinute }
                }), displayedComponents: .hourAndMinute)
                .disabled(!store.brief.isEnabled)
                Toggle("Jours ouvrés seulement", isOn: Binding(get: { store.brief.isWeekdaysOnly }, set: { value in store.setBrief { $0.isWeekdaysOnly = value } }))
                    .disabled(!store.brief.isEnabled)
            } header: { Text("Brief du matin") } footer: {
                Text("Mouvements inhabituels de la dernière séance, seuils proches et agenda du jour. Envoyé au réveil si le Mac dormait à l’heure prévue.")
                    .typeRole(.caption).foregroundStyle(DesignColor.textMuted)
            }
        }.formStyle(.grouped).onAppear { store.loginItem.refresh() }
    }

    private var briefTime: Date {
        Calendar.current.date(bySettingHour: store.brief.hour, minute: store.brief.minute, second: 0, of: .now) ?? .now
    }

    private var sensitivityDescription: String {
        let sensitivity = store.moveSensitivity
        let perMonth = sensitivity.expectedAlertsPerYear / 12
        let monthly = Int(perMonth.rounded())
        let frequency = perMonth >= 1 ? "environ \(monthly) alerte\(monthly > 1 ? "s" : "") par mois et par repère"
            : sensitivity.expectedAlertsPerYear >= 1 ? "environ \(Int(sensitivity.expectedAlertsPerYear.rounded())) alertes par an et par repère"
            : "moins d’une alerte par an et par repère"
        return MarketFormat.ratio(sensitivity.multiplier) + " l’habituel · " + frequency + " en théorie"
    }

    private var appearanceSettings: some View {
        Form {
            Section("Affichage") {
                HStack(alignment: .top) {
                    Text("Mode").padding(.top, Self.choiceLabelTop)
                    Spacer(minLength: Self.modeSpacing)
                    ForEach(Appearance.allCases) { mode in
                        SettingsChoice(title: mode.title, symbol: appearanceSymbol(mode), isSelected: store.appearance == mode) {
                            store.setAppearance(mode)
                        }
                    }
                }.padding(.vertical, DesignSpace.rowInset)
            }
            Section("Palette") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DesignSpace.fieldGap), count: DesignPalette.allCases.count), spacing: DesignSpace.fieldGap) {
                    ForEach(DesignPalette.allCases, id: \.self) { palette in
                        Button { store.setPalette(palette) } label: {
                            VStack(spacing: DesignSpace.fieldGap) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: Self.swatchCorner).fill(DesignColor.palettePreview1(palette))
                                    RoundedRectangle(cornerRadius: Self.innerSwatchCorner).fill(DesignColor.palettePreview2(palette))
                                        .padding(Self.innerSwatchInset)
                                }
                                .padding(Self.swatchPadding).frame(height: DesignLayout.settingsSwatchHeight)
                                .overlay(RoundedRectangle(cornerRadius: Self.swatchCorner).strokeBorder(
                                    store.palette == palette ? DesignColor.accent(store.palette) : .clear, lineWidth: DesignLayout.selectedStroke))
                                Text(palette.title).typeRole(.caption).lineLimit(Int(DesignMeasure.settingsPaletteTitleLines))
                                    .frame(maxWidth: .infinity, minHeight: DesignLayout.settingsPaletteTitleHeight, alignment: .top)
                            }.contentShape(Rectangle())
                        }
                        .buttonStyle(.plain).accessibilityLabel("Palette " + palette.title)
                        .accessibilityAddTraits(store.palette == palette ? [.isSelected] : [])
                    }
                }.padding(.vertical, DesignSpace.rowInset)
            }
            Section("Bandeau") {
                HStack(alignment: .top) {
                    Text("Position").padding(.top, Self.choiceLabelTop)
                    Spacer(minLength: Self.positionSpacing)
                    ForEach(MenuRibbonPosition.allCases) { position in
                        SettingsChoice(title: position.title, symbol: position.symbol, isSelected: store.ribbonPosition == position) {
                            store.setRibbonPosition(position)
                        }
                    }
                }.padding(.vertical, DesignSpace.rowInset)
            }
            RibbonGlassSettingsView()
        }.formStyle(.grouped)
    }

    private var aboutSettings: some View {
        Form {
            Section {
                HStack(spacing: Self.aboutSpacing) {
                    Symbol().frame(width: DesignLayout.settingsMarkSize, height: DesignLayout.settingsMarkSize)
                    VStack(alignment: .leading, spacing: Self.aboutTextSpacing) {
                        Text("sema").typeRole(.title)
                        Text("Gardez vos repères.").foregroundStyle(DesignColor.textMuted)
                        Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—")")
                            .typeRole(.caption).foregroundStyle(DesignColor.textMuted)
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
    private static let spacing = DesignIcon.gap
    private static let corner = DesignRadius.block
    @Environment(\.palette) private var palette
    private var accent: Color { DesignColor.accent(palette) }
    let title: String
    let symbol: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Self.spacing) {
                Image(systemName: symbol).typeRole(.section)
                    .frame(maxWidth: .infinity).frame(height: DesignLayout.settingsChoiceTileHeight)
                    .background(isSelected ? DesignColor.selection(palette) : DesignColor.surface, in: RoundedRectangle(cornerRadius: Self.corner))
                    .overlay(RoundedRectangle(cornerRadius: Self.corner).strokeBorder(isSelected ? accent : .clear, lineWidth: DesignLayout.selectedStroke))
                Text(title).typeRole(.caption).lineLimit(1)
            }
            .frame(width: DesignLayout.settingsChoiceWidth).contentShape(Rectangle())
        }
        .buttonStyle(.plain).accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
