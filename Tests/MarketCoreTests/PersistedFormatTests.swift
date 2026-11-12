// Fige les noms de clés et les valeurs des fichiers que les utilisateurs ont déjà sur leur disque.
import Foundation
import Testing
@testable import MarketCore

struct PersistedFormatTests {
    private static let ruleID = "0F1396B5-51D9-42B3-A6DC-75E16B00D144"
    private static let fullDocument = """
    {"schemaVersion":2,"favoriteIDs":["eurusd"],"followedSeriesIDs":["eurusd","fr10"],
     "alerts":[{"id":"\(ruleID)","seriesID":"fr10","direction":"rise","threshold":2.5,"isEnabled":true,"condition":"level","lastEvaluatedAt":800000000}],
     "notificationsEnabled":true,"themeID":"polar","appearanceID":"dark","ribbonPositionID":"left","onboardingCompleted":true,
     "disabledSourceIDs":["fred"],"profile":{"firstName":"Ada","lastName":"Lovelace"},
     "alertBaselineIDs":["1B4E28BA-2FA1-11D2-883F-0016D3CCA427"],"invertedCurrencyPairs":["eurusd"],
     "ribbonGlass":{"transparency":0.5,"tint":0.25,"grain":0.125},
     "shortcuts":{"ribbon":{"keyCode":11,"modifiers":3,"key":"B"},"workspace":{"keyCode":4,"modifiers":5,"key":"H"}},
     "periodID":"threeYears","moveSensitivityID":"high","headlineSourceID":"gdelt","summaryWriterID":"claude",
     "brief":{"isEnabled":true,"hour":7,"minute":30,"weekdaysOnly":false,"lastSentAt":800000000}}
    """

