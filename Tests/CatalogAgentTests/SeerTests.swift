import Foundation
import GraniteAgents
import XCTest
@testable import CatalogAgent

/// The Seer call (`Schema/examples/seer.json`) held to Seer's scorecard: every code item of the `models` and `world`
/// areas the kit owns matches what the call writes, every word the spec quotes for its screens is in the code, and
/// each destination opens its state.
final class SeerTests: XCTestCase {
    /// The Seer call's files, written once: into `CATALOG_OUT` when it is set, for a script to read.
    nonisolated(unsafe) private static var written: (result: CatalogResult, code: String)?

    private func seer() throws -> (result: CatalogResult, code: String) {
        if let written = Self.written { return written }
        var input = try Fixture.example("seer")
        let out = ProcessInfo.processInfo.environment["CATALOG_OUT"]
        let folder = try out.map { URL(fileURLWithPath: $0) } ?? Fixture.folder()
        input.directory = folder.path
        let result = try CatalogAgent.write(input, note: { _ in }, yield: { _ in })
        let written = (result, try Fixture.all(result.paths))
        Self.written = written
        return written
    }

    /// Each code item of `models` and `world` in `task/seer/scorecard.json`, its patterns as the scorecard gives them,
    /// but the items the brief gives elsewhere: B-models-16 and B-data-5/6/7 are `$mocks`' seeded data, B-world-17 is
    /// the Void page's infinity button. B-data-1 is the launch every kit reads.
    static let scorecard: [(id: String, all: [String])] = [
        ("B-models-12", [#"spring\(duration:\s*0\.20?,\s*bounce:\s*0\.40?\)"#, #"\b0\.97\b"#, #"spring\(duration:\s*0\.65,\s*bounce:\s*0\.35\)"#,
                         #"\.delay\(0\.10?\)"#]),
        ("B-models-13", [#"easeInOut\(duration:\s*1\.9\)"#, #"repeatForever\(autoreverses:\s*true\)"#, #"\b1\.4\b"#]),
        ("B-models-14", [#"wallet\.bifold"#, "Edit model", "Set Offline", #"network\.slash"#, "Set Online", "Delete model"]),
        ("B-models-15", [#""credits""#, #""documents?"|documents""#, "No Models", #"questionmark\.folder\.fill"#]),
        ("B-models-17", [#"\) Model"|" Model""#, "Updated: "]),
        ("B-models-18", [#"presentationDetents\(\s*\[\s*\.fraction\(0\.60?\)"#]),
        ("B-models-19", [#"swipeActions|\.onDelete"#]),
        ("B-models-20", [#"Name your model\.\.\."#, #"Describe this model\.\.\."#]),
        ("B-models-21", ["add tag", "Add Tag", "Edit Tag", "Tag name"]),
        ("B-models-22", ["paintpalette", #"\.fraction\(0\.32\)"#, #"presentationCornerRadius\(28(\.0)?\)"#]),
        ("B-models-23", [#"\.mint\b"#, #"\.teal\b"#, #"\.cyan\b"#, #"\.indigo\b"#]),
        ("B-models-24", [#"\.fraction\(0\.78\)"#, #"location:\s*1\.5\b"#, #"spring\(duration:\s*0\.25\)"#]),
        ("B-world-8", [#"Search all models(…|\.\.\.)"#, #"ContentUnavailableView\.search"#]),
        ("B-world-9", [#"%\.2f|fractionLength\(2\)"#, #"(\s|")cr""#]),
        ("B-world-10", ["Add to Loom", "Add to existing Loom", "Create new Loom", "Create with your models"]),
        ("B-world-11", [#"plus\.circle"#, #"xmark\.circle\.fill"#, "magnifyingglass"]),
        ("B-world-12", [##""#(\\\(|")"##, #"<=\s*3\b|<\s*4\b|\.\.\.\s*3\b"#]),
        ("B-world-13", [#"slider\.horizontal\.3"#, "No Looms Yet",
                        #"Create a Loom to organize and filter your favorite models for focused conversations\."#]),
        ("B-world-14", ["active loom", "deselect", #""pencil""#, #"checkmark\.circle\.fill"#, #"joined\(separator:\s*" · "\)"#]),
        ("B-world-15", [#"e\.g\. Research, News, Deep Cuts(…|\.\.\.)"#, "Loom name", "Models in this Loom", "Add your personal models"]),
        ("B-world-16", ["Edit Loom", "Add Models", "Public Models", "Your Models"]),
        ("B-data-1", ["UserDefaults", #""destination""#]),
    ]

    func testEveryCodeItemOfModelsAndWorldMatchesTheSeerCall() throws {
        let code = try seer().code
        for item in Self.scorecard {
            for pattern in item.all {
                XCTAssertNotNil(code.range(of: pattern, options: .regularExpression), "\(item.id): no match for \(pattern)")
            }
        }
    }

    /// The words the spec quotes for Models, Model detail, Model edit, The World and Looms, as the code writes them; a
    /// word the view fills in as it draws is held to its literal part (`"by \(owner)"` for "by Tomas Vey").
    static let quoted = [
        // Models.
        #""Models""#, #""documents""#, #""document""#, #""credits""#, "%.2f", #""No Models""#, #""Edit model""#, #""Set Offline""#,
        #""Set Online""#, #""Delete model""#,
        // Model detail: "Space Model", "Updated: Nov 12, 2026".
        #") Model""#, #""Updated: \("#, ".abbreviated",
        // Model edit.
        #""Cancel""#, #""Edit Model""#, #""Save""#, #""Name your model...""#, #""Description""#, #""Describe this model...""#, #""Tags""#,
        #""add tag""#, #""Add Tag""#, #""Edit Tag""#, #""Tag name""#, #""Color""#, #""Done""#,
        // The World: "by Tomas Vey", "#1", "58.40 cr", "8 docs", "1 doc", "2 models".
        #""The World""#, #""Browse""#, #""Looms""#, #""Search all models…""#, #""by \("#, ##""#\("##, #") cr""#, #") docs""#, #") doc""#,
        #""Add to Loom""#, #""Add to existing Loom""#, #") models""#, #""Create new Loom""#, #""New Loom""#, #""Create with your models""#,
        // Looms: "1 model".
        #""active loom""#, #""deselect""#, #") model""#, #"" · ""#, #""No Looms Yet""#,
        #""Create a Loom to organize and filter your favorite models for focused conversations.""#, #""Create""#, #""Loom name""#,
        #""e.g. Research, News, Deep Cuts…""#, #""Models in this Loom""#, #""Add your personal models""#, #""Edit Loom""#,
        #""Add Models""#, #""Public Models""#, #""Your Models""#,
    ]

    func testEveryWordTheSpecQuotesForTheseScreensIsInTheCode() throws {
        let code = try seer().code
        for word in Self.quoted { XCTAssertTrue(code.contains(word), "the code has no \(word)") }
    }

    func testEachDestinationOpensItsState() throws {
        let (result, _) = try seer()
        let launch = try Fixture.text(result.paths, "CatalogLaunch.swift")
        for line in [#"case "models": return .mine"#, #"case "model": return .detail("Space")"#, #"case "model.edit": return .edit("Space")"#,
                     #"case "world": return .browse"#, #"case "looms": return .groupings"#, #"case "looms.create": return .newGrouping"#] {
            XCTAssertTrue(launch.contains(line), line)
        }
        let collections = try Fixture.text(result.paths, "CollectionsView.swift")
        XCTAssertTrue(collections.contains("@State private var launch = CatalogLaunch.current"))
        XCTAssertTrue(collections.contains("unanimated.disablesAnimations = true"), "a launch's sheet goes up unanimated")
        // `looms` and `looms.create` open the Looms tab; `looms.create` with the New Loom form up from the first frame.
        let catalog = try Fixture.text(result.paths, "CatalogView.swift")
        XCTAssertTrue(catalog.contains("_tab = State(initialValue: launch == .groupings || launch == .newGrouping ? .groupings : .browse)"))
        XCTAssertTrue(catalog.contains("_form = State(initialValue: launch == .newGrouping ? CatalogForm(grouping: nil, members: []) : nil)"))
        let form = try Fixture.text(result.paths, "GroupingFormView.swift")
        for word in [#""New Loom""#, #""Loom name""#, #""e.g. Research, News, Deep Cuts…""#, #""Add your personal models""#,
                     #""Cancel""#, #""Create""#] {
            XCTAssertTrue(form.contains(word), "the New Loom form has \(word)")
        }
    }

    /// The look is the original's: the bronze tint and DesignAgent's type and spacing by name, the cards' and panels'
    /// colours by hex, and the system's background and text where the original reads the system's.
    func testTheLookIsTheOriginals() throws {
        let (result, _) = try seer()
        let look = try Fixture.text(result.paths, "CatalogLook.swift")
        for line in ["static var accent: Color { Color.accent }",
                     "static var background: Color { CatalogLook.system(.background) }",
                     "static var ink: Color { Color.primary }",
                     "static var card: Color { CatalogLook.dynamic(light: 0xFFFFFF, lightOpacity: 1, dark: 0xFFFFFF, darkOpacity: 0.10) }",
                     "static var panel: Color { CatalogLook.dynamic(light: 0xFFFFFF, lightOpacity: 1, dark: 0x1A1A1A, darkOpacity: 1) }",
                     "static var cardShadow: Color { CatalogLook.dynamic(light: 0x8E8E8E, lightOpacity: 0.14, dark: 0x000000, darkOpacity: 0) }",
                     "static var title: Font { Font.brandTitle }", "static var note2: Font { Font.brandNote2 }",
                     "static var design: Font.Design { .serif }", "static var layer7: CGFloat { CGFloat.layer7 }"] {
            XCTAssertTrue(look.contains(line), line)
        }
        let all = try seer().code
        XCTAssertTrue(all.contains(#"CatalogValue.formatted(date, "MMMM d, yyyy · h:mm:ss a")"#), "the card's date as the original writes it")
        XCTAssertTrue(all.contains("CatalogValue.formatted(date, date: .abbreviated, time: .omitted)"), "a row's: Nov 12, 2026")
        // Every date in New York's zone and US English, whatever the device's, as the original's `asReadableDateTime`.
        XCTAssertTrue(all.contains(#"static let dateZone: TimeZone? = TimeZone(identifier: "America/New_York")"#))
        XCTAssertTrue(all.contains("if let dateZone { formatter.timeZone = dateZone }"))
        XCTAssertTrue(all.contains(#"locale: Locale(identifier: "en_US")"#))
        XCTAssertTrue(all.contains(#""text.document.fill""#) && all.contains(#""person""#))
    }

    func testTheAnswerGivesEachInitializerWithSeersTypes() throws {
        let (result, _) = try seer()
        XCTAssertEqual(result.conformances, ["ModelGroup: collection", "Note: document", "World: listing", "Loom: grouping"])
        XCTAssertTrue(result.initializers[0].hasPrefix("CollectionsView(collections: [ModelGroup], documents: [Note], "))
        XCTAssertTrue(result.initializers[0].hasSuffix("page: (@MainActor (Note) -> AnyView)? = nil)"))
        XCTAssertTrue(result.initializers[1].hasPrefix("CatalogView(listings: [World], mine: [ModelGroup], groupings: [Loom], "))
        XCTAssertTrue(result.initializers[1].contains("search: (@MainActor (String) async throws -> [World])? = nil"))
        let world = try Fixture.text(result.paths, "World+Listing.swift")
        XCTAssertTrue(world.hasPrefix("import Foundation\nimport SwiftUI\nimport SeerKit\n"))
        XCTAssertTrue(world.contains("var catalogCredits: Double? { CatalogValue.number(self.credits) }"))
        XCTAssertTrue(try Fixture.text(result.paths, "Loom+Grouping.swift").contains("var catalogMembers: [String] { CatalogValue.keys(self.models) }"))
    }

    /// `Schema/examples/seer.answer.json` is what the call answers through the roster, its paths from the project.
    /// `CATALOG_EXAMPLES=1` writes it afresh.
    func testTheExampleAnswerIsWhatTheCallAnswers() async throws {
        let folder = try Fixture.folder()
        var call = try JSONSerialization.jsonObject(with: Data(contentsOf: Fixture.package.appendingPathComponent("Schema/examples/seer.json"))) as! [String: Any]
        call["directory"] = folder.path
        let answer = try await AnyAgentPackage(CatalogAgent.self).perform(try JSONSerialization.data(withJSONObject: call),
                                                                           host: AgentHost(directory: folder.path))
        let root = folder.resolvingSymlinksInPath().path + "/"
        let text = String(decoding: answer, as: UTF8.self)
            .replacingOccurrences(of: root.replacingOccurrences(of: "/", with: "\\/"), with: "")
            .replacingOccurrences(of: root, with: "")
            .replacingOccurrences(of: folder.path + "/", with: "")
        let object = try JSONSerialization.jsonObject(with: Data(text.utf8))
        let pretty = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        let file = Fixture.package.appendingPathComponent("Schema/examples/seer.answer.json")
        if ProcessInfo.processInfo.environment["CATALOG_EXAMPLES"] == "1" {
            try (String(decoding: pretty, as: UTF8.self) + "\n").write(to: file, atomically: true, encoding: .utf8)
        }
        let kept = try JSONSerialization.jsonObject(with: Data(contentsOf: file))
        XCTAssertEqual(try JSONSerialization.data(withJSONObject: kept, options: [.sortedKeys]),
                       try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]),
                       "seer.answer.json is stale: run with CATALOG_EXAMPLES=1")
        XCTAssertTrue(text.contains("Components/Catalog/CollectionsView.swift"))
    }

    /// The other example, a recipe app's, is read and written whole.
    func testTheOtherExampleIsAccepted() throws {
        var input = try Fixture.example("recipes")
        input.directory = try Fixture.folder().path
        let result = try CatalogAgent.write(input, note: { _ in }, yield: { _ in })
        XCTAssertTrue(result.paths.contains { $0.hasSuffix("/Cookbook+Collection.swift") })
    }
}
