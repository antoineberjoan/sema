// Fige la liste des types publics du cœur : un déplacement de fichier ne doit pas changer ce que l'app peut lire.
import Foundation
import Testing

struct PublicSurfaceTests {
    private static let expected: [String] = [
        "AgendaItem",
        "AlertCondition",
        "AlertDirection",
        "AlertEvaluator",
        "AlertEvent",
        "AlertRule",
        "AlertThreshold",
        "AlphaVantageClient",
        "AppPreferences",
        "AppShortcut",
        "BriefPreferences",
        "CentralBankFeed",
        "ClaudeClient",
        "ContextFact",
        "DayAgenda",
        "DayContext",
        "EconomicRelease",
        "ExchangeRatePair",
        "FredClient",
        "GdeltClient",
        "Headline",
        "HeadlineSource",
        "HistoryPeriod",
        "IdentifierMigration",
        "LocalProfile",
        "MarketCatalogue",
        "MarketDataConnector",
        "MarketDataError",
        "MarketInstrument",
        "MarketObservation",
        "MarketProvider",
        "MarketSeries",
        "MorningBrief",
        "MoveSensitivity",
        "NewYorkFedClient",
        "ObservationFrequency",
        "PeerMove",
        "PreferencesError",
        "PreferencesMigration",
        "PreferencesRepository",
        "PressRelease",
        "PressReleaseClient",
        "PublicDataError",
        "RefreshPolicy",
        "RibbonGlassPreferences",
        "SDMXParser",
        "SdmxClient",
        "SeriesCategory",
        "SeriesEquivalence",
        "SeriesExplanation",
        "SeriesSearch",
        "SessionRank",
        "SessionSentence",
        "ShortcutAction",
        "ShortcutPreferences",
        "StatisticalCode",
        "StatisticalCodelistReference",
        "StatisticalConnector",
        "StatisticalDataset",
        "StatisticalDimension",
        "StatisticalSeriesDescriptor",
        "StatisticalSource",
        "StatisticalStarter",
        "StatisticalStructure",
        "SummaryCheck",
        "SummaryPrompt",
        "SummarySentence",
        "SummaryWriter",
        "TwelveDataClient",
        "UnusualMove",
        "ValueUnit",
        "VariationConvention",
        "WebstatClient",
        "WebstatDataset",
        "WebstatError",
        "WebstatPage",
        "WebstatSearch",
        "WebstatSeriesDescriptor",
        "WebstatSite",
        "WebstatStarter",
        "WebstatValue",
        "WorldBankClient"
    ]

    private func declaredPublicTypes() throws -> [String] {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/MarketCore", isDirectory: true)
        let pattern = try NSRegularExpression(pattern: "^public (?:final |indirect )?(?:struct|enum|class|protocol|actor|typealias) ([A-Za-z0-9_]+)",
                                              options: [.anchorsMatchLines])
        let files = try #require(FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil))
        var names: [String] = []
        for case let url as URL in files where url.pathExtension == "swift" {
            let text = try String(contentsOf: url, encoding: .utf8)
            let range = NSRange(text.startIndex..., in: text)
            for match in pattern.matches(in: text, range: range) {
                if let name = Range(match.range(at: 1), in: text) { names.append(String(text[name])) }
            }
        }
        return names.sorted()
    }

    @Test func coreExposesTheSamePublicTypes() throws {
        #expect(try declaredPublicTypes() == Self.expected.sorted())
    }
}
