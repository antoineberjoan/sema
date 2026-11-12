// Consigne commune aux deux rédacteurs : faits numérotés, chiffres recopiés, aucune cause affirmée.
import Foundation

public enum SummaryPrompt {
    public static let instructions = """
    Tu écris pour un conseiller en gestion de patrimoine une synthèse d’une séance de marché, en français simple.
    Écris au plus trois phrases courtes. Utilise uniquement les faits numérotés fournis.
    Chaque phrase donne les identifiants des faits qu’elle utilise, par exemple f1.
    Recopie les chiffres exactement comme ils figurent dans les faits.
    N’affirme aucune cause : écris « le même jour » ou « dans le même temps », jamais « à cause de », « en raison de » ou « parce que ».
    Si les faits ne suffisent pas, écris moins de phrases.
    """

    /// Facts as numbered lines, after the date of the session.
    public static func facts(_ facts: [ContextFact], day: Date) -> String {
        (["Séance du \(ContextFact.longDate(day)).", "Faits :"] + facts.map { "\($0.id) · \($0.text)" }).joined(separator: "\n")
    }
}
