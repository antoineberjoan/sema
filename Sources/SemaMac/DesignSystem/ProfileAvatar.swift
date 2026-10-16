import AppKit
import SwiftUI
import MarketCore

struct ProfileAvatar: View {
    let profile: LocalProfile
    var size: CGFloat = 32

    var body: some View {
        ZStack {
            Circle().fill(Color.primary.opacity(0.06))
            if let data = profile.avatarJPEG, let image = NSImage(data: data) {
                Image(nsImage: image).resizable().scaledToFill()
            } else if !profile.initials.isEmpty {
                Text(profile.initials).font(.system(size: size * 0.34, weight: .medium))
            } else {
                Image(systemName: "person.fill").font(.system(size: size * 0.4)).foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size).clipShape(Circle()).accessibilityHidden(true)
    }
}
