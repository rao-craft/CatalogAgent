//  WHAT: A catalog of collections as a Granite agent package: my collections as cards, a collection's detail sheet
//        and its edit form (tags as chips, a colour from system swatches), other people's collections ranked and
//        searchable, and named groupings of them. A call names the app's types with one mapping line a role
//        (`collection: Album name=title count=tracks`), the words, symbols, timings and look it wants, and the
//        destinations it launches into; the run writes plain SwiftUI views into the folder the call names, the
//        protocols they read, the conformances that make the app's types those protocols, and answers where.
//  IN:   Input: the folder, the mapping lines, the screens, the look, strings, symbols and tuning lines, the launch
//        lines, a prefix for view names, the modules a mapped type lives in.
//  OUT:  CatalogResult: the files written, the views, the conformances, each root view's initializer, and what the
//        app still has to do.
//  PIN:  NO MODEL. Every file is made from the call, the same way every time; a line that is not understood is
//        refused with its reason, and nothing is written until every problem is fixed and every file parses.
//  PIN:  THE VIEWS NEVER ROUTE. They take values and closures and hold no global state, so the app's services,
//        navigation and modals stay the app's; a control whose closure is nil is not drawn. A view presents only
//        its own flow's sheets: a collection's detail and edit form, the colour picker, the add and grouping forms.

import Foundation
import GraniteAgents

public struct CatalogAgent: GraniteAgentPackage {
    public struct Input: Codable, Sendable {
        /// The folder the views go in, relative to the project; `Components/Catalog` when left out.
        public var into: String?
        /// One line a role: `collection: ModelGroup name=name summary=summary count=documents earnings=earnings`.
        public var mappings: [String]?
        /// The screens to write; every one when left out.
        public var screens: [CatalogScreen]?
        /// `role = value`: the app's colours, type and spacing (`accent = Color.accent`, `card = #FFFFFF / #FFFFFF 0.10`).
        public var look: [String]?
        /// `key = "words"`: any word the views show (`catalog.title = "The World"`), the nouns first.
        public var strings: [String]?
        /// `key = symbol`: any SF Symbol the views draw (`mine.trailing = wallet.bifold`).
        public var symbols: [String]?
        /// `key = value`: timings, sizes, detents, swatches, date styles (`detail = [.fraction(0.6)]`).
        public var tuning: [String]?
        /// `destination = state`: the state the views open in for a `-destination` launch (`model = detail "Space"`).
        public var launch: [String]?
        /// A prefix for the view types, when the app already has names that clash: `Kit` writes `KitCatalogView`.
        public var prefix: String?
        /// Modules the conformances import: where a mapped type lives.
        public var imports: [String]?
        /// The host's folder.
        public var directory: String?

        public init(into: String? = nil, mappings: [String]? = nil, screens: [CatalogScreen]? = nil, look: [String]? = nil,
                    strings: [String]? = nil, symbols: [String]? = nil, tuning: [String]? = nil, launch: [String]? = nil,
                    prefix: String? = nil, imports: [String]? = nil, directory: String? = nil) {
            self.into = into; self.mappings = mappings; self.screens = screens; self.look = look; self.strings = strings
            self.symbols = symbols; self.tuning = tuning; self.launch = launch; self.prefix = prefix; self.imports = imports
            self.directory = directory
        }
    }

    public typealias Event = CatalogFrame
    public typealias Output = CatalogResult
    public typealias Compute = Void

