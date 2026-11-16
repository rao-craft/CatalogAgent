//  WHAT: `CollectionDetailView.swift`: one collection's documents in a sheet of its own: "<name> <Collection>" over
//        an inset grouped list of badges, titles and "Updated: …" lines; a row opens the document, a swipe deletes it.

extension Template {
    static let collectionDetailView = ##"""
    import SwiftUI

    /// One collection's documents, newest first, in a sheet over the cards. A row opens the app's page for the
    /// document (or its title and date when the app gives none); a swipe deletes it when the app can.
    struct CollectionDetailView: View {
        let entry: CatalogEntry
        let documents: [CatalogDoc]
        var delete: (@MainActor (String) async throws -> Void)? = nil
        var page: (@MainActor (String) -> AnyView?)? = nil

        @Environment(\.dismiss) private var dismiss
        @State private var removed: Set<String> = []

        private var shown: [CatalogDoc] { documents.filter { !removed.contains($0.id) } }

        var body: some View {
            NavigationStack {
                VStack {
                    List {
                        ForEach(shown) { document in
                            NavigationLink {
                                destination(document)
                            } label: {
                                CatalogDocumentRow(document: document)
                            }
                        }
                        .onDelete { offsets in remove(offsets) }
                        .deleteDisabled(delete == nil)
                    }
                    .catalogInsetGrouped()
                    .contentMargins(.vertical, CatalogLook.layer1, for: .scrollContent)
                }
                .catalogTitle({{s:detail.title|name=entry.name}})
                .toolbar {
                    ToolbarItem(placement: CatalogPlacement.trailing) {
                        CatalogCloseButton { dismiss() }
                    }
                }
            }
            .presentationDragIndicator(.visible)
            .presentationBackground(.regularMaterial)
            .presentationDetents({{n:detail}})
            .tint(CatalogLook.accent)
        }

        @ViewBuilder
        private func destination(_ document: CatalogDoc) -> some View {
            if let view = page?(document.id) {
                view
            } else {
                CatalogDocumentPage(document: document)
            }
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

    /// A document's row: a round badge with the document symbol, its title over when it was updated.
    struct CatalogDocumentRow: View {
        let document: CatalogDoc

        var body: some View {
            VStack(alignment: .leading) {
                HStack(spacing: CatalogLook.layer4) {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 36, height: 36)
                        .overlay {
                            Image(systemName: {{sym:document}})
                                .foregroundStyle(CatalogLook.ink.opacity(0.8).gradient)
                                .offset(x: 0.5, y: 0)
                        }
                        .catalogBadge()
                    VStack(alignment: .leading) {
                        Text(verbatim: document.title)
                            .lineLimit(1)
                            .foregroundStyle(CatalogLook.ink)
                            .fontWeight(.medium)
                        if let updated = document.updated {
                            VStack(alignment: .leading) {
                                Text({{s:detail.updated|date=CatalogValue.rowDate(updated)}})
                                    .lineLimit(1)
                                    .foregroundStyle(.secondary)
                                    .font(.caption2)
                                    .padding(.bottom, 1)
                            }
                        }
                    }
                }
            }
        }
    }

    /// A document the app gives no page for: its title and when it was updated.
    struct CatalogDocumentPage: View {
        let document: CatalogDoc

        var body: some View {
            VStack(alignment: .leading, spacing: CatalogLook.layer2) {
                Text(verbatim: document.title)
                    .catalogText(.title)
                if let updated = document.updated {
                    Text({{s:detail.updated|date=CatalogValue.rowDate(updated)}})
                        .catalogText(.note2)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(CatalogLook.layer4)
        }
    }

    #Preview {
        CollectionDetailView(entry: CatalogEntry(collection: CatalogSamples.collections[0]),
                             documents: CatalogSamples.documents.map { CatalogDoc(document: $0) }, delete: { _ in })
    }
    """##
}
