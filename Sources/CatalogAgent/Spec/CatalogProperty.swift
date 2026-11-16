//  WHAT: One thing a catalog view reads off an app's type: the word a mapping line names it by, the requirement it
//        is in the protocol, what it holds, and the sentence that documents it.

import Foundation

struct CatalogProperty: Sendable, Equatable {
    /// The word on a mapping line: `name`, `earnings`, `members`.
    let key: String
    /// The protocol requirement: `catalogName`. Namespaced, so an app's own `name` never collides with it.
    let member: String
    let kind: CatalogKind
    /// One sentence, the requirement's doc comment.
    let doc: String
    /// Other words a line may use for it.
    let aliases: [String]

    init(_ key: String, _ member: String, _ kind: CatalogKind, _ doc: String, aliases: [String] = []) {
        self.key = key; self.member = member; self.kind = kind; self.doc = doc; self.aliases = aliases
    }
}
