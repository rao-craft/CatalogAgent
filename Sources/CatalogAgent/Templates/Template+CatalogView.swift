//  WHAT: `CatalogView.swift`, the root of `browse` and `groupings`: the bar's title and round close, two equal tabs
//        with a rule between them, and the sheets the tabs open: add to a grouping, and the grouping form.

extension Template {
    static let catalogView = ##"""
    import SwiftUI

    /// Others' collections, ranked and searchable, and named groupings of collections, under one bar. A page shows it
    /// with the app's own values and closures:
    ///
    ///     CatalogView(listings: world.state.worlds, mine: models.state.models, groupings: world.state.looms,
    ///                 active: world.state.activeLoom, select: { world.set(.activeLoom($0)) })
    struct CatalogView<Listing: ListingRepresentable, Item: CollectionRepresentable, Grouping: GroupingRepresentable>: View {
        let listings: [Listing]
        let mine: [Item]
        let groupings: [Grouping]
        let active: String?
        let select: (@MainActor (String?) async throws -> Void)?
        let save: (@MainActor (CatalogGroupingDraft) async throws -> Void)?
        let delete: (@MainActor (String) async throws -> Void)?
        let refresh: (@MainActor () async throws -> Void)?
        let search: (@MainActor (String) async throws -> [Listing])?
        let close: (@MainActor () -> Void)?

        @State private var tab: CatalogTab
        @State private var adding: CatalogEntry?
        @State private var form: CatalogForm?
        @State private var loading = false

        init(listings: [Listing], mine: [Item], groupings: [Grouping], active: String? = nil,
             select: (@MainActor (String?) async throws -> Void)? = nil,
             save: (@MainActor (CatalogGroupingDraft) async throws -> Void)? = nil,
             delete: (@MainActor (String) async throws -> Void)? = nil,
             refresh: (@MainActor () async throws -> Void)? = nil,
             search: (@MainActor (String) async throws -> [Listing])? = nil,
             close: (@MainActor () -> Void)? = nil) {
            self.listings = listings
            self.mine = mine
            self.groupings = groupings
            self.active = active
            self.select = select
            self.save = save
            self.delete = delete
            self.refresh = refresh
            self.search = search
            self.close = close
            // A launch into the groupings opens on their tab; `groupings new` with the new grouping's form up.
            let launch = CatalogLaunch.current
            _tab = State(initialValue: launch == .groupings || launch == .newGrouping ? .groupings : .browse)
            _form = State(initialValue: launch == .newGrouping ? CatalogForm(grouping: nil, members: []) : nil)
        }

        var body: some View {
            VStack(spacing: 0) {
    //@if screen.browse && screen.groupings
                tabRow
    //@endif
                content
            }
            .catalogTitle({{s:catalog.title}})
            .toolbar {
                if let close {
                    ToolbarItem(placement: CatalogPlacement.trailing) {
                        CatalogCloseButton { close() }
                    }
                }
            }
    //@if screen.browse && screen.groupings
            .sheet(item: $adding) { entry in
                AddToGroupingView(entry: entry, groupings: sets, mine: own, entries: ranked + own, save: save) { members in
                    form = CatalogForm(grouping: nil, members: members)
                }
                .presentationDetents({{n:add}})
            }
    //@endif
    //@if screen.groupings
            .sheet(item: $form) { form in
                GroupingFormView(grouping: form.grouping, members: form.members, listings: ranked, mine: own, save: save) {
                    tab = .groupings
                }
                .presentationDetents({{n:form}})
            }
    //@endif
            .task {
                // Opened with nothing to show: the app's refresh, once, under a spinner.
                guard let refresh, listings.isEmpty || groupings.isEmpty else { return }
                loading = true
                try? await refresh()
                loading = false
            }
            .tint(CatalogLook.accent)
        }

        // MARK: Values

        /// Others' collections, each at its rank or its place in the list.
        private var ranked: [CatalogEntry] {
            listings.enumerated().map { CatalogEntry(listing: $0.element, place: $0.offset + 1) }
        }

        private var own: [CatalogEntry] { mine.map { CatalogEntry(collection: $0) } }

        private var sets: [CatalogSet] { groupings.map { CatalogSet(grouping: $0) } }

        // MARK: Tabs

    //@if screen.browse && screen.groupings
        private var tabRow: some View {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    tabButton(.browse, {{s:browse.tab}})
                    Divider()
                        .frame(width: 1, height: 30)
                        .background(CatalogLook.ink.opacity(0.15))
                    tabButton(.groupings, {{s:groupings.tab}})
                }
                .padding(.horizontal, CatalogLook.layer4)
            }
            .padding(.vertical, CatalogLook.layer2)
            .background(CatalogLook.background)
        }

        private func tabButton(_ value: CatalogTab, _ title: String) -> some View {
            Button {
                CatalogHaptic.light()
                tab = value
            } label: {
                Text(verbatim: title)
                    .font(CatalogLook.font(16, .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .foregroundStyle(tab == value ? CatalogLook.accent : CatalogLook.ink.opacity(0.7))
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        }

    //@endif
        @ViewBuilder
        private var content: some View {
    //@if screen.browse && screen.groupings
            switch tab {
            case .browse:
                browseTab
            case .groupings:
                groupingsTab
            }
    //@else
    //@if screen.browse
            browseTab
    //@else
            groupingsTab
    //@endif
    //@endif
        }

    //@if screen.browse
        private var browseTab: some View {
    //@if screen.groupings
            ListingsView(listings: ranked, loading: loading, refresh: refresh, search: searcher, add: { entry in adding = entry }) {
                form = CatalogForm(grouping: nil, members: [])
            }
    //@else
            ListingsView(listings: ranked, loading: loading, refresh: refresh, search: searcher)
    //@endif
        }

        /// The app's search, its answers ranked as the list ranks them.
        private var searcher: (@MainActor (String) async throws -> [CatalogEntry])? {
            guard let search else { return nil }
            return { query in
                let found = try await search(query)
                return found.enumerated().map { CatalogEntry(listing: $0.element, place: $0.offset + 1) }
            }
        }

    //@endif
    //@if screen.groupings
        private var groupingsTab: some View {
            GroupingsView(groupings: sets, entries: ranked + own, active: active, select: select, delete: delete,
                          new: { form = CatalogForm(grouping: nil, members: []) },
                          edit: { grouping in form = editing(grouping) })
        }

        /// The form for a grouping, its members found among everything listed and mine.
        private func editing(_ grouping: CatalogSet) -> CatalogForm {
            let everything = ranked + own
            let members = grouping.members.map { key in
                everything.first { CatalogValue.matches(key, $0) } ?? CatalogEntry(id: key, name: key)
            }
            return CatalogForm(grouping: grouping, members: members)
        }
    //@endif
    }

    /// The tabs under the bar.
    enum CatalogTab: Hashable {
        case browse, groupings
    }

    /// The grouping form a tab has up: a new grouping and what it starts with, or one being changed.
    struct CatalogForm: Identifiable {
        let id = UUID()
        /// The grouping being changed; nil for a new one.
        var grouping: CatalogSet?
        var members: [CatalogEntry]
    }

    #Preview {
        NavigationStack {
            CatalogView(listings: CatalogSamples.listings, mine: CatalogSamples.collections, groupings: CatalogSamples.groupings,
                        select: { _ in }, save: { _ in }, delete: { _ in }, close: {})
        }
    }
    """##
}
