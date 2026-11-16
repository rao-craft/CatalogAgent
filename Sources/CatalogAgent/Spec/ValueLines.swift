//  WHAT: The lines that set a value by key, read: `look` (a role to the app's name for it), `strings` (a word),
//        `symbols` (an SF Symbol) and `tuning` (a timing, size, detent list, swatch list or date style), each
//        `key = value`; and `launch`, a destination to the state the views open in.
//
//            look:    accent = Color.accent              card = #FFFFFF / #FFFFFF 0.10
//            strings: catalog.title = "The World"        browse.credits = "{credits} cr"
//            symbols: mine.trailing = wallet.bifold
//            tuning:  press = .spring(duration: 0.2, bounce: 0.4)        detail = [.fraction(0.6)]
//            launch:  model = detail "Space"             looms = groupings
//
//  PIN:  A LINE THAT IS NOT UNDERSTOOD IS REFUSED WITH THE REASON, naming what the key takes or which keys there are,
//        so the model fixes the line it is told about instead of guessing again.

import Foundation

enum ValueLine {
    /// `key = value`, cut at the first `=` outside quotes and brackets that is not part of `==`.
    static func split(_ line: String, example: String) throws -> (key: String, value: String) {
        let text = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw CatalogError.line(line, "it is empty") }
        guard let equals = LineSplit.firstTop(text, "=") else {
            throw CatalogError.line(line, "a line is `key = value`, like `\(example)`, and this has no `=`")
        }
        let key = text[..<equals].trimmingCharacters(in: .whitespaces)
        let value = text[text.index(after: equals)...].trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else { throw CatalogError.line(line, "it names no key: `\(example)`") }
        guard !value.isEmpty, value != "=" else { throw CatalogError.line(line, "`\(key)` has `=` and no value") }
        return (key, value)
    }

    /// Whether `text` is one Swift expression on one line: brackets and quotes balanced, no `;`.
    static func isExpression(_ text: String) -> Bool {
        guard !text.isEmpty, !text.contains("\n"), !text.contains(";") else { return false }
        var depth: [Character] = [], quoted = false, escaped = false
        let pairs: [Character: Character] = [")": "(", "]": "[", "}": "{"]
        for character in text {
            if quoted {
                if escaped { escaped = false } else if character == "\\" { escaped = true } else if character == "\"" { quoted = false }
                continue
            }
            switch character {
            case "\"": quoted = true
            case "(", "[", "{": depth.append(character)
            case ")", "]", "}":
                guard depth.popLast() == pairs[character] else { return false }
            default: break
            }
        }
        return depth.isEmpty && !quoted
    }

    /// A quoted literal read as its text (`\"`, `\\`, `\n` and `\t` understood); a value that does not start with a
    /// quote as written; nil for a quote left open.
    static func unquoted(_ value: String) -> String? {
        guard value.hasPrefix("\"") else { return value }
        guard value.count >= 2, value.hasSuffix("\"") else { return nil }
        var text = "", escaped = false
        for character in value.dropFirst().dropLast() {
            if escaped {
                switch character {
                case "n": text.append("\n")
                case "t": text.append("\t")
                default: text.append(character)
                }
                escaped = false
            } else if character == "\\" {
                escaped = true
            } else if character == "\"" {
                return nil
            } else {
                text.append(character)
            }
        }
        return escaped ? nil : text
    }

    /// A number as Swift writes it: `0.97`, `28`, `-1.5`.
    static func isNumber(_ text: String) -> Bool {
        text.range(of: #"^-?\d+(\.\d+)?$"#, options: .regularExpression) != nil
    }
}

enum LookLine {
    static let example = "accent = Color.accent"

