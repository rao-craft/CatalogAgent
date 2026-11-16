import Foundation
import GraniteAgents
import XCTest
@testable import CatalogAgent

/// The documents a host and a person read, held to the code: the schemas are the record's, as `craft agents schema`
/// writes them, with every key a line may name given as an example; the reference's tables are the tables every
/// line is read against; and the Seer call and page bodies it gives are the ones the suite and the gated build use.
/// `CATALOG_EXAMPLES=1` writes them afresh.
final class ReferenceTests: XCTestCase {
    private var regenerate: Bool { ProcessInfo.processInfo.environment["CATALOG_EXAMPLES"] == "1" }
    private let catalog = AnyAgentPackage(CatalogAgent.self)
    private let base = "https://github.com/rao-craft/CatalogAgent/blob/main/Schema/"

    func testTheInputSchemaIsTheRecordsWithEveryKeyAsAnExample() throws {
        var input = try XCTUnwrap(try JSONSerialization.jsonObject(
            with: catalog.schema.jsonSchema(notes: catalog.fields, hiding: [AnyAgentPackage.directoryField])) as? [String: Any])
        input["$schema"] = "https://json-schema.org/draft/2020-12/schema"
        input["$id"] = base + "catalog.input.schema.json"
        input["title"] = "What catalog takes (craft-agent/1)"
        input["description"] = "Every field a call to catalog may give; `directory` is Craft's, never the model's."
        var properties = try XCTUnwrap(input["properties"] as? [String: Any])
        for (field, lines) in Self.everyKey {
            var property = try XCTUnwrap(properties[field] as? [String: Any], field)
            property["examples"] = [lines]
            properties[field] = property
        }
        input["properties"] = properties
        try check(input, "catalog.input.schema.json")
    }

    func testTheAnswerSchemaIsGraniteAnswerWithTheKindsItMakes() throws {
        let item: [String: Any] = ["type": "object", "required": ["kind", "name"],
                                   "properties": ["kind": ["type": "string", "enum": CatalogAgent.makes.map(\.kind)], "name": ["type": "string"]]]
        let answer: [String: Any] = [
            "$schema": "https://json-schema.org/draft/2020-12/schema", "$id": base + "catalog.answer.schema.json",
            "title": "What catalog answers (granite-answer/1)",
            "description": "A granite-answer/1 answer; what catalog makes and expects is one of its own kinds.",
            "allOf": [["$ref": "https://github.com/riteshpakala/Granite/blob/main/Schema/granite-agent-answer.schema.json"]],
            "properties": ["made": ["type": "array", "items": item], "expected": ["type": "array", "items": item]],
        ]
        try check(answer, "catalog.answer.schema.json")
    }

    /// Every example line is one the agent reads: a default written as a line is a line it takes.
    func testEveryKeyGivenAsAnExampleIsALineItReads() throws {
        let lines = Dictionary(uniqueKeysWithValues: Self.everyKey)
        for line in lines["strings"] ?? [] { XCTAssertNoThrow(try StringLine.parse(line), line) }
        for line in lines["symbols"] ?? [] { XCTAssertNoThrow(try SymbolLine.parse(line), line) }
        for line in lines["tuning"] ?? [] { XCTAssertNoThrow(try TuningLine.parse(line), line) }
        XCTAssertEqual(lines["strings"]?.count, CatalogWords.all.count)
        XCTAssertEqual(lines["symbols"]?.count, CatalogSymbol.all.count)
        XCTAssertEqual(lines["tuning"]?.count, CatalogTuning.all.count)
    }

