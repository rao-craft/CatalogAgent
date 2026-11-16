//  WHAT: `CatalogModels.swift`: what the inner views draw (an entry, a document, a set, a swatch), what the forms
//        hand back (the drafts), and the kit's own value types for a role the app has no type for.

extension Template {
    static let catalogModels = ##"""
    import SwiftUI

    /// A collection as the inner views draw it, mine or someone else's: read once from the app's value, so the views
    /// under the roots need no generic parameter.
    struct CatalogEntry: Identifiable, Hashable {
        /// The key the closures are handed.
        let id: String
        var name: String
        var summary: String? = nil
        var count: Int? = nil
        /// Earnings for mine, credits for someone else's.
        var earnings: Double? = nil
        var tags: [String] = []
        var online: Bool? = nil
        var color: Color? = nil
        var colorName: String? = nil
        var updated: Date? = nil
        var owner: String? = nil
        var rank: Int? = nil
    }

    extension CatalogEntry {
        /// One of mine.
        init<Value: CollectionRepresentable>(collection value: Value) {
            self.init(id: value.catalogKey, name: value.catalogName, summary: value.catalogSummary, count: value.catalogCount,
                      earnings: value.catalogEarnings, tags: value.catalogTags, online: value.catalogOnline,
                      color: value.catalogColor, colorName: value.catalogColorName, updated: value.catalogUpdated)
        }

        /// Someone else's, ranked at its place in the list when it says no rank of its own.
        init<Value: ListingRepresentable>(listing value: Value, place: Int) {
            self.init(id: value.catalogKey, name: value.catalogName, summary: value.catalogSummary, count: value.catalogCount,
                      earnings: value.catalogCredits, tags: value.catalogTags, owner: value.catalogOwner,
                      rank: value.catalogRank ?? place)
        }
    }

    /// A document as the detail sheet draws it.
    struct CatalogDoc: Identifiable, Hashable {
        let id: String
        var title: String
        var updated: Date? = nil
        /// The key or name of the collection it belongs to.
        var collection: String? = nil
    }

    extension CatalogDoc {
        init<Value: DocumentRepresentable>(document value: Value) {
            self.init(id: value.catalogKey, title: value.catalogTitle, updated: value.catalogUpdated,
                      collection: value.catalogCollectionKey)
        }
    }

    /// A grouping as the groupings tab draws it.
    struct CatalogSet: Identifiable, Hashable {
        let id: String
        var name: String
        /// Each member's key or name.
        var members: [String] = []
    }

    extension CatalogSet {
        init<Value: GroupingRepresentable>(grouping value: Value) {
            self.init(id: value.catalogKey, name: value.catalogName, members: value.catalogMembers)
        }
    }

    /// A swatch the edit form offers: a system colour and its name.
    struct CatalogSwatch: Identifiable, Hashable {
        let name: String
        let color: Color
        var id: String { name }

        init(_ name: String, _ color: Color) {
            self.name = name
            self.color = color
        }

        /// The swatches, in the order they are drawn.
        static var all: [CatalogSwatch] {
            [{{swatches}}]
        }
    }

    /// What the edit form hands `save`: the collection as the person left it.
    struct CatalogCollectionDraft: Equatable, Sendable {
        /// The collection's key.
        var id: String
        var name: String
        var summary: String
        var tags: [String]
        /// The colour as the app named it, or the name of the swatch the person picked.
        var color: String
        var online: Bool
    }

    extension CatalogCollectionDraft {
        init(_ entry: CatalogEntry) {
            self.init(id: entry.id, name: entry.name, summary: entry.summary ?? "", tags: entry.tags,
                      color: entry.colorName ?? "", online: entry.online ?? true)
        }
    }

    /// What the grouping forms and the add sheet hand `save`.
    struct CatalogGroupingDraft: Equatable, Sendable {
        /// The grouping's key; nil for a new one.
        var id: String?
        var name: String
        /// Each member's key.
        var members: [String]
        /// Each member's name, in the same order.
        var names: [String]
    }

    /// The kit's own collection: for an app with no type of its own, and for the previews.
    struct CatalogCollection: CollectionRepresentable, Hashable {
        var id: String
        var name: String
        var summary: String? = nil
        var count: Int? = nil
        var earnings: Double? = nil
        var tags: [String] = []
        var online: Bool? = nil
        var colorName: String? = nil
        var updated: Date? = nil

        var catalogName: String { name }
        var catalogSummary: String? { summary }
        var catalogCount: Int? { count }
        var catalogEarnings: Double? { earnings }
        var catalogTags: [String] { tags }
        var catalogOnline: Bool? { online }
        var catalogColor: Color? { CatalogValue.named(colorName) }
        var catalogColorName: String? { colorName }
        var catalogUpdated: Date? { updated }
    }

    /// The kit's own document.
    struct CatalogDocument: DocumentRepresentable, Hashable {
        var id: String
        var title: String
        var updated: Date? = nil
        var collection: String? = nil

        var catalogTitle: String { title }
        var catalogUpdated: Date? { updated }
        var catalogCollectionKey: String? { collection }
    }

    /// The kit's own listing: someone else's collection.
    struct CatalogListing: ListingRepresentable, Hashable {
        var id: String
        var name: String
        var owner: String? = nil
        var summary: String? = nil
        var tags: [String] = []
        var credits: Double? = nil
        var count: Int? = nil
        var rank: Int? = nil

        var catalogName: String { name }
        var catalogOwner: String? { owner }
        var catalogSummary: String? { summary }
        var catalogTags: [String] { tags }
        var catalogCredits: Double? { credits }
        var catalogCount: Int? { count }
        var catalogRank: Int? { rank }
    }

    /// The kit's own grouping.
    struct CatalogGrouping: GroupingRepresentable, Hashable {
        var id: String
        var name: String
        var members: [String] = []

        var catalogName: String { name }
        var catalogMembers: [String] { members }
    }
    """##
}
