//  WHAT: Every word the catalog views show, by key, with its natural English default: the one table a `strings`
//        line names a key from, the guide and the reference list, and the templates write as Swift literals.
//
//            catalog.title = "The World"        browse.credits = "{credits} cr"        collection = "model"
//
//  PIN:  NOUNS FIRST. `collection`, `collections`, `grouping` and `groupings` are the words every other default is
//        made of (`{Collection}` capitalised), so an app renames its nouns in four lines and every string follows.
//        A placeholder in lower case that is not a noun (`{name}`, `{count}`) is what the view fills in as it draws;
//        each key says which it takes.

import Foundation

struct CatalogWord: Sendable, Equatable {
    let key: String
    /// The English default, made of the nouns and the key's placeholders.
    let fallback: String
    /// What the view fills in as it draws: `name`, `count`, `date`, `owner`, `rank`, `credits`, `tag`.
    let fills: [String]
    /// Where it shows, in one line.
    let doc: String

    init(_ key: String, _ fallback: String, fills: [String] = [], _ doc: String) {
        self.key = key; self.fallback = fallback; self.fills = fills; self.doc = doc
    }
}

enum CatalogWords {
    /// The nouns, which every other default is made of.
    static let nouns = ["collection", "collections", "grouping", "groupings"]

    static let all: [CatalogWord] = [
        // The nouns.
        .init("collection", "collection", "one of the person's collections, as a word in a sentence: `model`"),
        .init("collections", "collections", "several of them: `models`"),
        .init("grouping", "group", "one named set of collections: `loom`"),
        .init("groupings", "groups", "several of them: `looms`"),
        // Mine.
        .init("mine.title", "{Collections}", "the bar's title over the cards"),
        .init("mine.leading", "Profile", "the leading bar button's accessibility label"),
        .init("mine.trailing", "More", "the trailing bar button's accessibility label"),
        .init("mine.empty.title", "No {Collections}", "the cards' empty state"),
        .init("mine.empty.message", "Your {collections} show here.", "the line under it, in italics"),
        .init("card.documents.one", "document", "after a card's count of one"),
        .init("card.documents.other", "documents", "after any other count"),
        .init("card.earnings", "credits", "under a card's earnings"),
        .init("card.online", "Online", "the online dot's accessibility label"),
        .init("card.offline", "Offline", "the offline dot's accessibility label"),
        .init("menu.edit", "Edit {collection}", "the long-press menu's edit item"),
        .init("menu.offline", "Set Offline", "the menu's item that takes an online collection offline"),
        .init("menu.online", "Set Online", "the item that puts it back"),
        .init("menu.delete", "Delete {collection}", "the menu's delete item, and the confirmation's button"),
        .init("delete.title", "Delete {name}?", fills: ["name"], "the confirmation's title"),
        .init("delete.message", "This can't be undone.", "the confirmation's message"),
        // The detail sheet.
        .init("detail.title", "{name} {Collection}", fills: ["name"], "the detail sheet's title"),
        .init("detail.updated", "Updated: {date}", fills: ["date"], "under each document's title"),
        // The edit form.
        .init("edit.title", "Edit {Collection}", "the edit form's title"),
        .init("edit.name", "Name your {collection}...", "the name field's placeholder"),
        .init("edit.description.header", "Description", "over the description field"),
        .init("edit.description", "Describe this {collection}...", "the description field's placeholder"),
        .init("edit.tags.header", "Tags", "over the tags"),
        .init("edit.tags.add", "add tag", "the chip that adds a tag"),
        .init("edit.tag.add", "Add Tag", "the alert that adds one"),
        .init("edit.tag.edit", "Edit Tag", "the alert that changes one"),
        .init("edit.tag.field", "Tag name", "the alert's field"),
        .init("edit.tag.remove", "Remove {tag}", fills: ["tag"], "a chip's remove button's accessibility label"),
        .init("edit.color", "Color", "the colour sheet's title, and the colour button's accessibility label"),
        .init("edit.keyboard", "Ok", "the bar's button that drops the keyboard"),
        .init("edit.failed", "Couldn't Save", "the alert when saving fails"),
        // Buttons.
        .init("close", "Close", "the close buttons' accessibility label"),
        .init("save", "Save", "the edit form's and the tag alert's save"),
        .init("cancel", "Cancel", "every cancel"),
        .init("done", "Done", "the colour sheet's, the add sheet's and the edit grouping form's done"),
        .init("create", "Create", "the new grouping form's create"),
        .init("ok", "OK", "dismisses the failure alert"),
        // Others' collections.
        .init("catalog.title", "Explore", "the bar's title over the browse and groupings tabs"),
        .init("browse.tab", "Browse", "the browse tab"),
        .init("groupings.tab", "{Groupings}", "the groupings tab"),
        .init("browse.search", "Search all {collections}…", "the search field's placeholder"),
        .init("browse.clear", "Clear", "the button that empties the search, for accessibility"),
        .init("browse.owner", "by {owner}", fills: ["owner"], "under a listing's name"),
        .init("browse.rank", "#{rank}", fills: ["rank"], "a listing's rank"),
        .init("browse.credits", "{credits} credits", fills: ["credits"], "a listing's credits, at the call's decimals"),
        .init("browse.count.one", "{count} doc", fills: ["count"], "a listing's count of one"),
        .init("browse.count.other", "{count} docs", fills: ["count"], "any other count"),
        .init("browse.empty.title", "No {Collections} Yet", "the browse tab with nothing listed"),
        .init("browse.empty.message", "Public {collections} will appear here once activity begins.", "the line under it"),
        .init("add.title", "Add to {Grouping}", "the add sheet's title, and the add button's accessibility label"),
        .init("add.existing", "Add to existing {Grouping}", "its section of groupings"),
        .init("add.new", "Create new {Grouping}", "its row that starts a grouping"),
        .init("add.mine", "Create with your {collections}", "its section of mine"),
        // Groupings.
        .init("groupings.count.one", "{count} {collection}", fills: ["count"], "a grouping's count of one"),
        .init("groupings.count.other", "{count} {collections}", fills: ["count"], "any other count"),
        .init("groupings.active", "active {grouping}", "over the active grouping's name in the banner"),
        .init("groupings.deselect", "deselect", "the banner's button"),
        .init("groupings.separator", " · ", "between a grouping's members' names"),
        .init("groupings.select", "Select {grouping}", "a grouping's circle, for accessibility"),
        .init("groupings.new", "New {Grouping}", "the button and the form that make a grouping"),
        .init("groupings.edit", "Edit {Grouping}", "the form that changes one, and its pencil's accessibility label"),
        .init("groupings.empty.title", "No {Groupings} Yet", "the groupings tab with none"),
        .init("groupings.empty.message", "Create a {grouping} to gather the {collections} you come back to.", "the line under it"),
        .init("form.name.header", "{Grouping} name", "over the name field, and the edit form's placeholder"),
        .init("form.name", "e.g. Reading, Work, Favorites…", "the new form's name placeholder"),
        .init("form.members", "{Collections} in this {Grouping}", "the section of members"),
        .init("form.mine", "Add your personal {collections}", "the new form's section of mine to add"),
        .init("form.add", "Add {Collections}", "the edit form's section to add from"),
        .init("form.public", "Public {Collections}", "its first group: the top of the ranking"),
        .init("form.yours", "Your {Collections}", "its second group: mine"),
    ]

