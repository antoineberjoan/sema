// Arbre XML minimal et sûr, partagé par les messages SDMX et les flux de communiqués : entités refusées, annotations ignorées.
import Foundation

/// The same reader handles SDMX 2.1 messages and RSS or Atom feeds.
/// Annotations are not needed for navigation; entity declarations are rejected.
final class XMLTree {
    let name: String
    let attributes: [String: String]
    var text = ""
    var children: [XMLTree] = []
    init(name: String, attributes: [String: String] = [:]) { self.name = name; self.attributes = attributes }
    func descendants(_ name: String) -> [XMLTree] {
        children.flatMap { ($0.name == name ? [$0] : []) + $0.descendants(name) }
    }
    func child(_ name: String) -> XMLTree? { children.first { $0.name == name } }
    var label: String {
        let names = children.filter { $0.name == "Name" }
        return (names.first { $0.attributes["xml:lang"] == "fr" } ?? names.first { $0.attributes["xml:lang"] == "en" } ?? names.first)?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? attributes["id"] ?? ""
    }

    /// Reads a whole message; an entity declaration, an `Error` or a `Fault` element makes it invalid.
    static func read(_ data: Data) throws -> XMLTree {
        let reader = XMLTreeReader(); let parser = XMLParser(data: data)
        parser.shouldResolveExternalEntities = false; parser.delegate = reader
        guard parser.parse(), !reader.rejectedEntity else { throw StatisticalClient.ClientError.invalidData }
        guard reader.root.descendants("Error").isEmpty, reader.root.descendants("Fault").isEmpty else { throw StatisticalClient.ClientError.invalidData }
        return reader.root
    }
}

private final class XMLTreeReader: NSObject, XMLParserDelegate {
    let root = XMLTree(name: "root")
    private var stack: [XMLTree] = []
    private var ignoredDepth = 0
    var rejectedEntity = false
    override init() { super.init(); stack = [root] }
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes: [String: String]) {
        let name = String(elementName.split(separator: ":").last ?? "")
        if ignoredDepth > 0 || name == "Annotations" { ignoredDepth += 1; return }
        let node = XMLTree(name: name, attributes: attributes)
        stack.last?.children.append(node); stack.append(node)
    }
    func parser(_ parser: XMLParser, foundCharacters string: String) { if ignoredDepth == 0 { stack.last?.text += string } }
    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        if ignoredDepth == 0, let text = String(data: CDATABlock, encoding: .utf8) { stack.last?.text += text }
    }
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if ignoredDepth > 0 { ignoredDepth -= 1 } else { _ = stack.popLast() }
    }
    func parser(_ parser: XMLParser, foundInternalEntityDeclarationWithName name: String, value: String?) { rejectedEntity = true; parser.abortParsing() }
    func parser(_ parser: XMLParser, foundExternalEntityDeclarationWithName name: String, publicID: String?, systemID: String?) { rejectedEntity = true; parser.abortParsing() }
}
