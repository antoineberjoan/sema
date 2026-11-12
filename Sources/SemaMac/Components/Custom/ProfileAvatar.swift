// Affiche la photo locale ou les initiales du profil dans les surfaces de l’app.
// @documentation https://developer.apple.com/documentation/swiftui/image
// @decision docs/decisions/2026-11-12-composant-profile-avatar.md
import AppKit
import SemaDesign
import SwiftUI
import MarketCore

struct ProfileAvatar: View {
    private static let placeholderFill = DesignColor.text.opacity(DesignOpacity.glassRest)
    let profile: LocalProfile
    var size = DesignLayout.profileAvatarDefaultSize

    var body: some View {
        ZStack {
            Circle().fill(Self.placeholderFill)
            if let data = profile.avatarJPEG, let image = NSImage(data: data) {
                Image(nsImage: image).resizable().scaledToFill()
            } else if !profile.initials.isEmpty {
                Text(profile.initials).font(.system(size: size * CGFloat(DesignMeasure.avatarInitialsScale), weight: DesignType.labelWeight))
            } else {
                Image(systemName: "person.fill").font(.system(size: size * CGFloat(DesignMeasure.avatarSymbolScale))).foregroundStyle(DesignColor.textMuted)
            }
        }
        .frame(width: size, height: size).clipShape(Circle()).accessibilityHidden(true)
    }
}