    public static let word = "catalog"
    /// What it makes: reusable views a page shows, and the conformances that make the app's types theirs.
    public static let makes = [
        AgentMake(kind: "view", what: "a catalog of collections as reusable SwiftUI views: my collections as cards with a detail sheet and an edit form (CollectionsView), others' collections ranked and searchable with named groupings of them (CatalogView); a page shows them with CollectionsView(…) and CatalogView(…)",
                  into: ["Components/Catalog/*"], never: "routes; never a page, a service, a client or a model type"),
        AgentMake(kind: "conformance", what: "the app's own types made the views' types: one extension a mapping line",
                  into: ["Components/Catalog/Conformances/*"], never: "a change to the app's types themselves"),
    ]
    public static let summary = "writes a catalog of collections as plain SwiftUI: my collections as cards with a detail sheet and an edit form (tags, colour), others' collections ranked and searchable, and named groupings of them, made to show the app's own types from one mapping line a type."
    public static let fields = [
        "into": "the folder for the views, relative to the project; Components/Catalog when left out",
        "mappings": "one line a role (collection, document, listing, grouping): `collection: ModelGroup name=name summary=summary count=documents earnings=earnings tags=tags online=online color=color`; a bare path is read off the value, anything else is Swift that may name `value`",
        "screens": "the screens to write, every one when left out: mine (the cards, detail and edit form), browse (others' ranked and searchable), groupings (named sets of collections)",
        "look": "one line a look role, `role = value`: a colour (accent, background, ink, card, panel, cardShadow, fieldShadow, badgeShadow, positive, inactive) as the app's name or `#RRGGBB [opacity] [/ #RRGGBB [opacity]]`, a font (title, body, body2, note, note2), design (serif, rounded, monospaced, default), a spacing (layer1 … layer7); a role left out takes the system's",
        "strings": "one line a word, `key = \"words\"`: the nouns collection, collections, grouping, groupings first (every default is made of them), then any key such as catalog.title, browse.credits = \"{credits} cr\" or detail.title = \"{name} {Collection}\"",
        "symbols": "one line an SF Symbol, `key = name`: mine.leading, mine.trailing, mine.empty, groupings.empty and the rest",
        "tuning": "one line a timing, size or style, `key = value`: press, earnings, pulse, tags (animations as SwiftUI writes them), pressScale, pulseScale, earningsRise, cardRadius, fieldRadius, gradientStart, gradientStop, colorRadius, swatchSize (numbers), swatchColumns, decimals, topRanks, publicLimit (whole numbers), detail, edit, color, add, form (detents like [.fraction(0.6)]), swatches (system colour names), cardDate (a date style or a quoted format), cardTime, rowDate (styles)",
        "launch": "one line a destination, `destination = state`: mine, detail \"<name>\", edit \"<name>\", browse or groupings; the views open in that state, their own sheets presented, when the app is launched with -destination <name>",
        "prefix": "a prefix for the view types when the app already has views of these names: `Kit` writes KitCatalogView",
        "imports": "modules the conformances import, such as the package a mapped type is declared in",
    ]
    public static let guide = """
        Tag catalog for a catalog of collections: my collections as cards (name, summary, a count, earnings, tags, an \
        online dot, a date; a pressed card scales, a long press offers edit, online or offline, delete), a \
        collection's detail sheet listing its documents ("Updated: …", swipe to delete), its edit form (name, \
        description, tags as chips through an alert, a colour from system swatches), other people's collections \
        ranked and searchable with credits and "Add to <grouping>", and named groupings of collections with an \
        active-grouping banner, a new and an edit form and an empty state. It writes plain SwiftUI (iOS 17 and macOS \
        14) into `into` (Components/Catalog). `mappings` make the app's types conform, one line a role: \
        `role: Type word=value …`. Roles and their words: collection (name, summary, count, earnings, tags, online, \
        color, updated); document (title, updated, collection: the collection's id or name); listing (name, owner, \
        summary, tags, credits, count, rank); grouping (name, members: ids or names). A bare path is read off the \
        value (`owner=owner.name`); anything else is Swift that may name `value`. Say `id=` only when the type has \
        no `id` of its own; a type from a package needs `imports`. A role no line maps uses the kit's own value type \
        (CatalogCollection, CatalogDocument, CatalogListing, CatalogGrouping). Words, symbols, timings and the look \
        are lines too: `strings` (`collection = "model"` renames every default at once; `catalog.title = "The \
        World"`), `symbols` (`mine.trailing = wallet.bifold`), `tuning` (`press = .spring(duration: 0.2, bounce: \
        0.4)`, `detail = [.fraction(0.6)]`), `look` (`accent = Color.accent`, `title = Font.brandTitle`, `card = \
        #FFFFFF / #FFFFFF 0.10`), and `launch` (`model = detail "Space"`: the views open there, sheets presented, \
        when the app is launched with -destination model). The views never route: they take values and closures, \
        and a control whose closure is nil is not drawn. Use them as `CollectionsView(collections: albums, \
        documents: tracks, save: { try await library.update(id: $0.id, name: $0.name) })` and \
        `CatalogView(listings: charts, mine: albums, groupings: crates, active: crate, select: { … })`; the answer \
        gives each initializer with the app's types. Every view has a #Preview. \
        Examples. A music app's albums, the charts and crates of albums: \
        {"mappings": ["collection: Album name=title summary=notes count=trackCount tags=genres color=tint", \
        "document: Track title=title updated=addedAt collection=albumID", "listing: ChartEntry name=title \
        owner=artist count=tracks rank=position", "grouping: Crate name=name members=albumIDs"], "strings": \
        ["collection = \\"album\\"", "collections = \\"albums\\"", "grouping = \\"crate\\"", "groupings = \\"crates\\""]}. \
        Only my collections, beside the app's own views of these names: {"mappings": ["collection: Folder \
        name=name count=files.count"], "screens": ["mine"], "prefix": "Kit"}. \
        A line it cannot read is refused with the reason and nothing is written: fix the line and call again. Not for \
        the app's services, its network client or its model types.
        """

