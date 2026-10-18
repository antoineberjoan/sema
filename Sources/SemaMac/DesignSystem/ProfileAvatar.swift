// Affiche la photo locale ou les initiales du profil dans les surfaces de l’app.
import AppKit
import SwiftUI
import MarketCore

struct ProfileAvatar: View {
    private static let placeholderFill = Color.primary.opacity(0.06)
    private static let initialsScale: CGFloat = 0.34
    private static let symbolScale: CGFloat = 0.4
    let profile: LocalProfile
    var size: CGFloat = 32

    var body: some View {
        ZStack {
            Circle().fill(Self.placeholderFill)
            if let data = profile.avatarJPEG, let image = NSImage(data: data) {
                Image(nsImage: image).resizable().scaledToFill()
            } else if !profile.initials.isEmpty {
                Text(profile.initials).font(.system(size: size * Self.initialsScale, weight: .medium))
            } else {
                Image(systemName: "person.fill").font(.system(size: size * Self.symbolScale)).foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size).clipShape(Circle()).accessibilityHidden(true)
    }
}
