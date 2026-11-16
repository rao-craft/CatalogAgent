import Foundation
@testable import CatalogAgent

enum Fixture {
    /// A folder of its own for one test, removed with the process's temporary files.
    static func folder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("catalog-\(UUID().uuidString.prefix(8))", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// The package's own folder, for the examples in `Schema/`.
    static let package = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent()

    /// An example call in `Schema/examples`, as a host sends it.
    static func example(_ name: String) throws -> CatalogAgent.Input {
        let data = try Data(contentsOf: package.appendingPathComponent("Schema/examples/\(name).json"))
        return try JSONDecoder().decode(CatalogAgent.Input.self, from: data)
    }

    /// A recipe app's types, mapped: what the package is held to reading well.
    static let recipes = [
        "collection: Cookbook name=title summary=blurb count=recipeCount earnings=sales tags=cuisines online=isPublished color=tint updated=editedAt",
        "document: Recipe title=name updated=addedAt collection=bookID",
        "listing: SharedBook name=title owner=author.name summary=blurb tags=cuisines credits=sales count=recipes.count rank=position",
        "grouping: Shelf name=label members=bookIDs",
    ]

    /// The text of the file `name` among `paths`.
    static func text(_ paths: [String], _ name: String) throws -> String {
        guard let path = paths.first(where: { $0.hasSuffix("/" + name) }) else {
            throw CocoaError(.fileNoSuchFile, userInfo: [NSFilePathErrorKey: name])
        }
        return try String(contentsOfFile: path, encoding: .utf8)
    }

    /// Every file a call wrote, joined: what a scorecard's patterns read.
    static func all(_ paths: [String]) throws -> String {
        try paths.sorted().map { try String(contentsOfFile: $0, encoding: .utf8) }.joined(separator: "\n")
    }
}
