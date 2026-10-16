import SwiftUI
import UniformTypeIdentifiers

struct ProfileSettingsView: View {
    @Environment(AppStore.self) private var store
    @State private var showsImporter = false
    @State private var isImporting = false
    @State private var importError: String?

    var body: some View {
        Form {
            Section {
                HStack(spacing: 20) {
                    ProfileAvatar(profile: store.profile, size: 76)
                    VStack(alignment: .leading, spacing: 10) {
                        Text(store.profile.displayName.isEmpty ? "Votre espace" : store.profile.displayName)
                            .font(.system(size: 20, weight: .medium))
                        HStack(spacing: 14) {
                            Button(isImporting ? "Importation…" : "Choisir une photo…") { showsImporter = true }
                                .disabled(isImporting)
                            if store.profile.avatarJPEG != nil {
                                Button("Retirer") {
                                    var profile = store.profile; profile.avatarJPEG = nil; store.setProfile(profile)
                                }.disabled(isImporting)
                            }
                        }.font(.system(size: 12))
                    }
                    Spacer()
                }.padding(.vertical, 12)
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
                    .font(.system(size: 12)).foregroundStyle(.secondary)
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
