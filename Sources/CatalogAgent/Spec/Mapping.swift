//  WHAT: One mapping line, read: which role an app's type takes, and how each thing the views show is read off it.

import Foundation

struct Mapping: Sendable, Equatable {
    /// How a right side reads its value.
    enum Source: Sendable, Equatable {
        /// A bare path, read off the value: `owner.name`, `stats?.credits`.
        case path(String)
        /// Swift that may name `value`: `value.name ?? "Untitled"`.
        case expression(String)
    }

    struct Assignment: Sendable, Equatable {
        let property: CatalogProperty
        let source: Source
    }

    let line: String
    let role: CatalogRole
    /// The app's type, as the line wrote it: `ModelGroup`, `SeerKit.ModelGroup`.
    let type: String
    /// How the type is identified, when the line says so (`id=slug`); nil when it has an `id` of its own.
    let id: Source?
    let assignments: [Assignment]

    /// The type's name for a file: `SeerKit.ModelGroup` is `SeerKitModelGroup`.
    var fileStem: String { type.replacingOccurrences(of: ".", with: "") }
}