    public static func output(from events: [CatalogFrame]) -> CatalogResult? { events.compactMap(\.result).last }

    public init() {}

    public func run(_ input: Input, context: Context) -> AsyncThrowingStream<CatalogFrame, Error> {
        // The folder is the call's, else the host's (a host over the wire may give it only there), else the
        // process's: never the runner's working folder while the host named one.
        var resolved = input
        if resolved.directory == nil { resolved.directory = context.host.directory }
        let call = resolved
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let result = try Self.write(call, note: context.host.note) { continuation.yield($0) }
                    continuation.yield(.written(result))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// The folder a call writes into when it names none.
    static let defaultFolder = "Components/Catalog"

    /// Every line of a call read, its problems gathered: what `write` makes the files from.
    struct Read: Sendable {
        var mappings: [Mapping] = []
        var strings: [String: String] = [:]
        var symbols: [String: String] = [:]
        var tuning: [String: String] = [:]
        var look: [String: String] = [:]
        var launches: [LaunchState] = []
        var problems: [String] = []
    }

    /// The call's lines read, each refusal named by its field.
    static func read(_ input: Input) -> Read {
        var read = Read()
        func lines(_ field: String, _ values: [String]?, _ each: (String) throws -> Void) {
            for line in values ?? [] where !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                do { try each(line) } catch { read.problems.append("\(field) \(error)") }
            }
        }
        lines("mappings", input.mappings) { read.mappings.append(try MappingLine.parse($0)) }
        var roles: Set<CatalogRole> = []
        for mapping in read.mappings where !roles.insert(mapping.role).inserted {
            read.problems.append("mappings: \(mapping.role.rawValue) is mapped twice: one type a role")
        }
        func once(_ field: String, _ key: String, _ line: String, _ seen: inout Set<String>) throws {
            guard seen.insert(key).inserted else { throw CatalogError.line(line, "`\(key)` is set twice") }
        }
        var seen: [String: Set<String>] = [:]
        lines("look", input.look) { line in
            let (key, swift) = try LookLine.parse(line)
            try once("look", key, line, &seen["look", default: []])
            read.look[key] = swift
        }
        lines("strings", input.strings) { line in
            let (key, value) = try StringLine.parse(line)
            try once("strings", key, line, &seen["strings", default: []])
            read.strings[key] = value
        }
        lines("symbols", input.symbols) { line in
            let (key, value) = try SymbolLine.parse(line)
            try once("symbols", key, line, &seen["symbols", default: []])
            read.symbols[key] = value
        }
        lines("tuning", input.tuning) { line in
            let (key, swift) = try TuningLine.parse(line)
            try once("tuning", key, line, &seen["tuning", default: []])
            read.tuning[key] = swift
        }
        lines("launch", input.launch) { line in
            let launch = try LaunchLine.parse(line)
            try once("launch", launch.destination, line, &seen["launch", default: []])
            read.launches.append(launch)
        }
        return read
    }