    private func makeFile(_ contents: String) throws -> (directory: URL, file: URL, data: Data) {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("sema-format-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("preferences.json")
        let data = Data(contents.utf8)
        try data.write(to: file)
        return (directory, file, data)
    }

    private func keys(of data: Data) throws -> Set<String> {
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        return Set(object.keys)
    }

    @Test func fullCurrentDocumentKeepsEveryValue() throws {
        let stored = try makeFile(Self.fullDocument)
        defer { try? FileManager.default.removeItem(at: stored.directory) }
        let value = try PreferencesRepository(fileURL: stored.file).load()
        let date = Date(timeIntervalSinceReferenceDate: 800_000_000)
        #expect(value.schemaVersion == 2)
        #expect(value.favoriteIDs == [WebstatStarter.canonicalID("eurusd")])
        #expect(value.followedSeriesIDs == ["eurusd", "fr10"].map(WebstatStarter.canonicalID))
        #expect(value.alerts.count == 1)
        #expect(value.alerts.first?.id == UUID(uuidString: Self.ruleID))
        #expect(value.alerts.first?.seriesID == WebstatStarter.canonicalID("fr10"))
        #expect(value.alerts.first?.direction == .rise)
        #expect(value.alerts.first?.threshold == Decimal(string: "2.5"))
        #expect(value.alerts.first?.isEnabled == true)
        #expect(value.alerts.first?.condition == .level)
        #expect(value.alerts.first?.lastEvaluatedAt == date)
        #expect(value.canNotify)
        #expect(value.themeID == "polar")
        #expect(value.appearanceID == "dark")
        #expect(value.ribbonPositionID == "left")
        #expect(value.isOnboardingCompleted == true)
        #expect(value.disabledSourceIDs == ["fred"])
        #expect(value.profile == LocalProfile(firstName: "Ada", lastName: "Lovelace"))
        #expect(value.alertBaselineIDs == [UUID(uuidString: "1B4E28BA-2FA1-11D2-883F-0016D3CCA427")!])
        #expect(value.invertedCurrencyPairs == ["eurusd"])
        #expect(value.ribbonGlass == RibbonGlassPreferences(transparency: 0.5, tint: 0.25, grain: 0.125))
        #expect(value.shortcuts?.ribbon == AppShortcut(keyCode: 11, modifiers: [.control, .option], key: "B"))
        #expect(value.shortcuts?.workspace == AppShortcut(keyCode: 4, modifiers: [.control, .shift], key: "H"))
        #expect(value.periodID == "threeYears")
        #expect(value.moveSensitivityID == "high")
        #expect(value.headlineSourceID == "gdelt")
        #expect(value.summaryWriterID == "claude")
        #expect(value.brief?.isEnabled == true)
        #expect(value.brief?.hour == 7)
        #expect(value.brief?.minute == 30)
        #expect(value.brief?.weekdaysOnly == false)
        #expect(value.brief?.lastSentAt == date)
        #expect(try Data(contentsOf: stored.file) == stored.data)
    }

    @Test func savedDocumentKeepsEveryKeyName() throws {
        let stored = try makeFile(Self.fullDocument)
        defer { try? FileManager.default.removeItem(at: stored.directory) }
        let store = PreferencesRepository(fileURL: stored.file)
        try store.save(try store.load())
        let saved = try Data(contentsOf: stored.file)
        #expect(try keys(of: saved) == [
            "schemaVersion", "favoriteIDs", "followedSeriesIDs", "alerts", "notificationsEnabled", "themeID", "appearanceID",
            "ribbonPositionID", "onboardingCompleted", "disabledSourceIDs", "profile", "alertBaselineIDs", "invertedCurrencyPairs",
            "ribbonGlass", "shortcuts", "periodID", "moveSensitivityID", "headlineSourceID", "summaryWriterID", "brief"
        ])
        let object = try #require(try JSONSerialization.jsonObject(with: saved) as? [String: Any])
        let rule = try #require((object["alerts"] as? [[String: Any]])?.first)
        #expect(Set(rule.keys) == ["id", "seriesID", "direction", "threshold", "isEnabled", "condition", "lastEvaluatedAt"])
        let brief = try #require(object["brief"] as? [String: Any])
        #expect(Set(brief.keys) == ["isEnabled", "hour", "minute", "weekdaysOnly", "lastSentAt"])
        let glass = try #require(object["ribbonGlass"] as? [String: Any])
        #expect(Set(glass.keys) == ["transparency", "tint", "grain"])
        let profile = try #require(object["profile"] as? [String: Any])
        #expect(Set(profile.keys) == ["firstName", "lastName"])
        let shortcuts = try #require(object["shortcuts"] as? [String: Any])
        #expect(Set(shortcuts.keys) == ["ribbon", "workspace"])
        let ribbon = try #require(shortcuts["ribbon"] as? [String: Any])
        #expect(Set(ribbon.keys) == ["keyCode", "modifiers", "key"])
    }

    @Test func versionOneDocumentIsMigratedAndKeptBesideTheNewFile() throws {
        let stored = try makeFile(#"{"schemaVersion":1,"favoriteIDs":["fr10"],"notificationsEnabled":false,"alerts":[]}"#)
        defer { try? FileManager.default.removeItem(at: stored.directory) }
        let store = PreferencesRepository(fileURL: stored.file)
        let value = try store.load()
        #expect(value.schemaVersion == AppPreferences.currentSchemaVersion)
        #expect(value.isOnboardingCompleted == true)
        #expect(value.followedSeriesIDs == WebstatStarter.ids.map(WebstatStarter.canonicalID))
        let backup = stored.file.appendingPathExtension("v1-backup")
        #expect(try Data(contentsOf: backup) == stored.data)
        let migrated = try JSONDecoder().decode(AppPreferences.self, from: Data(contentsOf: stored.file))
        #expect(migrated.schemaVersion == AppPreferences.currentSchemaVersion)
        #expect(try store.load() == value)
        #expect(try Data(contentsOf: backup) == stored.data)
    }

    @Test func cachedSeriesKeepTheirKeyNames() throws {
        let day = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let series = MarketSeries(id: "fr10", name: "OAT 10 ans", subtitle: "Taux", category: .markets, unit: .percent,
                                  source: "Banque de France", observations: [MarketObservation(date: day, value: Decimal(string: "3.25")!)])
        let data = try JSONEncoder().encode([series])
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [[String: Any]])
        let first = try #require(object.first)
        #expect(Set(first.keys) == ["id", "name", "subtitle", "category", "unit", "fractionDigits", "source", "observations"])
        let observation = try #require((first["observations"] as? [[String: Any]])?.first)
        #expect(Set(observation.keys) == ["date", "value"])
        #expect(try JSONDecoder().decode([MarketSeries].self, from: data) == [series])
    }

    @Test func renamedPropertiesKeepTheKeysOfTheFile() throws {
        let preferences = AppPreferences(canNotify: true, isOnboardingCompleted: true)
        let object = try #require(try JSONSerialization.jsonObject(with: JSONEncoder().encode(preferences)) as? [String: Any])
        #expect(object["notificationsEnabled"] as? Bool == true)
        #expect(object["onboardingCompleted"] as? Bool == true)
        #expect(object["canNotify"] == nil && object["isOnboardingCompleted"] == nil)
        var brief = BriefPreferences()
        brief.isWeekdaysOnly = false
        let briefObject = try #require(try JSONSerialization.jsonObject(with: JSONEncoder().encode(brief)) as? [String: Any])
        #expect(briefObject["weekdaysOnly"] as? Bool == false)
        #expect(briefObject["isWeekdaysOnly"] == nil)
    }

    @Test func instrumentKeepsItsWeeklyKeyAndReadsAnOldFile() throws {
        let instrument = MarketInstrument(provider: .alphaVantage, symbol: "IBM", name: "IBM", exchange: "NYSE", currency: "USD", kind: "Stock", isWeekly: true)
        let object = try #require(try JSONSerialization.jsonObject(with: JSONEncoder().encode(instrument)) as? [String: Any])
        #expect(object["weekly"] as? Bool == true)
        #expect(object["isWeekly"] == nil)
        let stored = Data(#"{"provider":"alpha-vantage","symbol":"IBM","name":"IBM","exchange":"NYSE","currency":"USD","kind":"Stock","weekly":true}"#.utf8)
        #expect(try JSONDecoder().decode(MarketInstrument.self, from: stored).isWeekly)
    }
}
