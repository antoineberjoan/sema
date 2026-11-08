// Gère l’autorisation et l’envoi des notifications système demandées par l’app.
import Foundation
import UserNotifications

@MainActor
final class NotificationService {
    /// All alerts of sema share one thread, so macOS stacks them instead of filling the screen.
    private static let thread = "sema.alerts"

    func requestPermission() async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }

    func send(title: String, subtitle: String, body: String) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        content.body = body
        content.sound = .default
        content.threadIdentifier = Self.thread
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        try await UNUserNotificationCenter.current().add(request)
    }
}
