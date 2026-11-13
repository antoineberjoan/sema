// Orchestre le tracé du symbole et la signature à chaque ouverture, avec réduction des animations.
import AppKit
import SemaDesign
import SwiftUI

// SIGNATURE — une lecture, sans boucle. Le texte reste disponible à VoiceOver.
//    0 ms  Le cartouche est posé, le signe attend la fin de l’entrée du panneau.
//  100 ms  Le signe se trace pendant 550 ms, de la boucle vers le palier.
//  650 ms  Le point sarcelle et « L’économie bouge. » apparaissent en fondu, sur 200 ms.
//  700 ms  « Gardez vos repères. » se pose en fondu avec un léger décalage, sur 200 ms. La séquence finit à 900 ms.
// Réduire les animations : le cartouche est immédiatement dans son état final.
private enum SignatureMotion {
    // La ligne se dessine pendant `DesignDuration.explain` (vue à chaque ouverture, donc courte), puis le point et le
    // contexte apparaissent ensemble, la mission suit après `DesignMotion.stagger`.
    static let drawDuration = DesignDuration.explain
    static let contextDelay = Int(DesignDuration.signatureMotionDrawDelay * 1_000) + Int(drawDuration * 1_000)
    static let missionDelay = contextDelay + Int(DesignMotion.stagger * 1_000)
    static let textDuration = DesignDuration.standard
    static let textOffset = DesignMotion.shift
    static let lineWidth = SignalPath.stroke * DesignLayout.signatureMotionMarkSize / SignalPath.viewBox
    static let drawStage = 1
    static let contextStage = 2
    static let missionStage = 3
}

struct RibbonSignatureView: View {
    private static let titleTopPadding = DesignSpace.markInset
    private static let feedbackPadding = DesignSpace.frameInset
    private static let feedbackTopPadding = DesignSpace.cardInset
    @Environment(AppStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let presentationID: UUID?
    @State private var stage = 0
    @State private var isFormUnavailable = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                SignalPath().trim(from: 0, to: stage >= SignatureMotion.drawStage ? 1 : 0)
                    .stroke(DesignColor.onAccent, style: StrokeStyle(lineWidth: SignatureMotion.lineWidth, lineCap: .round, lineJoin: .round))
                // Le point sarcelle se pose quand la ligne est arrivée.
                SignalDot().fill(DesignColor.accentControl(.brand))
                    .opacity(stage >= SignatureMotion.contextStage ? 1 : 0)
                    .animation(reduceMotion ? nil : Animation.timingCurve(DesignEase.out, duration: SignatureMotion.textDuration), value: stage >= SignatureMotion.contextStage)
            }
                .frame(width: DesignLayout.signatureMotionMarkSize, height: DesignLayout.signatureMotionMarkSize)
                .frame(height: DesignLayout.ribbonSignatureMarkAreaHeight).accessibilityHidden(true)
                .animation(reduceMotion ? nil : Animation.timingCurve(DesignEase.inOut, duration: SignatureMotion.drawDuration), value: stage >= SignatureMotion.drawStage)
            Spacer(minLength: DesignSpace.fieldGap)
            Text("L’économie bouge.")
                .typeRole(.small).foregroundStyle(DesignColor.onAccent.opacity(DesignOpacity.signatureContextText))
                .opacity(stage >= SignatureMotion.contextStage ? 1 : 0)
                .animation(reduceMotion ? nil : Animation.timingCurve(DesignEase.out, duration: SignatureMotion.textDuration), value: stage >= SignatureMotion.contextStage)
            Text("Gardez vos repères.")
                .typeRole(.section).padding(.top, Self.titleTopPadding)
                .opacity(stage >= SignatureMotion.missionStage ? 1 : 0)
                .offset(y: stage >= SignatureMotion.missionStage || reduceMotion ? 0 : SignatureMotion.textOffset)
                .animation(reduceMotion ? nil : Animation.timingCurve(DesignEase.out, duration: SignatureMotion.textDuration), value: stage >= SignatureMotion.missionStage)
            Button(action: openFeedback) {
                Label("Une idée ou un bug ?", systemImage: "bubble.left")
                    .typeRole(.overline).padding(.horizontal, Self.feedbackPadding)
                    .frame(height: DesignLayout.ribbonSignatureFeedbackHeight).background(DesignColor.onAccent.opacity(DesignOpacity.signatureFeedbackFill), in: Capsule())
            }
            .buttonStyle(PressStyle()).padding(.top, Self.feedbackTopPadding)
            .help(FeedbackClient.formURL == nil ? "Le formulaire de retour est en préparation" : "Ouvrir le formulaire Notion dans votre navigateur")
            .accessibilityLabel("Une idée ou un bug ? Ouvrir le formulaire Notion")
            .disabled(FeedbackClient.formURL == nil)
        }
        .foregroundStyle(DesignColor.onAccent)
        .padding(MenuRibbonLayout.cardPadding).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background {
            let shape = RoundedRectangle(cornerRadius: DesignRadius.card, style: .continuous)
            shape.fill(DesignColor.signatureBase)
            shape.fill(LinearGradient(colors: [DesignColor.accentControl(store.palette).opacity(DesignOpacity.signatureGradientTop), DesignColor.accentControl(store.palette).opacity(DesignOpacity.signatureGradientBottom)],
                                      startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        .overlay {
            RoundedRectangle(cornerRadius: DesignRadius.card, style: .continuous)
                .strokeBorder(LinearGradient(colors: [DesignColor.onAccent.opacity(DesignOpacity.signatureEdgeTop), DesignColor.onAccent.opacity(DesignOpacity.signatureEdgeBottom)],
                                              startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: DesignBorder.width)
                .allowsHitTesting(false).accessibilityHidden(true)
        }
        .elevation(DesignElevation.floating)
        .task(id: presentationID) { await play() }
        .onChange(of: reduceMotion) { _, value in if value { stage = SignatureMotion.missionStage } }
        .alert("Le formulaire n’a pas pu s’ouvrir", isPresented: $isFormUnavailable) {
            Button("Copier le lien") {
                guard let url = FeedbackClient.formURL else { return }
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(url.absoluteString, forType: .string)
            }
            Button("Fermer", role: .cancel) {}
        } message: {
            Text("Copiez le lien pour l’ouvrir dans votre navigateur.")
        }
    }

    private func openFeedback() {
        guard let url = FeedbackClient.formURL else { return }
        isFormUnavailable = !NSWorkspace.shared.open(url)
    }

    private func play() async {
        // Une nouvelle présentation annule la tâche précédente avant de remettre sa scène à zéro.
        var transaction = Transaction(); transaction.disablesAnimations = true
        withTransaction(transaction) { stage = reduceMotion || presentationID == nil ? SignatureMotion.missionStage : 0 }
        guard !reduceMotion, presentationID != nil else { return }
        do {
            try await Task.sleep(for: .milliseconds(Int(DesignDuration.signatureMotionDrawDelay * 1_000)))
            if !reduceMotion { stage = SignatureMotion.drawStage }
            try await Task.sleep(for: .milliseconds(SignatureMotion.contextDelay - Int(DesignDuration.signatureMotionDrawDelay * 1_000)))
            if !reduceMotion { stage = SignatureMotion.contextStage }
            try await Task.sleep(for: .milliseconds(SignatureMotion.missionDelay - SignatureMotion.contextDelay))
            if !reduceMotion { stage = SignatureMotion.missionStage }
        } catch { /* Présentation interrompue. */ }
    }
}
