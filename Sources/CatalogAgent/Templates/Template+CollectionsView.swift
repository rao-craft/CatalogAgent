//  WHAT: `CollectionsView.swift`, the root of `mine`: my collections as cards in a plain list, the bar's two round
//        buttons, the long-press menu, and the detail and edit sheets it presents, opened by a launch state.

extension Template {
    static let collectionsView = ##"""
    import SwiftUI

    /// My collections as cards. A tap opens a collection's documents; a long press offers to edit it, take it off or
    /// online, or delete it. A page shows it with the app's own values and closures:
    ///
    ///     CollectionsView(collections: models.state.models, documents: library.state.notes,
    ///                     save: { try await models.update(id: $0.id, name: $0.name) })
    struct CollectionsView<Item: CollectionRepresentable, Document: DocumentRepresentable>: View {
        let collections: [Item]
        let documents: [Document]
        let leading: (@MainActor () -> Void)?
        let trailing: (@MainActor () -> Void)?
        let refresh: (@MainActor () async throws -> Void)?
        let save: (@MainActor (CatalogCollectionDraft) async throws -> Void)?
        let delete: (@MainActor (String) async throws -> Void)?
        let deleteDocument: (@MainActor (String) async throws -> Void)?
        let page: (@MainActor (Document) -> AnyView)?

        @State private var launch = CatalogLaunch.current
        @State private var detail: CatalogEntry?
        @State private var editing: CatalogEntry?
        @State private var deleting: CatalogEntry?
        @State private var confirming = false
        @State private var failed = false

        init(collections: [Item], documents: [Document],
             leading: (@MainActor () -> Void)? = nil, trailing: (@MainActor () -> Void)? = nil,
             refresh: (@MainActor () async throws -> Void)? = nil,
             save: (@MainActor (CatalogCollectionDraft) async throws -> Void)? = nil,
             delete: (@MainActor (String) async throws -> Void)? = nil,
             deleteDocument: (@MainActor (String) async throws -> Void)? = nil,
             page: (@MainActor (Document) -> AnyView)? = nil) {
            self.collections = collections
            self.documents = documents
            self.leading = leading
            self.trailing = trailing
            self.refresh = refresh
            self.save = save
            self.delete = delete
            self.deleteDocument = deleteDocument
            self.page = page
        }

        var body: some View {
            ZStack {
                if collections.isEmpty {
                    VStack(alignment: .center) {
                        Image(systemName: {{sym:mine.empty}})
                            .foregroundStyle(.secondary)
                            .font(.system(size: 50))
                            .padding(.bottom)
                        Text({{s:mine.empty.title}})
                            .catalogText(.title)
                            .bold()
                            .padding(.bottom, 3)
                        Text({{s:mine.empty.message}})
                            .catalogText(.note)
                            .italic()
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, CatalogLook.layer7)
                            .padding(.bottom, 15)
                    }
                    .padding(.bottom, 80)
                } else {
                    List {
                        ForEach(entries) { entry in
                            CollectionCard(entry: entry) { detail = entry }
                                .contextMenu { menu(entry) }
                                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: CatalogLook.layer3 + 2, trailing: 20))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .catalogRefreshable(refresh)
                    .contentMargins(.top, CatalogLook.layer2, for: .scrollContent)
                }
            }
            .catalogTitle({{s:mine.title}})
            .toolbar {
                if let leading {
                    ToolbarItem(placement: CatalogPlacement.leading) {
                        Button {
                            CatalogHaptic.light()
                            leading()
                        } label: {
                            Image(systemName: {{sym:mine.leading}})
                                .contentTransition(.symbolEffect(.replace))
                                .offset(y: -1)
                        }
                        .accessibilityLabel(Text({{s:mine.leading}}))
                    }
                }
                if let trailing {
                    ToolbarItem(placement: CatalogPlacement.trailing) {
                        Button {
                            CatalogHaptic.light()
                            trailing()
                        } label: {
                            Image(systemName: {{sym:mine.trailing}})
                                .contentTransition(.symbolEffect(.replace))
                                .font(.subheadline.bold())
                                .offset(y: -1)
                        }
                        .accessibilityLabel(Text({{s:mine.trailing}}))
                    }
                }
            }
            .sheet(item: $detail) { entry in
                CollectionDetailView(entry: entry, documents: documents(of: entry), delete: deleteDocument) { key in
                    pageView(key)
                }
            }
            .sheet(item: $editing) { entry in
                CollectionEditView(entry: entry, save: save)
            }
            .alert(Text({{s:delete.title|name=deletingName}}), isPresented: $confirming, presenting: deleting) { entry in
                Button({{s:menu.delete}}, role: .destructive) {
                    Task { await remove(entry) }
                }
                Button({{s:cancel}}, role: .cancel) {}
            } message: { _ in
                Text({{s:delete.message}})
            }
            .alert({{s:edit.failed}}, isPresented: $failed) {
                Button({{s:ok}}, role: .cancel) {}
            }
            .onChange(of: collections.map(\.catalogKey), initial: true) { _, _ in
                openLaunch()
            }
            .task {
                // Opened with nothing to show: the app's refresh, once.
                guard let refresh, collections.isEmpty || documents.isEmpty else { return }
                try? await refresh()
            }
            .tint(CatalogLook.accent)
        }

