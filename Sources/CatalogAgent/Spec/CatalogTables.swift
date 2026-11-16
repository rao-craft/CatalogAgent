//  WHAT: The look roles, SF Symbols and tuning keys a call may set, each with its default and a line saying where it
//        shows: what `look`, `symbols` and `tuning` lines name, what the guide and the reference list, and what the
//        templates write in the form a person would (`.spring(duration: 0.2, bounce: 0.4)`, `[.fraction(0.6)]`).
//  PIN:  EVERY KEY HAS A DEFAULT THAT BUILDS ANYWHERE. A look role falls back to a system value, a symbol to one
//        every OS the kit supports draws, a number to the one the views were drawn with.

import Foundation

/// A look role: where its value comes from in the app, and what stands in without one.
struct CatalogLookRole: Sendable, Equatable {
    enum Kind: String, Sendable { case color, font, design, spacing }
    let key: String
    let kind: Kind
    /// Swift for the value when the call maps none.
    let fallback: String
    let doc: String

    init(_ key: String, _ kind: Kind, _ fallback: String, _ doc: String) {
        self.key = key; self.kind = kind; self.fallback = fallback; self.doc = doc
    }

    static let all: [CatalogLookRole] = [
        .init("accent", .color, "Color.accentColor", "the tint: bar buttons and their glyphs, tags, the selected tab, ranks at the top, the active grouping"),
        .init("background", .color, "CatalogLook.system(.background)", "behind the tab row and the search row"),
        .init("ink", .color, "Color.primary", "text, rules and faint glyphs, at the opacity each is drawn at"),
        .init("card", .color, "CatalogLook.system(.card)", "a card's surface, the edit form's fields and a document's badge"),
        .init("panel", .color, "CatalogLook.system(.panel)", "where the edit form's and the colour sheet's gradients start"),
        .init("cardShadow", .color, "Color.black.opacity(0.08)", "the shadow under a card"),
        .init("fieldShadow", .color, "Color.black.opacity(0.12)", "the shadow under the name field"),
        .init("badgeShadow", .color, "Color.black.opacity(0.12)", "the shadow under a document's badge"),
        .init("positive", .color, "Color.green", "earnings, and the online dot"),
        .init("inactive", .color, "Color.gray", "the offline dot"),
        .init("title", .font, "CatalogLook.font(24)", "titles in the bar"),
        .init("body", .font, "CatalogLook.font(20)", "a listing's name over its description in the add sheet"),
        .init("body2", .font, "CatalogLook.font(18)", "a listing's or a grouping's name"),
        .init("note", .font, "CatalogLook.font(18, .light)", "the empty cards' line"),
        .init("note2", .font, "CatalogLook.font(16, .light)", "descriptions and section headers"),
        .init("design", .design, ".default", "the design of every other size the views draw: `serif` for Seer"),
        .init("layer1", .spacing, "4", "the smallest gap"),
        .init("layer2", .spacing, "8", "a small gap"),
        .init("layer3", .spacing, "12", "a gap"),
        .init("layer4", .spacing, "16", "padding"),
        .init("layer5", .spacing, "24", "the edit form's blocks"),
        .init("layer6", .spacing, "32", "a large gap"),
        .init("layer7", .spacing, "42", "the empty states' side inset"),
    ]

    static func role(_ key: String) -> CatalogLookRole? { all.first { $0.key.lowercased() == key.lowercased() } }
}

/// An SF Symbol a view draws.
struct CatalogSymbol: Sendable, Equatable {
    let key: String
    let fallback: String
    let doc: String

    init(_ key: String, _ fallback: String, _ doc: String) { self.key = key; self.fallback = fallback; self.doc = doc }

