// Décode les structures et observations SDMX en conservant leurs métadonnées officielles.
import Foundation

/// The same XML reader handles SDMX 2.1 generic and structure-specific messages.
/// Annotations are not needed for navigation; entity declarations are rejected.
private final class StatisticalXMLNode {
    let name: String
    let attributes: [String: String]
    var text = ""
    var children: [StatisticalXMLNode] = []
    init(name: String, attributes: [String: String] = [:]) { self.name = name; self.attributes = attributes }
    func descendants(_ name: String) -> [StatisticalXMLNode] {
        children.flatMap { ($0.name == name ? [$0] : []) + $0.descendants(name) }
    }
    func child(_ name: String) -> StatisticalXMLNode? { children.first { $0.name == name } }
    var label: String {
        let names = children.filter { $0.name == "Name" }
        return (names.first { $0.attributes["xml:lang"] == "fr" } ?? names.first { $0.attributes["xml:lang"] == "en" } ?? names.first)?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? attributes["id"] ?? ""
    }
}

private final class StatisticalXMLReader: NSObject, XMLParserDelegate {
    let root = StatisticalXMLNode(name: "root")
    private var stack: [StatisticalXMLNode] = []
    private var ignoredDepth = 0
    var rejectedEntity = false
    override init() { super.init(); stack = [root] }
    static func read(_ data: Data) throws -> StatisticalXMLNode {
        let reader = StatisticalXMLReader(); let parser = XMLParser(data: data)
        parser.shouldResolveExternalEntities = false; parser.delegate = reader
        guard parser.parse(), !reader.rejectedEntity else { throw StatisticalClient.ClientError.invalidData }
        guard reader.root.descendants("Error").isEmpty, reader.root.descendants("Fault").isEmpty else { throw StatisticalClient.ClientError.invalidData }
        return reader.root
    }
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes: [String: String]) {
        let name = String(elementName.split(separator: ":").last ?? "")
        if ignoredDepth > 0 || name == "Annotations" { ignoredDepth += 1; return }
        let node = StatisticalXMLNode(name: name, attributes: attributes)
        stack.last?.children.append(node); stack.append(node)
    }
    func parser(_ parser: XMLParser, foundCharacters string: String) { if ignoredDepth == 0 { stack.last?.text += string } }
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if ignoredDepth > 0 { ignoredDepth -= 1 } else { _ = stack.popLast() }
    }
    func parser(_ parser: XMLParser, foundInternalEntityDeclarationWithName name: String, value: String?) { rejectedEntity = true; parser.abortParsing() }
    func parser(_ parser: XMLParser, foundExternalEntityDeclarationWithName name: String, publicID: String?, systemID: String?) { rejectedEntity = true; parser.abortParsing() }
}

public enum SDMXParser {
    public static func datasets(_ data: Data, source: StatisticalSource) throws -> [StatisticalDataset] {
        let root = try StatisticalXMLReader.read(data)
        let flows = root.descendants("Dataflow").compactMap { flow -> StatisticalDataset? in
            guard let code = flow.attributes["id"], let agency = flow.attributes["agencyID"] else { return nil }
            let detail = flow.children.first { $0.name == "Description" && $0.attributes["xml:lang"] == "fr" }
                ?? flow.child("Description")
            return .init(source: source, code: code, agency: agency, version: flow.attributes["version"] ?? "latest",
                         title: flow.label, detail: detail?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
        }
        guard !flows.isEmpty else { throw StatisticalClient.ClientError.noData }
        return Dictionary(flows.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first }).values.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }

