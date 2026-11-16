# Testing CatalogAgent

How `catalog` is tested: its own suite, its gated build of real output, and the Seer call held to Seer's scorecard.
Prompts run through [Craft](https://github.com/riteshpakala/Craft) on a Mac will be logged below verbatim, with what
came out, as LoomAgent's are. A test that needs a server uses mock data, never a live service.

## The suite

```
swift test                                            # 51 tests, the gated build skipped
CATALOG_BUILD=1 swift test --filter CatalogBuildTests # the output built for real (gated, under a minute on an M4 Max)
CATALOG_EXAMPLES=1 swift test                         # writes the schemas, the reference's tables and seer.answer.json again
```

| File | Tests | What it holds |
| --- | --- | --- |
| `CatalogAgentTests` | 6 | the record (word, schema, fields, lanes, makes), the guide, a call through Granite's roster, the host's folder, a refused call that names every reason and writes nothing |
| `LineTests` | 12 | every kind of line accepted and refused, each refusal with its reason: mappings, look, strings, symbols, tuning, launch, and a whole call's problems at once |
| `TemplateTests` | 9 | every screen set fills and renders, every flag known, every part's views declared, a `#Preview` in every view, every icon-only control labelled, every key read, no literal words |
| `CatalogEmitTests` | 11 | the conformances, imports and shared members, the app's own types checked, the files each screen set writes, the prefix, the look, the launch, the words, symbols and timings, the same bytes twice |
| `SeerTests` | 7 | the Seer call's output against Seer's scorecard and spec (below), its answer, and the second app's call |
| `ReferenceTests` | 5 | the schemas as the record says, every example key a line it reads, the reference's tables from the code, the Seer call and page bodies in the reference |
| `CatalogBuildTests` | 1 | the gated build |

## The gated build

`CatalogBuildTests` writes a scratch package of apps, each with the kit written into it by a real call, and builds it:

- **Seer**, in Swift 6, and **SeerFive**, the same in Swift 5: `Schema/examples/seer.json` over stand-ins for SeerKit's
  `ModelGroup`, `Note`, `World` and `Loom` (in a module of their own, so the conformances import it), DesignAgent's
  names (`Color.accent`, `Font.brandTitle` … `Font.brandNote2`, `CGFloat.layer1` … `CGFloat.layer7`), the services the
  closures call, and the two pages with the bodies in [Schema/Catalog.md](Schema/Catalog.md#seer) as written.
- **Recipes**, in Swift 5: `Schema/examples/recipes.json`, whose fields are other types (UUID and Int ids, a
  `Decimal?`, dates as strings, tags in one comma-separated string).
- **Least**, in Swift 6: a call with nothing but a prefix, every role the kit's own value type.
- **Later**: a kit made by two calls into one folder, the second adding a screen and a launch line to the first.

Then `swift build` for the Mac with no warning in the kit's files, `swift run Check` to draw every screen of every app
offscreen with `ImageRenderer` (Seer's pages again under each `-destination` launch state, read from the registration
domain and never saved), and `xcodebuild -destination 'generic/platform=iOS Simulator'` with no warning in the kit's
files. No simulator is booted. Seer's stand-in data is the reference stub's, which the original's shots were taken
with.

Last run, 2026-11-15: 111 files written for 5 apps; the Mac built with 0 warnings in the kit's files; 48 screens drawn;
the iOS simulator build succeeded with 0 warnings in the kit's files; 45.3 s.

## Conformance on Seer

The Seer call ([`Schema/examples/seer.json`](Schema/examples/seer.json)) writes Seer's Models, Model, Model edit, The
World and Looms, and it builds: in Swift 6 and Swift 5, for the Mac and for the iOS simulator, in the gated build
above.

`SeerTests` holds its output to Seer's own checks (`.work/measure/task/seer/` in Craft):

- **Every `code` item** of the scorecard's `models` and `world` areas that is the kit's matches the output:
  B-models-12 to 15 and 17 to 24, B-world-8 to 16, and B-data-1. B-models-16 and B-data-5, 6 and 7 are `$mocks`'s
  (the data), and B-world-17 is the Void page's (it reads the active loom). Run over the real scorecard: 22 of 22.
- **Every quoted string** of the spec's Models, Model detail, Model edit, The World and Looms is in the emitted code,
  the words the views fill in as they draw (a name, a count, credits) checked by their literal parts.
- **The destinations** `models`, `model`, `model.edit`, `world`, `looms` and `looms.create` open the states the
  spec and the shots name: the cards, "Space"'s detail sheet, "Space"'s edit form, the browse tab, the groupings tab,
  and the groupings tab with the New Loom form up.
- **The look** maps Seer's names, leaves the text in the system's primary colour as the original draws it, and keeps
  serif for every other size.
- **The initializers** the answer gives name Seer's types.

Design parity with the original's subviews is held by an inventory of them (Craft's
`.work/measure/kits/inventory/catalog.md`), each mirrored by a template; the screens are read by eye against the
original's shots in the one-shot run (C-models-1 to 8, C-world-1 to 6).

## Prompts run on this Mac

None yet. The first is the one-shot Seer prompt, run unattended through Craft with the agent installed from this
repository.
