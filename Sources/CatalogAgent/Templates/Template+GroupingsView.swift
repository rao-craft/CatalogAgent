//  WHAT: `GroupingsView.swift`: the groupings tab: the active grouping's banner, an inset grouped list of groupings
//        (name, count, members joined by a separator, a pencil and a circle), the button that makes one, and an empty
//        tab.

extension Template {
    static let groupingsView = ##"""
    import SwiftUI

    /// Named sets of collections. A row or its circle makes a grouping the active one, or no longer; a swipe deletes
    /// one; its pencil opens it in the form.
    struct GroupingsView: View {
        let groupings: [CatalogSet]
        /// Everything a member's key may name, for the names a row joins.
        let entries: [CatalogEntry]
        var active: String? = nil
        var select: (@MainActor (String?) async throws -> Void)? = nil
        var delete: (@MainActor (String) async throws -> Void)? = nil
        var new: (@MainActor () -> Void)? = nil
        var edit: (@MainActor (CatalogSet) -> Void)? = nil

        @State private var removed: Set<String> = []

        private var shown: [CatalogSet] { groupings.filter { !removed.contains($0.id) } }

        /// The active grouping, by its key or its name.
        private var current: CatalogSet? {
            guard let active else { return nil }
            return groupings.first { $0.id == active || $0.name.lowercased() == active.lowercased() }
        }

        var body: some View {
            VStack(spacing: 0) {
                if let current {
                    banner(current)
                    Divider()
                }
                if shown.isEmpty {
                    CatalogEmptyTab(symbol: {{sym:groupings.empty}}, title: {{s:groupings.empty.title}}, message: {{s:groupings.empty.message}}) {
                        if let new {
                            CatalogNewButton(title: {{s:groupings.new}}, action: new)
                        }
                    }
                } else {
                    List {
                        ForEach(shown) { grouping in
                            row(grouping)
                        }
                        .onDelete { offsets in remove(offsets) }
                        .deleteDisabled(delete == nil)
                        if let new {
                            Section {
                                CatalogNewButton(title: {{s:groupings.new}}, action: new)
                                    .listRowBackground(Color.clear)
                            }
                        }
                    }
                    .catalogInsetGrouped()
                }
            }
        }

        private func banner(_ grouping: CatalogSet) -> some View {
            HStack(spacing: CatalogLook.layer3) {
                Circle()
                    .fill(CatalogLook.accent)
                    .frame(width: 6, height: 6)
                VStack(alignment: .leading, spacing: 1) {
                    Text({{s:groupings.active}})
                        .font(CatalogLook.font(10, .light))
                        .foregroundStyle(CatalogLook.accent.opacity(0.7))
                    Text(verbatim: grouping.name)
                        .font(CatalogLook.font(15))
                        .foregroundStyle(CatalogLook.ink.opacity(0.75))
                }
                Spacer()
                if select != nil {
                    Button {
                        CatalogHaptic.light()
                        choose(nil)
                    } label: {
                        Text({{s:groupings.deselect}})
                            .font(CatalogLook.font(12, .light))
                            .foregroundStyle(CatalogLook.accent.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, CatalogLook.layer4)
            .padding(.vertical, CatalogLook.layer3)
            .background(CatalogLook.accent.opacity(0.06))
        }

        private func row(_ grouping: CatalogSet) -> some View {
            let isSelected = current?.id == grouping.id
            let names = grouping.members.map { key in entries.first { CatalogValue.matches(key, $0) }?.name ?? key }
            return HStack(spacing: CatalogLook.layer3) {
                VStack(alignment: .leading, spacing: CatalogLook.layer1) {
                    Text(verbatim: grouping.name)
                        .catalogText(.body2)
                        .lineLimit(1)
                    Text(verbatim: names.count == 1 ? {{s:groupings.count.one|count=names.count}} : {{s:groupings.count.other|count=names.count}})
                        .font(CatalogLook.font(13, .light))
                        .foregroundStyle(CatalogLook.ink.opacity(0.5))
                    if !names.isEmpty {
                        Text(verbatim: names.joined(separator: {{s:groupings.separator}}))
                            .font(CatalogLook.font(11, .light))
                            .foregroundStyle(CatalogLook.ink.opacity(0.35))
                            .lineLimit(1)
                    }
                }
                Spacer()
                if let edit {
                    Button {
                        CatalogHaptic.light()
                        edit(grouping)
                    } label: {
                        Image(systemName: {{sym:groupings.edit}})
                            .font(.system(size: 16, weight: .light))
                            .foregroundStyle(CatalogLook.accent)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text({{s:groupings.edit}}))
                }
                if select != nil {
                    Button {
                        CatalogHaptic.medium()
                        choose(isSelected ? nil : grouping.id)
                    } label: {
                        Image(systemName: isSelected ? {{sym:groupings.selected}} : {{sym:groupings.unselected}})
                            .font(.system(size: 18, weight: .light))
                            .foregroundStyle(isSelected ? CatalogLook.accent : CatalogLook.ink.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text({{s:groupings.select}}))
                }
            }
            .padding(.vertical, CatalogLook.layer1)
            .contentShape(Rectangle())
            .onTapGesture {
                guard select != nil else { return }
                CatalogHaptic.medium()
                choose(isSelected ? nil : grouping.id)
            }
        }

        /// Hands the app the grouping to make active, or nil for none.
        private func choose(_ key: String?) {
            guard let select else { return }
            Task { try? await select(key) }
        }

        private func remove(_ offsets: IndexSet) {
            let keys = offsets.map { shown[$0].id }
            removed.formUnion(keys)
            guard let delete else { return }
            Task {
                for key in keys { try? await delete(key) }
            }
        }
    }

    #Preview {
        GroupingsView(groupings: CatalogSamples.groupings.map { CatalogSet(grouping: $0) },
                      entries: CatalogSamples.collections.map { CatalogEntry(collection: $0) },
                      active: "outdoors", select: { _ in }, delete: { _ in }, new: {}, edit: { _ in })
    }
    """##
}
