import Foundation
import UserNotifications

@MainActor
final class NotificationService {
    func requestPermission() async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }

    func send(title: String, body: String, isDemo: Bool) async throws {
        let content = UNMutableNotificationContent()
        content.title = isDemo ? "sema · test de notification" : "sema · seuil franchi"
        content.subtitle = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        try await UNUserNotificationCenter.current().add(request)
    }
}
