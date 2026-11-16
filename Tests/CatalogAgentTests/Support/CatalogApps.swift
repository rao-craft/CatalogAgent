import Foundation

/// The apps the gated build writes the kit into: Seer (its client's types in a module of their own, DesignAgent's
/// names stood in, its two pages written as the report gives their bodies) and a recipe app with other field types.
enum CatalogApps {
    // MARK: Seer

    /// SeerKit's entities as `$network` makes them, with the fields the Seer call's mappings read.
    static let seerKit = """
    import Foundation

    public struct ModelGroup: Codable, Hashable, Identifiable, Sendable {
        public var id: String
        public var name: String
        public var summary: String
        public var documents: Int
        public var earnings: Double
        public var tags: [String]
        public var online: Bool
        public var color: String
        public var updatedAt: Date

        public init(id: String, name: String, summary: String, documents: Int, earnings: Double, tags: [String], online: Bool, color: String,
                    updatedAt: Date) {
            self.id = id; self.name = name; self.summary = summary; self.documents = documents; self.earnings = earnings
            self.tags = tags; self.online = online; self.color = color; self.updatedAt = updatedAt
        }
    }

    public struct Note: Codable, Hashable, Identifiable, Sendable {
        public var id: String
        public var title: String
        public var body: String
        public var category: String
        public var createdAt: Date

        public init(id: String, title: String, body: String, category: String, createdAt: Date) {
            self.id = id; self.title = title; self.body = body; self.category = category; self.createdAt = createdAt
        }
    }

    public struct World: Codable, Hashable, Identifiable, Sendable {
        public var id: String
        public var name: String
        public var owner: String
        public var summary: String
        public var tags: [String]
        public var credits: Double
        public var documents: Int
        public var members: Int

        public init(id: String, name: String, owner: String, summary: String, tags: [String], credits: Double, documents: Int, members: Int) {
            self.id = id; self.name = name; self.owner = owner; self.summary = summary; self.tags = tags; self.credits = credits
            self.documents = documents; self.members = members
        }
    }

    public struct Loom: Codable, Hashable, Identifiable, Sendable {
        public var id: String
        public var name: String
        public var summary: String
        public var documents: Int
        public var models: [String]

        public init(id: String, name: String, summary: String, documents: Int, models: [String]) {
            self.id = id; self.name = name; self.summary = summary; self.documents = documents; self.models = models
        }
    }
    """

    /// DesignAgent's names, as Seer's `Shared/Design` declares them.
    static let seerDesign = """
    import SwiftUI

    extension Color {
        static var accent: Color { Color(red: 0xAE / 255, green: 0x90 / 255, blue: 0x60 / 255) }
        static var background: Color { Color.white }
        static var secondaryBackground: Color { Color.gray.opacity(0.1) }
        static var foreground: Color { Color.black }
        static var secondaryForeground: Color { Color.black.opacity(0.6) }
        static var separator: Color { Color.gray.opacity(0.3) }
    }

    extension Font {
        static var brandTitle: Font { .system(size: 24, weight: .regular, design: .serif) }
        static var brandBody: Font { .system(size: 20, weight: .regular, design: .serif) }
        static var brandBody2: Font { .system(size: 18, weight: .regular, design: .serif) }
        static var brandNote: Font { .system(size: 18, weight: .light, design: .serif) }
        static var brandNote2: Font { .system(size: 16, weight: .light, design: .serif) }
    }

    extension CGFloat {
        static var layer1: CGFloat { 4 }
        static var layer2: CGFloat { 8 }
        static var layer3: CGFloat { 12 }
        static var layer4: CGFloat { 16 }
        static var layer5: CGFloat { 24 }
        static var layer6: CGFloat { 32 }
        static var layer7: CGFloat { 42 }
    }
    """

