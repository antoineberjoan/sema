// Destination d’une notification : le repère et son contexte, ou une rubrique, retrouvée au clic dans les informations de la notification.
import Foundation

enum NotificationTarget: Equatable, Sendable {
    case series(String)
    case section(WorkspaceSection)

    private static let key = "target"
    private static let seriesPrefix = "series:"
    private static let sectionPrefix = "section:"

    var userInfo: [String: String] {
        switch self {
        case .series(let id): [Self.key: Self.seriesPrefix + id]
        case .section(let section): [Self.key: Self.sectionPrefix + section.rawValue]
        }
    }

    init?(userInfo: [AnyHashable: Any]) {
        guard let value = userInfo[Self.key] as? String else { return nil }
        if value.hasPrefix(Self.seriesPrefix) { self = .series(String(value.dropFirst(Self.seriesPrefix.count))) }
        else if value.hasPrefix(Self.sectionPrefix), let section = WorkspaceSection(rawValue: String(value.dropFirst(Self.sectionPrefix.count))) {
            self = .section(section)
        } else { return nil }
    }
}
