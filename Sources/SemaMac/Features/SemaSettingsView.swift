// Réunit les rubriques de réglages dans la fenêtre native de sema.
import SwiftUI

struct SemaSettingsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        @Bindable var store = store
        TabView(selection: $store.settingsTab) {
            Form {
                Section("Repères") {
                    LabeledContent("Repères") { Text(store.originSummary) }
                    HStack {
                        Button("Actualiser les repères") { Task { await store.refreshSeries() } }
                            .disabled(store.isLoading || !store.canRefresh)
                        Button("Afficher la démonstration") { store.restoreDemo() }.disabled(store.isLoading)
                    }
                    Text("Chaque repère conserve son unité, sa période et ses conditions de réutilisation. « Tout » charge l’historique disponible auprès de sa source, à la demande.")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Section("Premiers pas") {
                    Button("Revoir l’accueil de sema") {
                        store.beginOnboarding()
                        openWindow(id: "workspace")
                    }
                    Text("Retrouvez la sélection de départ et la connexion Webstat. Vos repères personnels sont conservés.")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Section("Notifications") {
                    Toggle("Autoriser les notifications de seuil et les tests", isOn: Binding(
                        get: { store.preferences.notificationsEnabled },
                        set: { value in Task { await store.setNotificationsEnabled(value) } }
                    ))
                    Text("Les seuils sont vérifiés à chaque actualisation des repères. Les signaux restent visibles dans sema sans notification système. Aucun contrôle quand l’app est quittée ou le Mac en veille.")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .tabItem { Label("Général", systemImage: "slider.horizontal.3") }
            .tag(SemaSettingsTab.general)
            SourceSettingsView()
                .tabItem { Label("Sources", systemImage: "globe.europe.africa") }.tag(SemaSettingsTab.sources)
            ProfileSettingsView()
                .tabItem { Label("Profil", systemImage: "person.crop.circle") }.tag(SemaSettingsTab.profile)
            Form {
                Section("Mode d’affichage") {
                    Picker("Apparence", selection: Binding(get: { store.appearance }, set: { store.setAppearance($0) })) {
                        ForEach(SemaAppearance.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Bandeau des favoris") {
                    Picker("Position à l’écran", selection: Binding(get: { store.ribbonPosition }, set: { store.setRibbonPosition($0) })) {
                        ForEach(MenuRibbonPosition.allCases) { position in
                            Label(position.title, systemImage: position.symbol).tag(position)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text("Au clic sur l’icône sema, retrouvez vos favoris sur le bord choisi. La matière translucide suit le mode d’affichage et la palette choisis.")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
                Section("Couleurs de sema") {
                    Picker("Thème", selection: Binding(get: { store.palette }, set: { store.setPalette($0) })) {
                        ForEach(SemaPalette.allCases) { Text($0.title).tag($0) }
                    }
                    HStack(spacing: 8) {
                        ForEach(store.palette.swatches, id: \.self) { hex in
                            RoundedRectangle(cornerRadius: 8).fill(SemaPalette.swatch(hex))
                                .frame(height: 52).accessibilityLabel(String(format: "#%06X", hex))
                        }
                    }
                    .accessibilityElement(children: .combine)
                    Text("La palette colore les courbes, les contrôles et légèrement le verre du bandeau. Elle reste identique lorsque vous changez de mode d’affichage.")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
                RibbonGlassSettingsView()
            }
            .formStyle(.grouped)
            .tabItem { Label("Apparence", systemImage: "paintpalette") }
            .tag(SemaSettingsTab.appearance)
            VStack(spacing: 14) {
                SemaMark(size: 64)
                Text("sema").font(.system(size: 28, weight: .medium)).tracking(-1)
                Text("Vos repères, à portée de main.").foregroundStyle(.secondary)
                Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—") · macOS 14+")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                Text("SwiftUI · AppKit · Swift Charts\nAucune bibliothèque externe.")
                    .font(.system(size: 11)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                Text("sema est gratuite. Vous pouvez soutenir son développement sur Ko-fi.")
                    .font(.system(size: 12)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    .frame(maxWidth: 330).padding(.top, 14)
                Link(destination: SemaSupport.url) { Label("Soutenir sema", systemImage: "heart") }
                    .font(.system(size: 13))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .tabItem { Label("À propos", systemImage: "info.circle") }
            .tag(SemaSettingsTab.about)
        }
        .padding(15).frame(width: 620, height: 650)
        .task { await store.checkWebstatKey() }
    }
}