    func testTheReferenceRegionsAreWrittenFromTheCode() throws {
        let file = Fixture.package.appendingPathComponent("Schema/Catalog.md")
        var text = try String(contentsOf: file, encoding: .utf8)
        for (name, written) in [("fields", Self.fieldsTable()), ("makes", Self.makesTable()), ("tables", Self.tables())] {
            let begin = "<!-- \(name): written by ReferenceTests from the code -->\n", end = "<!-- /\(name) -->"
            let start = try XCTUnwrap(text.range(of: begin), "Catalog.md marks where its \(name) go")
            let stop = try XCTUnwrap(text.range(of: end, range: start.upperBound..<text.endIndex), "Catalog.md closes its \(name)")
            if regenerate {
                text.replaceSubrange(start.upperBound..<stop.lowerBound, with: written)
            } else {
                XCTAssertEqual(String(text[start.upperBound..<stop.lowerBound]), written, "Catalog.md's \(name) are stale: run with CATALOG_EXAMPLES=1")
            }
        }
        if regenerate { try text.write(to: file, atomically: true, encoding: .utf8) }
    }

    /// The Seer call the reference gives is `seer.json`, and its page bodies are the ones `CatalogBuildTests` compiles.
    func testTheReferenceGivesTheSeerCallAndThePageBodiesTheBuildCompiles() throws {
        let reference = try String(contentsOf: Fixture.package.appendingPathComponent("Schema/Catalog.md"), encoding: .utf8)
        let seer = try String(contentsOf: Fixture.package.appendingPathComponent("Schema/examples/seer.json"), encoding: .utf8)
        XCTAssertTrue(reference.contains(seer.trimmingCharacters(in: .whitespacesAndNewlines)), "Catalog.md gives the Seer call as seer.json holds it")
        XCTAssertTrue(reference.contains(SeerPages.models), "Catalog.md gives the Models page's body")
        XCTAssertTrue(reference.contains(SeerPages.world), "Catalog.md gives The World page's body")
        for state in ["`mine`", "`detail \"<name>\"`", "`edit \"<name>\"`", "`browse`", "`groupings`", "`groupings new`"] {
            XCTAssertTrue(reference.contains(state), "Catalog.md names the launch state \(state)")
        }
    }

    // MARK: Writing

    private func check(_ object: [String: Any], _ name: String) throws {
        var data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        data.append(0x0A)
        let file = Fixture.package.appendingPathComponent("Schema/" + name)
        if regenerate { try data.write(to: file) }
        XCTAssertEqual(try Data(contentsOf: file), data, "\(name) is stale: run with CATALOG_EXAMPLES=1")
    }

    /// Every key a `strings`, `symbols` or `tuning` line may name, written as the line that sets its default.
    static var everyKey: [(String, [String])] {
        func quoted(_ text: String) -> String {
            "\"" + text.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + "\""
        }
        return [
            ("strings", CatalogWords.all.map { "\($0.key) = \(quoted($0.fallback))" }),
            ("symbols", CatalogSymbol.all.map { "\($0.key) = \($0.fallback)" }),
            ("tuning", CatalogTuning.all.map { "\($0.key) = \($0.fallback)" }),
        ]
    }

    private static func cell(_ text: String) -> String {
        text.replacingOccurrences(of: "|", with: "\\|").replacingOccurrences(of: "\n", with: " ")
    }

    static func fieldsTable() -> String {
        var lines = ["| Field | Required | What it is |", "| --- | --- | --- |"]
        for field in AnyAgentPackage(CatalogAgent.self).schema.fields where field.name != AnyAgentPackage.directoryField {
            lines.append("| `\(field.name)` | \(field.required ? "yes" : "no") | \(cell(CatalogAgent.fields[field.name] ?? "")) |")
        }
        return lines.joined(separator: "\n") + "\n"
    }

    static func makesTable() -> String {
        var lines = ["| Kind | What | Into | Never |", "| --- | --- | --- | --- |"]
        for make in CatalogAgent.makes {
            lines.append("| `\(make.kind)` | \(cell(make.what)) | " + make.into.map { "`\($0)`" }.joined(separator: ", ") + " | \(cell(make.never ?? "")) |")
        }
        return lines.joined(separator: "\n") + "\n"
    }