    /// The services the page bodies call, shaped as `$granite` writes them: state read off `state`, events that are
    /// `async throws`, a state field set through `set`, and the layout's `present` and `closeSheet`.
    static let seerServices = """
    import Foundation
    import SeerKit

    enum AppDestination { case profile, wallet, world }

    struct LayoutService {
        func present(_ destination: AppDestination) {}
        func closeSheet() {}
    }

    struct ModelsService {
        struct State { var models: [ModelGroup] = SeerSeed.models }
        var state = State()
        @discardableResult func load() async throws -> [ModelGroup] { state.models }
        func save(draft: CatalogCollectionDraft) async throws {}
        func delete(id: String) async throws {}
    }

    struct LibraryService {
        struct State { var notes: [Note] = SeerSeed.notes }
        var state = State()
        @discardableResult func load() async throws -> [Note] { state.notes }
        func deleteNote(id: String) async throws {}
    }

    struct WorldService {
        struct State {
            var worlds: [World] = SeerSeed.worlds
            var looms: [Loom] = SeerSeed.looms
            var activeLoom: String? = nil
        }
        enum Kind { case activeLoom(String?) }
        var state = State()
        func set(_ kind: Kind) {}
        @discardableResult func load() async throws -> [World] { state.worlds }
        @discardableResult func loadLooms() async throws -> [Loom] { state.looms }
        func saveLoom(draft: CatalogGroupingDraft) async throws {}
        func deleteLoom(id: String) async throws {}
    }
    """

