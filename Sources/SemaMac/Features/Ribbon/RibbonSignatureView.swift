// Orchestre le tracé du symbole et la signature à chaque ouverture, avec réduction des animations.
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
    static let drawStage = 1
    static let contextStage = 2
    static let missionStage = 3
}

struct RibbonSignatureView: View {
    private static let titleFont = Font.system(size: 18, weight: .medium)
    private static let titleTracking: CGFloat = -0.5
    private static let titleTopPadding: CGFloat = 3
    private static let markAreaHeight: CGFloat = 48
    private static let contextOpacity = 0.85
    private static let feedbackPadding: CGFloat = 10
    private static let feedbackHeight: CGFloat = 26
    private static let feedbackFillOpacity = 0.12
    private static let feedbackTopPadding: CGFloat = 18
    private static let backgroundTopOpacity = 0.85
    private static let backgroundBottomOpacity = 0.65
    private static let edgeTopOpacity = 0.22
    private static let edgeBottomOpacity = 0.03
    @Environment(AppStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let presentationID: UUID?
    @State private var stage = 0
    @State private var formUnavailable = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SignalPath().trim(from: 0, to: stage >= SignatureMotion.drawStage ? 1 : 0)
                .stroke(.white, style: StrokeStyle(lineWidth: SignatureMotion.lineWidth, lineCap: .round, lineJoin: .round))
                .frame(width: SignatureMotion.markSize, height: SignatureMotion.markSize)
                .frame(height: Self.markAreaHeight).accessibilityHidden(true)
                .animation(reduceMotion ? nil : .easeInOut(duration: SignatureMotion.drawDuration), value: stage >= SignatureMotion.drawStage)
            Spacer(minLength: Theme.minorSpacing)
            Text("L’économie bouge.")
                .font(.callout).foregroundStyle(.white.opacity(Self.contextOpacity))
                .opacity(stage >= SignatureMotion.contextStage ? 1 : 0)
                .animation(reduceMotion ? nil : .easeOut(duration: SignatureMotion.textDuration), value: stage >= SignatureMotion.contextStage)
            Text("Gardez vos repères.")
                .font(Self.titleFont).tracking(Self.titleTracking).padding(.top, Self.titleTopPadding)
                .opacity(stage >= SignatureMotion.missionStage ? 1 : 0)
                .offset(y: stage >= SignatureMotion.missionStage || reduceMotion ? 0 : SignatureMotion.textOffset)
                .animation(reduceMotion ? nil : .spring(response: SignatureMotion.textDuration, dampingFraction: 1), value: stage >= SignatureMotion.missionStage)
            Button(action: openFeedback) {
                Label("Une idée ou un bug ?", systemImage: "bubble.left")
                    .font(.subheadline.weight(.medium)).padding(.horizontal, Self.feedbackPadding)
                    .frame(height: Self.feedbackHeight).background(.white.opacity(Self.feedbackFillOpacity), in: Capsule())
            }
            .buttonStyle(PressStyle()).padding(.top, Self.feedbackTopPadding)
            .help(Feedback.formURL == nil ? "Le formulaire de retour est en préparation" : "Ouvrir le formulaire Notion dans votre navigateur")
            .accessibilityLabel("Une idée ou un bug ? Ouvrir le formulaire Notion")
            .disabled(Feedback.formURL == nil)
        }
        .foregroundStyle(.white)
        .padding(MenuRibbonLayout.cardPadding).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background {
            let shape = RoundedRectangle(cornerRadius: Theme.surfaceCorner, style: .continuous)
            shape.fill(.black)
            shape.fill(LinearGradient(colors: [store.palette.signatureAccent.opacity(Self.backgroundTopOpacity), store.palette.signatureAccent.opacity(Self.backgroundBottomOpacity)],
                                      startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        .overlay {
            RoundedRectangle(cornerRadius: Theme.surfaceCorner, style: .continuous)
                .strokeBorder(LinearGradient(colors: [.white.opacity(Self.edgeTopOpacity), .white.opacity(Self.edgeBottomOpacity)],
                                              startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: Theme.hairline)
                .allowsHitTesting(false).accessibilityHidden(true)
        }
        .shadow(.card)
        .task(id: presentationID) { await play() }
        .onChange(of: reduceMotion) { _, value in if value { stage = SignatureMotion.missionStage } }
        .alert("Le formulaire n’a pas pu s’ouvrir", isPresented: $formUnavailable) {
            Button("Copier le lien") {
                guard let url = Feedback.formURL else { return }
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(url.absoluteString, forType: .string)
            }
            Button("Fermer", role: .cancel) {}
        } message: {
            Text("Copiez le lien pour l’ouvrir dans votre navigateur.")
        }
    }

    private func openFeedback() {
        guard let url = Feedback.formURL else { return }
        formUnavailable = !NSWorkspace.shared.open(url)
    }

    private func play() async {
        // A new presentation cancels the previous task before resetting its stage.
        var transaction = Transaction(); transaction.disablesAnimations = true
        withTransaction(transaction) { stage = reduceMotion || presentationID == nil ? SignatureMotion.missionStage : 0 }
        guard !reduceMotion, presentationID != nil else { return }
        do {
            try await Task.sleep(for: .milliseconds(SignatureMotion.drawDelay))
            if !reduceMotion { stage = SignatureMotion.drawStage }
            try await Task.sleep(for: .milliseconds(SignatureMotion.contextDelay - SignatureMotion.drawDelay))
            if !reduceMotion { stage = SignatureMotion.contextStage }
            try await Task.sleep(for: .milliseconds(SignatureMotion.missionDelay - SignatureMotion.contextDelay))
            if !reduceMotion { stage = SignatureMotion.missionStage }
        } catch { /* Presentation interrupted. */ }
    }
}