    static let all: [CatalogSymbol] = [
        .init("mine.leading", "person.crop.circle", "the leading bar button over the cards"),
        .init("mine.trailing", "ellipsis.circle", "the trailing bar button"),
        .init("mine.empty", "tray", "the empty cards' symbol"),
        .init("menu.edit", "pencil", "the menu's edit item"),
        .init("menu.offline", "network.slash", "the menu's offline item"),
        .init("menu.online", "network", "the menu's online item"),
        .init("menu.delete", "trash.fill", "the menu's delete item"),
        .init("document", "doc.text.fill", "in each document's badge in the detail sheet"),
        .init("close", "xmark", "the close buttons"),
        .init("edit.color", "paintpalette", "the colour button"),
        .init("edit.keyboard", "checkmark", "the bar's button while a field has focus"),
        .init("edit.tag.add", "plus", "the add-tag chip"),
        .init("edit.tag.remove", "xmark", "a tag chip's remove button"),
        .init("swatch.check", "checkmark", "over the chosen swatch"),
        .init("browse.search", "magnifyingglass", "the search row's symbol"),
        .init("browse.clear", "xmark.circle.fill", "the button that empties the search"),
        .init("browse.add", "plus.circle", "a listing's add button, and every row that adds"),
        .init("browse.empty", "chart.bar", "the empty browse tab's symbol"),
        .init("groupings.edit", "pencil", "a grouping's edit button"),
        .init("groupings.selected", "checkmark.circle.fill", "the active grouping's circle, and a member's in the add sheet"),
        .init("groupings.unselected", "circle", "any other circle"),
        .init("groupings.new", "plus", "beside \"New …\""),
        .init("groupings.empty", "square.stack.3d.up", "the empty groupings tab's symbol"),
    ]

    static func symbol(_ key: String) -> CatalogSymbol? { all.first { $0.key == key } }
}

/// A timing, size, number, detent list, swatch list or date style a view uses.
struct CatalogTuning: Sendable, Equatable {
    enum Kind: String, Sendable { case animation, number, whole, detents, swatches, dateStyle, timeStyle }
    let key: String
    let kind: Kind
    /// The value as the templates write it.
    let fallback: String
    let doc: String

    init(_ key: String, _ kind: Kind, _ fallback: String, _ doc: String) {
        self.key = key; self.kind = kind; self.fallback = fallback; self.doc = doc
    }

    static let all: [CatalogTuning] = [
        .init("press", .animation, ".spring(duration: 0.2, bounce: 0.4)", "a pressed card scaling"),
        .init("earnings", .animation, ".spring(duration: 0.65, bounce: 0.35).delay(0.1)", "a card's earnings rising in"),
        .init("pulse", .animation, ".easeInOut(duration: 1.9).repeatForever(autoreverses: true)", "the online dot's pulse"),
        .init("tags", .animation, ".spring(duration: 0.25)", "tag and swatch changes"),
        .init("pressScale", .number, "0.97", "the scale of a pressed card"),
        .init("pulseScale", .number, "1.4", "the scale the online dot's halo pulses to"),
        .init("earningsRise", .number, "8", "how far the earnings rise as they appear, in points"),
        .init("cardRadius", .number, "16", "a card's corner radius"),
        .init("fieldRadius", .number, "24", "the edit form's fields' corner radius"),
        .init("gradientStart", .number, "0.2", "where the edit form's gradient leaves the panel colour"),
        .init("gradientStop", .number, "1.5", "where it reaches the collection's colour"),
        .init("colorRadius", .number, "28", "the colour sheet's corner radius"),
        .init("swatchSize", .number, "44", "a swatch's size, and the colour button's"),
        .init("swatchColumns", .whole, "6", "swatches a row"),
        .init("decimals", .whole, "2", "decimals in earnings and credits"),
        .init("topRanks", .whole, "3", "ranks drawn in the accent"),
        .init("publicLimit", .whole, "5", "listings the edit grouping form offers to add"),
        .init("detail", .detents, "[.fraction(0.6)]", "the detail sheet's detents"),
        .init("edit", .detents, "[.fraction(0.78), .large]", "the edit form's detents"),
        .init("color", .detents, "[.fraction(0.32)]", "the colour sheet's detents"),
        .init("add", .detents, "[.medium]", "the add sheet's detents"),
        .init("form", .detents, "[.medium]", "the new and edit grouping forms' detents"),
        .init("swatches", .swatches, "red orange yellow green mint teal cyan blue indigo purple pink brown", "the colours the edit form offers, as system colour names"),
        .init("cardDate", .dateStyle, ".abbreviated", "a card's date: abbreviated, long, numeric or complete, or a quoted date format"),
        .init("cardTime", .timeStyle, ".omitted", "a card's time after its date: omitted, shortened, standard or complete"),
        .init("rowDate", .dateStyle, ".abbreviated", "a document row's date, its time omitted"),
    ]

    static func tuning(_ key: String) -> CatalogTuning? { all.first { $0.key == key } }

    /// The system colours a swatch may name, as `Color`'s static members.
    static let systemColors = ["red", "orange", "yellow", "green", "mint", "teal", "cyan", "blue", "indigo", "purple", "pink", "brown", "gray", "black", "white"]
    static let dateStyles = ["abbreviated", "long", "numeric", "complete"]
    static let timeStyles = ["omitted", "shortened", "standard", "complete"]
}