    public static func structure(_ data: Data, dataset: StatisticalDataset, additionalCodelists: [Data] = []) throws -> StatisticalStructure {
        let root = try StatisticalXMLReader.read(data)
        let flow = root.descendants("Dataflow").first { $0.attributes["id"] == dataset.code && $0.attributes["agencyID"] == dataset.agency }
        let dsdID = flow?.descendants("Ref").first { $0.attributes["class"] == "DataStructure" }?.attributes["id"]
        let dsd = root.descendants("DataStructure").first { dsdID == nil || $0.attributes["id"] == dsdID }
        guard let dsd, let components = dsd.child("DataStructureComponents"), let list = components.child("DimensionList") else { throw StatisticalClient.ClientError.invalidData }
        var codelists: [StatisticalCodelistReference: [String: String]] = [:]
        let extraNodes = try additionalCodelists.flatMap { try StatisticalXMLReader.read($0).descendants("Codelist") }
        for list in root.descendants("Codelist") + extraNodes {
            guard let id = list.attributes["id"] else { continue }
            let key = StatisticalCodelistReference(agency: list.attributes["agencyID"] ?? "", code: id, version: list.attributes["version"] ?? "latest")
            codelists[key] = Dictionary(list.children.filter { $0.name == "Code" }.compactMap { node in
                node.attributes["id"].map { ($0, node.label) }
            }, uniquingKeysWith: { first, _ in first })
        }
        var labels: [String: [String: String]] = [:]
        var concepts: [String: String] = [:]
        for node in root.descendants("Concept") { if let id = node.attributes["id"] { concepts[id] = node.label } }
        let constraints = root.descendants("ContentConstraint").filter { constraint in
            constraint.child("ConstraintAttachment")?.descendants("Ref").contains { $0.attributes["id"] == dataset.code && $0.attributes["class"] == "Dataflow" } == true
        }
        let actual = constraints.filter { $0.attributes["type"] == "Actual" }
        var available: [String: Set<String>] = [:]
        for constraint in actual.isEmpty ? constraints : actual {
            for region in constraint.children where region.name == "CubeRegion" && region.attributes["include"] == "true" {
                for key in region.children where key.name == "KeyValue" {
                    if let id = key.attributes["id"] { available[id, default: []].formUnion(key.children.filter { $0.name == "Value" }.map { $0.text }) }
                }
            }
        }
        var missing: Set<StatisticalCodelistReference> = []
        func codes(_ component: StatisticalXMLNode) -> [String: String] {
            guard let reference = component.descendants("Ref").first(where: { $0.attributes["class"] == "Codelist" }), let id = reference.attributes["id"] else { return [:] }
            let agency = reference.attributes["agencyID"] ?? dataset.agency
            let version = reference.attributes["version"] ?? "latest"
            let target = StatisticalCodelistReference(agency: agency, code: id, version: version)
            let resolved = version == "latest" ? codelists.keys.filter { $0.agency == agency && $0.code == id }
                .max { $0.version.localizedStandardCompare($1.version) == .orderedAscending } : target
            if let resolved, let values = codelists[resolved] { return values }
            missing.insert(target)
            return [:]
        }
        let dimensions = list.children.filter { $0.name == "Dimension" }.compactMap { dimension -> StatisticalDimension? in
            guard let id = dimension.attributes["id"], let position = dimension.attributes["position"].flatMap(Int.init) else { return nil }
            let allCodes = codes(dimension)
            let values = available[id].map { allowed in allCodes.filter { allowed.contains($0.key) } } ?? allCodes
            labels[id.uppercased()] = allCodes
            let conceptID = dimension.child("ConceptIdentity")?.descendants("Ref").first?.attributes["id"] ?? id
            return .init(id: id, title: concepts[conceptID] ?? id, position: position,
                         codes: values.map { .init(id: $0.key, title: $0.value) }.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending })
        }.sorted { $0.position < $1.position }
        for attribute in components.child("AttributeList")?.children ?? [] {
            if let id = attribute.attributes["id"] { labels[id.uppercased()] = codes(attribute) }
        }
        guard !dimensions.isEmpty else { throw StatisticalClient.ClientError.invalidData }
        return .init(dimensions: dimensions, labels: labels, missingCodelists: Array(missing))
    }

    public static func series(_ data: Data, dataset: StatisticalDataset, structure: StatisticalStructure,
                              fullHistory: Bool = false, now: Date = .now) throws -> MarketSeries {
        let root = try StatisticalXMLReader.read(data)
        guard root.descendants("Footer").isEmpty else { throw StatisticalClient.ClientError.invalidData }
        var result: [MarketSeries] = []
        for set in root.descendants("DataSet") {
            let shared = fields(set)
            for node in set.children where node.name == "Series" {
                var attributes = shared.merging(fields(node), uniquingKeysWith: { _, new in new })
                var labels: [String: String] = [:]
                for (field, value) in attributes { labels[field] = structure.labels[field]?[value] }
                if attributes["TITLE_FR"] == nil && attributes["TITLE"] == nil && attributes["TITLE_EN"] == nil {
                    let title = structure.dimensions.compactMap { dimension -> String? in
                        let field = dimension.id.uppercased()
                        guard let code = attributes[field] else { return nil }
                        return labels[field] ?? code
                    }.joined(separator: " · ")
                    attributes["TITLE"] = dataset.title + (title.isEmpty ? "" : " · " + title)
                }
                let keyParts = structure.dimensions.map { attributes[$0.id.uppercased()] ?? "" }
                guard keyParts.allSatisfy({ !$0.isEmpty }) else { throw StatisticalClient.ClientError.invalidData }
                let descriptor = StatisticalSeriesDescriptor(dataset: dataset, key: keyParts.joined(separator: "."),
                    dimensionIDs: structure.dimensions.map(\.id), fields: attributes, labels: labels)
                var points: [MarketObservation] = []
                for obs in node.children where obs.name == "Obs" {
                    let observation = fields(obs)
                    guard let rawDate = obs.attributes["TIME_PERIOD"] ?? obs.child("ObsDimension")?.attributes["value"],
                          let rawValue = obs.attributes["OBS_VALUE"] ?? obs.child("ObsValue")?.attributes["value"],
                          let value = decimal(rawValue), !["M", "Q"].contains(observation["OBS_STATUS"] ?? "") else { continue }
                    guard let interval = period(rawDate) else { throw StatisticalClient.ClientError.unsupportedPeriod }
                    guard interval.start <= now else { continue }
                    for field in ["UNIT", "UNIT_MEASURE", "UNIT_MULT", "UNIT_INDEX_BASE", "BASIND"] {
                        if let value = observation[field], value != attributes[field] { throw StatisticalClient.ClientError.metadataChanged }
                    }
                    points.append(.init(date: interval.start, value: value, periodEnd: interval.end,
                        updatedAt: attributes["LAST_UPDATE"].flatMap { period(String($0.prefix(10)))?.start }, status: observation["OBS_STATUS"]))
                }
                if !points.isEmpty { result.append(descriptor.series(observations: points, syncedAt: now, completeHistory: fullHistory)) }
            }
        }
        guard result.count <= 1 else { throw StatisticalClient.ClientError.chooseOneSeries }
        guard let series = result.first else { throw StatisticalClient.ClientError.noData }
        return series
    }

    private static func fields(_ node: StatisticalXMLNode) -> [String: String] {
        var values = Dictionary(node.attributes.map { ($0.key.uppercased(), $0.value) }, uniquingKeysWith: { _, new in new })
        for container in node.children where ["SeriesKey", "Attributes"].contains(container.name) {
            for value in container.children where value.name == "Value" {
                if let id = value.attributes["id"], let text = value.attributes["value"] { values[id.uppercased()] = text }
            }
        }
        return values
    }
    static func decimal(_ text: String) -> Decimal? {
        guard text.range(of: "^-?(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)(?:[eE][+-]?[0-9]+)?$", options: .regularExpression) != nil,
              let value = Decimal(string: text, locale: .posix), !value.isNaN else { return nil }
        return value
    }
    static func period(_ text: String) -> (start: Date, end: Date)? {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let formatter = ISO8601DateFormatter(); formatter.formatOptions = [.withFullDate]
        if text.count == 10, let date = formatter.date(from: text), formatter.string(from: date) == text { return (date, date) }
        guard let year = Int(text.prefix(4)), year >= 1, text.count >= 4 else { return nil }
        var month = 1; var length = 12
        if text.count == 7, text.dropFirst(4).first == "-" {
            let suffix = String(text.suffix(2))
            if ["Q", "T"].contains(String(suffix.prefix(1))), let quarter = Int(suffix.suffix(1)), (1...4).contains(quarter) { month = (quarter - 1) * 3 + 1; length = 3 }
            else if ["S", "H"].contains(String(suffix.prefix(1))), let half = Int(suffix.suffix(1)), (1...2).contains(half) { month = (half - 1) * 6 + 1; length = 6 }
            else if let number = Int(suffix), (1...12).contains(number) { month = number; length = 1 }
            else { return nil }
        } else if text.count == 8, text.contains("-W"), let week = Int(text.suffix(2)), (1...53).contains(week) {
            var iso = Calendar(identifier: .iso8601); iso.timeZone = calendar.timeZone
            guard let start = iso.date(from: DateComponents(weekday: 2, weekOfYear: week, yearForWeekOfYear: year)),
                  iso.component(.weekOfYear, from: start) == week, iso.component(.yearForWeekOfYear, from: start) == year else { return nil }
            return (start, start.addingTimeInterval(6 * .day))
        } else if text.count != 4 { return nil }
        guard let start = calendar.date(from: DateComponents(year: year, month: month, day: 1)), let next = calendar.date(byAdding: .month, value: length, to: start) else { return nil }
        return (start, next.addingTimeInterval(-.day))
    }
}
