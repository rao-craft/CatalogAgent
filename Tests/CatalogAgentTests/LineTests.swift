import Foundation
import XCTest
@testable import CatalogAgent

/// Every line a call can hold, read: what each kind accepts, and every refusal with the reason a model can act on.
final class LineTests: XCTestCase {
    // MARK: Mappings

    func testAMappingLineReadsItsRoleTypeAndWords() throws {
        let line = try MappingLine.parse("collection: ModelGroup name=name summary=summary count=documents earnings=earnings tags=tags online=online color=color")
        XCTAssertEqual(line.role, .collection)
        XCTAssertEqual(line.type, "ModelGroup")
        XCTAssertNil(line.id)
        XCTAssertEqual(line.assignments.map(\.property.key), ["name", "summary", "count", "earnings", "tags", "online", "color"])
        XCTAssertEqual(line.assignments.map(\.source), ["name", "summary", "documents", "earnings", "tags", "online", "color"].map { .path($0) })

        // Aliases for roles and words, any case; commas and spaces around `=` read too; an expression kept whole.
        let world = try MappingLine.parse(#"world: Kit.World, label = name, by=owner.name, credits=value.cents / 100, position=rank, id=slug"#)
        XCTAssertEqual(world.role, .listing)
        XCTAssertEqual(world.type, "Kit.World")
        XCTAssertEqual(world.id, .path("slug"))
        XCTAssertEqual(world.assignments.map(\.property.key), ["name", "owner", "credits", "rank"])
        XCTAssertEqual(world.assignments[1].source, .path("owner.name"))
        XCTAssertEqual(world.assignments[2].source, .expression("value.cents / 100"))
        XCTAssertEqual(try MappingLine.parse("Loom: Crate members=albumIDs").role, .grouping)
        XCTAssertEqual(try MappingLine.parse("note: Track title=title updated=addedAt collection=albumID").role, .document)
        XCTAssertEqual(try MappingLine.parse(#"grouping: Crate name=value.title ?? "Untitled""#).assignments[0].source,
                       .expression(#"value.title ?? "Untitled""#))
    }

    func testEveryMappingRefusalSaysWhy() {
        let refusals: [(String, String)] = [
            ("", "it is empty"),
            ("collection ModelGroup name=name", "has no colon"),
            ("shelfie: ModelGroup name=name", "`shelfie` is not a role"),
            ("collection: name=name", "is not a type name"),
            ("collection: modelGroup name=name", "`modelGroup` is not a type name"),
            ("collection: Array<Int> name=name", "is not a type name"),
            ("collection: ModelGroup", "it maps nothing"),
            ("collection: ModelGroup name", "`name` is not `word=value`"),
            ("collection: ModelGroup name=", "`name` has `=` and no value"),
            ("collection: ModelGroup price=cost", "`price` is not something a collection shows; a collection maps id, name, summary, count"),
            ("collection: ModelGroup name=name title=label", "`name` is mapped twice"),
            ("listing: World id=slug id=key", "`id` is mapped twice"),
            ("grouping: Loom tags=tags", "a grouping maps id, name, members"),
        ]
        for (line, reason) in refusals {
            XCTAssertThrowsError(try MappingLine.parse(line), line) { error in
                XCTAssertTrue("\(error)".contains(reason), "\(line): \(error)")
            }
        }
    }

    // MARK: Look

    func testALookLineMapsARoleToTheAppsNameAHexADesignOrANumber() throws {
        XCTAssertEqual(try LookLine.parse("accent = Color.accent").swift, "Color.accent")
        XCTAssertEqual(try LookLine.parse("title = Font.brandTitle").swift, "Font.brandTitle")
        XCTAssertEqual(try LookLine.parse("design = serif").swift, ".serif")
        XCTAssertEqual(try LookLine.parse("design = .rounded").swift, ".rounded")
        XCTAssertEqual(try LookLine.parse("layer4 = 16").swift, "16")
        XCTAssertEqual(try LookLine.parse("layer4 = CGFloat.layer4").swift, "CGFloat.layer4")
        XCTAssertEqual(try LookLine.parse("card = #FFFFFF / #FFFFFF 0.10").swift,
                       "CatalogLook.dynamic(light: 0xFFFFFF, lightOpacity: 1, dark: 0xFFFFFF, darkOpacity: 0.10)")
        XCTAssertEqual(try LookLine.parse("cardShadow = #8e8e8e 14% / clear").swift,
                       "CatalogLook.dynamic(light: 0x8E8E8E, lightOpacity: 0.14, dark: 0x000000, darkOpacity: 0)")
        XCTAssertEqual(try LookLine.parse("Accent = #AE9060").key, "accent", "a role in any case")
    }

    func testEveryLookRefusalSaysWhy() {
        let refusals: [(String, String)] = [
            ("accent", "has no `=`"),
            ("accent =", "`accent` has `=` and no value"),
            ("= Color.accent", "it names no key"),
            ("glow = Color.accent", "`glow` is not a look role; look maps accent, background, ink, card, panel"),
            ("card = #FFF", "`#FFF` is not a colour"),
            ("card = #FFFFFF 1.5", "is not a colour"),
            ("card = #FFFFFF / #000000 / #111111", "is not a colour"),
            ("accent = accent", "names the look's own role"),
            ("accent = CatalogLook.ink", "names the look's own role"),
            ("accent = Color.accent)", "is not one Swift expression"),
            ("title = Font.brand; exit(0)", "is not one Swift expression"),
        ]
        for (line, reason) in refusals {
            XCTAssertThrowsError(try LookLine.parse(line), line) { error in
                XCTAssertTrue("\(error)".contains(reason), "\(line): \(error)")
            }
        }
    }

    // MARK: Strings

    func testAStringLineSetsAWordAndTheNounsMakeEveryDefault() throws {
        XCTAssertEqual(try StringLine.parse(#"catalog.title = "The World""#).value, "The World")
        XCTAssertEqual(try StringLine.parse(#"browse.credits = "{credits} cr""#).value, "{credits} cr")
        XCTAssertEqual(try StringLine.parse(#"delete.message = "Say \"yes\"""#).value, #"Say "yes""#)
        XCTAssertEqual(try StringLine.parse(#"mine.title = "My {Collections}""#).value, "My {Collections}")
        XCTAssertEqual(try StringLine.parse("catalog.title = The World").value, "The World", "words left unquoted are read as written")

        let words = CatalogWords.resolve(["collection": "model", "collections": "models", "grouping": "loom", "groupings": "looms"])
        XCTAssertEqual(words["mine.title"], "Models")
        XCTAssertEqual(words["menu.edit"], "Edit model")
        XCTAssertEqual(words["detail.title"], "{name} Model")
        XCTAssertEqual(words["add.title"], "Add to Loom")
        XCTAssertEqual(words["groupings.empty.title"], "No Looms Yet")
        XCTAssertEqual(words["form.members"], "Models in this Loom")
        XCTAssertEqual(words["groupings.active"], "active loom")
        // Every key has an English default that names no noun left in braces.
        for word in CatalogWords.all {
            let text = try XCTUnwrap(words[word.key], word.key)
            for name in CatalogWords.placeholders(in: text) { XCTAssertTrue(word.fills.contains(name), "\(word.key) keeps {\(name)}") }
        }
    }

    func testEveryStringRefusalSaysWhy() {
        let refusals: [(String, String)] = [
            (#"catalog.subtitle = "The World""#, "`catalog.subtitle` is not a string key; the keys are collection, collections"),
            (#"catalog.title = "The World"#, "is not one quoted string"),
            (#"collection = "{name}""#, "`collection` is a noun the other strings are made of"),
            (#"collections = """#, "is a noun the other strings are made of"),
            (#"browse.credits = "{amount} cr""#, "`{amount}` is not something `browse.credits` fills in: it takes {credits} and the nouns"),
            (#"mine.title = "{name}""#, "`{name}` is not something `mine.title` fills in"),
        ]
        for (line, reason) in refusals {
            XCTAssertThrowsError(try StringLine.parse(line), line) { error in
                XCTAssertTrue("\(error)".contains(reason), "\(line): \(error)")
            }
        }
    }

    // MARK: Symbols

    func testASymbolLineSetsAnSFSymbol() throws {
        XCTAssertEqual(try SymbolLine.parse("mine.trailing = wallet.bifold").value, "wallet.bifold")
        XCTAssertEqual(try SymbolLine.parse(#"groupings.empty = "slider.horizontal.3""#).value, "slider.horizontal.3")
        let refusals: [(String, String)] = [
            ("mine.wallet = wallet.bifold", "`mine.wallet` is not a symbol key; the keys are mine.leading"),
            ("mine.trailing = Wallet Bifold", "is not an SF Symbol name"),
            ("mine.trailing = wallet..bifold", "is not an SF Symbol name"),
        ]
        for (line, reason) in refusals {
            XCTAssertThrowsError(try SymbolLine.parse(line), line) { error in
                XCTAssertTrue("\(error)".contains(reason), "\(line): \(error)")
            }
        }
    }

    // MARK: Tuning

    func testATuningLineWritesItsValueAsSwiftUIDoes() throws {
        XCTAssertEqual(try TuningLine.parse("press = .spring(duration: 0.2, bounce: 0.4)").swift, ".spring(duration: 0.2, bounce: 0.4)")
        XCTAssertEqual(try TuningLine.parse("earnings = spring(duration: 0.65, bounce: 0.35).delay(0.1)").swift,
                       ".spring(duration: 0.65, bounce: 0.35).delay(0.1)")
        XCTAssertEqual(try TuningLine.parse("pulse = Animation.easeInOut(duration: 1.9).repeatForever(autoreverses: true)").swift,
                       ".easeInOut(duration: 1.9).repeatForever(autoreverses: true)")
        XCTAssertEqual(try TuningLine.parse("tags = .snappy").swift, ".snappy")
        XCTAssertEqual(try TuningLine.parse("pressScale = 0.97").swift, "0.97")
        XCTAssertEqual(try TuningLine.parse("swatchColumns = 4").swift, "4")
        XCTAssertEqual(try TuningLine.parse("publicLimit = 20").swift, "20")
        XCTAssertEqual(try TuningLine.parse("detail = [.fraction(0.6)]").swift, "[.fraction(0.6)]")
        XCTAssertEqual(try TuningLine.parse("edit = .fraction(0.78), large").swift, "[.fraction(0.78), .large]")
        XCTAssertEqual(try TuningLine.parse("form = [.height(320), .medium]").swift, "[.height(320), .medium]")
        XCTAssertEqual(try TuningLine.parse("swatches = [.red, .mint, .indigo]").swift, "red mint indigo")
        XCTAssertEqual(try TuningLine.parse("cardDate = .long").swift, ".long")
        XCTAssertEqual(try TuningLine.parse("cardTime = shortened").swift, ".shortened")
        XCTAssertEqual(try TuningLine.parse(#"cardDate = "MMMM d, yyyy · h:mm:ss a""#).swift, #""MMMM d, yyyy · h:mm:ss a""#)
        XCTAssertEqual(try TuningLine.parse("dateZone = America/New_York").swift, #"TimeZone(identifier: "America/New_York")"#)
        XCTAssertEqual(try TuningLine.parse(#"dateZone = "Asia/Kolkata""#).swift, #"TimeZone(identifier: "Asia/Kolkata")"#)
        XCTAssertEqual(try TuningLine.parse("dateZone = nil").swift, "nil", "nil keeps the device's zone")
    }

    func testEveryTuningRefusalSaysWhy() {
        let refusals: [(String, String)] = [
            ("speed = 0.2", "`speed` is not a tuning key; the keys are press, earnings"),
            ("press = spring 0.2 0.4", "is not an animation"),
            ("press = .spring(duration: 0.2) { }", "is not an animation"),
            ("pressScale = big", "is not a number for `pressScale`"),
            ("pressScale = -1", "is not a number for `pressScale`"),
            ("swatchColumns = 0", "`swatchColumns` needs at least 1"),
            ("swatchColumns = 2.5", "is not a whole number for `swatchColumns`"),
            ("detail = [.fraction(1.5)]", "is not a list of detents"),
            ("detail = [.tall]", "is not a list of detents"),
            ("detail = [.large, .large]", "is not a list of detents"),
            ("swatches = red, magenta", "`magenta` is not a system colour"),
            ("swatches = red red", "a swatch is named twice"),
            ("cardDate = .short", "is not a date style: write .abbreviated, .long, .numeric, .complete"),
            ("cardTime = .abbreviated", "is not a time style"),
            (#"rowDate = "MMM d""#, "is not a date style"),
            (#"cardDate = "MMM \"d""#, "is not a date format"),
            ("dateZone = Mars/Olympus", "is not a time zone: write an IANA name, like `America/New_York`"),
            ("dateZone = New York", "is not a time zone"),
        ]
        for (line, reason) in refusals {
            XCTAssertThrowsError(try TuningLine.parse(line), line) { error in
                XCTAssertTrue("\(error)".contains(reason), "\(line): \(error)")
            }
        }
    }

    // MARK: Launch

    func testALaunchLineOpensAState() throws {
        XCTAssertEqual(try LaunchLine.parse("models = mine"), LaunchState(destination: "models", state: .mine))
        XCTAssertEqual(try LaunchLine.parse(#"model = detail "Space""#), LaunchState(destination: "model", state: .detail("Space")))
        XCTAssertEqual(try LaunchLine.parse(#"model.edit = edit("Space")"#), LaunchState(destination: "model.edit", state: .edit("Space")))
        XCTAssertEqual(try LaunchLine.parse("model = detail Space"), LaunchState(destination: "model", state: .detail("Space")), "a name left unquoted")
        XCTAssertEqual(try LaunchLine.parse("world = browse"), LaunchState(destination: "world", state: .browse))
        XCTAssertEqual(try LaunchLine.parse("looms = groupings"), LaunchState(destination: "looms", state: .groupings))
        XCTAssertEqual(try LaunchLine.parse("looms.create = groupings new"), LaunchState(destination: "looms.create", state: .newGrouping))
        XCTAssertEqual(LaunchState.State.newGrouping.swift, ".newGrouping")
        XCTAssertEqual(LaunchState.State.detail(#"Say "hi""#).swift, #".detail("Say \"hi\"")"#)
    }

    func testEveryLaunchRefusalSaysWhy() {
        let refusals: [(String, String)] = [
            ("models", "has no `=`"),
            ("my models = mine", "`my models` is not a destination name"),
            ("model = detail", "`detail` opens one collection: name it"),
            (#"model = detail "Space"#, "is not a name: write it in quotes"),
            (#"models = mine "Space""#, "`mine` takes no name"),
            (#"looms = groupings "Research""#, "`groupings` takes no name: `groupings new` opens the form for a new grouping"),
            ("models = cards", "`cards` is not a state; a destination opens in mine, detail"),
        ]
        for (line, reason) in refusals {
            XCTAssertThrowsError(try LaunchLine.parse(line), line) { error in
                XCTAssertTrue("\(error)".contains(reason), "\(line): \(error)")
            }
        }
    }

    // MARK: A whole call

    /// Every line of every field read at once: each problem named by its field, a key set twice refused.
    func testACallsLinesAreReadTogetherAndEveryProblemIsNamedByItsField() {
        let read = CatalogAgent.read(.init(
            mappings: ["collection: ModelGroup name=name", "model: Other name=title", "nope"],
            look: ["accent = Color.accent", "accent = Color.red"],
            strings: [#"catalog.title = "The World""#, #"catalog.title = "World""#, #"catalog.nope = "x""#],
            symbols: ["close = xmark", "close = xmark.circle"],
            tuning: ["press = .snappy", "press = .smooth"],
            launch: ["models = mine", "models = browse", "  "]))
        let problems = read.problems.joined(separator: "\n")
        for reason in ["mappings `nope`: a mapping is", "mappings: collection is mapped twice", "look `accent = Color.red`: `accent` is set twice",
                       "strings `catalog.title = \"World\"`: `catalog.title` is set twice", "strings `catalog.nope = \"x\"`",
                       "symbols `close = xmark.circle`: `close` is set twice", "tuning `press = .smooth`: `press` is set twice",
                       "launch `models = browse`: `models` is set twice"] {
            XCTAssertTrue(problems.contains(reason), "\(reason) in\n\(problems)")
        }
        XCTAssertEqual(read.problems.count, 8, problems)
        XCTAssertEqual(read.look["accent"], "Color.accent")
        XCTAssertEqual(read.launches, [LaunchState(destination: "models", state: .mine)])
    }
}
