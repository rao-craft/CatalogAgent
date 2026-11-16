import Foundation
import XCTest
@testable import CatalogAgent

/// The kit compiled and run as apps would: the Seer call written into a Seer stand-in in Swift 6 and again in Swift 5
/// (SeerKit's entities in a module of their own, DesignAgent's names, its two pages with the bodies the report gives),
/// a recipe app's call over other field types, the least call with a prefix, and a kit made by two calls; built with
/// `swift build` for the Mac and with `xcodebuild` for the iPhone simulator, then every screen drawn offscreen.
/// Gated (`CATALOG_BUILD=1`): the builds take a few minutes.
final class CatalogBuildTests: XCTestCase {
    private struct App {
        let name: String
        let mode: String
        let input: CatalogAgent.Input
        let files: [String: String]
        let dependencies: [String]
    }

    func testTheKitBuildsForMacAndIPhoneInBothLanguageModesAndEveryScreenDraws() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["CATALOG_BUILD"] == "1", "set CATALOG_BUILD=1 to build the output")
        let package = try Fixture.folder()
        let seer = try Fixture.example("seer")
        var recipes = try Fixture.example("recipes")
        recipes.into = nil
        let seerFiles = ["SeerDesign.swift": CatalogApps.seerDesign, "SeerServices.swift": CatalogApps.seerServices,
                         "SeerSeed.swift": CatalogApps.seerSeed, "SeerPages.swift": CatalogApps.seerPages(), "Check.swift": CatalogApps.seerCheck]
        let apps = [
            App(name: "Seer", mode: ".v6", input: seer, files: seerFiles, dependencies: ["SeerKit"]),
            App(name: "SeerFive", mode: ".v5", input: seer, files: seerFiles, dependencies: ["SeerKit"]),
            App(name: "Recipes", mode: ".v5", input: recipes, files: ["Models.swift": CatalogApps.recipeModels, "Check.swift": CatalogApps.recipeCheck],
                dependencies: []),
            App(name: "Least", mode: ".v6", input: .init(prefix: "Kit"), files: ["Check.swift": CatalogApps.leastCheck], dependencies: []),
        ]
        let kitKit = package.appendingPathComponent("Sources/SeerKit")
        try FileManager.default.createDirectory(at: kitKit, withIntermediateDirectories: true)
        try CatalogApps.seerKit.write(to: kitKit.appendingPathComponent("SeerKit.swift"), atomically: true, encoding: .utf8)
        var written = 0
        for app in apps {
            let sources = package.appendingPathComponent("Sources/\(app.name)")
            try FileManager.default.createDirectory(at: sources, withIntermediateDirectories: true)
            // The app's own files first, so its types are there for the call to check its paths against.
            for (name, text) in app.files {
                try text.replacingOccurrences(of: "__APP__", with: app.name)
                    .write(to: sources.appendingPathComponent(name), atomically: true, encoding: .utf8)
            }
            var input = app.input
            input.into = "Sources/\(app.name)/" + (input.into ?? "Components/Catalog")
            input.directory = package.path
            written += try CatalogAgent.write(input, note: { _ in }, yield: { _ in }).paths.count
        }
        // A kit made by two calls into one folder: the second adds a screen to the first.
        for call in [CatalogAgent.Input(screens: [.mine]), CatalogAgent.Input(screens: [.browse], launch: ["shelf = browse"])] {
            var input = call
            input.into = "Sources/Later/Catalog"
            input.directory = package.path
            written += try CatalogAgent.write(input, note: { _ in }, yield: { _ in }).paths.count
        }
        XCTAssertGreaterThan(written, 80)
        print("catalog build: wrote \(written) files for \(apps.count + 1) apps")

        let libraries = apps.map(\.name) + ["Later"]
        let targets = [#".target(name: "SeerKit", swiftSettings: [.swiftLanguageMode(.v6)])"#]
            + apps.map { app in
                #".target(name: "\#(app.name)", dependencies: [\#(app.dependencies.map { "\"\($0)\"" }.joined(separator: ", "))], swiftSettings: [.swiftLanguageMode(\#(app.mode))])"#
            }
            + [#".target(name: "Later", swiftSettings: [.swiftLanguageMode(.v6)])"#]
        try """
        // swift-tools-version:6.0
        import PackageDescription
        let package = Package(
            name: "CatalogApps",
            platforms: [.iOS(.v17), .macOS(.v14)],
            products: [.library(name: "CatalogApps", targets: [\(libraries.map { "\"\($0)\"" }.joined(separator: ", "))])],
            targets: [
                \(targets.joined(separator: ",\n        ")),
                .executableTarget(name: "Check", dependencies: [\(apps.map { "\"\($0.name)\"" }.joined(separator: ", "))],
                                  swiftSettings: [.swiftLanguageMode(.v6)]),
            ]
        )
        """.write(to: package.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)
        let check = package.appendingPathComponent("Sources/Check")
        try FileManager.default.createDirectory(at: check, withIntermediateDirectories: true)
        try """
        import Foundation
        \(apps.map { "import \($0.name)" }.joined(separator: "\n"))

        let results = MainActor.assumeIsolated {
            [\(apps.map { "\($0.name)Check.run()" }.joined(separator: ", "))]
        }
        let failed = results.flatMap(\\.failed)
        print("drew \\(results.flatMap(\\.drawn).count) screens")
        if !failed.isEmpty {
            print("did not draw: \\(failed)")
            exit(1)
        }
        """.write(to: check.appendingPathComponent("main.swift"), atomically: true, encoding: .utf8)

        // The Mac: every target, Swift 6 and Swift 5, with no warning in what the kit wrote.
        let mac = try run(["swift", "build", "--package-path", package.path])
        XCTAssertEqual(mac.status, 0, String(mac.log.suffix(6_000)))
        let warnings = mac.log.split(separator: "\n").filter { ($0.contains("/Catalog/") || $0.contains("/Cookbooks/")) && $0.contains("warning:") }
        XCTAssertTrue(warnings.isEmpty, warnings.joined(separator: "\n"))
        print("catalog build: mac \(mac.status == 0 ? "built" : "failed"), \(warnings.count) warnings in the kit's files")

        // Every screen drawn from each app's own values: nothing traps.
        let drawn = try run(["swift", "run", "--package-path", package.path, "Check"])
        XCTAssertEqual(drawn.status, 0, String(drawn.log.suffix(4_000)))
        XCTAssertNotNil(drawn.log.range(of: #"drew \d{2,} screens"#, options: .regularExpression), drawn.log)
        print("catalog build: " + (drawn.log.split(separator: "\n").last { $0.hasPrefix("drew ") }.map(String.init) ?? "drew nothing"))

        // The iPhone simulator.
        let phone = try run(["xcodebuild", "-scheme", "CatalogApps", "-destination", "generic/platform=iOS Simulator",
                             "-derivedDataPath", package.appendingPathComponent("dd").path,
                             "-skipPackagePluginValidation", "-skipMacroValidation", "build"], in: package)
        XCTAssertTrue(phone.log.contains("** BUILD SUCCEEDED **"), String(phone.log.suffix(6_000)))
        let phoneWarnings = phone.log.split(separator: "\n").filter { ($0.contains("/Catalog/") || $0.contains("/Cookbooks/")) && $0.contains("warning:") }
        XCTAssertTrue(phoneWarnings.isEmpty, Array(Set(phoneWarnings)).joined(separator: "\n"))
        print("catalog build: iOS simulator \(phone.log.contains("** BUILD SUCCEEDED **") ? "BUILD SUCCEEDED" : "failed"), "
            + "\(Set(phoneWarnings).count) warnings in the kit's files")
    }

    private func run(_ arguments: [String], in folder: URL? = nil) throws -> (status: Int32, log: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = arguments
        if let folder { process.currentDirectoryURL = folder }
        let out = Pipe()
        process.standardOutput = out
        process.standardError = out
        try process.run()
        let data = out.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, String(decoding: data, as: UTF8.self))
    }
}
