// Permet de modifier le profil de ce Mac et sa photo sans créer de compte.
import SwiftUI
import UniformTypeIdentifiers

struct ProfileSettingsView: View {
    private static let avatarSize: CGFloat = 76
    private static let nameFont = Font.system(size: 20, weight: .medium)
    private static let avatarSpacing: CGFloat = 20
    private static let nameSpacing: CGFloat = 10
    private static let actionSpacing: CGFloat = 14
    private static let headerPadding: CGFloat = 12
    @Environment(AppStore.self) private var store
    @State private var showsImporter = false
    @State private var isImporting = false
    @State private var importError: String?

    var body: some View {
        Form {
            Section {
                HStack(spacing: Self.avatarSpacing) {
                    ProfileAvatar(profile: store.profile, size: Self.avatarSize)
                    VStack(alignment: .leading, spacing: Self.nameSpacing) {
                        Text(store.profile.displayName.isEmpty ? "Votre espace" : store.profile.displayName)
                            .font(Self.nameFont)
                        HStack(spacing: Self.actionSpacing) {
                            Button(isImporting ? "Importation…" : "Choisir une photo…") { showsImporter = true }
                                .disabled(isImporting)
                            if store.profile.avatarJPEG != nil {
                                Button("Retirer") {
                                    var profile = store.profile; profile.avatarJPEG = nil; store.setProfile(profile)
                                }.disabled(isImporting)
                            }
                        }.font(.callout)
                    }
                    Spacer()
                }.padding(.vertical, Self.headerPadding)
            }
            Section("Identité") {
                TextField("Prénom", text: Binding(get: { store.profile.firstName }, set: {
                    var profile = store.profile; profile.firstName = $0; store.setProfile(profile)
                }))
                .textContentType(.givenName)
                TextField("Nom", text: Binding(get: { store.profile.lastName }, set: {
                    var profile = store.profile; profile.lastName = $0; store.setProfile(profile)
                }))
                .textContentType(.familyName)
            }
            Section {
                Text("Ces informations sont facultatives et restent sur ce Mac. La photo est recadrée au centre et enregistrée en petit format, sans les métadonnées du fichier d’origine.")
                    .font(.callout).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .fileImporter(isPresented: $showsImporter, allowedContentTypes: [.image]) { result in
            switch result {
            case .failure(let error): importError = error.localizedDescription
            case .success(let url):
                isImporting = true
                Task {
                    defer { isImporting = false }
                    do {
                        let data = try await Task.detached(priority: .userInitiated) { try ProfilePhoto.prepare(url) }.value
                        var profile = store.profile; profile.avatarJPEG = data
                        if !store.setProfile(profile) { importError = store.errorMessage }
                    } catch { importError = error.localizedDescription }
                }
            }
        }
        .alert("Photo de profil", isPresented: Binding(get: { importError != nil }, set: { if !$0 { importError = nil } })) {
            Button("Compris", role: .cancel) { importError = nil }
        } message: { Text(importError ?? "") }
    }
}