    /// The whole call: the lines read, the kit planned and made, staged, checked and written.
    static func write(_ input: Input, note: @Sendable (String) -> Void, yield: (CatalogFrame) -> Void) throws -> CatalogResult {
        var read = Self.read(input)
        var problems = read.problems
        var imports = (input.imports ?? []).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let files = AgentFiles(directory: input.directory)
        let folderPath = (input.into ?? "").trimmingCharacters(in: .whitespaces).isEmpty ? defaultFolder : input.into!
        let folder = files.resolve(folderPath)
        // Each path checked against the app's own types, in their spelling; a type a local package declares imported.
        // The kit's own folder is not the app's: its samples declare its own value types.
        let app = AppTypes(root: files.root, excluding: folder)
        // The module the kit's own folder compiles into: a type declared there is imported by none of its files.
        let ownModule = AppTypes.module(of: folder.appendingPathComponent("CatalogProtocols.swift"))
        var typeNotes: [String] = []
        var nothing: [String] = []
        read.mappings = read.mappings.map { mapping in
            let kept = mapping.assignments.filter { assignment in
                guard case .expression(let text) = assignment.source, assignment.property.kind.isNothing(text) else { return true }
                nothing.append("\(assignment.property.key)=\(text.trimmingCharacters(in: .whitespaces))")
                return false
            }
            return Mapping(line: mapping.line, role: mapping.role, type: mapping.type, id: mapping.id, assignments: kept)
        }
        if !nothing.isEmpty {
            typeNotes.append("Left out \(nothing.prefix(6).joined(separator: ", "))\(nothing.count > 6 ? " and \(nothing.count - 6) more" : ""): "
                + "a property a line leaves out shows its default, so a line needs only what the type has.")
        }
        read.mappings = read.mappings.map { mapping in
            guard let declared = app.types[AppTypes.named(mapping.type)] else { return mapping }
            if let module = declared.module, module != ownModule, !imports.contains(module), !mapping.type.hasPrefix(module + ".") {
                imports.append(module)
                typeNotes.append("`\(mapping.type)` is declared in \(module), so the conformances import it.")
            }
            func checked(_ source: Mapping.Source, _ word: String, kind: CatalogKind?) -> Mapping.Source {
                if case .expression(let text) = source {
                    var out = text
                    for path in Set(text.matchesOf(#"(?<![\w.$])([a-z_]\w*(?:\.[A-Za-z_]\w*)+)"#)) where declared.field(String(path.split(separator: ".")[0])) != nil {
                        let (fixed, problem) = app.check(path, from: mapping.type)
                        if problem == nil, fixed != path {
                            out = out.replacingOccurrences(of: #"(?<![\w.$])"# + NSRegularExpression.escapedPattern(for: path) + #"(?![\w])"#, with: fixed, options: .regularExpression)
                        }
                    }
                    return .expression(out)
                }
                guard case .path(let path) = source else { return source }
                let (fixed, problem) = app.check(path, from: mapping.type)
                if let problem { problems.append("mappings: \(mapping.role.rawValue) \(word)=\(path): \(problem)"); return source }
                // A field of a type the conversion has no overload for: refused, with what it takes, before the build
                // finds it. A type this reader does not know is taken as written (READ, NOT COMPILED).
                if let kind, let written = app.type(of: fixed, from: mapping.type) {
                    let base = written.hasSuffix("?") || written.hasSuffix("!") ? String(written.dropLast()) : written
                    let known = CatalogKind.integers.union(["String", "Substring", "URL", "Double", "Float", "Bool", "Date", "UUID", "Decimal", "Color",
                                                           "[String]", "[Substring]", "[Int]", "[UUID]", "Set<String>"])
                    let declaredHere = app.types[AppTypes.named(base)] != nil && !base.hasPrefix("[")
                    if !kind.takes.contains(base), !kind.takes.contains(written), declaredHere || known.contains(base) {
                        problems.append("mappings: \(mapping.role.rawValue) \(word)=\(path): `\(fixed)` is `\(written)`, and `\(word)` shows \(kind.takesInWords): "
                            + "map a field of one of those, or leave `\(word)` out")
                        return source
                    }
                }
                if fixed != path { typeNotes.append("\(mapping.role.rawValue) \(word): `\(path)` is `\(fixed)` on \(declared.name).") }
                return .path(fixed)
            }
            return Mapping(line: mapping.line, role: mapping.role, type: mapping.type, id: mapping.id.map { checked($0, "id", kind: nil) },
                           assignments: mapping.assignments.map { Mapping.Assignment(property: $0.property, source: checked($0.source, $0.property.key, kind: $0.property.kind)) })
        }
        let conformanceFiles = ConformanceEmitter.emit(read.mappings, imports: imports)
        problems += conformanceFiles.problems
        let conformances = folder.appendingPathComponent("Conformances", isDirectory: true)
        let prefix = (input.prefix ?? "").trimmingCharacters(in: .whitespaces)
        if !prefix.isEmpty, !SwiftName.isTypeName(prefix) {
            problems.append("prefix: `\(prefix)` is not a prefix for type names: UpperCamelCase letters and digits, like `Kit`")
        }
        for module in imports where !SwiftName.isModuleName(module) {
            problems.append("imports: `\(module)` is not a module name")
        }
        guard problems.isEmpty else { throw CatalogError.problems(problems) }

        var screens: [CatalogScreen] = []
        for screen in input.screens ?? CatalogScreen.allCases where !screens.contains(screen) { screens.append(screen) }
        let parts = KitCatalog.plan(Set(screens))
        let flags = KitCatalog.flags(Set(screens))
        let views = parts.flatMap(\.views)
        yield(.read(mappings: read.mappings.count, views: views.count))
        note("writing \(views.count) views for \(screens.count) screen\(screens.count == 1 ? "" : "s") into \(files.relative(folder))")

        let values = CatalogValues(strings: read.strings, symbols: read.symbols, tuning: read.tuning, look: read.look)
        var planned: [(url: URL, text: String)] = []
        func prefixed(_ text: String) -> String { TemplateRender.prefixing(text, names: views, prefix: prefix) }
        planned.append((folder.appendingPathComponent("CatalogProtocols.swift"), ProtocolsEmitter.emit()))
        planned.append((folder.appendingPathComponent("CatalogLook.swift"), LookEmitter.emit(values, mapped: Set(read.look.keys))))
        planned.append((folder.appendingPathComponent("CatalogLaunch.swift"), LaunchEmitter.emit(read.launches)))
        for part in parts {
            let filled = try TemplateFill.fill(part.template, values: values)
            let text = try TemplateRender.render(filled, flags: flags)
            let file = (part.isView ? prefix : "") + part.name + ".swift"
            planned.append((folder.appendingPathComponent(file), prefixed(text)))
        }
        for file in conformanceFiles.files {
            planned.append((conformances.appendingPathComponent(file.name), file.text))
        }

        var types: [CatalogRole: String] = [:]
        for mapping in read.mappings { types[mapping.role] = mapping.type }
        var notes: [String] = typeNotes
        let unmapped = CatalogRole.allCases.filter { types[$0] == nil && wanted($0, by: Set(screens)) }
        if !unmapped.isEmpty {
            notes.append("No line maps \(unmapped.map(\.rawValue).joined(separator: ", ")): the views take the kit's own \(unmapped.map(\.valueType).joined(separator: ", ")) there.")
        }
        if screens.contains(.mine) {
            notes.append("The edit form hands `save` a CatalogCollectionDraft (id, name, summary, tags, color as the name it was given or a swatch's name, online); the menu's online switch saves the same draft with `online` flipped.")
        }
        if screens.contains(.groupings) {
            notes.append("The grouping forms hand `save` a CatalogGroupingDraft (id, nil for a new one; name; members, each member's id; names, each member's name); `select` is handed a grouping's key, or nil to deselect.")
        }
        if read.launches.isEmpty {
            notes.append("No launch line: the views open as they are; a line like `model = detail \"Space\"` opens a state for a -destination launch.")
        }

        let existed = Set(planned.map(\.url.path).filter { FileManager.default.fileExists(atPath: $0) })
        let written = try files.write(planned)
        note("wrote \(written.count) files")
        func state(_ path: String) -> AgentMade.State { existed.contains(path) ? .rewritten : .written }
        func file(_ name: String) -> String? { written.first { ($0 as NSString).lastPathComponent == name } }
        let asked = screens.flatMap { KitCatalog.views(of: $0) }.filter { views.contains($0) }.map { prefix + $0 }
        var expected = asked.reduce(into: [String]()) { if !$0.contains($1) { $0.append($1) } }.map { AgentExpected(kind: "view", name: $0) }
        expected += read.mappings.map { AgentExpected(kind: "conformance", name: $0.type) }
        var made: [AgentMade] = views.map { prefix + $0 }.compactMap { view in
            file(view + ".swift").map { AgentMade(kind: "view", name: view, path: $0, state: state($0)) }
        }
        made += read.mappings.compactMap { mapping in
            file("\(mapping.fileStem)+\(mapping.role.name).swift").map { AgentMade(kind: "conformance", name: mapping.type, path: $0, state: state($0)) }
        }
        return CatalogResult(path: written.first, paths: written, views: views.map { prefix + $0 },
                             conformances: read.mappings.map { "\($0.type): \($0.role.rawValue)" },
                             initializers: initializers(screens: screens, types: types, prefix: prefix), notes: notes,
                             made: made, expected: expected)
    }

    /// Whether the screens asked for show a role at all.
    static func wanted(_ role: CatalogRole, by screens: Set<CatalogScreen>) -> Bool {
        switch role {
        case .collection: return true
        case .document: return screens.contains(.mine)
        case .listing: return screens.contains(.browse) || screens.contains(.groupings)
        case .grouping: return screens.contains(.groupings)
        }
    }

    /// Each root view's initializer as a page calls it, with the app's types where a line maps them.
    static func initializers(screens: [CatalogScreen], types: [CatalogRole: String], prefix: String) -> [String] {
        func type(_ role: CatalogRole) -> String { types[role] ?? role.valueType }
        var lines: [String] = []
        if screens.contains(.mine) {
            lines.append("\(prefix)CollectionsView(collections: [\(type(.collection))], documents: [\(type(.document))], "
                + "leading: (@MainActor () -> Void)? = nil, trailing: (@MainActor () -> Void)? = nil, "
                + "refresh: (@MainActor () async throws -> Void)? = nil, "
                + "save: (@MainActor (CatalogCollectionDraft) async throws -> Void)? = nil, "
                + "delete: (@MainActor (String) async throws -> Void)? = nil, "
                + "deleteDocument: (@MainActor (String) async throws -> Void)? = nil, "
                + "page: (@MainActor (\(type(.document))) -> AnyView)? = nil)")
        }
        if screens.contains(.browse) || screens.contains(.groupings) {
            lines.append("\(prefix)CatalogView(listings: [\(type(.listing))], mine: [\(type(.collection))], groupings: [\(type(.grouping))], "
                + "active: String? = nil, select: (@MainActor (String?) async throws -> Void)? = nil, "
                + "save: (@MainActor (CatalogGroupingDraft) async throws -> Void)? = nil, "
                + "delete: (@MainActor (String) async throws -> Void)? = nil, refresh: (@MainActor () async throws -> Void)? = nil, "
                + "search: (@MainActor (String) async throws -> [\(type(.listing))])? = nil, close: (@MainActor () -> Void)? = nil)")
        }
        return lines
    }
}

extension String {
    /// The first capture of every match of `pattern`.
    func matchesOf(_ pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        return regex.matches(in: self, range: NSRange(startIndex..., in: self)).compactMap { Range($0.range(at: 1), in: self).map { String(self[$0]) } }
    }
}
