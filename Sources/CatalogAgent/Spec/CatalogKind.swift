//  WHAT: What a role property holds, and how a mapped value becomes it: its Swift type, its default, and the
//        `CatalogValue` conversion a conformance wraps every right side in.
//  PIN:  EVERY RIGHT SIDE IS CONVERTED. An app's `updated` may be a `Date`, an ISO string or seconds; its `tags` a list
//        or one comma-separated string; `CatalogValue` has an overload for each, so a bare path compiles whatever
//        the field's type.

import Foundation

enum CatalogKind: Sendable, Equatable {
    case text, optionalText, optionalInt, number, tags, flag, color, date, keys

    /// The requirement's type in the protocol.
    var swiftType: String {
        switch self {
        case .text: return "String"
        case .optionalText: return "String?"
        case .optionalInt: return "Int?"
        case .number: return "Double?"
        case .tags, .keys: return "[String]"
        case .flag: return "Bool?"
        case .color: return "Color?"
        case .date: return "Date?"
        }
    }

    /// What a type that does not map the property shows.
    var defaultValue: String {
        switch self {
        case .text: return "\"\""
        case .tags, .keys: return "[]"
        case .optionalText, .optionalInt, .number, .flag, .color, .date: return "nil"
        }
    }

    /// The field types `CatalogValue`'s overloads for this kind take, optional or not, as the template declares them.
    var takes: Set<String> {
        let integers = Self.integers
        switch self {
        case .text, .optionalText: return integers.union(["String", "Substring", "URL", "UUID"])
        case .optionalInt: return integers.union(["Double", "String"])
        case .number: return integers.union(["Double", "Float", "Decimal", "String"])
        case .tags: return ["[String]", "[String]?", "[Substring]", "String", "Set<String>"]
        case .flag: return integers.union(["Bool", "String"])
        case .color: return ["String", "Color"]
        case .date: return ["Date", "String", "Double", "Int", "TimeInterval"]
        case .keys: return ["[String]", "[String]?", "[UUID]", "[Int]", "String", "Set<String>"]
        }
    }

    /// What `takes` says, in words, for a refusal.
    var takesInWords: String {
        switch self {
        case .text, .optionalText: return "text (a String, a URL, a UUID or a whole number)"
        case .optionalInt: return "a whole number (an Int, a Double or a String)"
        case .number: return "a number (an Int, a Double, a Decimal or a String)"
        case .tags: return "tags (a list of Strings, or one String with commas between them)"
        case .flag: return "a flag (a Bool, a whole number or a String such as \"online\")"
        case .color: return "a colour (a Color, or a String naming a system colour such as \"brown\" or a hex such as \"#AE9060\")"
        case .date: return "a date (a Date, an ISO String, or seconds as a Double or an Int)"
        case .keys: return "ids or names (a list of Strings, UUIDs or Ints, or one String with commas between them)"
        }
    }

    static let integers: Set<String> = ["Int", "Int8", "Int16", "Int32", "Int64", "UInt", "UInt8", "UInt16", "UInt32", "UInt64"]

    /// A right side that says the property has nothing: what leaving it out already shows.
    func isNothing(_ value: String) -> Bool {
        let text = value.trimmingCharacters(in: .whitespaces)
        return ["nil", "[]", "\"\"", ".none"].contains(text) || text == defaultValue
    }

    /// The `CatalogValue` function a mapped value goes through.
    var conversion: String {
        switch self {
        case .text: return "text"
        case .optionalText: return "optionalText"
        case .optionalInt: return "optionalInt"
        case .number: return "number"
        case .tags: return "tags"
        case .flag: return "flag"
        case .color: return "color"
        case .date: return "date"
        case .keys: return "keys"
        }
    }
}