    /// The role and the Swift its value is: the app's name for it, a hex colour, a design or a number.
    static func parse(_ line: String) throws -> (key: String, swift: String) {
        let (key, value) = try ValueLine.split(line, example: example)
        guard let role = CatalogLookRole.role(key) else {
            throw CatalogError.line(line, "`\(key)` is not a look role; look maps " + CatalogLookRole.all.map(\.key).joined(separator: ", "))
        }
        switch role.kind {
        case .color:
            if value.hasPrefix("#") || value.lowercased().hasPrefix("clear") {
                guard let swift = hexColor(value) else {
                    throw CatalogError.line(line, "`\(value)` is not a colour: write `#RRGGBB`, an opacity after it (`#FFFFFF 0.10`), and a dark one after a slash (`#FFFFFF / #1A1A1A`), or the app's name for it (`Color.accent`)")
                }
                return (role.key, swift)
            }
        case .design:
            let word = value.hasPrefix(".") ? String(value.dropFirst()) : value
            if ["default", "serif", "rounded", "monospaced"].contains(word) { return (role.key, "." + word) }
        case .spacing:
            if ValueLine.isNumber(value) { return (role.key, value) }
        case .font:
            break
        }
        // Inside `CatalogLook`, a bare role name is the role itself, and its getter would call itself forever.
        let own = CatalogLookRole.all.map(\.key) + ["font", "dynamic", "system"]
        if own.contains(value) || own.contains(where: { value == "self." + $0 || value == "CatalogLook." + $0 || value == "Self." + $0 }) {
            throw CatalogError.line(line, "`\(value)` names the look's own role: name the app's \(role.kind.rawValue), like `\(example(role))`")
        }
        guard ValueLine.isExpression(value) else {
            throw CatalogError.line(line, "`\(value)` is not one Swift expression: name the app's \(role.kind.rawValue), like `\(example(role))`")
        }
        return (role.key, value)
    }

    private static func example(_ role: CatalogLookRole) -> String {
        switch role.kind {
        case .color: return "Color.accent"
        case .font: return "Font.brandTitle"
        case .design: return "serif"
        case .spacing: return "CGFloat.layer4"
        }
    }

    /// `#RRGGBB [opacity] [/ #RRGGBB [opacity]]`, `clear` for either side: one colour for light and dark, or two.
    static func hexColor(_ value: String) -> String? {
        let sides = value.split(separator: "/", omittingEmptySubsequences: false).map { $0.trimmingCharacters(in: .whitespaces) }
        guard sides.count == 1 || sides.count == 2 else { return nil }
        var parsed: [(hex: String, opacity: String)] = []
        for side in sides {
            let words = side.split(separator: " ").map(String.init)
            guard let first = words.first, words.count <= 2 else { return nil }
            var hex: String
            var opacity = "1"
            if first.lowercased() == "clear" {
                guard words.count == 1 else { return nil }
                hex = "0x000000"; opacity = "0"
            } else {
                guard first.range(of: #"^#[0-9A-Fa-f]{6}$"#, options: .regularExpression) != nil else { return nil }
                hex = "0x" + first.dropFirst().uppercased()
            }
            if words.count == 2 {
                var amount = words[1]
                if amount.hasSuffix("%") {
                    guard let percent = Double(amount.dropLast()), (0...100).contains(percent) else { return nil }
                    amount = Self.number(percent / 100)
                }
                guard ValueLine.isNumber(amount), let number = Double(amount), (0...1).contains(number) else { return nil }
                opacity = amount
            }
            parsed.append((hex, opacity))
        }
        let light = parsed[0], dark = parsed.count == 2 ? parsed[1] : parsed[0]
        return "CatalogLook.dynamic(light: \(light.hex), lightOpacity: \(light.opacity), dark: \(dark.hex), darkOpacity: \(dark.opacity))"
    }

    private static func number(_ value: Double) -> String {
        let text = String(format: "%.4f", value)
        var trimmed = text
        while trimmed.hasSuffix("0") { trimmed.removeLast() }
        if trimmed.hasSuffix(".") { trimmed.removeLast() }
        return trimmed
    }
}

enum StringLine {
    static let example = "catalog.title = \"The World\""

    /// The key and its text, as the call wrote it: placeholders checked, nothing escaped yet.
    static func parse(_ line: String) throws -> (key: String, value: String) {
        let (key, raw) = try ValueLine.split(line, example: example)
        guard let word = CatalogWords.word(key) else {
            throw CatalogError.line(line, "`\(key)` is not a string key; the keys are " + CatalogWords.all.map(\.key).joined(separator: ", "))
        }
        guard let value = ValueLine.unquoted(raw) else {
            throw CatalogError.line(line, "`\(raw)` is not one quoted string: write `\(key) = \"…\"`, with `\\\"` for a quote inside")
        }
        if CatalogWords.nouns.contains(key) {
            guard !value.contains("{"), !value.contains("}"), !value.trimmingCharacters(in: .whitespaces).isEmpty else {
                throw CatalogError.line(line, "`\(key)` is a noun the other strings are made of: plain words, no braces, like `\(key) = \"\(word.fallback == "collection" ? "model" : word.fallback)\"`")
            }
            return (key, value)
        }
        let allowed = CatalogWords.nouns + CatalogWords.capitalNouns + word.fills
        for name in CatalogWords.placeholders(in: value) where !allowed.contains(name) {
            let fills = word.fills.isEmpty ? "" : word.fills.map { "{\($0)}" }.joined(separator: ", ") + " and "
            throw CatalogError.line(line, "`{\(name)}` is not something `\(key)` fills in: it takes \(fills)the nouns {collection}, {collections}, {grouping}, {groupings} (capitalised: {Collection} …)")
        }
        return (key, value)
    }
}

enum SymbolLine {
    static let example = "mine.trailing = wallet.bifold"

