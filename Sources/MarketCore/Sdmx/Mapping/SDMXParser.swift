// Décode les structures et observations SDMX en conservant leurs métadonnées officielles.
import Foundation

public enum SDMXParser {
    public static func datasets(_ data: Data, source: StatisticalSource) throws -> [StatisticalDataset] {
        let root = try XMLTree.read(data)
        let flows = root.descendants("Dataflow").compactMap { flow -> StatisticalDataset? in
            guard let code = flow.attributes["id"], let agency = flow.attributes["agencyID"] else { return nil }
            let detail = flow.children.first { $0.name == "Description" && $0.attributes["xml:lang"] == "fr" }
                ?? flow.child("Description")
            return .init(source: source, code: code, agency: agency, version: flow.attributes["version"] ?? "latest",
                         title: flow.label, detail: detail?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
        }
        guard !flows.isEmpty else { throw PublicDataError.noData }
        return Dictionary(flows.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first }).values.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }

    public static func structure(_ data: Data, dataset: StatisticalDataset, additionalCodelists: [Data] = []) throws -> StatisticalStructure {
        let root = try XMLTree.read(data)
        let flow = root.descendants("Dataflow").first { $0.attributes["id"] == dataset.code && $0.attributes["agencyID"] == dataset.agency }
        let dsdID = flow?.descendants("Ref").first { $0.attributes["class"] == "DataStructure" }?.attributes["id"]
        let dsd = root.descendants("DataStructure").first { dsdID == nil || $0.attributes["id"] == dsdID }
        guard let dsd, let components = dsd.child("DataStructureComponents"), let list = components.child("DimensionList") else { throw PublicDataError.invalidData }
        var codelists: [StatisticalCodelistReference: [String: String]] = [:]
        let extraNodes = try additionalCodelists.flatMap { try XMLTree.read($0).descendants("Codelist") }
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
        func codes(_ component: XMLTree) -> [String: String] {
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
        guard !dimensions.isEmpty else { throw PublicDataError.invalidData }
        return .init(dimensions: dimensions, labels: labels, missingCodelists: Array(missing))
    }

    public static func catalogue(_ data: Data, dataset: StatisticalDataset, structure: StatisticalStructure) throws -> [StatisticalSeriesDescriptor] {
        let root = try XMLTree.read(data)
        guard root.descendants("Footer").isEmpty else { throw PublicDataError.invalidData }
        var items: [String: StatisticalSeriesDescriptor] = [:]
        for set in root.descendants("DataSet") {
            let shared = fields(set)
            for node in set.children where node.name == "Series" {
                let value = try descriptor(fields: shared.merging(fields(node), uniquingKeysWith: { _, new in new }), dataset: dataset, structure: structure)
                if let previous = items[value.id], previous != value { throw PublicDataError.invalidData }
                items[value.id] = value
            }
        }
        guard !items.isEmpty else { throw PublicDataError.noData }
        return items.values.sorted {
            let order = $0.title.localizedStandardCompare($1.title)
            return order == .orderedSame ? $0.key < $1.key : order == .orderedAscending
        }
    }

    private static func descriptor(fields: [String: String], dataset: StatisticalDataset, structure: StatisticalStructure) throws -> StatisticalSeriesDescriptor {
        var attributes = fields
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
        let parts = structure.dimensions.map { attributes[$0.id.uppercased()] ?? "" }
        guard parts.allSatisfy({ !$0.isEmpty }), !parts.isEmpty else { throw PublicDataError.invalidData }
        return .init(dataset: dataset, key: parts.joined(separator: "."), dimensionIDs: structure.dimensions.map(\.id), fields: attributes, labels: labels)
    }

    public static func series(_ data: Data, dataset: StatisticalDataset, structure: StatisticalStructure,
                              fullHistory: Bool = false, now: Date = .now) throws -> MarketSeries {
        let root = try XMLTree.read(data)
        guard root.descendants("Footer").isEmpty else { throw PublicDataError.invalidData }
        var result: [MarketSeries] = []
        for set in root.descendants("DataSet") {
            let shared = fields(set)
            for node in set.children where node.name == "Series" {
                let descriptor = try descriptor(fields: shared.merging(fields(node), uniquingKeysWith: { _, new in new }), dataset: dataset, structure: structure)
                let attributes = descriptor.fields
                var points: [MarketObservation] = []
                for obs in node.children where obs.name == "Obs" {
                    let observation = fields(obs)
                    guard let rawDate = obs.attributes["TIME_PERIOD"] ?? obs.child("ObsDimension")?.attributes["value"],
                          let rawValue = obs.attributes["OBS_VALUE"] ?? obs.child("ObsValue")?.attributes["value"],
                          let value = PublicDataFormat.decimal(rawValue), !["M", "Q"].contains(observation["OBS_STATUS"] ?? "") else { continue }
                    guard let interval = PublicDataFormat.period(rawDate) else { throw PublicDataError.unsupportedPeriod }
                    guard interval.start <= now else { continue }
                    for field in ["UNIT", "UNIT_MEASURE", "UNIT_MULT", "UNIT_INDEX_BASE", "BASIND"] {
                        if let value = observation[field], value != attributes[field] { throw PublicDataError.metadataChanged }
                    }
                    points.append(.init(date: interval.start, value: value, periodEnd: interval.end,
                        updatedAt: attributes["LAST_UPDATE"].flatMap { PublicDataFormat.period(String($0.prefix(10)))?.start }, status: observation["OBS_STATUS"]))
                }
                if !points.isEmpty { result.append(descriptor.series(observations: points, syncedAt: now, completeHistory: fullHistory)) }
            }
        }
        guard result.count <= 1 else { throw PublicDataError.chooseOneSeries }
        guard let series = result.first else { throw PublicDataError.noData }
        return series
    }

    private static func fields(_ node: XMLTree) -> [String: String] {
        var values = Dictionary(node.attributes.map { ($0.key.uppercased(), $0.value) }, uniquingKeysWith: { _, new in new })
        for container in node.children where ["SeriesKey", "Attributes"].contains(container.name) {
            for value in container.children where value.name == "Value" {
                if let id = value.attributes["id"], let text = value.attributes["value"] { values[id.uppercased()] = text }
            }
        }
        return values
    }
}
