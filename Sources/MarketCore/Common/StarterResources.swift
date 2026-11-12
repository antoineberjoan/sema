// Lit un fichier JSON de repères de départ livré avec le cœur ; un fichier absent ou illisible arrête l'app avec son nom.
import Foundation

enum StarterResources {
    static func load<Value: Decodable>(_ type: Value.Type, file: String) -> Value {
        guard let url = Bundle.module.url(forResource: file, withExtension: "json", subdirectory: "Starters") else {
            fatalError("Repères de départ introuvables : \(file).json")
        }
        do { return try JSONDecoder().decode(type, from: Data(contentsOf: url)) }
        catch { fatalError("Repères de départ illisibles : \(file).json (\(error))") }
    }
}
