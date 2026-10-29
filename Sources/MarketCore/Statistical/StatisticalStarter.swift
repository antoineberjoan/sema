// Références de départ exactes, à résoudre contre le catalogue vivant de chaque source.
import Foundation

public struct StatisticalStarter: Equatable, Sendable, Identifiable {
    public let source: StatisticalSource
    public let agency: String?
    public let datasetCode: String
    public let key: String
    /// Libellé de navigation ; l’aperçu conserve toujours le titre officiel du fournisseur.
    public let title: String

    public var id: String { "\(source.rawValue):\(agency ?? ""):\(datasetCode):\(key)" }

    public func matches(_ dataset: StatisticalDataset) -> Bool {
        dataset.source == source && dataset.code == datasetCode && (agency == nil || dataset.agency == agency)
    }

    public static func recommendations(for source: StatisticalSource) -> [StatisticalStarter] {
        switch source {
        case .insee: insee
        case .ecb: ecb
        case .eurostat: eurostat
        case .bis: bis
        case .oecd: oecd
        case .newYorkFed: newYorkFed
        case .worldBank: worldBank
        }
    }

    private static func item(_ source: StatisticalSource, _ agency: String?, _ dataset: String, _ key: String, _ title: String) -> StatisticalStarter {
        .init(source: source, agency: agency, datasetCode: dataset, key: key, title: title)
    }

    private static let inseeCategories: [(String, String)] = [
        ("00", "Ensemble"),
        ("01", "Alimentation et boissons non alcoolisées"),
        ("02", "Boissons alcoolisées et tabac"),
        ("03", "Habillement et chaussures"),
        ("04", "Logement, eau, électricité et gaz"),
        ("05", "Ameublement et équipement ménager"),
        ("06", "Santé"),
        ("07", "Transports"),
        ("08", "Information et communication"),
        ("09", "Loisirs et culture"),
        ("10", "Enseignement"),
        ("11", "Restaurants et hôtels"),
        ("12", "Assurance et services financiers"),
        ("13", "Soins personnels et autres biens et services")
    ]

    private static var insee: [StatisticalStarter] {
        let ipc = inseeCategories.map { code, label in
            let product = code == "00" ? "00" : "SO"
            let key = "M.IPC.SO.\(code).\(product).INDICE.ENSEMBLE.FE.SO.BRUT.2025.FALSE"
            return item(.insee, nil, "IPC-2025", key, "IPC France · \(label)")
        }
        let ipch = inseeCategories.prefix(6).map { code, label in
            item(.insee, nil, "IPCH-2025", "M.IPCH.\(code).INDICE.FE.SO.BRUT.2025.FALSE", "IPCH France · \(label)")
        }
        return ipc + ipch
    }

    private static let ecbCurrencies: [(String, String)] = [
        ("USD", "États-Unis · dollar"), ("GBP", "Royaume-Uni · livre sterling"),
        ("JPY", "Japon · yen"), ("CHF", "Suisse · franc suisse"),
        ("CAD", "Canada · dollar"), ("AUD", "Australie · dollar"),
        ("CNY", "Chine · yuan renminbi"), ("INR", "Inde · roupie"),
        ("KRW", "Corée du Sud · won"), ("HKD", "Hong Kong · dollar"),
        ("SGD", "Singapour · dollar"), ("BRL", "Brésil · real"),
        ("MXN", "Mexique · peso"), ("ZAR", "Afrique du Sud · rand"),
        ("TRY", "Turquie · livre"), ("PLN", "Pologne · zloty"),
        ("SEK", "Suède · couronne"), ("NOK", "Norvège · couronne"),
        ("DKK", "Danemark · couronne"), ("NZD", "Nouvelle-Zélande · dollar")
    ]
    private static var ecb: [StatisticalStarter] {
        ecbCurrencies.map { code, title in item(.ecb, "ECB", "EXR", "D.\(code).EUR.SP00.A", "EUR / \(title)") }
    }

    private static let eurostatHICP: [(String, String)] = [
        ("FR", "France"), ("DE", "Allemagne"), ("IT", "Italie"), ("ES", "Espagne"),
        ("NL", "Pays-Bas"), ("EA20", "Zone euro"), ("EU27_2020", "Union européenne"),
        ("BE", "Belgique"), ("PL", "Pologne"), ("PT", "Portugal"), ("IE", "Irlande"), ("AT", "Autriche")
    ]
    private static let eurostatUnemployment: [(String, String)] = [
        ("FR", "France"), ("DE", "Allemagne"), ("IT", "Italie"), ("ES", "Espagne"),
        ("NL", "Pays-Bas"), ("EA20", "Zone euro"), ("EU27_2020", "Union européenne"), ("BE", "Belgique")
    ]
    private static var eurostat: [StatisticalStarter] {
        let inflation = eurostatHICP.map { geo, title in
            item(.eurostat, "ESTAT", "PRC_HICP_MINR", "M.RCH_A.TOTAL.\(geo)", "Inflation annuelle · \(title)")
        }
        let unemployment = eurostatUnemployment.map { geo, title in
            item(.eurostat, "ESTAT", "UNE_RT_A", "A.Y15-74.PC_ACT.T.\(geo)", "Chômage · \(title)")
        }
        return inflation + unemployment
    }