    static func parse(_ line: String) throws -> (key: String, value: String) {
        let (key, raw) = try ValueLine.split(line, example: example)
        guard CatalogSymbol.symbol(key) != nil else {
            throw CatalogError.line(line, "`\(key)` is not a symbol key; the keys are " + CatalogSymbol.all.map(\.key).joined(separator: ", "))
        }
        let value = (ValueLine.unquoted(raw) ?? raw).trimmingCharacters(in: .whitespaces)
        guard value.range(of: #"^[a-z0-9]+(\.[a-z0-9]+)*$"#, options: .regularExpression) != nil else {
            throw CatalogError.line(line, "`\(raw)` is not an SF Symbol name: lower-case words joined by dots, like `wallet.bifold`")
        }
        return (key, value)
    }
}

enum TuningLine {
    static let example = "press = .spring(duration: 0.2, bounce: 0.4)"

    /// The key and its value as the templates write it.
    static func parse(_ line: String) throws -> (key: String, swift: String) {
        let (key, value) = try ValueLine.split(line, example: example)
        guard let tuning = CatalogTuning.tuning(key) else {
            throw CatalogError.line(line, "`\(key)` is not a tuning key; the keys are " + CatalogTuning.all.map(\.key).joined(separator: ", "))
        }
        switch tuning.kind {
        case .animation:
            guard let swift = animation(value) else {
                throw CatalogError.line(line, "`\(value)` is not an animation: write it as SwiftUI does, like `.spring(duration: 0.2, bounce: 0.4)`, `.easeInOut(duration: 1.9).repeatForever(autoreverses: true)` or `.snappy`")
            }
            return (key, swift)
        case .number:
            guard ValueLine.isNumber(value), let number = Double(value), number >= 0 else {
                throw CatalogError.line(line, "`\(value)` is not a number for `\(key)`: write it as Swift does, like `\(tuning.fallback)`")
            }
            return (key, value)
        case .whole:
            guard let number = Int(value), number >= 0, number <= 12 || key == "publicLimit" || key == "topRanks" else {
                throw CatalogError.line(line, "`\(value)` is not a whole number for `\(key)`, like `\(tuning.fallback)`")
            }
            if key == "swatchColumns", number == 0 { throw CatalogError.line(line, "`swatchColumns` needs at least 1") }
            return (key, String(number))
        case .detents:
            guard let swift = detents(value) else {
                throw CatalogError.line(line, "`\(value)` is not a list of detents: write `.medium`, `.large`, `.fraction(0.6)` or `.height(320)`, several between brackets, like `[.fraction(0.78), .large]`")
            }
            return (key, swift)
        case .swatches:
            let names = value.replacingOccurrences(of: ",", with: " ").replacingOccurrences(of: "[", with: " ").replacingOccurrences(of: "]", with: " ")
                .split(separator: " ").map { $0.hasPrefix(".") ? String($0.dropFirst()) : String($0) }
            let unknown = names.filter { !CatalogTuning.systemColors.contains($0) }
            guard !names.isEmpty, unknown.isEmpty else {
                throw CatalogError.line(line, "`\(unknown.first ?? value)` is not a system colour: swatches are among " + CatalogTuning.systemColors.joined(separator: ", "))
            }
            guard Set(names).count == names.count else { throw CatalogError.line(line, "a swatch is named twice") }
            return (key, names.joined(separator: " "))
        case .dateStyle, .timeStyle:
            // A card's date may instead be a date format, quoted: `"MMMM d, yyyy · h:mm:ss a"`.
            if key == "cardDate", value.hasPrefix("\"") {
                guard let format = ValueLine.unquoted(value), !format.isEmpty, !format.contains("\\"), !format.contains("\"") else {
                    throw CatalogError.line(line, "`\(value)` is not a date format: quote it, like `\"MMMM d, yyyy · h:mm:ss a\"`")
                }
                return (key, TemplateFill.literal(format))
            }
            let word = value.hasPrefix(".") ? String(value.dropFirst()) : value
            let styles = tuning.kind == .dateStyle ? CatalogTuning.dateStyles : CatalogTuning.timeStyles
            guard styles.contains(word) else {
                throw CatalogError.line(line, "`\(value)` is not a \(tuning.kind == .dateStyle ? "date" : "time") style: write " + styles.map { "." + $0 }.joined(separator: ", "))
            }
            return (key, "." + word)
        }
    }