    static func word(_ key: String) -> CatalogWord? { all.first { $0.key == key } }

    /// The capitalised nouns a string may name besides the lower-case ones: `{Collection}`.
    static let capitalNouns = nouns.map { $0.prefix(1).uppercased() + $0.dropFirst() }

    /// Every word's value for a call: its own lines over the defaults, the nouns written in.
    static func resolve(_ given: [String: String]) -> [String: String] {
        var nouns: [String: String] = [:]
        for noun in Self.nouns { nouns[noun] = given[noun] ?? word(noun)?.fallback ?? noun }
        var values: [String: String] = [:]
        for word in all {
            var text = given[word.key] ?? word.fallback
            if !Self.nouns.contains(word.key) {
                for noun in Self.nouns {
                    let value = nouns[noun] ?? noun
                    text = text.replacingOccurrences(of: "{\(noun.prefix(1).uppercased() + noun.dropFirst())}", with: value.prefix(1).uppercased() + value.dropFirst())
                    text = text.replacingOccurrences(of: "{\(noun)}", with: value)
                }
            }
            values[word.key] = text
        }
        return values
    }

    /// The placeholders `text` names in braces, in order: `{name}`, `{Collection}`.
    static func placeholders(in text: String) -> [String] {
        var found: [String] = []
        var rest = Substring(text)
        while let open = rest.firstIndex(of: "{") {
            let after = rest[rest.index(after: open)...]
            guard let close = after.firstIndex(of: "}") else { break }
            let name = String(after[..<close])
            if name.range(of: #"^[A-Za-z]+$"#, options: .regularExpression) != nil { found.append(name) }
            rest = after[after.index(after: close)...]
        }
        return found
    }
}
