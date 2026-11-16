# CatalogAgent

Give an app a catalog of collections without drawing it by hand. Say which of your types are your collections, the
documents in them, other people's collections and the groupings you keep, and `catalog` writes the cards, a
collection's detail sheet and edit form, the ranked and searchable list of others' collections, and the groupings
that show them. What it writes is plain SwiftUI that works in any app, with no Granite dependency in it.

## What you can ask

```
$catalog my albums as cards, with a detail sheet of their tracks and an edit form, over the app's Album and Track
$catalog the charts and crates screens: others' playlists ranked and searchable, and crates to keep them in
$catalog Seer's Models, Model, The World and Looms over SeerKit's ModelGroup, Note, World and Loom
$catalog only the cards for the app's Folder type, its views prefixed Kit
```

Craft writes the call from your request, shows it on its agent map as `catalog-1`, and builds and tests what it
writes with the turn.

## What you get

- **Your collections as cards.** Each with its name, summary, count, earnings, tags, an online dot and a date. A
  pressed card scales; a long press offers edit, online or offline, and delete, after a confirmation.
- **A collection's detail and edit form.** Its documents newest first with "Updated: …", a swipe to delete one; a
  form for the name, the description, tags as chips added through an alert, and a colour from system swatches.
- **Others' collections, ranked and searchable.** Ranks, owners, credits and tags, and "Add to <grouping>" from each
  row.
- **Named groupings.** An active banner, rows to select, a new and an edit form, and an empty state that says what a
  grouping is for.
- **Your own types, words and look.** One line a type says which field is the name, the count or the members; the
  views read protocols, and your types are made to conform to them, without a change to the types themselves. Four
  nouns rename every word (`collection = "album"`), and any word, symbol, timing, detent or colour can be set by key.
- **Views ready to drop in.** They take values and closures, hold no global state and never route, so your app keeps
  its own navigation; a control with no action is not drawn. A launch line opens a state for a `-destination`
  launch, as UI tests and screenshots launch an app. Every view has a `#Preview`, every word is natural English, and
  every icon-only control is labelled for VoiceOver.

## How it works

- It reads each line and refuses one it cannot read with the reason and the words or keys it can take, every bad
  line at once, and writes nothing.
- When it can read your types in the project, it checks each mapped field against them, and imports the package a
  type lives in.
- It writes from templates and asks no model, so the same call makes the same files every time.
- Every file is parsed with `swiftc -parse` before any lands, and they land together.
- What it makes is built and tested with the turn.

## Works well with

`catalog` writes the catalog; the other Rao Craft Agents fill in the rest. `design` names the colours, type and
spacing its `look` lines map, `models` and `network` write the types it maps, `mocks` the data it shows before the
server exists, and `granite` the pages that show its `CollectionsView` and `CatalogView` and the services their
closures call.

## Get it

In Craft, install Catalog from the Agent Store, or run
`craft agents add https://github.com/rao-craft/CatalogAgent.git`, then say `$catalog` in a request.

## Requirements

- A Mac on macOS 14 or later, with Xcode.
- The views target iOS 17 and macOS 14 and compile in Swift 5 and Swift 6 language modes. They are plain SwiftUI:
  no Granite, and no package to add.
- MIT licensed.

## For developers

What a call takes and answers, every line's syntax and every key with its default are in the
[reference](Schema/Catalog.md), and how it is measured is [TESTING.md](TESTING.md).
