// swift-tools-version:6.0
// CatalogAgent: a catalog of collections (my collections as cards with a detail sheet and an edit form, others'
// collections ranked and searchable, named groupings of them) as plain SwiftUI any app can use, written into an app
// from its own types, as a Granite agent package. An app that links it finds the `catalog` agent through Granite's
// roster, with nothing listed by hand.

import PackageDescription

let package = Package(
    name: "CatalogAgent",
    platforms: [.macOS(.v14)],
    products: [.library(name: "CatalogAgent", targets: ["CatalogAgent"])],
    dependencies: [.package(url: "https://github.com/riteshpakala/Granite.git", branch: "main")],
    targets: [
        .target(name: "CatalogAgent", dependencies: [.product(name: "GraniteAgents", package: "Granite")],
                swiftSettings: [.swiftLanguageMode(.v6)]),
        .testTarget(name: "CatalogAgentTests",
                    dependencies: ["CatalogAgent", .product(name: "GraniteAgents", package: "Granite")],
                    swiftSettings: [.swiftLanguageMode(.v6)]),
    ]
)