    private static let bisAreas: [(String, String)] = [
        ("US", "États-Unis"), ("GB", "Royaume-Uni"), ("JP", "Japon"), ("CA", "Canada"),
        ("AU", "Australie"), ("CH", "Suisse"), ("CN", "Chine"), ("IN", "Inde"),
        ("BR", "Brésil"), ("MX", "Mexique"), ("KR", "Corée du Sud"), ("NO", "Norvège"),
        ("SE", "Suède"), ("NZ", "Nouvelle-Zélande"), ("PL", "Pologne"), ("CZ", "Tchéquie"),
        ("ZA", "Afrique du Sud"), ("TR", "Turquie"), ("ID", "Indonésie"), ("TH", "Thaïlande")
    ]
    private static var bis: [StatisticalStarter] {
        bisAreas.map { area, title in item(.bis, "BIS", "WS_CBPOL", "M.\(area)", "Taux directeur · \(title)") }
    }

    private static let oecdCountries: [(String, String)] = [
        ("FRA", "France"), ("ITA", "Italie"), ("ESP", "Espagne"), ("NLD", "Pays-Bas"),
        ("BEL", "Belgique"), ("JPN", "Japon"), ("CAN", "Canada"), ("CHE", "Suisse"),
        ("MEX", "Mexique"), ("TUR", "Turquie"), ("NOR", "Norvège"), ("SWE", "Suède"),
        ("DNK", "Danemark"), ("POL", "Pologne"), ("IRL", "Irlande"), ("GRC", "Grèce"),
        ("PRT", "Portugal"), ("FIN", "Finlande"), ("CZE", "Tchéquie"), ("HUN", "Hongrie")
    ]
    private static var oecd: [StatisticalStarter] {
        oecdCountries.map { geo, title in
            item(.oecd, "OECD.SDD.TPS", "DSD_PRICES_COICOP2018@DF_PRICES_C2018_ALL",
                 "\(geo).M.N.CPI.PA._T.N.GY", "Inflation · \(title)")
        }
    }

    private static let newYorkFedMeasures: [(String, String, String)] = [
        ("EFFR", "percentRate", "Taux effectif des fonds fédéraux"),
        ("EFFR", "targetRateFrom", "Cible des fonds fédéraux · borne basse"),
        ("EFFR", "targetRateTo", "Cible des fonds fédéraux · borne haute"),
        ("EFFR", "percentPercentile25", "EFFR · 25e percentile"),
        ("EFFR", "percentPercentile75", "EFFR · 75e percentile"),
        ("EFFR", "volumeInBillions", "EFFR · volume en milliards de dollars"),
        ("SOFR", "percentRate", "SOFR · taux garanti au jour le jour"),
        ("SOFR", "percentPercentile25", "SOFR · 25e percentile"),
        ("SOFR", "percentPercentile75", "SOFR · 75e percentile"),
        ("SOFR", "percentPercentile1", "SOFR · 1er percentile"),
        ("SOFR", "percentPercentile99", "SOFR · 99e percentile"),
        ("SOFR", "volumeInBillions", "SOFR · volume en milliards de dollars"),
        ("SOFRAI", "average30day", "SOFR · moyenne composée sur 30 jours"),
        ("SOFRAI", "average90day", "SOFR · moyenne composée sur 90 jours"),
        ("SOFRAI", "average180day", "SOFR · moyenne composée sur 180 jours"),
        ("SOFRAI", "index", "SOFR · indice composé"),
        ("OBFR", "percentRate", "Taux de financement bancaire overnight"),
        ("OBFR", "percentPercentile25", "OBFR · 25e percentile"),
        ("TGCR", "percentRate", "Taux général des pensions du Trésor"),
        ("BGCR", "percentRate", "Taux général des pensions du Trésor (garanties bilatérales)")
    ]
    private static var newYorkFed: [StatisticalStarter] {
        newYorkFedMeasures.map { type, measure, title in item(.newYorkFed, "NYFED", type, measure, title) }
    }

    private static let worldBankIndicators: [(String, String)] = [
        ("NY.GDP.MKTP.CD", "PIB · dollars courants"),
        ("NY.GDP.PCAP.CD", "PIB par habitant · dollars courants"),
        ("NY.GDP.MKTP.KD.ZG", "Croissance du PIB"),
        ("FP.CPI.TOTL.ZG", "Inflation · prix à la consommation"),
        ("SL.UEM.TOTL.ZS", "Chômage · total"),
        ("SP.POP.TOTL", "Population totale"),
        ("NE.EXP.GNFS.CD", "Exportations · biens et services"),
        ("NE.IMP.GNFS.CD", "Importations · biens et services"),
        ("NE.TRD.GNFS.ZS", "Commerce extérieur · part du PIB"),
        ("NV.AGR.TOTL.ZS", "Agriculture · part du PIB"),
        ("NV.IND.TOTL.ZS", "Industrie · part du PIB"),
        ("NV.SRV.TOTL.ZS", "Services · part du PIB"),
        ("BX.KLT.DINV.CD.WD", "Investissements directs étrangers · flux"),
        ("BX.KLT.DINV.WD.GD.ZS", "Investissements directs étrangers · part du PIB"),
        ("SP.DYN.LE00.IN", "Espérance de vie à la naissance"),
        ("EG.FEC.RNEW.ZS", "Énergies renouvelables · part de la consommation"),
        ("IT.NET.USER.ZS", "Population utilisant Internet"),
        ("SH.DYN.MORT", "Mortalité avant 5 ans"),
        ("SP.URB.TOTL.IN.ZS", "Population urbaine"),
        ("SP.RUR.TOTL.ZS", "Population rurale")
    ]
    private static var worldBank: [StatisticalStarter] {
        worldBankIndicators.map { code, title in item(.worldBank, "2", code, "FR", "France · \(title)") }
    }
}
