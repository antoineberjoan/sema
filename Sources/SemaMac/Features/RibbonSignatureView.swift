import AppKit
import SwiftUI

// SIGNATURE — une lecture, sans boucle. Le texte reste disponible à VoiceOver.
//    0 ms  Le cartouche est posé, le signe attend la fin de l’entrée du panneau.
//  300 ms  Le signe se trace pendant 1 800 ms, de la boucle vers le palier.
// 1250 ms  « L’économie bouge. » apparaît en fondu, sur 800 ms.
// 1850 ms  « Gardez vos repères. » se pose avec un ressort amorti, sur 800 ms.
// Réduire les animations : le cartouche est immédiatement dans son état final.
private enum SignatureMotion {
    static let drawDelay = 300
    static let contextDelay = 1_250
    static let missionDelay = 1_850
    static let drawDuration = 1.8
    static let textDuration = 0.8
    static let textOffset: CGFloat = 4
    static let lineWidth: CGFloat = 1.5
    static let markSize: CGFloat = 72
}

struct RibbonSignatureView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let presentationID: UUID?
    @State private var stage = 0
    @State private var formUnavailable = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SemaSignalPath().trim(from: 0, to: stage >= 1 ? 1 : 0)
                .stroke(.white, style: StrokeStyle(lineWidth: SignatureMotion.lineWidth, lineCap: .round, lineJoin: .round))
                .frame(width: SignatureMotion.markSize, height: SignatureMotion.markSize)
                .frame(height: 48).accessibilityHidden(true)
                .animation(reduceMotion ? nil : .easeInOut(duration: SignatureMotion.drawDuration), value: stage >= 1)
            Spacer(minLength: 8)
            Text("L’économie bouge.")
                .font(.system(size: 12)).foregroundStyle(.white.opacity(0.85))
                .opacity(stage >= 2 ? 1 : 0)
                .animation(reduceMotion ? nil : .easeOut(duration: SignatureMotion.textDuration), value: stage >= 2)
            Text("Gardez vos repères.")
                .font(.system(size: 18, weight: .medium)).tracking(-0.5).padding(.top, 3)
                .opacity(stage >= 3 ? 1 : 0)
                .offset(y: stage >= 3 || reduceMotion ? 0 : SignatureMotion.textOffset)
                .animation(reduceMotion ? nil : .spring(response: SignatureMotion.textDuration, dampingFraction: 1), value: stage >= 3)
            Button(action: openFeedback) {
                Label("Une idée ou un bug ?", systemImage: "bubble.left")
                    .font(.system(size: 11, weight: .medium)).padding(.horizontal, 10)
                    .frame(height: 26).background(.white.opacity(0.12), in: Capsule())
            }
            .buttonStyle(SemaPressStyle()).padding(.top, 18)
            .help(SemaFeedback.formURL == nil ? "Le formulaire de retour est en préparation" : "Ouvrir le formulaire Notion dans votre navigateur")
            .accessibilityLabel("Une idée ou un bug ? Ouvrir le formulaire Notion")
            .disabled(SemaFeedback.formURL == nil)
        }
        .foregroundStyle(.white)
        .padding(16).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background {
            let shape = RoundedRectangle(cornerRadius: MenuRibbonLayout.cardCornerRadius, style: .continuous)
            shape.fill(.black)
            shape.fill(LinearGradient(colors: [store.palette.signatureAccent.opacity(0.85), store.palette.signatureAccent.opacity(0.65)],
                                      startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        .overlay {
            RoundedRectangle(cornerRadius: MenuRibbonLayout.cardCornerRadius, style: .continuous)
                .strokeBorder(LinearGradient(colors: [.white.opacity(0.22), .white.opacity(0.03)],
                                              startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.5)
                .allowsHitTesting(false).accessibilityHidden(true)
        }
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 3)
        .task(id: presentationID) { await play() }
        .onChange(of: reduceMotion) { _, value in if value { stage = 3 } }
        .alert("Le formulaire n’a pas pu s’ouvrir", isPresented: $formUnavailable) {
            Button("Copier le lien") {
                guard let url = SemaFeedback.formURL else { return }
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(url.absoluteString, forType: .string)
            }
            Button("Fermer", role: .cancel) {}
        } message: {
            Text("Copiez le lien pour l’ouvrir dans votre navigateur.")
        }
    }

    private func openFeedback() {
        guard let url = SemaFeedback.formURL else { return }
        formUnavailable = !NSWorkspace.shared.open(url)
    }

    private func play() async {
        // A new presentation cancels the previous task before resetting its stage.
        var transaction = Transaction(); transaction.disablesAnimations = true
        withTransaction(transaction) { stage = reduceMotion || presentationID == nil ? 3 : 0 }
        guard !reduceMotion, presentationID != nil else { return }
        do {
            try await Task.sleep(for: .milliseconds(SignatureMotion.drawDelay))
            if !reduceMotion { stage = 1 }
            try await Task.sleep(for: .milliseconds(SignatureMotion.contextDelay - SignatureMotion.drawDelay))
            if !reduceMotion { stage = 2 }
            try await Task.sleep(for: .milliseconds(SignatureMotion.missionDelay - SignatureMotion.contextDelay))
            if !reduceMotion { stage = 3 }
        } catch { /* Presentation interrupted. */ }
    }
}