    /// The Seer mock world the screens show.
    static let seerSeed = """
    import Foundation
    import SeerKit

    /// The reference stub's data, which the original's shots were taken with: its leaderboard by credits and its two
    /// looms. Owners and lines the shots do not show (Roman Roads, Compilers Notebook, Tea Journal) are stand-ins.
    enum SeerSeed {
        /// 9:05 in the morning, `day` November 2026 (October past the 30th): when a model last changed.
        static func morning(_ day: Int) -> Date {
            let components = day > 30 ? DateComponents(year: 2026, month: 10, day: day, hour: 9, minute: 5)
                : DateComponents(year: 2026, month: 11, day: day, hour: 9, minute: 5)
            return Calendar(identifier: .gregorian).date(from: components) ?? Date(timeIntervalSince1970: 1_794_500_000)
        }

        static let models = [
            ModelGroup(id: "space", name: "Space", summary: "Planets, probes and telescopes: notes from a year of reading about spaceflight.",
                       documents: 10, earnings: 18.42, tags: ["astronomy", "mars", "nasa"], online: true, color: "brown", updatedAt: morning(12)),
            ModelGroup(id: "cooking", name: "Cooking", summary: "Techniques and base recipes worth keeping, from carbonara to ramen broth.",
                       documents: 10, earnings: 9.75, tags: ["recipes", "technique"], online: true, color: "brown", updatedAt: morning(9)),
            ModelGroup(id: "ml", name: "Machine Learning", summary: "Working notes on how neural networks learn and where they fail.",
                       documents: 10, earnings: 7.90, tags: ["ai", "training"], online: true, color: "brown", updatedAt: morning(6)),
            ModelGroup(id: "history", name: "Ancient History", summary: "Empires, libraries and trade routes of the ancient world.",
                       documents: 10, earnings: 4.10, tags: ["rome", "egypt", "trade"], online: true, color: "brown", updatedAt: morning(3)),
            ModelGroup(id: "music", name: "Music", summary: "Scales, rhythm and harmony, written while learning to play.",
                       documents: 10, earnings: 2.35, tags: ["theory", "rhythm"], online: false, color: "brown", updatedAt: morning(31)),
        ]
        static let notes = (1...6).map { day in
            Note(id: "space-00\\(day)", title: "space-00\\(day)", body: "", category: "Space",
                 createdAt: Date(timeIntervalSince1970: 1_794_500_000 - Double(day) * 86_400))
        }
        static let worlds = [
            World(id: "stoic", name: "Stoic Letters", owner: "Tomas Vey", summary: "Seneca and Epictetus, annotated letter by letter.",
                  tags: ["philosophy", "stoicism"], credits: 61.20, documents: 4, members: 2),
            World(id: "botany", name: "Field Botany", owner: "Priya Nand", summary: "Plant keys and field sketches from two seasons in the Western Ghats.",
                  tags: ["plants", "fieldwork"], credits: 48.90, documents: 7, members: 2),
            World(id: "jazz", name: "Jazz Voicings", owner: "Jun Okafor", summary: "Rootless voicings and comping patterns for standards.",
                  tags: ["jazz", "piano"], credits: 37.40, documents: 10, members: 2),
            World(id: "sourdough", name: "Sourdough Lab", owner: "Mara Ellison", summary: "Hydration, flour blends and fermentation timings, measured.",
                  tags: ["baking", "fermentation"], credits: 33.00, documents: 6, members: 2),
            World(id: "orbital", name: "Orbital Mechanics", owner: "Tomas Vey", summary: "Transfers, windows and delta-v budgets worked by hand.",
                  tags: ["space", "physics"], credits: 29.60, documents: 9, members: 3),
            World(id: "roman", name: "Roman Roads", owner: "Priya Nand", summary: "How an empire moved goods, armies and news.",
                  tags: ["history", "trade"], credits: 21.30, documents: 5, members: 1),
            World(id: "space", name: "Space", owner: "Ada Marlow", summary: "Planets, probes and telescopes: notes from a year of reading about spaceflight.",
                  tags: ["astronomy", "mars", "nasa"], credits: 18.42, documents: 10, members: 1),
            World(id: "compilers", name: "Compilers Notebook", owner: "Jun Okafor", summary: "Parsers, type checkers and code generation, one pass at a time.",
                  tags: ["compilers", "languages"], credits: 17.80, documents: 8, members: 1),
            World(id: "tea", name: "Tea Journal", owner: "Mara Ellison", summary: "Tastings, steep times and the gardens behind each leaf.",
                  tags: ["tea", "tasting"], credits: 12.40, documents: 6, members: 1),
            World(id: "cooking", name: "Cooking", owner: "Ada Marlow", summary: "Techniques and base recipes worth keeping, from carbonara to ramen broth.",
                  tags: ["recipes", "technique"], credits: 9.75, documents: 10, members: 1),
        ]
        static let looms = [
            Loom(id: "night-sky", name: "Night Sky", summary: "", documents: 0, models: ["Space", "Orbital Mechanics"]),
            Loom(id: "kitchen", name: "Kitchen", summary: "", documents: 0, models: ["Cooking", "Sourdough Lab", "Tea Journal"]),
        ]
    }
    """

    /// The pages as `$granite` writes a `blank` page: its relays, then the body the report gives, word for word.
    static func seerPages() -> String {
        """
        import SwiftUI
        import SeerKit

        /// The Models tab: `models`, and `model` and `model.edit` through it.
        struct ModelsPage: View {
            var models = ModelsService()
            var library = LibraryService()
            var layout = LayoutService()

            var body: some View {
        \(indent(SeerPages.models, by: 8))
            }
        }

        /// The World sheet: `world`, and `looms` through it.
        struct WorldPage: View {
            var world = WorldService()
            var models = ModelsService()
            var layout = LayoutService()

            var body: some View {
        \(indent(SeerPages.world, by: 8))
            }
        }
        """
    }

