// Permet de modifier le profil de ce Mac et sa photo sans créer de compte.
import SwiftUI
import UniformTypeIdentifiers

struct ProfileSettingsView: View {
    private static let avatarSize: CGFloat = 56
    @Environment(AppStore.self) private var store
    @State private var showsImporter = false
    @State private var isImporting = false
    @State private var importError: String?

    var body: some View {
        Form {
            Section {
                HStack(spacing: SemaTheme.majorSpacing) {
                    Button { showsImporter = true } label: {
                        ProfileAvatar(profile: store.profile, size: Self.avatarSize)
                    }
                    .buttonStyle(.plain).disabled(isImporting)
                    .accessibilityLabel("Modifier la photo")
                    VStack(alignment: .leading, spacing: SemaTheme.minorSpacing) {
                        if !store.profile.displayName.isEmpty {
                            Text(store.profile.displayName).font(.title3.weight(.medium))
                        }
                        Button(isImporting ? "Importation…" : store.profile.avatarJPEG == nil ? "Ajouter une photo…" : "Modifier la photo…") {
                            showsImporter = true
                        }.disabled(isImporting)
                        if store.profile.avatarJPEG != nil {
                            Button("Retirer la photo", role: .destructive) {
                                var profile = store.profile; profile.avatarJPEG = nil; store.setProfile(profile)
                            }.disabled(isImporting)
                        }
                    }.buttonStyle(.link)
                    Spacer()
                }.padding(.vertical, SemaTheme.minorSpacing)
            }
            Section {
                TextField("Prénom", text: Binding(get: { store.profile.firstName }, set: {
                    var profile = store.profile; profile.firstName = $0; store.setProfile(profile)
                })).textContentType(.givenName)
                TextField("Nom", text: Binding(get: { store.profile.lastName }, set: {
                    var profile = store.profile; profile.lastName = $0; store.setProfile(profile)
                })).textContentType(.familyName)
            }
            .help("Profil conservé sur ce Mac. Les métadonnées de la photo sont retirées.")
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
