import Foundation

/// A screen family a call may leave out; every one is written when the call names none.
public enum CatalogScreen: String, Codable, Sendable, CaseIterable {
    /// My collections as cards, a collection's detail sheet and its edit form: `CollectionsView`.
    case mine
    /// Other people's collections, ranked and searchable: the Browse tab of `CatalogView`.
    case browse
    /// Named sets of collections, with their banner and forms: the second tab of `CatalogView`.
    case groupings
}
