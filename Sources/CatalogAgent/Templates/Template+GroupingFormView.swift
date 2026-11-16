//  WHAT: `GroupingFormView.swift`: one form for a new grouping and for one being changed: its name, its members (a
//        swipe takes one out), and the collections to add: mine for a new one, the top of the ranking and mine for one
//        being changed.

extension Template {
    static let groupingFormView = ##"""
    import SwiftUI

    /// A grouping's form. A new one is made by "Create", disabled while its name is blank; one being changed keeps
    /// its changes with "Done". "Cancel" drops them.
    struct GroupingFormView: View {
        let grouping: CatalogSet?
        let listings: [CatalogEntry]
        let mine: [CatalogEntry]
        let save: (@MainActor (CatalogGroupingDraft) async throws -> Void)?
        let created: (@MainActor () -> Void)?

        @Environment(\.dismiss) private var dismiss
        @State private var name: String
        @State private var members: [CatalogEntry]

        init(grouping: CatalogSet?, members: [CatalogEntry], listings: [CatalogEntry], mine: [CatalogEntry],
             save: (@MainActor (CatalogGroupingDraft) async throws -> Void)? = nil,
             created: (@MainActor () -> Void)? = nil) {
            self.grouping = grouping
            self.listings = listings
            self.mine = mine
            self.save = save
            self.created = created
            _name = State(initialValue: grouping?.name ?? "")
            _members = State(initialValue: members)
        }

        private var isNew: Bool { grouping == nil }

        private var blank: Bool { name.trimmingCharacters(in: .whitespaces).isEmpty }

        private func isMember(_ entry: CatalogEntry) -> Bool {
            members.contains { $0.id == entry.id || $0.name.lowercased() == entry.name.lowercased() }
        }

        var body: some View {
            NavigationStack {
                Form {
                    Section {
                        TextField(isNew ? {{s:form.name}} : {{s:form.name.header}}, text: $name)
                            .font(CatalogLook.font(16, .light))
                    } header: {
                        Text({{s:form.name.header}})
                            .catalogText(.note2)
                    }
                    if !members.isEmpty {
                        Section {
                            ForEach(members) { member in
                                ListingRow(entry: CatalogEntry(id: member.id, name: member.name, summary: member.summary,
                                                               count: member.count, earnings: member.earnings, tags: member.tags))
                            }
                            .onDelete { offsets in members.remove(atOffsets: offsets) }
                        } header: {
                            Text({{s:form.members}})
                                .catalogText(.note2)
                        }
                    }
                    if isNew {
                        let available = mine.filter { !isMember($0) }
                        if !available.isEmpty {
                            Section {
                                ForEach(available) { entry in
                                    CatalogAddRow(name: entry.name, summary: entry.summary) {
                                        members.append(entry)
                                    }
                                }
                            } header: {
                                Text({{s:form.mine}})
                                    .catalogText(.note2)
                            }
                        }
                    } else {
                        Section {
                            if !listings.isEmpty {
                                Text({{s:form.public}})
                                    .catalogText(.note2)
                                ForEach(Array(listings.prefix({{n:publicLimit}}))) { entry in
                                    if !isMember(entry) {
                                        CatalogAddRow(name: entry.name) {
                                            members.append(entry)
                                        }
                                    }
                                }
                            }
                            if !mine.isEmpty {
                                Text({{s:form.yours}})
                                    .catalogText(.note2)
                                ForEach(mine) { entry in
                                    if !isMember(entry) {
                                        CatalogAddRow(name: entry.name) {
                                            members.append(entry)
                                        }
                                    }
                                }
                            }
                        } header: {
                            Text({{s:form.add}})
                                .catalogText(.note2)
                        }
                    }
                }
                .catalogTitle(isNew ? {{s:groupings.new}} : {{s:groupings.edit}})
                .toolbar {
                    ToolbarItem(placement: CatalogPlacement.leading) {
                        Button({{s:cancel}}) { dismiss() }
                    }
                    ToolbarItem(placement: CatalogPlacement.trailing) {
                        if isNew {
                            Button({{s:create}}) {
                                Task { await commit() }
                            }
                            .disabled(blank || save == nil)
                        } else {
                            Button({{s:done}}) {
                                Task { await commit() }
                            }
                        }
                    }
                }
            }
            .tint(CatalogLook.accent)
        }

        private func commit() async {
            let trimmed = name.trimmingCharacters(in: .whitespaces)
            if isNew {
                guard !trimmed.isEmpty else { return }
                CatalogHaptic.medium()
            }
            if let save {
                let draft = CatalogGroupingDraft(id: grouping?.id, name: trimmed.isEmpty ? (grouping?.name ?? "") : trimmed,
                                                 members: members.map(\.id), names: members.map(\.name))
                try? await save(draft)
            }
            if isNew { created?() }
            dismiss()
        }
    }

    #Preview {
        GroupingFormView(grouping: nil, members: [],
                         listings: CatalogSamples.listings.enumerated().map { CatalogEntry(listing: $0.element, place: $0.offset + 1) },
                         mine: CatalogSamples.collections.map { CatalogEntry(collection: $0) }, save: { _ in })
    }
    """##
}
