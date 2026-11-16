//  WHAT: The files that make an app's types the views' types: one extension a mapping line, each mapped property a
//        computed requirement that reads the type through `CatalogValue`.
//  PIN:  AN UNMAPPED PROPERTY IS NOT WRITTEN: the protocol's default answers for it, so a conformance holds only
//        what the line says. An `id` the type already has is never redeclared.
//  PIN:  ONE TYPE, SEVERAL ROLES (a model that is mine and also listed): a requirement two of its protocols share
//        (`catalogKey`, `catalogName`, …) is written once, from the line that maps it or as its default, since Swift
//        will not choose between two protocols' defaults for one type.

import Foundation

enum ConformanceEmitter {
    /// What every role's protocol holds besides its table: the key the closures are handed.
    private static let key = CatalogProperty("", "catalogKey", .text, "")

    /// One file a mapping line, `<Type>+<Role>.swift`: `extension ModelGroup: CollectionRepresentable { … }`. The
    /// lines of one type are read together, and a member two of its roles share is written once, in its first role's
    /// file. Answers the files, or every reason the lines of one type disagree.
    static func emit(_ mappings: [Mapping], imports: [String]) -> (files: [(name: String, text: String)], problems: [String]) {
        var files: [(name: String, text: String)] = [], problems: [String] = []
        var types: [String] = []
        for mapping in mappings where !types.contains(mapping.type) { types.append(mapping.type) }
        for type in types {
            let lines = mappings.filter { $0.type == type }.sorted { order($0.role) < order($1.role) }
            var kinds: [String: CatalogKind] = [:], owners: [String: [CatalogRole]] = [:]
            for line in lines {
                for property in [key] + line.role.properties {
                    if let kind = kinds[property.member], kind != property.kind {
                        let roles = (owners[property.member] ?? []) + [line.role]
                        problems.append("`\(type)` cannot be both a \(roles.map(\.rawValue).joined(separator: " and a ")): they show `\(property.key)` differently")
                    }
                    kinds[property.member] = property.kind
                    owners[property.member, default: []].append(line.role)
                }
            }
            let shared = Set(owners.filter { $0.value.count > 1 }.keys)
            var sharedSources: [String: Mapping.Source] = [:]
            var ids: [Mapping.Source] = []
            for line in lines {
                if let id = line.id, !ids.contains(id) { ids.append(id) }
                for assignment in line.assignments where shared.contains(assignment.property.member) {
                    let member = assignment.property.member
                    if let source = sharedSources[member], source != assignment.source {
                        problems.append("`\(type)` maps `\(assignment.property.key)` one way as a \(lines[0].role.rawValue) and another as a \(line.role.rawValue): say it the same way in both lines")
                    }
                    sharedSources[member] = assignment.source
                }
            }
            if ids.count > 1 { problems.append("`\(type)` maps `id` differently in its lines: say it the same way in each") }
            for (index, line) in lines.enumerated() {
                var body: [String] = []
                if index == 0 {
                    if let id = ids.first, id != .path("id") {
                        // `Identifiable` is public, so a public type's `id` must be too; on an internal type it is internal.
                        body.append("    /// Identifies it to the views; public because `Identifiable` asks that of a public type.")
                        body += getter("id", type: "String", conversion: "id", source: id, access: "public ")
                    }
                    // Every shared member once: as a line maps it, or as its default.
                    for property in sharedProperties(lines, shared) {
                        if let source = sharedSources[property.member] {
                            body += getters(property, source: source)
                        } else if property.member == key.member {
                            body.append("    var catalogKey: String { CatalogValue.key(id) }")
                        } else {
                            body.append("    var \(property.member): \(property.kind.swiftType) { \(property.kind.defaultValue) }")
                        }
                    }
                }
                for assignment in line.assignments where !shared.contains(assignment.property.member) {
                    body += getters(assignment.property, source: assignment.source)
                }
                var text = header(imports)
                text += [
                    "/// \(article(type).capitalized) `\(type)` as the catalog views show \(line.role == .document ? "a document" : "a \(line.role.rawValue)").",
                    "extension \(type): \(line.role.protocolName) {",
                ]
                text += body
                text.append("}")
                files.append((name: "\(line.fileStem)+\(line.role.name).swift", text: text.joined(separator: "\n") + "\n"))
            }
        }
        return (files, problems)
    }

    /// The members `lines`' roles share, once each, in the first role's order, the key first.
    private static func sharedProperties(_ lines: [Mapping], _ shared: Set<String>) -> [CatalogProperty] {
        var seen: Set<String> = [], properties: [CatalogProperty] = []
        for line in lines {
            for property in [key] + line.role.properties where shared.contains(property.member) && seen.insert(property.member).inserted {
                properties.append(property)
            }
        }
        return properties
    }

    private static func order(_ role: CatalogRole) -> Int { CatalogRole.allCases.firstIndex(of: role) ?? 0 }

    // MARK: Lines

    static func header(_ imports: [String]) -> [String] {
        (["Foundation", "SwiftUI"] + imports.filter { $0 != "Foundation" && $0 != "SwiftUI" }).map { "import \($0)" } + [""]
    }

    /// The requirements a mapped property writes: a colour writes its name beside it, so the edit form can hand the
    /// name back.
    private static func getters(_ property: CatalogProperty, source: Mapping.Source) -> [String] {
        var lines = getter(property.member, type: property.kind.swiftType, conversion: property.kind.conversion, source: source)
        if property.kind == .color {
            lines += getter("catalogColorName", type: "String?", conversion: "colorName", source: source)
        }
        return lines
    }

    /// A computed requirement: a bare path read off the type, or an expression that names `value`.
    private static func getter(_ member: String, type: String, conversion: String, source: Mapping.Source,
                               access: String = "") -> [String] {
        switch source {
        case .path(let path):
            return ["    \(access)var \(member): \(type) { CatalogValue.\(conversion)(self.\(path)) }"]
        case .expression(let expression):
            guard expression.range(of: #"(?<![A-Za-z0-9_.])value(?![A-Za-z0-9_])"#, options: .regularExpression) != nil else {
                return ["    \(access)var \(member): \(type) { CatalogValue.\(conversion)(\(expression)) }"]
            }
            return [
                "    \(access)var \(member): \(type) {",
                "        let value = self",
                "        return CatalogValue.\(conversion)(\(expression))",
                "    }",
            ]
        }
    }

    private static func article(_ word: String) -> String {
        guard let first = word.first?.lowercased() else { return "a" }
        return "aeiou".contains(first) ? "an" : "a"
    }
}
