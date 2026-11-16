import Foundation
import XCTest
import GraniteAgents
@testable import CatalogAgent

/// What the files say: the conformances the lines make, the parts the screens choose, the prefix, the look and
/// launch files, the same bytes on a second call, and nothing written when the call is refused.
final class CatalogEmitTests: XCTestCase {
    private func write(_ input: CatalogAgent.Input, in folder: URL? = nil) throws -> (CatalogResult, URL) {
        let folder = try folder ?? Fixture.folder()
        var input = input
        input.directory = folder.path
        return (try CatalogAgent.write(input, note: { _ in }, yield: { _ in }), folder)
    }

    private func names(_ result: CatalogResult) -> Set<String> {
        Set(result.paths.map { URL(fileURLWithPath: $0).lastPathComponent })
    }

    // MARK: Conformances

    func testAConformanceReadsEachPathThroughCatalogValueAndBindsValueOnlyWhenNamed() throws {
        let (result, _) = try write(.init(mappings: [
            #"collection: Cookbook id=slug name=value.title ?? "Untitled" count=recipeCount color=tint updated=editedAt"#,
        ], screens: [.mine]))
        let book = try Fixture.text(result.paths, "Cookbook+Collection.swift")
        XCTAssertTrue(book.hasPrefix("import Foundation\nimport SwiftUI\n\n"))
        XCTAssertTrue(book.contains("extension Cookbook: CollectionRepresentable {"))
        XCTAssertTrue(book.contains("public var id: String { CatalogValue.id(self.slug) }"), "a public type's id must be public")
        XCTAssertTrue(book.contains("        let value = self\n        return CatalogValue.text(value.title ?? \"Untitled\")"))
        XCTAssertTrue(book.contains("var catalogCount: Int? { CatalogValue.optionalInt(self.recipeCount) }"))
        XCTAssertTrue(book.contains("var catalogColor: Color? { CatalogValue.color(self.tint) }"))
        XCTAssertTrue(book.contains("var catalogColorName: String? { CatalogValue.colorName(self.tint) }"), "the colour's name, for the edit form")
        XCTAssertTrue(book.contains("var catalogUpdated: Date? { CatalogValue.date(self.editedAt) }"))
        XCTAssertFalse(book.contains("catalogSummary"), "an unmapped property keeps the protocol's default")
    }

    func testAnIdTheTypeHasIsNotRedeclaredAndImportsAreWritten() throws {
        let (result, _) = try write(.init(mappings: ["grouping: Kit.Shelf id=id name=label members=bookIDs"], screens: [.groupings],
                                          imports: ["Kit"]))
        let shelf = try Fixture.text(result.paths, "KitShelf+Grouping.swift")
        XCTAssertFalse(shelf.contains("var id"))
        XCTAssertTrue(shelf.hasPrefix("import Foundation\nimport SwiftUI\nimport Kit\n"))
        XCTAssertTrue(shelf.contains("var catalogMembers: [String] { CatalogValue.keys(self.bookIDs) }"))
    }

    /// A book of mine that is also listed for others: what both protocols ask for is written once, as a line maps it
    /// or as its default, since Swift will not choose between two protocols' defaults for one type.
    func testOneTypeInTwoRolesWritesSharedMembersOnce() throws {
        let (result, _) = try write(.init(mappings: [
            "collection: Book name=title summary=blurb tags=cuisines",
            "listing: Book name=title summary=blurb owner=author",
        ]))
        let mine = try Fixture.text(result.paths, "Book+Collection.swift")
        let listed = try Fixture.text(result.paths, "Book+Listing.swift")
        XCTAssertEqual(mine.components(separatedBy: "var catalogName").count, 2)
        XCTAssertFalse(listed.contains("catalogName"))
        XCTAssertTrue(mine.contains("var catalogKey: String { CatalogValue.key(id) }"), "the shared key is written out")
        XCTAssertTrue(mine.contains("var catalogTags: [String] { CatalogValue.tags(self.cuisines) }"))
        XCTAssertTrue(listed.contains("var catalogTags: [String] { [] }") || mine.contains("var catalogTags"), "tags once")
        XCTAssertTrue(listed.contains("var catalogOwner: String? { CatalogValue.optionalText(self.author) }"))
    }

