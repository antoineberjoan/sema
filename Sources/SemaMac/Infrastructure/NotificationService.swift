import Foundation
import UserNotifications

@MainActor
final class NotificationService {
    func requestPermission() async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }

    func sendDemo(title: String, body: String) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Sema · test de notification"
        content.subtitle = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        try await UNUserNotificationCenter.current().add(request)
    }
}