    /// Every screen of the Seer call drawn offscreen from the mock world: nothing traps.
    static let seerCheck = """
    import SwiftUI
    import SeerKit

    public enum __APP__Check {
        @MainActor public static func run() -> (drawn: [String], failed: [String]) {
            var drawn: [String] = [], failed: [String] = []
            func draw<Content: View>(_ name: String, _ view: Content) {
                let renderer = ImageRenderer(content: view.frame(width: 402, height: 874))
                #if os(macOS)
                let image = renderer.nsImage
                #else
                let image = renderer.uiImage
                #endif
                if image == nil { failed.append(name) } else { drawn.append(name) }
            }
            let space = CatalogEntry(collection: SeerSeed.models[0])
            let ranked = SeerSeed.worlds.enumerated().map { CatalogEntry(listing: $0.element, place: $0.offset + 1) }
            let mine = SeerSeed.models.map { CatalogEntry(collection: $0) }
            let looms = SeerSeed.looms.map { CatalogSet(grouping: $0) }
            draw("models", NavigationStack { ModelsPage() })
            draw("world", NavigationStack { WorldPage() })
            draw("card", CollectionCard(entry: space))
            draw("detail", CollectionDetailView(entry: space, documents: SeerSeed.notes.map { CatalogDoc(document: $0) }))
            draw("edit", CollectionEditView(entry: space, save: { _ in }))
            draw("swatches", CatalogSwatchesView(color: .constant(.brown), name: .constant("brown")))
            draw("tags", CatalogTagsEditor(tags: .constant(space.tags)))
            draw("ranking", ListingsView(listings: ranked, add: { _ in }, new: {}))
            draw("row", ListingRow(entry: ranked[0], add: { _ in }))
            draw("looms", GroupingsView(groupings: looms, entries: ranked + mine, select: { _ in }, delete: { _ in }, new: {}, edit: { _ in }))
            draw("active", GroupingsView(groupings: looms, entries: ranked + mine, active: "night-sky", select: { _ in }))
            draw("empty looms", GroupingsView(groupings: [], entries: [], new: {}))
            draw("new loom", GroupingFormView(grouping: nil, members: [], listings: ranked, mine: mine, save: { _ in }))
            draw("edit loom", GroupingFormView(grouping: looms[0], members: [ranked[0], mine[0]], listings: ranked, mine: mine, save: { _ in }))
            draw("add", AddToGroupingView(entry: ranked[1], groupings: looms, mine: mine, entries: ranked + mine, save: { _ in }, new: { _ in }))
            draw("no models", NavigationStack { CollectionsView(collections: [ModelGroup](), documents: [Note]()) })
            // Each destination as a -destination launch opens it: the state read in the registration domain, never saved.
            for destination in ["models", "model", "model.edit", "world", "looms", "looms.create"] {
                UserDefaults.standard.register(defaults: ["destination": destination])
                if destination.hasPrefix("model") {
                    draw("launch " + destination, NavigationStack { ModelsPage() })
                } else {
                    draw("launch " + destination, NavigationStack { WorldPage() })
                }
            }
            UserDefaults.standard.register(defaults: ["destination": ""])
            return (drawn, failed)
        }
    }
    """

    // MARK: Recipes

    /// A recipe app's types: ids that are UUIDs, a Decimal of sales, an optional colour name, a nested author.
    static let recipeModels = """
    import Foundation

    struct Cookbook: Identifiable {
        var id: String
        var title: String
        var blurb: String?
        var recipeCount: Int
        var sales: Decimal?
        var cuisines: [String]
        var isPublished: Bool
        var tint: String?
        var editedAt: Date
    }

    struct Recipe: Identifiable {
        var id: UUID
        var name: String
        var addedAt: String
        var bookID: String
    }

    struct Author {
        var name: String
    }

    struct SharedBook: Identifiable {
        var id: Int
        var title: String
        var author: Author
        var blurb: String
        var cuisines: String
        var sales: Double
        var recipeCount: Int
        var position: Int
    }

    struct Shelf: Identifiable {
        var id: UUID
        var label: String
        var bookIDs: [String]
    }

    enum RecipeSeed {
        static let books = [
            Cookbook(id: "weeknights", title: "Weeknights", blurb: "Thirty minutes or less.", recipeCount: 24, sales: 12.5,
                     cuisines: ["quick", "family"], isPublished: true, tint: "#E07A5F", editedAt: Date()),
        ]
        static let recipes = [Recipe(id: UUID(), name: "Lemon pasta", addedAt: "2026-11-12T09:05:00Z", bookID: "weeknights")]
        static let shared = [
            SharedBook(id: 7, title: "Bread Basics", author: Author(name: "Mara"), blurb: "Loaves for beginners.", cuisines: "baking, bread",
                       sales: 41.75, recipeCount: 12, position: 1),
        ]
        static let shelves = [Shelf(id: UUID(), label: "Sundays", bookIDs: ["weeknights", "7"])]
    }
    """

