//  WHAT: A call's values written into a template where it names them, in the form a person writes them:
//
//            {{s:menu.edit}}                          "Edit model"          a word, as a Swift literal
//            {{s:detail.title|name=item.catalogName}} "\(item.catalogName) Model"   with what it fills in
//            {{sym:browse.add}}                       "plus.circle"         an SF Symbol, quoted
//            {{m:press}}                              .spring(duration: 0.2, bounce: 0.4)
//            {{n:pressScale}}                         0.97                  a number, or a detent list, a date style
//            {{swatches}}                             CatalogSwatch("red", .red), …
//            {{look:accent}}                          Color.accent          a look role's Swift
//            {{date:card}}                            date.formatted(date: .abbreviated, time: .omitted)
//
//  PIN:  A TEMPLATE NAMES ONLY KEYS THE TABLES HOLD, and every word it fills gives every placeholder its key takes;
//        both are faults of the template, caught by the tests before any call is made.

import Foundation

/// Every value a call writes, its lines over the defaults.
struct CatalogValues: Sendable, Equatable {
    /// Each word with the nouns written in, its fill-ins still in braces.
    var strings: [String: String]
    var symbols: [String: String]
    var tuning: [String: String]
    /// Each look role's Swift.
    var look: [String: String]

    /// The defaults alone.
    static var defaults: CatalogValues { CatalogValues(strings: [:], symbols: [:], tuning: [:], look: [:]) }

    init(strings: [String: String], symbols: [String: String], tuning: [String: String], look: [String: String]) {
        self.strings = CatalogWords.resolve(strings)
        var symbolValues: [String: String] = [:]
        for symbol in CatalogSymbol.all { symbolValues[symbol.key] = symbols[symbol.key] ?? symbol.fallback }
        self.symbols = symbolValues
        var tuningValues: [String: String] = [:]
        for key in CatalogTuning.all { tuningValues[key.key] = tuning[key.key] ?? key.fallback }
        self.tuning = tuningValues
        var lookValues: [String: String] = [:]
        for role in CatalogLookRole.all { lookValues[role.key] = look[role.key] ?? role.fallback }
        self.look = lookValues
    }
}

enum TemplateFill {
    enum Failure: Error, Equatable, CustomStringConvertible {
        case unknown(String)
        case unfilled(String)

        var description: String {
            switch self {
            case .unknown(let token): return "the template names `\(token)`, which no table holds"
            case .unfilled(let token): return "the template's `\(token)` leaves a placeholder of its key unfilled"
            }
        }
    }

    /// `source` with every `{{…}}` replaced by the call's value.
    static func fill(_ source: String, values: CatalogValues) throws -> String {
        var output = ""
        var rest = Substring(source)
        while let open = rest.range(of: "{{") {
            output += rest[..<open.lowerBound]
            guard let close = rest[open.upperBound...].range(of: "}}") else {
                throw Failure.unknown(String(rest[open.lowerBound...].prefix(40)))
            }
            let token = String(rest[open.upperBound..<close.lowerBound])
            output += try value(token, values: values)
            rest = rest[close.upperBound...]
        }
        output += rest
        return output
    }

    private static func value(_ token: String, values: CatalogValues) throws -> String {
        if token == "swatches" {
            let names = (values.tuning["swatches"] ?? "").split(separator: " ")
            return names.map { "CatalogSwatch(\"\($0)\", .\($0))" }.joined(separator: ", ")
        }
        guard let colon = token.firstIndex(of: ":") else { throw Failure.unknown(token) }
        let kind = token[..<colon]
        let body = String(token[token.index(after: colon)...])
        switch kind {
        case "s":
            var parts = body.components(separatedBy: "|")
            let key = parts.removeFirst()
            guard let word = CatalogWords.word(key), let text = values.strings[key] else { throw Failure.unknown(token) }
            var fills: [String: String] = [:]
            for part in parts {
                guard let equals = part.firstIndex(of: "=") else { throw Failure.unknown(token) }
                fills[String(part[..<equals])] = String(part[part.index(after: equals)...])
            }
            guard Set(word.fills).isSubset(of: Set(fills.keys)) else { throw Failure.unfilled(token) }
            return literal(text, fills: fills)
        case "sym":
            guard let symbol = values.symbols[body] else { throw Failure.unknown(token) }
            return "\"\(symbol)\""
        case "m", "n":
            guard let value = values.tuning[body] else { throw Failure.unknown(token) }
            return value
        case "look":
            guard let value = values.look[body] else { throw Failure.unknown(token) }
            return value
        case "date":
            // `date` formatted as the call says: a card's by its style or quoted format, a row's by its style.
            switch body {
            case "card":
                guard let style = values.tuning["cardDate"], let time = values.tuning["cardTime"] else { throw Failure.unknown(token) }
                if style.hasPrefix("\"") { return "CatalogValue.formatted(date, \(style))" }
                return "CatalogValue.formatted(date, date: \(style), time: \(time))"
            case "row":
                guard let style = values.tuning["rowDate"] else { throw Failure.unknown(token) }
                return "CatalogValue.formatted(date, date: \(style), time: .omitted)"
            default:
                throw Failure.unknown(token)
            }
        default:
            throw Failure.unknown(token)
        }
    }

    /// `text` as a Swift string literal: quotes, backslashes and line breaks escaped, each `{fill}` it is given
    /// written as an interpolation of its Swift.
    static func literal(_ text: String, fills: [String: String] = [:]) -> String {
        var out = "\""
        var index = text.startIndex
        while index < text.endIndex {
            let character = text[index]
            if character == "{", let close = text[index...].firstIndex(of: "}") {
                let name = String(text[text.index(after: index)..<close])
                if let swift = fills[name] {
                    out += "\\(" + swift + ")"
                    index = text.index(after: close)
                    continue
                }
            }
            switch character {
            case "\\": out += "\\\\"
            case "\"": out += "\\\""
            case "\n": out += "\\n"
            case "\t": out += "\\t"
            case "\r": out += "\\r"
            default: out.append(character)
            }
            index = text.index(after: index)
        }
        return out + "\""
    }
}
