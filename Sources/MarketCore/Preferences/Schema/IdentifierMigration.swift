// Fait passer un identifiant enregistré dans un fichier de la personne vers le code de série Webstat.
import Foundation

/// Un fichier écrit par une version publiée peut porter un nom de départ (« fr10 ») à la place du code de série.
/// Appelée seulement au chargement d'un fichier. Retrait : voir `docs/decisions/2026-11-12-relecture-des-versions-de-fichiers.md`.
public enum IdentifierMigration {
    public static func upgrade(_ savedID: String) -> String { codesByShortName[savedID] ?? savedID }

    /// Code de série Webstat de chaque nom court qu'un fichier écrit par une version publiée peut porter.
    private static let codesByShortName: [String: String] = [
        "fr10": "FM.M.FR.EUR.FR2.BB.FR10YT_RR.YLD",
        "ecb": "FM.D.U2.EUR.4F.KR.DFR.LEV",
        "eurusd": "EXR.D.USD.EUR.SP00.A",
        "eurjpy": "EXR.D.JPY.EUR.SP00.A",
        "eurchf": "EXR.D.CHF.EUR.SP00.A",
        "livreta": "MIR1.M.FR.B.L23FRLA.D.R.A.2230U6.EUR.O",
        "lep": "MIR1.M.FR.B.L23FRLP.H.R.A.2250U6.EUR.O",
        "inflation": "HICP.M.FR.N.000000.4D0.ANR",
        "ldds": "MIR1.M.FR.B.L23FRLD.D.R.A.2254U6.EUR.O",
        "estr": "ESTR.B.EU000A2X2A25.WT",
        "inflation-euro": "HICP.M.U2.N.000000.4D0.ANR",
        "eurgbp": "EXR.D.GBP.EUR.SP00.A",
        "mortgage-fr": "MIR1.M.FR.B.A22HR.A.R.A.2254U6.EUR.N",
        "de10": "FM.M.DE.EUR.FR2.BB.DE10YT_RR.YLD",
        "us10": "FM.M.US.USD.FR2.BB.US10YT_RR.YLD",
        "mro": "FM.D.U2.EUR.4F.KR.MRR_FR.LEV"
    ]
}
