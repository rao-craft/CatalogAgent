import Foundation
import XCTest
@testable import CatalogAgent

/// The templates held to the catalog and the tables, so no call can write a file that names a key no table holds,
/// keeps a marker, leaves a view unprefixed, or draws an icon a screen reader cannot name.
final class TemplateTests: XCTestCase {
    private var templates: [(name: String, text: String)] {
        KitCatalog.parts.map { ($0.name, $0.template) } + [("CatalogLookTail", Template.catalogLookTail)]
    }

    /// Every non-empty set of screens.
    private var screenSets: [Set<CatalogScreen>] {
        let all = CatalogScreen.allCases
        return (1..<(1 << all.count)).map { mask in Set(all.enumerated().filter { mask & (1 << $0.offset) != 0 }.map(\.element)) }
    }

    func testEveryTemplateFillsAndRendersForEverySetOfScreens() throws {
        for screens in screenSets {
            let flags = KitCatalog.flags(screens)
            for part in KitCatalog.plan(screens) {
                let filled = try TemplateFill.fill(part.template, values: .defaults)
                XCTAssertFalse(filled.contains("{{"), "\(part.name) keeps a token")
                let rendered = try TemplateRender.render(filled, flags: flags)
                XCTAssertFalse(rendered.contains("//@"), "\(part.name) keeps a marker for \(screens)")
            }
        }
    }

    func testEveryFlagATemplateNamesIsOneACallCanSet() {
        let known = Set(CatalogScreen.allCases.map { "screen.\($0.rawValue)" } + KitCatalog.parts.map { "part.\($0.name)" })
        for (name, text) in templates {
            for line in text.split(separator: "\n") where line.trimmingCharacters(in: .whitespaces).hasPrefix("//@if ") {
                let condition = line.trimmingCharacters(in: .whitespaces).dropFirst(6)
                for word in condition.split(whereSeparator: { " &|!()".contains($0) }) {
                    XCTAssertTrue(known.contains(String(word)), "\(name) names the flag \(word)")
                }
            }
        }
    }

