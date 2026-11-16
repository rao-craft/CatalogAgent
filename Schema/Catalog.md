# craft-agent/1 · catalog

Writes a catalog of collections as plain SwiftUI: my collections as cards with a detail sheet and an edit form (tags, colour), others' collections ranked and searchable, and named groupings of them, made to show the app's own types from one mapping line a type.

catalog's copy of Craft's agent standard (`craft-agent/1`, Craft's `Schema/Agent.md`). The parts written from the
code (what it takes, what it makes, and the tables of words, look roles, symbols and tunings) are held to it by
`ReferenceTests`, which writes them again with `CATALOG_EXAMPLES=1`. Changes is catalog's own log.

| File | What it holds |
| --- | --- |
| [`catalog.input.schema.json`](catalog.input.schema.json) | What it takes, as JSON Schema, with every string, symbol and tuning key as an example |
| [`catalog.answer.schema.json`](catalog.answer.schema.json) | What it answers: `granite-answer/1` with its own kinds |
| [`examples/seer.json`](examples/seer.json) | The call that writes Seer's Models, Model, Model edit, The World and Looms |
| [`examples/seer.answer.json`](examples/seer.answer.json) | What that call answers |
| [`examples/recipes.json`](examples/recipes.json) | A call for another app: a recipe app's cookbooks, recipes, shared books and shelves |

## What it takes

<!-- fields: written by ReferenceTests from the code -->
| Field | Required | What it is |
| --- | --- | --- |
| `into` | no | the folder for the views, relative to the project; Components/Catalog when left out |
| `mappings` | no | one line a role (collection, document, listing, grouping): `collection: ModelGroup name=name summary=summary count=documents earnings=earnings tags=tags online=online color=color`; a bare path is read off the value, anything else is Swift that may name `value` |
| `screens` | no | the screens to write, every one when left out: mine (the cards, detail and edit form), browse (others' ranked and searchable), groupings (named sets of collections) |
| `look` | no | one line a look role, `role = value`: a colour (accent, background, ink, card, panel, cardShadow, fieldShadow, badgeShadow, positive, inactive) as the app's name or `#RRGGBB [opacity] [/ #RRGGBB [opacity]]`, a font (title, body, body2, note, note2), design (serif, rounded, monospaced, default), a spacing (layer1 … layer7); a role left out takes the system's |
| `strings` | no | one line a word, `key = "words"`: the nouns collection, collections, grouping, groupings first (every default is made of them), then any key such as catalog.title, browse.credits = "{credits} cr" or detail.title = "{name} {Collection}" |
| `symbols` | no | one line an SF Symbol, `key = name`: mine.leading, mine.trailing, mine.empty, groupings.empty and the rest |
| `tuning` | no | one line a timing, size or style, `key = value`: press, earnings, pulse, tags (animations as SwiftUI writes them), pressScale, pulseScale, earningsRise, cardRadius, fieldRadius, gradientStart, gradientStop, colorRadius, swatchSize (numbers), swatchColumns, decimals, topRanks, publicLimit (whole numbers), detail, edit, color, add, form (detents like [.fraction(0.6)]), swatches (system colour names), cardDate (a date style or a quoted format), cardTime, rowDate (styles) |
| `launch` | no | one line a destination, `destination = state`: mine, detail "<name>", edit "<name>", browse or groupings; the views open in that state, their own sheets presented, when the app is launched with -destination <name> |
| `prefix` | no | a prefix for the view types when the app already has views of these names: `Kit` writes KitCatalogView |
| `imports` | no | modules the conformances import, such as the package a mapped type is declared in |
<!-- /fields -->

`directory` is filled by Craft with the project folder. The person's request and the host's model are offered
beside the call, never in it. Every field has a default, so a call may give only `mappings`, or nothing at all.

## The lines

Every field but `into`, `screens`, `prefix` and `imports` is a list of lines, one thing a line. A line that is not
understood is refused with its reason, naming what the key takes or which keys there are, and nothing is written
until every line reads. A key set twice is refused too.

### `mappings`: `role: Type word=value …`

```
collection: ModelGroup name=name summary=summary count=documents earnings=earnings online=online
document: Note title=title updated=createdAt collection=category
listing: World name=name owner=owner.name credits=value.cents / 100 rank=position
grouping: Loom name=name members=models
```

A role, a colon, the type, then one `word=value` for each thing the views show, with spaces or commas between them
and spaces around `=` if you like. The type is UpperCamelCase, with its module before a dot if need be
(`SeerKit.World`), and no generic arguments. One type a role. A role no line maps takes the kit's own value type
(`CatalogCollection`, `CatalogDocument`, `CatalogListing`, `CatalogGrouping`).

- A right side that is a bare path (`owner`, `owner.name`, `stats?.count`) is read off the value. Anything else is
  Swift that may name `value` (`credits=value.cents / 100`).
- Every right side goes through `CatalogValue`, so the app's field may be any type in the table under **Mapping
  words**: a date as a `Date`, an ISO string or seconds; tags as a list or one string with commas; a colour as a
  `Color`, a system colour's name or a hex.
- `id=` is read only for a type with no `id` of its own. The views hand every closure a value's key,
  `CatalogValue.key(id)`.
- A word written as nothing (`summary=nil`, `tags=[]`) is left out with a note, since leaving it out shows the same.
- When the type is declared in the project, each path is checked against it: a field that is not there is refused
  with the type's fields, a field the word cannot show is refused with what it takes, a step through an optional
  reads on with `?.`, and a type declared in a local package is imported with a note.

### `look`: `role = value`

```
accent = Color.accent
card = #FFFFFF / #FFFFFF 0.10
title = Font.brandTitle
design = serif
layer4 = CGFloat.layer4
```

A colour role takes the app's name for it (one Swift expression), or `#RRGGBB` with an opacity after it (`0.10` or
`10%`) and the dark one after a slash; `clear` stands for either side. A font role takes the app's font. `design`
takes `serif`, `rounded`, `monospaced` or `default`, and every size the views draw besides the five font roles uses
it. A spacing role takes a number or the app's name for one. A role left out takes the value in **Look roles**: the
views draw in the system's colours unless a line says otherwise.

### `strings`: `key = "words"`

```
collection = "model"
catalog.title = "The World"
browse.credits = "{credits} cr"
```

One quoted string, with `\"` for a quote inside. The four nouns come first and every other default is made of
them, so `collection = "model"` makes the menu say "Edit model" and a detail sheet's title "Space Model". A key
that fills something in as the view draws (`{name}`, `{count}`, `{credits}`) names it in braces; any key may
name the nouns, `{collection}`, or capitalised, `{Collection}`.

### `symbols`: `key = name`

```
mine.trailing = wallet.bifold
document = text.document.fill
```

An SF Symbol's name: lower-case words joined by dots. Every default draws on iOS 17 and macOS 14; a symbol a call
names has to draw on the app's own targets.

### `tuning`: `key = value`

```
press = .spring(duration: 0.2, bounce: 0.4)
pulse = .easeInOut(duration: 1.9).repeatForever(autoreverses: true)
pressScale = 0.97
detail = [.fraction(0.6)]
swatches = red orange green blue purple brown
cardDate = "MMMM d, yyyy · h:mm:ss a"
```

An animation as SwiftUI writes it, the leading dot optional; a number; a whole number; detents in brackets
(`.medium`, `.large`, `.fraction(0.6)`, `.height(320)`); swatches as system colour names; a date style or, for
`cardDate`, a quoted date format; a time style.

### `launch`: `destination = state`

```
models = mine
model = detail "Space"
model.edit = edit "Space"
world = browse
looms = groupings
```

When the app is launched with `-destination <name>`, as UI tests and screenshots launch it, the view the state
belongs to opens in it and presents its own sheets. The states:

| State | What opens |
| --- | --- |
| `mine` | the cards of my collections |
| `detail "<name>"` | that collection's detail sheet over the cards, found by its name or its id |
| `edit "<name>"` | that collection's edit form over the cards |
| `browse` | others' collections, ranked, on the browse tab |
| `groupings` | the groupings tab |

A destination is letters, digits, dots and dashes. The views open the state; getting to the page that shows them is
the app's navigation.

## The tables

<!-- tables: written by ReferenceTests from the code -->
### Mapping words

A line starts with the role or one of its other words, any case. `id=` is read too, only for a type with no `id` of its own.

| Role | A line may start with | Word | Also read as | Requirement | What it is |
| --- | --- | --- | --- | --- | --- |
| `collection` | `collection`, `model`, `folder`, `board`, `playlist`, `album`, `mine` | `name` | `title`, `label` | `catalogName: String` | What it is called, on its card and in its detail's title. |
|  |  | `summary` | `description`, `about`, `details`, `subtitle` | `catalogSummary: String?` | What it holds, in a sentence or two. |
|  |  | `count` | `documents`, `documentCount`, `size`, `items`, `notes` | `catalogCount: Int?` | How many documents it holds; nil counts the documents that name it. |
|  |  | `earnings` | `credits`, `revenue`, `royalties`, `balance` | `catalogEarnings: Double?` | What it has earned, drawn with two decimals; nil draws none. |
|  |  | `tags` | `labels`, `keywords`, `topics` | `catalogTags: [String]` | Its tags, drawn as chips. |
|  |  | `online` | `available`, `isOnline`, `live`, `active`, `published` | `catalogOnline: Bool?` | Whether others can use it now: the card's dot and the menu's switch; nil draws neither. |
|  |  | `color` | `colour`, `tint` | `catalogColor: Color?` | Its colour: the card's spine and the edit form's tint; a String naming a system colour or a hex is written back as it was named. |
|  |  | `updated` | `date`, `modified`, `updatedAt`, `createdAt`, `created` | `catalogUpdated: Date?` | When it last changed; nil takes the newest date of its documents. |
| `document` | `document`, `note`, `item`, `entry`, `file`, `page`, `post` | `title` | `name`, `label` | `catalogTitle: String` | What the document is called, on its row. |
|  |  | `updated` | `date`, `createdAt`, `created`, `modified`, `updatedAt` | `catalogUpdated: Date?` | When it last changed: "Updated: …" under its title, newest first. |
|  |  | `collection` | `category`, `group`, `model`, `folder`, `parent` | `catalogCollectionKey: String?` | The collection it is in, by the collection's id or its name. |
| `listing` | `listing`, `world`, `public`, `shared`, `other`, `ranking` | `name` | `title`, `label` | `catalogName: String` | What it is called, on its row. |
|  |  | `owner` | `by`, `creator`, `author`, `user` | `catalogOwner: String?` | Whose it is: "by …" under its name. |
|  |  | `summary` | `description`, `about`, `details` | `catalogSummary: String?` | What it holds, in a sentence or two. |
|  |  | `tags` | `labels`, `keywords`, `topics` | `catalogTags: [String]` | Its tags, drawn as chips. |
|  |  | `credits` | `earnings`, `price`, `revenue` | `catalogCredits: Double?` | What it has earned, drawn with two decimals; nil draws none. |
|  |  | `count` | `documents`, `documentCount`, `size`, `items` | `catalogCount: Int?` | How many documents it holds; nil draws none. |
|  |  | `rank` | `position`, `place` | `catalogRank: Int?` | Its place in the ranking; nil takes its place in the list, from 1. |
| `grouping` | `grouping`, `loom`, `group`, `set`, `stack`, `bundle`, `shelf` | `name` | `title`, `label` | `catalogName: String` | What the grouping is called. |
|  |  | `members` | `models`, `collections`, `items`, `ids`, `groups` | `catalogMembers: [String]` | The collections in it, each by its id or its name, mine or others'. |

A right side goes through `CatalogValue`, which takes the app's field as it is:

| Words | Requirement | The app's field may be |
| --- | --- | --- |
| `name`, `title` | `String` | text (a String, a URL, a UUID or a whole number) |
| `summary`, `collection`, `owner` | `String?` | text (a String, a URL, a UUID or a whole number) |
| `count`, `rank` | `Int?` | a whole number (an Int, a Double or a String) |
| `earnings`, `credits` | `Double?` | a number (an Int, a Double, a Decimal or a String) |
| `tags` | `[String]` | tags (a list of Strings, or one String with commas between them) |
| `online` | `Bool?` | a flag (a Bool, a whole number or a String such as "online") |
| `color` | `Color?` | a colour (a Color, or a String naming a system colour such as "brown" or a hex such as "#AE9060") |
| `updated` | `Date?` | a date (a Date, an ISO String, or seconds as a Double or an Int) |
| `members` | `[String]` | ids or names (a list of Strings, UUIDs or Ints, or one String with commas between them) |

### Look roles

| Role | Kind | Without a line | Where it shows |
| --- | --- | --- | --- |
| `accent` | color | `Color.accentColor` | the tint: bar buttons and their glyphs, tags, the selected tab, ranks at the top, the active grouping |
| `background` | color | `CatalogLook.system(.background)` | behind the tab row and the search row |
| `ink` | color | `Color.primary` | text, rules and faint glyphs, at the opacity each is drawn at |
| `card` | color | `CatalogLook.system(.card)` | a card's surface, the edit form's fields and a document's badge |
| `panel` | color | `CatalogLook.system(.panel)` | where the edit form's and the colour sheet's gradients start |
| `cardShadow` | color | `Color.black.opacity(0.08)` | the shadow under a card |
| `fieldShadow` | color | `Color.black.opacity(0.12)` | the shadow under the name field |
| `badgeShadow` | color | `Color.black.opacity(0.12)` | the shadow under a document's badge |
| `positive` | color | `Color.green` | earnings, and the online dot |
| `inactive` | color | `Color.gray` | the offline dot |
| `title` | font | `CatalogLook.font(24)` | titles in the bar |
| `body` | font | `CatalogLook.font(20)` | a listing's name over its description in the add sheet |
| `body2` | font | `CatalogLook.font(18)` | a listing's or a grouping's name |
| `note` | font | `CatalogLook.font(18, .light)` | the empty cards' line |
| `note2` | font | `CatalogLook.font(16, .light)` | descriptions and section headers |
| `design` | design | `.default` | the design of every other size the views draw: `serif` for Seer |
| `layer1` | spacing | `4` | the smallest gap |
| `layer2` | spacing | `8` | a small gap |
| `layer3` | spacing | `12` | a gap |
| `layer4` | spacing | `16` | padding |
| `layer5` | spacing | `24` | the edit form's blocks |
| `layer6` | spacing | `32` | a large gap |
| `layer7` | spacing | `42` | the empty states' side inset |

### String keys

The defaults are made of the four nouns, `{collection}` (`{Collection}` capitalised) and the others, so four lines rename every word. A key that fills something in as the view draws names it in braces, and takes no other placeholder but the nouns.

| Key | Default | Fills in | Where it shows |
| --- | --- | --- | --- |
| `collection` | "collection" |  | one of the person's collections, as a word in a sentence: `model` |
| `collections` | "collections" |  | several of them: `models` |
| `grouping` | "group" |  | one named set of collections: `loom` |
| `groupings` | "groups" |  | several of them: `looms` |
| `mine.title` | "{Collections}" |  | the bar's title over the cards |
| `mine.leading` | "Profile" |  | the leading bar button's accessibility label |
| `mine.trailing` | "More" |  | the trailing bar button's accessibility label |
| `mine.empty.title` | "No {Collections}" |  | the cards' empty state |
| `mine.empty.message` | "Your {collections} show here." |  | the line under it, in italics |
| `card.documents.one` | "document" |  | after a card's count of one |
| `card.documents.other` | "documents" |  | after any other count |
| `card.earnings` | "credits" |  | under a card's earnings |
| `card.online` | "Online" |  | the online dot's accessibility label |
| `card.offline` | "Offline" |  | the offline dot's accessibility label |
| `menu.edit` | "Edit {collection}" |  | the long-press menu's edit item |
| `menu.offline` | "Set Offline" |  | the menu's item that takes an online collection offline |
| `menu.online` | "Set Online" |  | the item that puts it back |
| `menu.delete` | "Delete {collection}" |  | the menu's delete item, and the confirmation's button |
| `delete.title` | "Delete {name}?" | `{name}` | the confirmation's title |
| `delete.message` | "This can't be undone." |  | the confirmation's message |
| `detail.title` | "{name} {Collection}" | `{name}` | the detail sheet's title |
| `detail.updated` | "Updated: {date}" | `{date}` | under each document's title |
| `edit.title` | "Edit {Collection}" |  | the edit form's title |
| `edit.name` | "Name your {collection}..." |  | the name field's placeholder |
| `edit.description.header` | "Description" |  | over the description field |
| `edit.description` | "Describe this {collection}..." |  | the description field's placeholder |
| `edit.tags.header` | "Tags" |  | over the tags |
| `edit.tags.add` | "add tag" |  | the chip that adds a tag |
| `edit.tag.add` | "Add Tag" |  | the alert that adds one |
| `edit.tag.edit` | "Edit Tag" |  | the alert that changes one |
| `edit.tag.field` | "Tag name" |  | the alert's field |
| `edit.tag.remove` | "Remove {tag}" | `{tag}` | a chip's remove button's accessibility label |
| `edit.color` | "Color" |  | the colour sheet's title, and the colour button's accessibility label |
| `edit.keyboard` | "Ok" |  | the bar's button that drops the keyboard |
| `edit.failed` | "Couldn't Save" |  | the alert when saving fails |
| `close` | "Close" |  | the close buttons' accessibility label |
| `save` | "Save" |  | the edit form's and the tag alert's save |
| `cancel` | "Cancel" |  | every cancel |
| `done` | "Done" |  | the colour sheet's, the add sheet's and the edit grouping form's done |
| `create` | "Create" |  | the new grouping form's create |
| `ok` | "OK" |  | dismisses the failure alert |
| `catalog.title` | "Explore" |  | the bar's title over the browse and groupings tabs |
| `browse.tab` | "Browse" |  | the browse tab |
| `groupings.tab` | "{Groupings}" |  | the groupings tab |
| `browse.search` | "Search all {collections}…" |  | the search field's placeholder |
| `browse.clear` | "Clear" |  | the button that empties the search, for accessibility |
| `browse.owner` | "by {owner}" | `{owner}` | under a listing's name |
| `browse.rank` | "#{rank}" | `{rank}` | a listing's rank |
| `browse.credits` | "{credits} credits" | `{credits}` | a listing's credits, at the call's decimals |
| `browse.count.one` | "{count} doc" | `{count}` | a listing's count of one |
| `browse.count.other` | "{count} docs" | `{count}` | any other count |
| `browse.empty.title` | "No {Collections} Yet" |  | the browse tab with nothing listed |
| `browse.empty.message` | "Public {collections} will appear here once activity begins." |  | the line under it |
| `add.title` | "Add to {Grouping}" |  | the add sheet's title, and the add button's accessibility label |
| `add.existing` | "Add to existing {Grouping}" |  | its section of groupings |
| `add.new` | "Create new {Grouping}" |  | its row that starts a grouping |
| `add.mine` | "Create with your {collections}" |  | its section of mine |
| `groupings.count.one` | "{count} {collection}" | `{count}` | a grouping's count of one |
| `groupings.count.other` | "{count} {collections}" | `{count}` | any other count |
| `groupings.active` | "active {grouping}" |  | over the active grouping's name in the banner |
| `groupings.deselect` | "deselect" |  | the banner's button |
| `groupings.separator` | " · " |  | between a grouping's members' names |
| `groupings.select` | "Select {grouping}" |  | a grouping's circle, for accessibility |
| `groupings.new` | "New {Grouping}" |  | the button and the form that make a grouping |
| `groupings.edit` | "Edit {Grouping}" |  | the form that changes one, and its pencil's accessibility label |
| `groupings.empty.title` | "No {Groupings} Yet" |  | the groupings tab with none |
| `groupings.empty.message` | "Create a {grouping} to gather the {collections} you come back to." |  | the line under it |
| `form.name.header` | "{Grouping} name" |  | over the name field, and the edit form's placeholder |
| `form.name` | "e.g. Reading, Work, Favorites…" |  | the new form's name placeholder |
| `form.members` | "{Collections} in this {Grouping}" |  | the section of members |
| `form.mine` | "Add your personal {collections}" |  | the new form's section of mine to add |
| `form.add` | "Add {Collections}" |  | the edit form's section to add from |
| `form.public` | "Public {Collections}" |  | its first group: the top of the ranking |
| `form.yours` | "Your {Collections}" |  | its second group: mine |

### Symbol keys

| Key | Default | Where it shows |
| --- | --- | --- |
| `mine.leading` | `person.crop.circle` | the leading bar button over the cards |
| `mine.trailing` | `ellipsis.circle` | the trailing bar button |
| `mine.empty` | `tray` | the empty cards' symbol |
| `menu.edit` | `pencil` | the menu's edit item |
| `menu.offline` | `network.slash` | the menu's offline item |
| `menu.online` | `network` | the menu's online item |
| `menu.delete` | `trash.fill` | the menu's delete item |
| `document` | `doc.text.fill` | in each document's badge in the detail sheet |
| `close` | `xmark` | the close buttons |
| `edit.color` | `paintpalette` | the colour button |
| `edit.keyboard` | `checkmark` | the bar's button while a field has focus |
| `edit.tag.add` | `plus` | the add-tag chip |
| `edit.tag.remove` | `xmark` | a tag chip's remove button |
| `swatch.check` | `checkmark` | over the chosen swatch |
| `browse.search` | `magnifyingglass` | the search row's symbol |
| `browse.clear` | `xmark.circle.fill` | the button that empties the search |
| `browse.add` | `plus.circle` | a listing's add button, and every row that adds |
| `browse.empty` | `chart.bar` | the empty browse tab's symbol |
| `groupings.edit` | `pencil` | a grouping's edit button |
| `groupings.selected` | `checkmark.circle.fill` | the active grouping's circle, and a member's in the add sheet |
| `groupings.unselected` | `circle` | any other circle |
| `groupings.new` | `plus` | beside "New …" |
| `groupings.empty` | `square.stack.3d.up` | the empty groupings tab's symbol |

### Tuning keys

The motion keys are the four animations; the rest are sizes, counts, detents, swatches and date styles.

| Key | Kind | Default | What it sets |
| --- | --- | --- | --- |
| `press` | animation | `.spring(duration: 0.2, bounce: 0.4)` | a pressed card scaling |
| `earnings` | animation | `.spring(duration: 0.65, bounce: 0.35).delay(0.1)` | a card's earnings rising in |
| `pulse` | animation | `.easeInOut(duration: 1.9).repeatForever(autoreverses: true)` | the online dot's pulse |
| `tags` | animation | `.spring(duration: 0.25)` | tag and swatch changes |
| `pressScale` | number | `0.97` | the scale of a pressed card |
| `pulseScale` | number | `1.4` | the scale the online dot's halo pulses to |
| `earningsRise` | number | `8` | how far the earnings rise as they appear, in points |
| `cardRadius` | number | `16` | a card's corner radius |
| `fieldRadius` | number | `24` | the edit form's fields' corner radius |
| `gradientStart` | number | `0.2` | where the edit form's gradient leaves the panel colour |
| `gradientStop` | number | `1.5` | where it reaches the collection's colour |
| `colorRadius` | number | `28` | the colour sheet's corner radius |
| `swatchSize` | number | `44` | a swatch's size, and the colour button's |
| `swatchColumns` | whole | `6` | swatches a row |
| `decimals` | whole | `2` | decimals in earnings and credits |
| `topRanks` | whole | `3` | ranks drawn in the accent |
| `publicLimit` | whole | `5` | listings the edit grouping form offers to add |
| `detail` | detents | `[.fraction(0.6)]` | the detail sheet's detents |
| `edit` | detents | `[.fraction(0.78), .large]` | the edit form's detents |
| `color` | detents | `[.fraction(0.32)]` | the colour sheet's detents |
| `add` | detents | `[.medium]` | the add sheet's detents |
| `form` | detents | `[.medium]` | the new and edit grouping forms' detents |
| `swatches` | swatches | `red orange yellow green mint teal cyan blue indigo purple pink brown` | the colours the edit form offers, as system colour names |
| `cardDate` | dateStyle | `.abbreviated` | a card's date: abbreviated, long, numeric or complete, or a quoted date format |
| `cardTime` | timeStyle | `.omitted` | a card's time after its date: omitted, shortened, standard or complete |
| `rowDate` | dateStyle | `.abbreviated` | a document row's date, its time omitted |

Swatches are among `red`, `orange`, `yellow`, `green`, `mint`, `teal`, `cyan`, `blue`, `indigo`, `purple`, `pink`, `brown`, `gray`, `black`, `white`. Date styles: `.abbreviated`, `.long`, `.numeric`, `.complete`; time styles: `.omitted`, `.shortened`, `.standard`, `.complete`.
<!-- /tables -->

## What it writes

Into `into` (`Components/Catalog` when left out), for the screens asked for (every one when left out):

| File | Written for | What it holds |
| --- | --- | --- |
| `CatalogProtocols.swift` | every call | `CollectionRepresentable`, `DocumentRepresentable`, `ListingRepresentable` and `GroupingRepresentable`, each requirement with its default |
| `CatalogLook.swift` | every call | the look roles, words, symbols and tunings, as the call set them |
| `CatalogLaunch.swift` | every call | the launch lines, read from the `destination` default |
| `CatalogValue.swift`, `CatalogParts.swift`, `CatalogModels.swift`, `CatalogSamples.swift` | every call | the conversions; text roles, buttons, chips and empty states; the drafts and the kit's own value types; the previews' samples |
| `CollectionsView`, `CollectionCard`, `CollectionDetailView`, `CollectionEditView`, `CatalogTagsEditor`, `CatalogSwatchesView` | `mine` | the cards and their menu, the detail sheet, the edit form, the tag chips, the swatches |
| `CatalogView`, `ListingRow` | `browse` or `groupings` | the page with its two tabs, and a ranked row |
| `ListingsView` | `browse` | the ranking and the search |
| `AddToGroupingView` | `browse` and `groupings` | "Add to <grouping>" |
| `GroupingsView`, `GroupingFormView` | `groupings` | the active banner and the rows, and the new and edit forms |
| `Conformances/<Type>+<Role>.swift` | each mapping line | the extension that makes the app's type the role |

`prefix` goes on every view type and its file (`Kit` writes `KitCatalogView.swift`); the shared files keep their
names. Nothing is written until every line reads and every file parses, and the same call writes the same bytes.

## The views

A page shows two roots. They take values and closures and hold no global state; a control whose closure is nil is
not drawn, and a view presents only its own flow's sheets.

```swift
CollectionsView(collections: [Collection], documents: [Document],
                leading: (@MainActor () -> Void)? = nil, trailing: (@MainActor () -> Void)? = nil,
                refresh: (@MainActor () async throws -> Void)? = nil,
                save: (@MainActor (CatalogCollectionDraft) async throws -> Void)? = nil,
                delete: (@MainActor (String) async throws -> Void)? = nil,
                deleteDocument: (@MainActor (String) async throws -> Void)? = nil,
                page: (@MainActor (Document) -> AnyView)? = nil)

CatalogView(listings: [Listing], mine: [Collection], groupings: [Grouping],
            active: String? = nil, select: (@MainActor (String?) async throws -> Void)? = nil,
            save: (@MainActor (CatalogGroupingDraft) async throws -> Void)? = nil,
            delete: (@MainActor (String) async throws -> Void)? = nil,
            refresh: (@MainActor () async throws -> Void)? = nil,
            search: (@MainActor (String) async throws -> [Listing])? = nil,
            close: (@MainActor () -> Void)? = nil)
```

- `leading`, `trailing`: the bar's buttons over the cards.
- `refresh`: pull to refresh. A root that opens with a list still empty runs it once, under a spinner.
- `save` (mine): a `CatalogCollectionDraft` (`id`, `name`, `summary`, `tags`, `color`, `online`) from the edit form,
  and from the menu's online switch with `online` flipped. `color` is the colour as the app named it, or the
  swatch's name.
- `delete`: a collection's key from the menu, after a confirmation; in `CatalogView`, a grouping's key from its form.
- `deleteDocument`: a document's key, from a swipe in the detail sheet.
- `page`: the app's page for a document. Without it a row opens the document's title and date.
- `active`, `select`: the active grouping's key, and what is handed a key, or nil to deselect.
- `save` (groupings): a `CatalogGroupingDraft` (`id`, nil for a new grouping; `name`; `members`, each member's key;
  `names`, each member's name in the same order).
- `search`: the app's search over others' collections. Without it, a search reads the names, summaries and tags.
- `close`: the round close button at the trailing end of the bar.

The answer gives both initializers with the app's types.

## Seer

The call that writes Seer's Models, Model, Model edit, The World and Looms ([`examples/seer.json`](examples/seer.json)):

```json
{
  "mappings": [
    "collection: ModelGroup name=name summary=summary count=documents earnings=earnings tags=tags online=online color=color",
    "document: Note title=title updated=createdAt collection=category",
    "listing: World name=name owner=owner summary=summary tags=tags credits=credits count=documents",
    "grouping: Loom name=name members=models"
  ],
  "imports": ["SeerKit"],
  "look": [
    "accent = Color.accent",
    "card = #FFFFFF / #FFFFFF 0.10",
    "panel = #FFFFFF / #1A1A1A",
    "cardShadow = #8E8E8E 0.14 / clear",
    "fieldShadow = #8E8E8E 0.40 / clear",
    "badgeShadow = #8E8E8E 0.40 / clear",
    "title = Font.brandTitle",
    "body = Font.brandBody",
    "body2 = Font.brandBody2",
    "note = Font.brandNote",
    "note2 = Font.brandNote2",
    "design = serif",
    "layer1 = CGFloat.layer1",
    "layer2 = CGFloat.layer2",
    "layer3 = CGFloat.layer3",
    "layer4 = CGFloat.layer4",
    "layer5 = CGFloat.layer5",
    "layer6 = CGFloat.layer6",
    "layer7 = CGFloat.layer7"
  ],
  "strings": [
    "collection = \"model\"",
    "collections = \"models\"",
    "grouping = \"loom\"",
    "groupings = \"looms\"",
    "mine.trailing = \"Wallet\"",
    "mine.empty.message = \"Start writing and assign a category!\"",
    "close = \"Dismiss\"",
    "catalog.title = \"The World\"",
    "browse.credits = \"{credits} cr\"",
    "groupings.empty.message = \"Create a Loom to organize and filter your favorite models for focused conversations.\"",
    "form.name = \"e.g. Research, News, Deep Cuts…\""
  ],
  "symbols": [
    "mine.leading = person",
    "mine.trailing = wallet.bifold",
    "mine.empty = questionmark.folder.fill",
    "document = text.document.fill",
    "groupings.empty = slider.horizontal.3"
  ],
  "tuning": [
    "press = .spring(duration: 0.2, bounce: 0.4)",
    "earnings = .spring(duration: 0.65, bounce: 0.35).delay(0.1)",
    "pulse = .easeInOut(duration: 1.9).repeatForever(autoreverses: true)",
    "tags = .spring(duration: 0.25)",
    "pressScale = 0.97",
    "pulseScale = 1.4",
    "detail = [.fraction(0.6)]",
    "edit = [.fraction(0.78), .large]",
    "color = [.fraction(0.32)]",
    "colorRadius = 28",
    "cardDate = \"MMMM d, yyyy · h:mm:ss a\""
  ],
  "launch": [
    "models = mine",
    "model = detail \"Space\"",
    "model.edit = edit \"Space\"",
    "world = browse",
    "looms = groupings"
  ]
}
```

The Models page (`models`, and `model` and `model.edit` through its launch states) shows:

```swift
CollectionsView(collections: models.state.models, documents: library.state.notes,
                leading: { layout.present(.profile) }, trailing: { layout.present(.wallet) },
                refresh: { try await models.load(); try await library.load() },
                save: { try await models.save(draft: $0) }, delete: { try await models.delete(id: $0) },
                deleteDocument: { try await library.deleteNote(id: $0) })
```

The World sheet over the Void (`world`, and `looms` through its launch state) shows:

```swift
CatalogView(listings: world.state.worlds, mine: models.state.models, groupings: world.state.looms,
            active: world.state.activeLoom, select: { world.set(.activeLoom($0)) },
            save: { try await world.saveLoom(draft: $0) }, delete: { try await world.deleteLoom(id: $0) },
            refresh: { try await world.load(); try await world.loadLooms() }, close: { layout.closeSheet() })
```

What Seer provides for them:

- **Types** (SeerKit): `ModelGroup` (`name`, `summary`, `documents: Int`, `earnings: Double`, `tags: [String]`,
  `online: Bool`, `color: String`); `Note` (`title`, `createdAt: Date`, `category`: a model's id or name); `World`
  (`name`, `owner: String`, `summary`, `tags: [String]`, `credits: Double`, `documents: Int`); `Loom` (`name`,
  `models: [String]`, each a model's id or name).
- **Services** (Granite relays): `models.state.models`, `models.load()`, `models.save(draft:)`,
  `models.delete(id:)`; `library.state.notes`, `library.load()`, `library.deleteNote(id:)`; `world.state.worlds`,
  `world.state.looms`, `world.state.activeLoom: String?`, `world.set(.activeLoom(_:))`, `world.load()`,
  `world.loadLooms()`, `world.saveLoom(draft:)`, `world.deleteLoom(id:)`; `layout.present(.profile)`,
  `layout.present(.wallet)`, `layout.closeSheet()`.
- **Navigation**: `model` and `model.edit` reach the Models page, and `looms` The World sheet, where the views open
  the state. The World is a sheet at `[.medium, .large]`, opened at `.large` for `world` and `.medium` for `looms`;
  the kit draws its own close button, so the host draws none. The Void reads `world.state.activeLoom != nil` for its
  active loom.

## What it makes

<!-- makes: written by ReferenceTests from the code -->
| Kind | What | Into | Never |
| --- | --- | --- | --- |
| `view` | a catalog of collections as reusable SwiftUI views: my collections as cards with a detail sheet and an edit form (CollectionsView), others' collections ranked and searchable with named groupings of them (CatalogView); a page shows them with CollectionsView(…) and CatalogView(…) | `Components/Catalog/*` | routes; never a page, a service, a client or a model type |
| `conformance` | the app's own types made the views' types: one extension a mapping line | `Components/Catalog/Conformances/*` | a change to the app's types themselves |
<!-- /makes -->

## What it answers

A `granite-answer/1` answer (Granite's `Schema/GraniteAgent.md` §4.2): `paths`, `made` against `expected` by kind and
name, `problems` for what it could only do in part, and its own keys beside them:

| Key | What it is |
| --- | --- |
| `path` | the first file written |
| `views` | the views written, by type name |
| `conformances` | one line a mapped type: `ModelGroup: collection` |
| `initializers` | each root view's initializer, with the app's types where a line maps them |
| `notes` | one sentence each: what the call left out, or what the app still has to do |

`made` holds one `view` for each view written and one `conformance` for each mapping line; `expected` holds the views
each asked-for screen is built from and one conformance a mapping line. Craft measures each call by what it made
of what it expected.

## How it refuses

With an `AgentRefusal` of kind `call`: every problem with the call at once, each naming its field and the line, so
all are fixed in one call. Nothing is written. A refusal names what the key takes or which keys there are, and for
a mapped field of the project's own type, the type's fields or the types the word can show.

## Changes

Each change made to make this agent more precise, dated, with the run that measured it and what it made of what it
was asked before and after (`TESTING.md`). Newest first.

### 2026-11-15 · first cut

catalog writes Seer's Models, Model, Model edit, The World and Looms from one call: twelve views, four conformances,
the look, the words and the launch states. The Seer call builds for the iOS simulator in the gated build, and its
output matches every `code` item of the scorecard's `models` and `world` areas that is the kit's.

Measured: not yet. The first measure is the one-shot Seer run.
