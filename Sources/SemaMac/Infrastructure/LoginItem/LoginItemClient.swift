// Reflète et modifie l’ouverture de session confiée à macOS, sans préférence locale parallèle.
import Observation
import ServiceManagement

@Observable @MainActor
final class LoginItemClient {
    private(set) var status = SMAppService.mainApp.status
    private(set) var error: String?

    var isEnabled: Bool { status == .enabled }
    var isApprovalRequired: Bool { status == .requiresApproval }

    func refresh() { status = SMAppService.mainApp.status }

    func setEnabled(_ enabled: Bool) {
        refresh()
        error = nil
        if enabled && isApprovalRequired { openSettings(); return }
        guard enabled != isEnabled else { return }
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch {
            self.error = "L’ouverture de session n’a pas pu être modifiée : \(error.localizedDescription)"
        }
        refresh()
        if isApprovalRequired { error = nil }
    }

    func openSettings() { SMAppService.openSystemSettingsLoginItems() }
}
