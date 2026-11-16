//  WHAT: The files a call makes from its own values rather than from a template: `CatalogProtocols.swift` from the
//        role table, `CatalogLook.swift` from the look lines over the system's values, and `CatalogLaunch.swift` from
//        the launch lines.

import Foundation

enum ProtocolsEmitter {
    /// One protocol a role, every requirement with a default, so a type maps only what it has.
    static func emit() -> String {
        var lines = [
            "import SwiftUI",
            "",
            "// The app's types, as the catalog views know them: one protocol a role. Every view is generic over the roles",
            "// it shows, so it draws the app's own values and hands their keys back to the app's closures. A role the app",
            "// has no type for is filled by the kit's own value type (`CatalogCollection`, `CatalogDocument`,",
            "// `CatalogListing`, `CatalogGrouping`).",
        ]
        for role in CatalogRole.allCases {
            lines += [
                "",
                "/// \(role.doc)",
                "///",
                "/// Every requirement has a default, so a type maps only what it has. The names start with `catalog` so they",
                "/// never meet the type's own properties.",
                "protocol \(role.protocolName): Identifiable {",
                "    /// Identifies it to the app's closures: its `id`, as text.",
                "    var catalogKey: String { get }",
            ]
            for property in role.properties {
                lines.append("    /// \(property.doc)")
                lines.append("    var \(property.member): \(property.kind.swiftType) { get }")
                if property.kind == .color {
                    lines.append("    /// The colour as the app named it (`brown`, `#AE9060`), handed back when the edit form keeps it.")
                    lines.append("    var catalogColorName: String? { get }")
                }
            }
            lines += ["}", "", "extension \(role.protocolName) {", "    var catalogKey: String { CatalogValue.key(id) }"]
            for property in role.properties {
                lines.append("    var \(property.member): \(property.kind.swiftType) { \(property.kind.defaultValue) }")
                if property.kind == .color { lines.append("    var catalogColorName: String? { nil }") }
            }
            lines.append("}")
        }
        return TemplateRender.tidy(lines)
    }
}

enum LookEmitter {
    /// `enum CatalogLook`: one static member a role, the call's value or the system's.
    static func emit(_ values: CatalogValues, mapped: Set<String>) -> String {
        var lines = [
            "import SwiftUI",
            "#if canImport(UIKit)",
            "import UIKit",
            "#elseif canImport(AppKit)",
            "import AppKit",
            "#endif",
            "",
            "/// The look the catalog views read: the app's colours, type and spacing where the call named them, the",
            "/// system's elsewhere, so the views build in any app.",
            "enum CatalogLook {",
        ]
        let sections: [(CatalogLookRole.Kind, String)] = [(.color, "Colours"), (.design, "Type"), (.font, ""), (.spacing, "Spacing")]
        for (kind, title) in sections {
            if !title.isEmpty { lines += ["", "    // MARK: \(title)", ""] }
            for role in CatalogLookRole.all where role.kind == kind {
                let swift = values.look[role.key] ?? role.fallback
                let type: String
                switch kind {
                case .color: type = "Color"
                case .font: type = "Font"
                case .design: type = "Font.Design"
                case .spacing: type = "CGFloat"
                }
                let source = mapped.contains(role.key) ? "" : " The system's, as no look line maps it."
                lines.append("    /// \(role.doc.prefix(1).uppercased() + role.doc.dropFirst()).\(source)")
                lines.append("    static var \(role.key): \(type) { \(swift) }")
            }
        }
        lines += Template.catalogLookTail.components(separatedBy: "\n")
        return TemplateRender.tidy(lines)
    }
}

enum LaunchEmitter {
    /// `enum CatalogLaunch`: the states the views open in, and which `-destination` names which.
    static func emit(_ launches: [LaunchState]) -> String {
        var lines = [
            "import Foundation",
            "",
            "/// The state the catalog views open in when the app is launched with `-destination <name>`, as UI tests and",
            "/// screenshots launch it: read once by the view the state belongs to, which presents its own sheets for it.",
            "enum CatalogLaunch: Equatable {",
            "    /// The cards of my collections.",
            "    case mine",
            "    /// One collection's detail sheet, by its name or id.",
            "    case detail(String)",
            "    /// One collection's edit form, by its name or id.",
            "    case edit(String)",
            "    /// Others' collections, ranked.",
            "    case browse",
            "    /// The groupings.",
            "    case groupings",
            "    /// The groupings, with the form for a new one up.",
            "    case newGrouping",
            "",
            "    /// The state the launch names, when it names one of this kit's.",
            "    static var current: CatalogLaunch? {",
            "        guard let destination = UserDefaults.standard.string(forKey: \"destination\") else { return nil }",
            "        switch destination {",
        ]
        for launch in launches {
            lines.append("        case \(TemplateFill.literal(launch.destination)): return \(launch.state.swift)")
        }
        lines += [
            "        default: return nil",
            "        }",
            "    }",
            "",
            "    /// The collection this state opens, when it opens one.",
            "    var collection: String? {",
            "        switch self {",
            "        case .detail(let name), .edit(let name): return name",
            "        case .mine, .browse, .groupings, .newGrouping: return nil",
            "        }",
            "    }",
            "}",
        ]
        return TemplateRender.tidy(lines)
    }
}