    static func tables() -> String {
        var lines: [String] = []

        lines += ["### Mapping words", "",
                  "A line starts with the role or one of its other words, any case. `id=` is read too, only for a type with no `id` of its own.", "",
                  "| Role | A line may start with | Word | Also read as | Requirement | What it is |", "| --- | --- | --- | --- | --- | --- |"]
        for role in CatalogRole.allCases {
            for (index, property) in role.properties.enumerated() {
                let head = index == 0 ? "`\(role.rawValue)`" : ""
                let starts = index == 0 ? ([role.rawValue] + role.aliases).map { "`\($0)`" }.joined(separator: ", ") : ""
                let aliases = property.aliases.map { "`\($0)`" }.joined(separator: ", ")
                lines.append("| \(head) | \(starts) | `\(property.key)` | \(aliases) | `\(property.member): \(property.kind.swiftType)` | \(cell(property.doc)) |")
            }
        }
        var kinds: [(kind: CatalogKind, words: [String])] = []
        for property in CatalogRole.allCases.flatMap(\.properties) {
            if let index = kinds.firstIndex(where: { $0.kind == property.kind }) {
                if !kinds[index].words.contains(property.key) { kinds[index].words.append(property.key) }
            } else {
                kinds.append((property.kind, [property.key]))
            }
        }
        lines += ["", "A right side goes through `CatalogValue`, which takes the app's field as it is:", "",
                  "| Words | Requirement | The app's field may be |", "| --- | --- | --- |"]
        for (kind, words) in kinds {
            lines.append("| " + words.map { "`\($0)`" }.joined(separator: ", ") + " | `\(kind.swiftType)` | \(cell(kind.takesInWords)) |")
        }

        lines += ["", "### Look roles", "", "| Role | Kind | Without a line | Where it shows |", "| --- | --- | --- | --- |"]
        for role in CatalogLookRole.all {
            lines.append("| `\(role.key)` | \(role.kind.rawValue) | `\(role.fallback)` | \(cell(role.doc)) |")
        }

        lines += ["", "### String keys", "",
                  "The defaults are made of the four nouns, `{collection}` (`{Collection}` capitalised) and the others, so four lines rename every word. " +
                  "A key that fills something in as the view draws names it in braces, and takes no other placeholder but the nouns.", "",
                  "| Key | Default | Fills in | Where it shows |", "| --- | --- | --- | --- |"]
        for word in CatalogWords.all {
            let fills = word.fills.map { "`{\($0)}`" }.joined(separator: ", ")
            lines.append("| `\(word.key)` | \"\(cell(word.fallback))\" | \(fills) | \(cell(word.doc)) |")
        }

        lines += ["", "### Symbol keys", "", "| Key | Default | Where it shows |", "| --- | --- | --- |"]
        for symbol in CatalogSymbol.all { lines.append("| `\(symbol.key)` | `\(symbol.fallback)` | \(cell(symbol.doc)) |") }

        lines += ["", "### Tuning keys", "",
                  "The motion keys are the four animations; the rest are sizes, counts, detents, swatches and date styles.", "",
                  "| Key | Kind | Default | What it sets |", "| --- | --- | --- | --- |"]
        for tuning in CatalogTuning.all {
            lines.append("| `\(tuning.key)` | \(tuning.kind.rawValue) | `\(tuning.fallback)` | \(cell(tuning.doc)) |")
        }
        lines += ["", "Swatches are among " + CatalogTuning.systemColors.map { "`\($0)`" }.joined(separator: ", ") +
                  ". Date styles: " + CatalogTuning.dateStyles.map { "`.\($0)`" }.joined(separator: ", ") +
                  "; time styles: " + CatalogTuning.timeStyles.map { "`.\($0)`" }.joined(separator: ", ") + "."]
        return lines.joined(separator: "\n") + "\n"
    }
}