        // MARK: Values

        private var docs: [CatalogDoc] { documents.map { CatalogDoc(document: $0) } }

        /// Each collection as its card draws it: a count and a date from its documents when it says none.
        private var entries: [CatalogEntry] {
            let docs = self.docs
            return collections.map { collection in
                var entry = CatalogEntry(collection: collection)
                let own = docs.filter { CatalogValue.matches($0.collection, entry) }
                if entry.count == nil { entry.count = own.count }
                if entry.updated == nil { entry.updated = own.compactMap(\.updated).max() }
                return entry
            }
        }

        /// A collection's documents, newest first.
        private func documents(of entry: CatalogEntry) -> [CatalogDoc] {
            docs.filter { CatalogValue.matches($0.collection, entry) }
                .sorted { ($0.updated ?? .distantPast) > ($1.updated ?? .distantPast) }
        }

        private var deletingName: String { deleting?.name ?? "" }

        /// The app's page for a document, when it gives one.
        private func pageView(_ key: String) -> AnyView? {
            guard let page, let document = documents.first(where: { $0.catalogKey == key }) else { return nil }
            return page(document)
        }

        // MARK: The menu

        @ViewBuilder
        private func menu(_ entry: CatalogEntry) -> some View {
            if save != nil {
                Button {
                    editing = entry
                } label: {
                    Label({{s:menu.edit}}, systemImage: {{sym:menu.edit}})
                }
                if let online = entry.online {
                    Button {
                        Task { await flip(entry, online: !online) }
                    } label: {
                        if online {
                            Label({{s:menu.offline}}, systemImage: {{sym:menu.offline}})
                        } else {
                            Label({{s:menu.online}}, systemImage: {{sym:menu.online}})
                        }
                    }
                }
            }
            if delete != nil {
                Button(role: .destructive) {
                    deleting = entry
                    confirming = true
                } label: {
                    Label({{s:menu.delete}}, systemImage: {{sym:menu.delete}})
                }
            }
        }

        // MARK: Work

        private func flip(_ entry: CatalogEntry, online: Bool) async {
            guard let save else { return }
            var draft = CatalogCollectionDraft(entry)
            draft.online = online
            do {
                try await save(draft)
            } catch {
                failed = true
            }
        }

        private func remove(_ entry: CatalogEntry) async {
            guard let delete else { return }
            do {
                try await delete(entry.id)
            } catch {
                failed = true
            }
        }

        /// The launch's sheet, up at once and unanimated, once its collection has arrived.
        private func openLaunch() {
            guard let state = launch, let name = state.collection,
                  let entry = entries.first(where: { CatalogValue.matches(name, $0) }) else { return }
            launch = nil
            var unanimated = Transaction()
            unanimated.disablesAnimations = true
            withTransaction(unanimated) {
                if case .edit = state {
                    editing = entry
                } else {
                    detail = entry
                }
            }
        }
    }

    extension CollectionsView where Document == CatalogDocument {
        /// Collections with no documents of the app's.
        init(collections: [Item],
             leading: (@MainActor () -> Void)? = nil, trailing: (@MainActor () -> Void)? = nil,
             refresh: (@MainActor () async throws -> Void)? = nil,
             save: (@MainActor (CatalogCollectionDraft) async throws -> Void)? = nil,
             delete: (@MainActor (String) async throws -> Void)? = nil) {
            self.init(collections: collections, documents: [], leading: leading, trailing: trailing, refresh: refresh,
                      save: save, delete: delete)
        }
    }

    #Preview {
        NavigationStack {
            CollectionsView(collections: CatalogSamples.collections, documents: CatalogSamples.documents,
                            leading: {}, trailing: {}, save: { _ in }, delete: { _ in })
        }
    }
    """##
}
