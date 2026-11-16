//  WHAT: `CatalogSamples.swift`: the values the previews draw, in the kit's own value types.

extension Template {
    static let catalogSamples = ##"""
    import Foundation

    /// What the previews draw: a few collections, their documents, a ranking and two groupings.
    enum CatalogSamples {
        static var collections: [CatalogCollection] {
            [
                CatalogCollection(id: "field-notes", name: "Field Notes",
                                  summary: "Birds, weather and long walks, written down the same evening.",
                                  count: 12, earnings: 18.42, tags: ["birds", "walks", "weather"], online: true,
                                  colorName: "brown", updated: Date(timeIntervalSince1970: 1_794_000_000)),
                CatalogCollection(id: "recipes", name: "Recipes",
                                  summary: "Base recipes worth keeping, from stock to sourdough.",
                                  count: 8, earnings: 9.75, tags: ["cooking"], online: false,
                                  colorName: "orange", updated: Date(timeIntervalSince1970: 1_793_700_000)),
            ]
        }

        static var documents: [CatalogDocument] {
            [
                CatalogDocument(id: "note-1", title: "Swifts over the river", updated: Date(timeIntervalSince1970: 1_794_000_000), collection: "field-notes"),
                CatalogDocument(id: "note-2", title: "First frost", updated: Date(timeIntervalSince1970: 1_793_900_000), collection: "field-notes"),
                CatalogDocument(id: "note-3", title: "Brown stock", updated: Date(timeIntervalSince1970: 1_793_700_000), collection: "recipes"),
            ]
        }

        static var listings: [CatalogListing] {
            [
                CatalogListing(id: "letters", name: "Letters", owner: "Ana Reyes", summary: "Old letters, annotated one by one.",
                               tags: ["history"], credits: 61.2, count: 4),
                CatalogListing(id: "botany", name: "Field Botany", owner: "Sam Ito", summary: "Plant keys and sketches from two seasons.",
                               tags: ["plants", "fieldwork"], credits: 48.9, count: 7),
                CatalogListing(id: "jazz", name: "Voicings", owner: "Lee Park", summary: "Chord shapes for standards.",
                               tags: ["music"], credits: 37.4, count: 1),
                CatalogListing(id: "bread", name: "Bread Lab", owner: "Ana Reyes", summary: "Hydration and timings, measured.",
                               tags: ["baking"], credits: 33, count: 6),
            ]
        }

        static var groupings: [CatalogGrouping] {
            [
                CatalogGrouping(id: "outdoors", name: "Outdoors", members: ["field-notes", "botany"]),
                CatalogGrouping(id: "kitchen", name: "Kitchen", members: ["recipes", "bread", "jazz"]),
            ]
        }
    }
    """##
}
