//  WHAT: `AddToGroupingView.swift`: the sheet a listing's plus opens: the collection over a divider, then the
//        groupings to put it in or take it out of, a row that starts a grouping with it, and mine to start one with.

extension Template {
    static let addToGroupingView = ##"""
    import SwiftUI

    /// Puts a collection in a grouping or takes it out (a tap, and the sheet closes), or starts a new grouping holding
    /// it, alone or with one of mine.
    struct AddToGroupingView: View {
        let entry: CatalogEntry
        let groupings: [CatalogSet]
        let mine: [CatalogEntry]
        /// Everything a member's key may name, for the names a draft carries.
        let entries: [CatalogEntry]
        var save: (@MainActor (CatalogGroupingDraft) async throws -> Void)? = nil
        var new: (@MainActor ([CatalogEntry]) -> Void)? = nil

        @Environment(\.dismiss) private var dismiss

        var body: some View {
            NavigationStack {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: CatalogLook.layer1) {
                        Text(verbatim: entry.name)
                            .catalogText(.body)
                        if let summary = entry.summary {
                            Text(verbatim: summary)
                                .catalogText(.note2)
                        }
                    }
                    .padding(CatalogLook.layer4)
                    Divider()
                    List {
                        if !groupings.isEmpty {
                            Section {
                                ForEach(groupings) { grouping in
                                    existing(grouping)
                                }
                            } header: {
                                Text({{s:add.existing}})
                                    .catalogText(.note2)
                            }
                        }
                        if let new {
                            Section {
                                Button {
                                    CatalogHaptic.light()
                                    dismiss()
                                    new([entry])
                                } label: {
                                    HStack(spacing: CatalogLook.layer2) {
                                        Image(systemName: {{sym:browse.add}})
                                            .font(.system(size: 15, weight: .light))
                                        Text({{s:add.new}})
                                            .font(CatalogLook.font(16, .light))
                                    }
                                    .foregroundStyle(CatalogLook.accent)
                                }
                            }
                            let others = mine.filter { $0.id != entry.id }
                            if !others.isEmpty {
                                Section {
                                    ForEach(others) { other in
                                        CatalogAddRow(name: other.name, summary: other.summary) {
                                            dismiss()
                                            new([entry, other])
                                        }
                                    }
                                } header: {
                                    Text({{s:add.mine}})
                                        .catalogText(.note2)
                                }
                            }
                        }
                    }
                    .catalogInsetGrouped()
                }
                .catalogTitle({{s:add.title}})
                .toolbar {
                    ToolbarItem(placement: CatalogPlacement.trailing) {
                        Button({{s:done}}) { dismiss() }
                    }
                }
            }
            .tint(CatalogLook.accent)
        }

        private func existing(_ grouping: CatalogSet) -> some View {
            let isIn = grouping.members.contains { CatalogValue.matches($0, entry) }
            return Button {
                CatalogHaptic.light()
                toggle(grouping, isIn: isIn)
                dismiss()
            } label: {
                HStack {
                    Image(systemName: isIn ? {{sym:groupings.selected}} : {{sym:groupings.unselected}})
                        .foregroundStyle(isIn ? CatalogLook.accent : CatalogLook.ink.opacity(0.3))
                        .font(.system(size: 16, weight: .light))
                    Text(verbatim: grouping.name)
                        .font(CatalogLook.font(16, .light))
                        .foregroundStyle(CatalogLook.ink.opacity(0.75))
                    Spacer()
                    Text(verbatim: grouping.members.count == 1 ? {{s:groupings.count.one|count=grouping.members.count}} : {{s:groupings.count.other|count=grouping.members.count}})
                        .font(CatalogLook.font(13, .light))
                        .foregroundStyle(CatalogLook.ink.opacity(0.5))
                }
            }
            .buttonStyle(.plain)
            .disabled(save == nil)
        }

        private func toggle(_ grouping: CatalogSet, isIn: Bool) {
            guard let save else { return }
            var members = grouping.members
            if isIn {
                members.removeAll { CatalogValue.matches($0, entry) }
            } else {
                members.append(entry.id)
            }
            let names = members.map { key in entries.first { CatalogValue.matches(key, $0) }?.name ?? key }
            let draft = CatalogGroupingDraft(id: grouping.id, name: grouping.name, members: members, names: names)
            Task { try? await save(draft) }
        }
    }

    #Preview {
        AddToGroupingView(entry: CatalogEntry(listing: CatalogSamples.listings[0], place: 1),
                          groupings: CatalogSamples.groupings.map { CatalogSet(grouping: $0) },
                          mine: CatalogSamples.collections.map { CatalogEntry(collection: $0) },
                          entries: [], save: { _ in }, new: { _ in })
    }
    """##
}