    static let recipeCheck = """
    import SwiftUI

    public enum __APP__Check {
        @MainActor public static func run() -> (drawn: [String], failed: [String]) {
            var drawn: [String] = [], failed: [String] = []
            func draw<Content: View>(_ name: String, _ view: Content) {
                let renderer = ImageRenderer(content: view.frame(width: 402, height: 874))
                #if os(macOS)
                let image = renderer.nsImage
                #else
                let image = renderer.uiImage
                #endif
                if image == nil { failed.append(name) } else { drawn.append(name) }
            }
            draw("books", NavigationStack {
                CollectionsView(collections: RecipeSeed.books, documents: RecipeSeed.recipes, save: { _ in }, delete: { _ in })
            })
            draw("kitchen", NavigationStack {
                CatalogView(listings: RecipeSeed.shared, mine: RecipeSeed.books, groupings: RecipeSeed.shelves, active: "Sundays",
                            select: { _ in }, save: { _ in }, delete: { _ in }, search: { _ in RecipeSeed.shared })
            })
            return (drawn, failed)
        }
    }
    """

    /// The least call's app: no type of its own, the kit's value types and samples in their place.
    static let leastCheck = """
    import SwiftUI

    public enum __APP__Check {
        @MainActor public static func run() -> (drawn: [String], failed: [String]) {
            var drawn: [String] = [], failed: [String] = []
            func draw<Content: View>(_ name: String, _ view: Content) {
                let renderer = ImageRenderer(content: view.frame(width: 402, height: 874))
                #if os(macOS)
                let image = renderer.nsImage
                #else
                let image = renderer.uiImage
                #endif
                if image == nil { failed.append(name) } else { drawn.append(name) }
            }
            draw("mine", NavigationStack { KitCollectionsView(collections: CatalogSamples.collections) })
            draw("catalog", NavigationStack {
                KitCatalogView(listings: CatalogSamples.listings, mine: CatalogSamples.collections, groupings: CatalogSamples.groupings)
            })
            return (drawn, failed)
        }
    }
    """

    static func indent(_ text: String, by spaces: Int) -> String {
        text.split(separator: "\n", omittingEmptySubsequences: false).map { String(repeating: " ", count: spaces) + $0 }.joined(separator: "\n")
    }
}

/// The page bodies the report gives the host for Seer's destinations, compiled as written by the gated build.
enum SeerPages {
    /// `models` (and `model`, `model.edit` through it): the Models tab.
    static let models = """
    CollectionsView(collections: models.state.models, documents: library.state.notes,
                    leading: { layout.present(.profile) }, trailing: { layout.present(.wallet) },
                    refresh: { try await models.load(); try await library.load() },
                    save: { try await models.save(draft: $0) }, delete: { try await models.delete(id: $0) },
                    deleteDocument: { try await library.deleteNote(id: $0) })
    """

    /// `world` (and `looms` through it): The World sheet over the Void.
    static let world = """
    CatalogView(listings: world.state.worlds, mine: models.state.models, groupings: world.state.looms,
                active: world.state.activeLoom, select: { world.set(.activeLoom($0)) },
                save: { try await world.saveLoom(draft: $0) }, delete: { try await world.deleteLoom(id: $0) },
                refresh: { try await world.load(); try await world.loadLooms() }, close: { layout.closeSheet() })
    """
}
