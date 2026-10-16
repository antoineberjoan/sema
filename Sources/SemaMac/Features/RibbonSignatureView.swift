import SwiftUI

// SIGNATURE — une lecture, sans boucle. Le texte reste disponible à VoiceOver.
//    0 ms  Le cartouche est posé, le signe attend la fin de l’entrée du panneau.
//  240 ms  Le signe se trace pendant 920 ms, de la boucle vers la sortie.
//  660 ms  « L’économie bouge. » apparaît en fondu, sur 420 ms.
//  900 ms  « Gardez vos repères. » se pose avec un ressort amorti, sur 420 ms.
// Réduire les animations : le cartouche est immédiatement dans son état final.
private enum SignatureMotion {
    static let drawDelay = 240
    static let contextDelay = 660
    static let missionDelay = 900
    static let drawDuration = 0.92
    static let textDuration = 0.42
    static let textOffset: CGFloat = 4
    static let lineWidth: CGFloat = 1.5
    static let markSize: CGFloat = 86
}

struct RibbonSignatureView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let presentationID: UUID?
    @State private var stage = 0
    @State private var replayID = UUID()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text("SEMA").font(.system(size: 10, weight: .medium)).tracking(2).foregroundStyle(.secondary)
                Spacer()
                Button { replayID = UUID() } label: {
                    Image(systemName: "arrow.counterclockwise").font(.system(size: 10)).foregroundStyle(.secondary)
                        .frame(width: 22, height: 22).contentShape(Circle())
                }
                .buttonStyle(.plain).help("Rejouer la signature").accessibilityLabel("Rejouer la signature de Sema")
            }
            Spacer(minLength: 0)
            SemaSignalPath().trim(from: 0, to: stage >= 1 ? 1 : 0)
                .stroke(.primary, style: StrokeStyle(lineWidth: SignatureMotion.lineWidth, lineCap: .round, lineJoin: .round))
                .frame(width: SignatureMotion.markSize, height: SignatureMotion.markSize)
                .frame(height: 49).accessibilityHidden(true)
                .animation(reduceMotion ? nil : .easeInOut(duration: SignatureMotion.drawDuration), value: stage >= 1)
            Spacer(minLength: 6)
            Text("L’économie bouge.")
                .font(.system(size: 12)).foregroundStyle(.secondary)
                .opacity(stage >= 2 ? 1 : 0)
                .animation(reduceMotion ? nil : .easeOut(duration: SignatureMotion.textDuration), value: stage >= 2)
            Text("Gardez vos repères.")
                .font(.system(size: 18, weight: .medium)).tracking(-0.5).padding(.top, 3)
                .opacity(stage >= 3 ? 1 : 0)
                .offset(y: stage >= 3 || reduceMotion ? 0 : SignatureMotion.textOffset)
                .animation(reduceMotion ? nil : .spring(response: SignatureMotion.textDuration, dampingFraction: 1), value: stage >= 3)
        }
        .padding(18).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .modifier(RibbonSurface(emphasized: true))
        .task(id: [presentationID, replayID]) { await play() }
        .onChange(of: reduceMotion) { _, value in if value { stage = 3 } }
    }

    private func play() async {
        // A new presentation or replay cancels the previous task before resetting its stage.
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
        } catch { /* Presentation or replay interrupted. */ }
    }
}