    func testRolesThatDisagreeAndEveryOtherProblemAreRefusedAtOnceAndNothingIsWritten() throws {
        let folder = try Fixture.folder()
        let input = CatalogAgent.Input(mappings: [
            "collection: Book name=title count=pages", "listing: Book name=headline", "collection: Other name=x",
        ], look: ["glow = Color.red"], prefix: "kit", imports: ["Not A Module"], directory: folder.path)
        XCTAssertThrowsError(try CatalogAgent.write(input, note: { _ in }, yield: { _ in })) { error in
            let text = "\(error)"
            for reason in ["problems with the call, so nothing was written", "collection is mapped twice", "`glow` is not a look role",
                           "`Book` maps `name` one way as a collection and another as a listing", "`kit` is not a prefix",
                           "`Not A Module` is not a module name"] {
                XCTAssertTrue(text.contains(reason), "\(reason) in \(text)")
            }
        }
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: folder.path), [], "nothing is written")
    }

    /// The app's own Swift is read: a path its type lacks is refused with the fields it has, a field of a type the
    /// views cannot show is refused with what they take, and a type a local package declares is imported.
    func testPathsAreCheckedAgainstTheAppsTypes() throws {
        let folder = try Fixture.folder()
        let kit = folder.appendingPathComponent("Packages/BookKit/Sources/BookKit")
        try FileManager.default.createDirectory(at: kit, withIntermediateDirectories: true)
        try "// swift-tools-version:6.0\n".write(to: folder.appendingPathComponent("Packages/BookKit/Package.swift"), atomically: true, encoding: .utf8)
        try """
        public struct Book: Identifiable {
            public var id: String
            public var title: String
            public var genres: [String]
            public var author: Author
        }

        public struct Author {
            public var name: String
        }
        """.write(to: kit.appendingPathComponent("Book.swift"), atomically: true, encoding: .utf8)
        var input = CatalogAgent.Input(mappings: ["collection: Book name=titel online=genres"], directory: folder.path)
        XCTAssertThrowsError(try CatalogAgent.write(input, note: { _ in }, yield: { _ in })) { error in
            let text = "\(error)"
            XCTAssertTrue(text.contains("`Book` has no `titel`: its fields are id, title, genres, author"), text)
            XCTAssertTrue(text.contains("`genres` is `[String]`, and `online` shows a flag"), text)
        }
        input.mappings = ["listing: Book name=title tags=genres owner=author.name"]
        let result = try CatalogAgent.write(input, note: { _ in }, yield: { _ in })
        let book = try Fixture.text(result.paths, "Book+Listing.swift")
        XCTAssertTrue(book.contains("import BookKit"))
        XCTAssertTrue(book.contains("var catalogOwner: String? { CatalogValue.optionalText(self.author.name) }"))
        XCTAssertTrue(result.notes.contains("`Book` is declared in BookKit, so the conformances import it."))
    }

    // MARK: Parts

    func testTheScreensChooseTheFiles() throws {
        let core: Set<String> = ["CatalogProtocols.swift", "CatalogLook.swift", "CatalogLaunch.swift", "CatalogValue.swift",
                                 "CatalogParts.swift", "CatalogModels.swift", "CatalogSamples.swift"]
        let mine: Set<String> = ["CollectionsView.swift", "CollectionCard.swift", "CollectionDetailView.swift", "CollectionEditView.swift",
                                 "CatalogTagsEditor.swift", "CatalogSwatchesView.swift"]
        let (onlyMine, _) = try write(.init(screens: [.mine]))
        XCTAssertEqual(names(onlyMine), core.union(mine))
        XCTAssertEqual(onlyMine.initializers.count, 1)
        XCTAssertTrue(onlyMine.notes.contains("No line maps collection, document: the views take the kit's own CatalogCollection, CatalogDocument there."))

        let (browse, _) = try write(.init(screens: [.browse]))
        XCTAssertEqual(names(browse), core.union(["CatalogView.swift", "ListingRow.swift", "ListingsView.swift"]))
        let catalog = try Fixture.text(browse.paths, "CatalogView.swift")
        XCTAssertFalse(catalog.contains("tabRow"), "one screen draws no tabs")
        XCTAssertFalse(catalog.contains("GroupingsView") || catalog.contains("AddToGroupingView"))

        let (groupings, _) = try write(.init(screens: [.groupings]))
        XCTAssertEqual(names(groupings), core.union(["CatalogView.swift", "ListingRow.swift", "GroupingsView.swift", "GroupingFormView.swift"]))
        XCTAssertFalse(try Fixture.text(groupings.paths, "CatalogView.swift").contains("ListingsView"))

        let (both, _) = try write(.init(screens: [.browse, .groupings]))
        XCTAssertTrue(names(both).contains("AddToGroupingView.swift"))
        XCTAssertTrue(try Fixture.text(both.paths, "CatalogView.swift").contains("tabRow"))
        XCTAssertEqual(both.initializers.count, 1)
    }

    func testAPrefixRenamesTheViewsAndTheirFilesAndNothingElse() throws {
        let (result, _) = try write(.init(prefix: "Kit"))
        let files = names(result)
        for view in ["KitCollectionsView.swift", "KitCatalogView.swift", "KitListingRow.swift", "KitGroupingFormView.swift"] {
            XCTAssertTrue(files.contains(view), view)
        }
        XCTAssertTrue(files.contains("CatalogParts.swift") && files.contains("CatalogModels.swift"))
        let catalog = try Fixture.text(result.paths, "KitCatalogView.swift")
        XCTAssertTrue(catalog.contains("struct KitCatalogView<"))
        XCTAssertTrue(catalog.contains("KitListingsView(") && catalog.contains("KitGroupingsView("))
        XCTAssertTrue(catalog.contains("CatalogCloseButton"), "a helper keeps its name")
        XCTAssertFalse(catalog.contains("KitCatalogLook"))
        XCTAssertTrue(result.views.allSatisfy { $0.hasPrefix("Kit") })
        XCTAssertTrue(result.initializers.allSatisfy { $0.hasPrefix("Kit") })
    }

    // MARK: Values

    func testTheLookFileTakesTheCallsValuesAndTheSystemsElsewhere() throws {
        let (result, _) = try write(.init(screens: [.mine], look: ["accent = Color.accent", "card = #FFFFFF / #FFFFFF 0.10", "design = serif",
                                                                   "layer4 = CGFloat.layer4"]))
        let look = try Fixture.text(result.paths, "CatalogLook.swift")
        XCTAssertTrue(look.contains("enum CatalogLook {"))
        XCTAssertTrue(look.contains("    static var accent: Color { Color.accent }"))
        XCTAssertTrue(look.contains("    static var card: Color { CatalogLook.dynamic(light: 0xFFFFFF, lightOpacity: 1, dark: 0xFFFFFF, darkOpacity: 0.10) }"))
        XCTAssertTrue(look.contains("    static var design: Font.Design { .serif }"))
        XCTAssertTrue(look.contains("    static var layer4: CGFloat { CGFloat.layer4 }"))
        XCTAssertTrue(look.contains("    static var ink: Color { Color.primary }"))
        XCTAssertTrue(look.contains("The system's, as no look line maps it."))
        XCTAssertTrue(look.contains("    static var title: Font { CatalogLook.font(24) }"))
    }

    func testTheLaunchFileReadsTheDestinationAndOpensEachState() throws {
        let (result, _) = try write(.init(screens: [.mine], launch: ["models = mine", #"model = detail "Space""#, #"model.edit = edit "Space""#]))
        let launch = try Fixture.text(result.paths, "CatalogLaunch.swift")
        XCTAssertTrue(launch.contains(#"guard let destination = UserDefaults.standard.string(forKey: "destination") else { return nil }"#))
        XCTAssertTrue(launch.contains(#"case "models": return .mine"#))
        XCTAssertTrue(launch.contains(#"case "model": return .detail("Space")"#))
        XCTAssertTrue(launch.contains(#"case "model.edit": return .edit("Space")"#))
        XCTAssertFalse(result.notes.contains { $0.contains("No launch line") })
        let (none, _) = try write(.init(screens: [.mine]))
        XCTAssertTrue(try Fixture.text(none.paths, "CatalogLaunch.swift").contains("        switch destination {\n        default: return nil"))
    }

    func testWordsSymbolsAndTimingsAreWrittenWhereTheViewsShowThem() throws {
        let (result, _) = try write(.init(
            strings: [#"collection = "album""#, #"collections = "albums""#, #"browse.credits = "{credits} plays""#,
                      #"detail.title = "{name}, the {Collection}""#],
            symbols: ["mine.trailing = music.note.list"],
            tuning: ["press = .snappy", "pressScale = 0.9", "detail = [.medium, .large]", "swatches = red mint", "decimals = 0",
                     "cardDate = .numeric", "cardTime = .shortened"]))
        let all = try Fixture.all(result.paths)
        XCTAssertTrue(all.contains(#""\(entry.name), the Album""#))
        XCTAssertTrue(all.contains(#""Edit album""#) && all.contains(#""No Albums""#))
        XCTAssertTrue(all.contains(#""\(CatalogValue.amount(credits)) plays""#))
        XCTAssertTrue(all.contains(#""music.note.list""#))
        XCTAssertTrue(all.contains(".animation(.snappy, value: pressed)") || all.contains(".snappy"))
        XCTAssertTrue(all.contains("0.9"))
        XCTAssertTrue(all.contains(".presentationDetents([.medium, .large])"))
        XCTAssertTrue(all.contains(#"[CatalogSwatch("red", .red), CatalogSwatch("mint", .mint)]"#))
        XCTAssertTrue(all.contains(#"String(format: "%.0f", value)"#))
        XCTAssertTrue(all.contains("CatalogValue.formatted(date, date: .numeric, time: .shortened)"))
        XCTAssertTrue(all.contains("static let dateZone: TimeZone? = nil"), "no zone named: the device's")
    }

    // MARK: Determinism

    /// The same call writes the same bytes: a second call into the same folder rewrites every file unchanged.
    func testTheSameCallWritesTheSameBytes() throws {
        let input = try Fixture.example("seer")
        let (first, folder) = try write(input)
        let bytes = try first.paths.map { try Data(contentsOf: URL(fileURLWithPath: $0)) }
        let (second, _) = try write(input, in: folder)
        XCTAssertEqual(first.paths, second.paths)
        XCTAssertEqual(try second.paths.map { try Data(contentsOf: URL(fileURLWithPath: $0)) }, bytes)
        XCTAssertTrue(first.made.allSatisfy { $0.state == .written })
        XCTAssertTrue(second.made.allSatisfy { $0.state == .rewritten })
    }
}
