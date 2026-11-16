//  WHAT: `ListingsView.swift`: the browse tab: a search row and a divider over the ranking, the search's answers in
//        the same rows, the system's view for a search with no answer, and an empty tab.

extension Template {
    static let listingsView = ##"""
    import SwiftUI

    /// Others' collections: a search row over the ranking. Return searches (the app's search when it gives one, the
    /// names, summaries and tags otherwise); emptying the field brings the ranking back.
    struct ListingsView: View {
        let listings: [CatalogEntry]
        /// The app's first refresh is under way: a spinner rather than the empty tab.
        var loading = false
        var refresh: (@MainActor () async throws -> Void)? = nil
        var search: (@MainActor (String) async throws -> [CatalogEntry])? = nil
        var add: (@MainActor (CatalogEntry) -> Void)? = nil
        var new: (@MainActor () -> Void)? = nil

        @State private var query = ""
        @State private var results: [CatalogEntry]?
        @State private var searching = false

        var body: some View {
            VStack(spacing: 0) {
                searchRow
                Divider()
                if let results {
                    found(results)
                } else {
                    ranking
                }
            }
        }

        private var searchRow: some View {
            HStack(spacing: CatalogLook.layer3) {
                Image(systemName: {{sym:browse.search}})
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(CatalogLook.ink.opacity(0.35))
                TextField({{s:browse.search}}, text: $query)
                    .font(CatalogLook.font(16, .light))
                    .autocorrectionDisabled()
                    .catalogNoCapitals()
                    .submitLabel(.search)
                    .onSubmit { Task { await find() } }
                    .onChange(of: query) { _, now in
                        if now.isEmpty { results = nil }
                    }
                if !query.isEmpty {
                    Button {
                        query = ""
                        results = nil
                    } label: {
                        Image(systemName: {{sym:browse.clear}})
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(CatalogLook.ink.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text({{s:browse.clear}}))
                }
            }
            .padding(.horizontal, CatalogLook.layer4)
            .padding(.vertical, CatalogLook.layer3)
            .background(CatalogLook.background)
        }

        @ViewBuilder
        private var ranking: some View {
            if listings.isEmpty, loading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if listings.isEmpty {
                CatalogEmptyTab(symbol: {{sym:browse.empty}}, title: {{s:browse.empty.title}}, message: {{s:browse.empty.message}}) {
                    if let new {
                        CatalogNewButton(title: {{s:groupings.new}}, action: new)
                    }
                }
            } else {
                List {
                    ForEach(listings) { listing in
                        ListingRow(entry: listing, add: add)
                    }
                }
                .listStyle(.plain)
                .catalogRefreshable(refresh)
            }
        }

        @ViewBuilder
        private func found(_ results: [CatalogEntry]) -> some View {
            if searching {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if results.isEmpty {
                ContentUnavailableView.search(text: query)
            } else {
                List(results) { listing in
                    ListingRow(entry: listing, add: add)
                }
                .listStyle(.plain)
            }
        }

        private func find() async {
            let text = query.trimmingCharacters(in: .whitespaces)
            guard !text.isEmpty else { return }
            if let search {
                searching = true
                results = []
                results = (try? await search(text)) ?? []
                searching = false
            } else {
                let needle = text.lowercased()
                results = listings.filter { listing in
                    listing.name.lowercased().contains(needle)
                        || (listing.summary ?? "").lowercased().contains(needle)
                        || listing.tags.contains { $0.lowercased().contains(needle) }
                }
            }
        }
    }

    #Preview {
        ListingsView(listings: CatalogSamples.listings.enumerated().map { CatalogEntry(listing: $0.element, place: $0.offset + 1) },
                     add: { _ in }, new: {})
    }
    """##
}
