//  WHAT: `ListingRow.swift`: someone else's collection in the ranking: its name, owner, summary and tags leading,
//        its rank, credits and count trailing, then the plus that adds it to a grouping.

extension Template {
    static let listingRow = ##"""
    import SwiftUI

    /// Someone else's collection as the ranking draws it. The plus is drawn only when the app can add it somewhere.
    struct ListingRow: View {
        let entry: CatalogEntry
        var add: (@MainActor (CatalogEntry) -> Void)? = nil

        var body: some View {
            HStack(spacing: CatalogLook.layer3) {
                VStack(alignment: .leading, spacing: CatalogLook.layer1) {
                    Text(verbatim: entry.name)
                        .catalogText(.body2)
                        .lineLimit(1)
                    if let owner = entry.owner, !owner.isEmpty {
                        Text({{s:browse.owner|owner=owner}})
                            .font(CatalogLook.font(12, .light))
                            .foregroundStyle(CatalogLook.ink.opacity(0.6))
                            .lineLimit(1)
                    }
                    if let summary = entry.summary {
                        Text(verbatim: summary)
                            .catalogText(.note2)
                            .lineLimit(2)
                    }
                    if !entry.tags.isEmpty {
                        CatalogTagRow(tags: entry.tags)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: CatalogLook.layer1) {
                    if let rank = entry.rank {
                        Text({{s:browse.rank|rank=rank}})
                            .font(CatalogLook.font(13))
                            .foregroundStyle(rank <= {{n:topRanks}} ? CatalogLook.accent : CatalogLook.ink.opacity(0.5))
                    }
                    if let credits = entry.earnings, credits > 0 {
                        Text({{s:browse.credits|credits=CatalogValue.amount(credits)}})
                            .font(CatalogLook.font(12, .light))
                            .foregroundStyle(CatalogLook.ink.opacity(0.5))
                    }
                    if let count = entry.count {
                        Text(verbatim: count == 1 ? {{s:browse.count.one|count=count}} : {{s:browse.count.other|count=count}})
                            .font(CatalogLook.font(12, .light))
                            .foregroundStyle(CatalogLook.ink.opacity(0.35))
                    }
                }
                if let add {
                    Button {
                        CatalogHaptic.light()
                        add(entry)
                    } label: {
                        Image(systemName: {{sym:browse.add}})
                            .font(.system(size: 18, weight: .light))
                            .foregroundStyle(CatalogLook.accent)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text({{s:add.title}}))
                }
            }
            .padding(.vertical, CatalogLook.layer1)
        }
    }

    #Preview {
        List {
            ForEach(CatalogSamples.listings.enumerated().map { CatalogEntry(listing: $0.element, place: $0.offset + 1) }) { entry in
                ListingRow(entry: entry, add: { _ in })
            }
        }
        .listStyle(.plain)
    }
    """##
}