    /// Whatever screens a call names, the files read as written by hand: no blank-line runs, no blank line against a
    /// brace, no trailing spaces, one newline at the end.
    func testEveryFileIsTidyWhateverTheScreens() throws {
        for screens in screenSets {
            for part in KitCatalog.plan(screens) {
                let text = try TemplateRender.render(try TemplateFill.fill(part.template, values: .defaults), flags: KitCatalog.flags(screens))
                XCTAssertFalse(text.contains("\n\n\n"), "\(part.name) has a run of blank lines")
                XCTAssertNil(text.range(of: #"\{\n\n|\n\n\s*\}"#, options: .regularExpression), "\(part.name) has a blank line against a brace")
                XCTAssertNil(text.range(of: #"[ \t]\n"#, options: .regularExpression), "\(part.name) has trailing spaces")
                XCTAssertTrue(text.hasSuffix("}\n"), "\(part.name) ends with one newline")
            }
        }
    }

    /// A view a part lists is declared by it, and is the one the prefix renames; any other view it declares is a
    /// helper of the kit's, named `Catalog…`.
    func testEveryViewAPartListsIsDeclaredByItAndHelpersAreNamedCatalog() {
        for part in KitCatalog.parts {
            let declared = matches(#"(?m)^struct ([A-Z][A-Za-z]*)(?:<[^>]*>)?: View(?![A-Za-z])"#, in: part.template, group: 1)
            XCTAssertTrue(Set(part.views).isSubset(of: Set(declared)), "\(part.name) declares \(declared), lists \(part.views)")
            for view in declared where !part.views.contains(view) {
                XCTAssertTrue(view.hasPrefix("Catalog"), "\(part.name)'s helper \(view) is named Catalog…")
                XCTAssertFalse(KitCatalog.parts.contains { $0.views.contains(view) }, "\(view) is listed by another part")
            }
        }
    }

    func testEveryViewFileHasAPreviewFromTheSamples() {
        for part in KitCatalog.parts where !part.views.isEmpty {
            XCTAssertTrue(part.template.contains("#Preview"), "\(part.name) has no #Preview")
            XCTAssertFalse(part.template.contains("ModelGroup"), "\(part.name) previews an app's types")
        }
    }

    /// A button drawn as a glyph alone carries a label a screen reader reads.
    func testEveryIconOnlyControlHasAnAccessibilityLabel() {
        for (name, text) in templates {
            var rest = Substring(text)
            while let label = rest.range(of: "} label: {") {
                let body = rest[label.upperBound...]
                guard let end = Self.closing(body) else { break }
                let content = body[..<end]
                let after = body[end...].prefix(400)
                if content.contains("Image(systemName:"), !content.contains("Text("), !content.contains("Label(") {
                    let tail = after.split(separator: "\n").prefix(6).joined(separator: "\n")
                    XCTAssertTrue(tail.contains(".accessibilityLabel("), "\(name): a glyph-only button has no label:\n\(content)")
                }
                rest = body[end...]
            }
        }
    }

    /// Every word, symbol, timing and look role a table holds is drawn somewhere, and every one a template names is
    /// in a table: a key no view reads is a key a call sets for nothing.
    func testEveryKeyOfTheTablesIsReadByATemplate() {
        let all = templates.map(\.text).joined(separator: "\n") + LookEmitter.emit(.defaults, mapped: [])
        for word in CatalogWords.all where !CatalogWords.nouns.contains(word.key) {
            XCTAssertTrue(all.contains("{{s:\(word.key)}}") || all.contains("{{s:\(word.key)|"), "no template shows \(word.key)")
        }
        for symbol in CatalogSymbol.all { XCTAssertTrue(all.contains("{{sym:\(symbol.key)}}"), "no template draws \(symbol.key)") }
        let viaDates: Set<String> = ["cardDate", "cardTime", "rowDate", "swatches"]
        for tuning in CatalogTuning.all where !viaDates.contains(tuning.key) {
            XCTAssertTrue(all.contains("{{n:\(tuning.key)}}") || all.contains("{{m:\(tuning.key)}}"), "no template uses \(tuning.key)")
        }
        XCTAssertTrue(all.contains("{{date:card}}") && all.contains("{{date:row}}") && all.contains("{{swatches}}"))
        // The spacing scale is the app's whole scale (layer1 … layer7), read where the original reads a step of it.
        for role in CatalogLookRole.all where role.kind != .design && role.kind != .spacing {
            XCTAssertTrue(templates.contains { $0.text.contains("CatalogLook.\(role.key)") }, "no template reads the look's \(role.key)")
        }
    }

    func testTheProtocolFileDeclaresEveryRequirementWithItsDefault() {
        let text = ProtocolsEmitter.emit()
        for role in CatalogRole.allCases {
            XCTAssertTrue(text.contains("protocol \(role.protocolName): Identifiable {"))
            for property in role.properties {
                XCTAssertTrue(text.contains("    var \(property.member): \(property.kind.swiftType) { get }"), property.member)
                XCTAssertTrue(text.contains("    var \(property.member): \(property.kind.swiftType) { \(property.kind.defaultValue) }"), property.member)
            }
        }
        // Every requirement a template reads is in the table, or one of the kit's own helpers.
        let requirements = Set(CatalogRole.allCases.flatMap { $0.properties.map(\.member) } + ["catalogKey", "catalogColorName"])
        let helpers: Set<String> = ["catalogText", "catalogTitle", "catalogInline", "catalogInsetGrouped", "catalogNoCapitals",
                                    "catalogRefreshable", "catalogField", "catalogBadge"]
        for (name, template) in templates {
            for member in matches(#"\bcatalog[A-Z][A-Za-z]*"#, in: template) where !requirements.contains(member) {
                XCTAssertTrue(helpers.contains(member), "\(name) reads \(member), which no role declares")
            }
        }
    }

    /// Every user-facing word comes from the words table: no literal English in `Text("…")`.
    func testNoTemplateWritesItsOwnWords() {
        for (name, text) in templates {
            for literal in matches(#"(?:Text|Button|Label|TextField)\("([^"\\{]+)""#, in: text, group: 1) {
                XCTFail("\(name) writes its own words: \(literal)")
            }
        }
    }

    // MARK: Helpers

    /// The index of the `}` that closes the block `text` starts inside.
    private static func closing(_ text: Substring) -> Substring.Index? {
        var depth = 1
        var index = text.startIndex
        while index < text.endIndex {
            switch text[index] {
            case "{": depth += 1
            case "}":
                depth -= 1
                if depth == 0 { return index }
            default: break
            }
            index = text.index(after: index)
        }
        return nil
    }

    private func matches(_ pattern: String, in text: String, group: Int = 0) -> [String] {
        guard let expression = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return expression.matches(in: text, range: range).compactMap { match in
            Range(match.range(at: group), in: text).map { String(text[$0]) }
        }
    }
}