    /// An animation as SwiftUI writes it, with its leading dot: `.spring(duration: 0.2, bounce: 0.4).delay(0.1)`.
    static func animation(_ value: String) -> String? {
        var text = value.trimmingCharacters(in: .whitespaces)
        if text.hasPrefix("Animation.") { text = String(text.dropFirst("Animation".count)) }
        if !text.hasPrefix(".") { text = "." + text }
        let call = #"\.[A-Za-z]+(\([A-Za-z0-9_.:, \-]*\))?"#
        guard text.range(of: "^(" + call + ")+$", options: .regularExpression) != nil else { return nil }
        return text
    }

    /// Detents as SwiftUI writes them, in brackets: `[.fraction(0.78), .large]`.
    static func detents(_ value: String) -> String? {
        var text = value.trimmingCharacters(in: .whitespaces)
        if text.hasPrefix("["), text.hasSuffix("]") { text = String(text.dropFirst().dropLast()) }
        let items = LineSplit.top(text, on: ",").flatMap { LineSplit.top($0, on: " ") }
        guard !items.isEmpty else { return nil }
        var out: [String] = []
        for raw in items {
            let item = raw.hasPrefix(".") ? String(raw.dropFirst()) : raw
            if item == "medium" || item == "large" { out.append("." + item); continue }
            guard let open = item.firstIndex(of: "("), item.hasSuffix(")") else { return nil }
            let name = String(item[..<open])
            let number = String(item[item.index(after: open)..<item.index(before: item.endIndex)]).trimmingCharacters(in: .whitespaces)
            guard ValueLine.isNumber(number), let amount = Double(number), amount > 0 else { return nil }
            switch name {
            case "fraction": guard amount <= 1 else { return nil }
            case "height": break
            default: return nil
            }
            out.append(".\(name)(\(number))")
        }
        guard Set(out).count == out.count else { return nil }
        return "[" + out.joined(separator: ", ") + "]"
    }
}

/// A destination and the state the views open in for it.
struct LaunchState: Sendable, Equatable {
    enum State: Sendable, Equatable {
        case mine, browse, groupings
        case detail(String), edit(String)

        /// The `CatalogLaunch` case, as Swift.
        var swift: String {
            switch self {
            case .mine: return ".mine"
            case .browse: return ".browse"
            case .groupings: return ".groupings"
            case .detail(let name): return ".detail(\(TemplateFill.literal(name)))"
            case .edit(let name): return ".edit(\(TemplateFill.literal(name)))"
            }
        }
    }

    let destination: String
    let state: State
}

enum LaunchLine {
    static let example = "model = detail \"Space\""
    static let states = "mine, detail \"<name>\", edit \"<name>\", browse or groupings"

    static func parse(_ line: String) throws -> LaunchState {
        let (destination, value) = try ValueLine.split(line, example: example)
        guard destination.range(of: #"^[A-Za-z0-9_][A-Za-z0-9_.\-]*$"#, options: .regularExpression) != nil else {
            throw CatalogError.line(line, "`\(destination)` is not a destination name: letters, digits, dots and dashes, like `model.edit`")
        }
        var word = value, argument: String?
        if let space = value.firstIndex(where: { $0 == " " || $0 == "(" }) {
            word = String(value[..<space])
            var rest = value[space...].trimmingCharacters(in: .whitespaces)
            if rest.hasPrefix("("), rest.hasSuffix(")") { rest = String(rest.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces) }
            guard let name = ValueLine.unquoted(rest), !name.trimmingCharacters(in: .whitespaces).isEmpty else {
                throw CatalogError.line(line, "`\(rest)` is not a name: write it in quotes, like `detail \"Space\"`")
            }
            argument = name
        }
        let state: LaunchState.State
        switch (word, argument) {
        case ("mine", nil): state = .mine
        case ("browse", nil): state = .browse
        case ("groupings", nil): state = .groupings
        case ("detail", let name?): state = .detail(name)
        case ("edit", let name?): state = .edit(name)
        case ("detail", nil), ("edit", nil):
            throw CatalogError.line(line, "`\(word)` opens one collection: name it, like `\(word) \"Space\"`")
        case (_, .some) where ["mine", "browse", "groupings"].contains(word):
            throw CatalogError.line(line, "`\(word)` takes no name")
        default:
            throw CatalogError.line(line, "`\(word)` is not a state; a destination opens in \(states)")
        }
        return LaunchState(destination: destination, state: state)
    }
}
