// Gère l’autorisation et l’envoi des notifications système demandées par l’app.
import Foundation
import UserNotifications

@MainActor
final class NotificationClient {
    /// Toutes les alertes de sema partagent un fil, pour que macOS les empile au lieu de remplir l’écran.
    private static let thread = "sema.alerts"

    func requestPermission() async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }

    /// `target` est relu quand la personne clique sur la notification.
    func send(title: String, subtitle: String, body: String, target: NotificationTarget? = nil) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        content.body = body
        content.sound = .default
        content.threadIdentifier = Self.thread
        if let target { content.userInfo = target.userInfo }
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        try await UNUserNotificationCenter.current().add(request)
    }
}
