//  WHAT: Every file of the kit a call can write: its template, the view types it declares, and the screens that
//        want it; and which parts a call writes for the screens it names, in the catalog's order.

import Foundation

/// One file of the kit a call can write.
struct KitPart: Sendable {
    /// The file's name without `.swift`, and its flag in templates: `part.GroupingsView`.
    let name: String
    /// The view types it declares, which the call's prefix renames.
    let views: [String]
    let template: String
    /// Written when any of these screens is asked for; always when empty.
    let screens: Set<CatalogScreen>
    /// Written only when every one of these screens is asked for.
    let all: Set<CatalogScreen>

    init(_ name: String, views: [String] = [], screens: Set<CatalogScreen> = [], all: Set<CatalogScreen> = [], _ template: String) {
        self.name = name; self.views = views; self.screens = screens; self.all = all; self.template = template
    }

    /// Whether the call's prefix goes on the file's name: a file named for the view it declares.
    var isView: Bool { views.contains(name) }

    func wanted(by screens: Set<CatalogScreen>) -> Bool {
        (self.screens.isEmpty || !self.screens.isDisjoint(with: screens)) && all.isSubset(of: screens)
    }
}

enum KitCatalog {
    /// Every part, in the order a call writes them.
    static let parts: [KitPart] = [
        KitPart("CatalogValue", Template.catalogValue),
        KitPart("CatalogParts", Template.catalogParts),
        KitPart("CatalogModels", Template.catalogModels),
        KitPart("CatalogSamples", Template.catalogSamples),
        KitPart("CollectionsView", views: ["CollectionsView"], screens: [.mine], Template.collectionsView),
        KitPart("CollectionCard", views: ["CollectionCard"], screens: [.mine], Template.collectionCard),
        KitPart("CollectionDetailView", views: ["CollectionDetailView"], screens: [.mine], Template.collectionDetailView),
        KitPart("CollectionEditView", views: ["CollectionEditView"], screens: [.mine], Template.collectionEditView),
        KitPart("CatalogTagsEditor", views: ["CatalogTagsEditor"], screens: [.mine], Template.catalogTagsEditor),
        KitPart("CatalogSwatchesView", views: ["CatalogSwatchesView"], screens: [.mine], Template.catalogSwatchesView),
        KitPart("CatalogView", views: ["CatalogView"], screens: [.browse, .groupings], Template.catalogView),
        KitPart("ListingRow", views: ["ListingRow"], screens: [.browse, .groupings], Template.listingRow),
        KitPart("ListingsView", views: ["ListingsView"], screens: [.browse], Template.listingsView),
        KitPart("AddToGroupingView", views: ["AddToGroupingView"], all: [.browse, .groupings], Template.addToGroupingView),
        KitPart("GroupingsView", views: ["GroupingsView"], screens: [.groupings], Template.groupingsView),
        KitPart("GroupingFormView", views: ["GroupingFormView"], screens: [.groupings], Template.groupingFormView),
    ]

    /// The root views a page shows, by screen.
    static func roots(of screen: CatalogScreen) -> [String] {
        switch screen {
        case .mine: return ["CollectionsView"]
        case .browse, .groupings: return ["CatalogView"]
        }
    }

    /// The views a screen is built from, root first.
    static func views(of screen: CatalogScreen) -> [String] {
        switch screen {
        case .mine: return ["CollectionsView", "CollectionCard", "CollectionDetailView", "CollectionEditView"]
        case .browse: return ["CatalogView", "ListingsView", "ListingRow"]
        case .groupings: return ["CatalogView", "GroupingsView", "GroupingFormView"]
        }
    }

    /// The parts a call writes for `screens`.
    static func plan(_ screens: Set<CatalogScreen>) -> [KitPart] { parts.filter { $0.wanted(by: screens) } }

    /// The template flags: each screen as `screen.X`, each part written as `part.X`.
    static func flags(_ screens: Set<CatalogScreen>) -> Set<String> {
        Set(screens.map { "screen.\($0.rawValue)" }).union(plan(screens).map { "part.\($0.name)" })
    }
}
