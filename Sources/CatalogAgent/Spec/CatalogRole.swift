//  WHAT: The four roles an app's type can take for the catalog views (a collection of mine, a document in it,
//        a listing of someone else's collection, a grouping of collections) and everything each role's views read.
//        The one source of the protocols written into the app, of what a mapping line may name, and of the guide's
//        word list.
//  PIN:  ONE TABLE. The protocol file, the conformances and the tests all read these lists, so a property added
//        here is a requirement, a mapping word and a default at once.

import Foundation

enum CatalogRole: String, CaseIterable, Sendable {
    case collection, document, listing, grouping

    /// The protocol an app's type conforms to: `CollectionRepresentable`.
    var protocolName: String { name + "Representable" }

    /// The role's name in Swift: `Collection`.
    var name: String { rawValue.prefix(1).uppercased() + rawValue.dropFirst() }

    /// The kit's own value type, for a role the app has no type for: `CatalogCollection`.
    var valueType: String { "Catalog" + name }

    /// Other words a mapping line may start with.
    var aliases: [String] {
        switch self {
        case .collection: return ["model", "folder", "board", "playlist", "album", "mine"]
        case .document: return ["note", "item", "entry", "file", "page", "post"]
        case .listing: return ["world", "public", "shared", "other", "ranking"]
        case .grouping: return ["loom", "group", "set", "stack", "bundle", "shelf"]
        }
    }

    /// What the role is, for the protocol's doc comment.
    var doc: String {
        switch self {
        case .collection: return "A collection of the person's own, as the catalog views show it: a card, a detail sheet, an edit form."
        case .document: return "A document in a collection, as the catalog views show it: a row in the collection's detail sheet."
        case .listing: return "Someone else's collection, as the catalog views show it: a ranked row to browse and add to a grouping."
        case .grouping: return "A named set of collections, as the catalog views show it: a row to select, a form to edit."
        }
    }

    var properties: [CatalogProperty] {
        switch self {
        case .collection:
            return [
                .init("name", "catalogName", .text, "What it is called, on its card and in its detail's title.", aliases: ["title", "label"]),
                .init("summary", "catalogSummary", .optionalText, "What it holds, in a sentence or two.", aliases: ["description", "about", "details", "subtitle"]),
                .init("count", "catalogCount", .optionalInt, "How many documents it holds; nil counts the documents that name it.", aliases: ["documents", "documentCount", "size", "items", "notes"]),
                .init("earnings", "catalogEarnings", .number, "What it has earned, drawn with two decimals; nil draws none.", aliases: ["credits", "revenue", "royalties", "balance"]),
                .init("tags", "catalogTags", .tags, "Its tags, drawn as chips.", aliases: ["labels", "keywords", "topics"]),
                .init("online", "catalogOnline", .flag, "Whether others can use it now: the card's dot and the menu's switch; nil draws neither.", aliases: ["available", "isOnline", "live", "active", "published"]),
                .init("color", "catalogColor", .color, "Its colour: the card's spine and the edit form's tint; a String naming a system colour or a hex is written back as it was named.", aliases: ["colour", "tint"]),
                .init("updated", "catalogUpdated", .date, "When it last changed; nil takes the newest date of its documents.", aliases: ["date", "modified", "updatedAt", "createdAt", "created"]),
            ]
        case .document:
            return [
                .init("title", "catalogTitle", .text, "What the document is called, on its row.", aliases: ["name", "label"]),
                .init("updated", "catalogUpdated", .date, "When it last changed: \"Updated: …\" under its title, newest first.", aliases: ["date", "createdAt", "created", "modified", "updatedAt"]),
                .init("collection", "catalogCollectionKey", .optionalText, "The collection it is in, by the collection's id or its name.", aliases: ["category", "group", "model", "folder", "parent"]),
            ]
        case .listing:
            return [
                .init("name", "catalogName", .text, "What it is called, on its row.", aliases: ["title", "label"]),
                .init("owner", "catalogOwner", .optionalText, "Whose it is: \"by …\" under its name.", aliases: ["by", "creator", "author", "user"]),
                .init("summary", "catalogSummary", .optionalText, "What it holds, in a sentence or two.", aliases: ["description", "about", "details"]),
                .init("tags", "catalogTags", .tags, "Its tags, drawn as chips.", aliases: ["labels", "keywords", "topics"]),
                .init("credits", "catalogCredits", .number, "What it has earned, drawn with two decimals; nil draws none.", aliases: ["earnings", "price", "revenue"]),
                .init("count", "catalogCount", .optionalInt, "How many documents it holds; nil draws none.", aliases: ["documents", "documentCount", "size", "items"]),
                .init("rank", "catalogRank", .optionalInt, "Its place in the ranking; nil takes its place in the list, from 1.", aliases: ["position", "place"]),
            ]
        case .grouping:
            return [
                .init("name", "catalogName", .text, "What the grouping is called.", aliases: ["title", "label"]),
                .init("members", "catalogMembers", .keys, "The collections in it, each by its id or its name, mine or others'.", aliases: ["models", "collections", "items", "ids", "groups"]),
            ]
        }
    }

    /// The property a mapping line's word names, by its key or an alias, any case.
    func property(named word: String) -> CatalogProperty? {
        let lower = word.lowercased()
        return properties.first { $0.key.lowercased() == lower } ?? properties.first { $0.aliases.contains { $0.lowercased() == lower } }
    }

    /// The role a mapping line's first word names, by its name or an alias, any case.
    static func named(_ word: String) -> CatalogRole? {
        let lower = word.lowercased()
        return CatalogRole(rawValue: lower) ?? allCases.first { $0.aliases.contains(lower) }
    }
}
