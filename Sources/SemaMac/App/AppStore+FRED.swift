// Connecte, vérifie et retire la clé FRED, et fournit aux catalogues un client qui la transmet seulement à FRED.
import Foundation
import MarketCore

extension AppStore {
    /// Connecteurs statistiques pour les catalogues et les actualisations ; la clé FRED est lue dans le Trousseau seulement si elle existe.
    func statisticalConnectors() async -> StatisticalConnectors {
        guard hasFREDKey, isSourceEnabled(StatisticalSource.fred.rawValue) else { return StatisticalConnectors(fredKey: nil) }
        return StatisticalConnectors(fredKey: try? await fredKeychain.read())
    }

    func checkFREDKey() async {
        do { hasFREDKey = try await fredKeychain.read() != nil }
        catch { fredError = "Le Trousseau n’a pas pu lire la clé FRED." }
    }

    func connectFRED(key: String) async -> Bool {
        let source = StatisticalSource.fred.rawValue
        guard !isConnectingFRED, isSourceEnabled(source) else { return false }
        isConnectingFRED = true; fredError = nil
        defer { isConnectingFRED = false }
        let key = key.trimmingCharacters(in: .whitespacesAndNewlines)
        let generation = sourceGenerations[source]
        do {
            try await FredClient(key: key).validateKey()
            guard isSourceEnabled(source), generation == sourceGenerations[source] else { return false }
            try await fredKeychain.save(key)
            hasFREDKey = true
            sourceGenerations[source] = UUID()
            return true
        } catch { fredError = error.localizedDescription; return false }
    }

    func removeFREDKey() async {
        guard !isConnectingFRED, !isLoading else { return }
        do {
            try await fredKeychain.remove()
            hasFREDKey = false; fredError = nil
            sourceGenerations[StatisticalSource.fred.rawValue] = UUID()
        } catch { fredError = "Le Trousseau n’a pas pu retirer la clé FRED." }
    }
}
