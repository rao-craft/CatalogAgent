import Foundation

/// What a run says as it goes.
public enum CatalogFrame: Sendable {
    /// The call was read: how many mapping lines, and how many views it writes.
    case read(mappings: Int, views: Int)
    /// The files are written.
    case written(CatalogResult)

    public var result: CatalogResult? {
        if case .written(let result) = self { return result }
        return nil
    }
}
