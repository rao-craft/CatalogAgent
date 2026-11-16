import Foundation
import GraniteAgents
import XCTest
@testable import CatalogAgent

/// The package as an app finds it: by its record, with the schema a model is shown and the guide a host prompts with.
final class CatalogAgentTests: XCTestCase {
    func testTheRecordIsFoundWithNothingListed() throws {
        let catalog = try XCTUnwrap(GraniteRoster.discovered().package("catalog"), "the record is in this test binary")
        XCTAssertEqual(catalog.module, "CatalogAgent")
        XCTAssertEqual(catalog.summary, CatalogAgent.summary)
    }

    func testTheSchemaIsWhatAModelIsShown() {
        let catalog = AnyAgentPackage(CatalogAgent.self)
        XCTAssertEqual(catalog.schema, .object([
            .init(name: "into", schema: .string, required: false),
            .init(name: "mappings", schema: .array(.string), required: false),
            .init(name: "screens", schema: .array(.choice(["mine", "browse", "groupings"])), required: false),
            .init(name: "look", schema: .array(.string), required: false),
            .init(name: "strings", schema: .array(.string), required: false),
            .init(name: "symbols", schema: .array(.string), required: false),
            .init(name: "tuning", schema: .array(.string), required: false),
            .init(name: "launch", schema: .array(.string), required: false),
            .init(name: "prefix", schema: .string, required: false),
            .init(name: "imports", schema: .array(.string), required: false),
            .init(name: "directory", schema: .string, required: false),
        ]))
        XCTAssertTrue(catalog.takesDirectory)
        XCTAssertEqual(Set(catalog.fields.keys), ["into", "mappings", "screens", "look", "strings", "symbols", "tuning", "launch", "prefix", "imports"],
                       "a note beside every field the model sees")
        XCTAssertEqual(catalog.lanes, 2)
        XCTAssertEqual(CatalogAgent.makes.map(\.kind), ["view", "conformance"])
    }

    func testTheGuideTeachesTheLineAndTwoCalls() {
        let guide = AnyAgentPackage(CatalogAgent.self).guide
        for word in ["mappings", "collection (", "document (", "listing (", "grouping (", "value", "id=", "imports", "strings",
                     "symbols", "tuning", "look", "launch", "-destination", "screens", "prefix", "CollectionsView", "CatalogView",
                     "#Preview", "nil is not drawn"] {
            XCTAssertTrue(guide.contains(word), "the guide says \(word)")
        }
        // Every word a role maps is in the guide, so the model never has to guess one.
        for role in CatalogRole.allCases {
            for property in role.properties { XCTAssertTrue(guide.contains(property.key), "the guide names \(role).\(property.key)") }
        }
        XCTAssertEqual(guide.components(separatedBy: "{\"").count - 1, 2, "two example calls")
        XCTAssertFalse(guide.contains("ModelGroup"), "no Seer type names to copy")
    }

    /// The call as a host makes it: JSON in, the host's folder filled, JSON out naming the files.
    func testACallThroughTheRosterWritesTheFilesItNames() async throws {
        let folder = try Fixture.folder()
        let input = try JSONSerialization.data(withJSONObject: ["mappings": Fixture.recipes, "directory": folder.path])
        let answer = try await AnyAgentPackage(CatalogAgent.self).perform(input, host: AgentHost(directory: folder.path, ask: "the catalog screens"))
        let result = try JSONDecoder().decode(CatalogResult.self, from: answer)
        let catalog = folder.appendingPathComponent("Components/Catalog").path
        XCTAssertEqual(result.path, result.paths.first)
        for path in result.paths {
            XCTAssertTrue(path.hasPrefix(catalog + "/"), path)
            XCTAssertTrue(FileManager.default.fileExists(atPath: path), path)
        }
        let names = Set(result.paths.map { URL(fileURLWithPath: $0).lastPathComponent })
        XCTAssertEqual(names, [
            "CatalogProtocols.swift", "CatalogLook.swift", "CatalogLaunch.swift", "CatalogValue.swift", "CatalogParts.swift",
            "CatalogModels.swift", "CatalogSamples.swift", "CollectionsView.swift", "CollectionCard.swift", "CollectionDetailView.swift",
            "CollectionEditView.swift", "CatalogTagsEditor.swift", "CatalogSwatchesView.swift", "CatalogView.swift", "ListingRow.swift",
            "ListingsView.swift", "AddToGroupingView.swift", "GroupingsView.swift", "GroupingFormView.swift",
            "Cookbook+Collection.swift", "Recipe+Document.swift", "SharedBook+Listing.swift", "Shelf+Grouping.swift",
        ])
        XCTAssertEqual(result.conformances, ["Cookbook: collection", "Recipe: document", "SharedBook: listing", "Shelf: grouping"])
        XCTAssertEqual(result.views, ["CollectionsView", "CollectionCard", "CollectionDetailView", "CollectionEditView", "CatalogTagsEditor",
                                      "CatalogSwatchesView", "CatalogView", "ListingRow", "ListingsView", "AddToGroupingView",
                                      "GroupingsView", "GroupingFormView"])
        XCTAssertEqual(result.initializers.count, 2)
        XCTAssertTrue(result.initializers[0].hasPrefix("CollectionsView(collections: [Cookbook], documents: [Recipe], "))
        XCTAssertTrue(result.initializers[1].hasPrefix("CatalogView(listings: [SharedBook], mine: [Cookbook], groupings: [Shelf], "))
        XCTAssertEqual(Set(result.made.map(\.kind)), ["view", "conformance"])
        XCTAssertEqual(result.made.count, 12 + 4)
        XCTAssertEqual(result.expected.filter { $0.kind == "view" }.map(\.name),
                       ["CollectionsView", "CollectionCard", "CollectionDetailView", "CollectionEditView", "CatalogView", "ListingsView",
                        "ListingRow", "GroupingsView", "GroupingFormView"])
        XCTAssertTrue(result.notes.contains { $0.contains("No launch line") })
    }

    /// A host over the wire may name its folder only in `AgentHost`: every file lands there all the same.
    func testTheHostsFolderIsUsedWhenTheCallNamesNone() async throws {
        let folder = try Fixture.folder()
        let input = try JSONSerialization.data(withJSONObject: ["mappings": Fixture.recipes, "screens": ["browse"]])
        let answer = try await AnyAgentPackage(CatalogAgent.self).perform(input, host: AgentHost(directory: folder.path))
        let result = try JSONDecoder().decode(CatalogResult.self, from: answer)
        XCTAssertFalse(result.paths.isEmpty)
        for path in result.paths {
            XCTAssertTrue(path.hasPrefix(folder.path + "/"), "\(path) is not under the host's folder")
            XCTAssertTrue(FileManager.default.fileExists(atPath: path), path)
        }
    }

    /// A refused call answers a typed refusal with every reason, the host's to hand back to the model.
    func testARefusedCallThroughTheRosterNamesEveryReason() async throws {
        let folder = try Fixture.folder()
        let input = try JSONSerialization.data(withJSONObject: [
            "mappings": ["shelf Cookbook name=title", "collection: Cookbook price=cost"],
            "look": ["glow = #FFFFFF"], "directory": folder.path,
        ])
        do {
            _ = try await AnyAgentPackage(CatalogAgent.self).perform(input, host: AgentHost(directory: folder.path))
            XCTFail("the call is refused")
        } catch {
            let text = "\(error)"
            for reason in ["has no colon", "`price` is not something a collection shows", "`glow` is not a look role"] {
                XCTAssertTrue(text.contains(reason), "\(reason) in \(text)")
            }
        }
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: folder.path), [], "nothing is written")
    }
}
