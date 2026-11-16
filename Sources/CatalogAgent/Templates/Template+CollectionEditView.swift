//  WHAT: `CollectionEditView.swift`: a collection's edit form in a tall sheet whose background runs from the panel
//        colour into the collection's: the name field and the colour button, the description, the tags.

extension Template {
    static let collectionEditView = ##"""
    import SwiftUI

    /// A collection's name, colour, description and tags. "Save" hands the app a draft; while a field has focus the
    /// bar's trailing button drops the keyboard instead.
    struct CollectionEditView: View {
        let entry: CatalogEntry
        let save: (@MainActor (CatalogCollectionDraft) async throws -> Void)?

        private enum Field: Hashable { case name, summary }

        @Environment(\.dismiss) private var dismiss
        @State private var name: String
        @State private var summary: String
        @State private var tags: [String]
        @State private var color: Color
        @State private var colorName: String
        @State private var choosing = false
        @State private var failed = false
        @FocusState private var focused: Field?

        init(entry: CatalogEntry, save: (@MainActor (CatalogCollectionDraft) async throws -> Void)?) {
            self.entry = entry
            self.save = save
            _name = State(initialValue: entry.name)
            _summary = State(initialValue: entry.summary ?? "")
            _tags = State(initialValue: entry.tags)
            _color = State(initialValue: entry.color ?? CatalogLook.accent)
            _colorName = State(initialValue: entry.colorName ?? "")
        }

        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: CatalogLook.layer5) {
                        HStack {
                            TextField({{s:edit.name}}, text: $name)
                                .catalogField(start: CatalogLook.card.opacity(0.8), end: color.opacity(0.8))
                                .focused($focused, equals: .name)
                            colorButton
                                .padding(.leading, CatalogLook.layer2)
                        }
                        VStack(alignment: .leading, spacing: CatalogLook.layer2) {
                            Text({{s:edit.description.header}})
                                .catalogText(.note2)
                                .padding(.leading, CatalogLook.layer1)
                            TextField({{s:edit.description}}, text: $summary, axis: .vertical)
                                .font(CatalogLook.font(16, .light))
                                .lineLimit(3...6)
                                .focused($focused, equals: .summary)
                                .padding()
                                .background(LinearGradient(colors: [CatalogLook.card.opacity(0.8), color.opacity(0.4)],
                                                           startPoint: .topLeading, endPoint: .bottomTrailing))
                                .clipShape(RoundedRectangle(cornerRadius: {{n:fieldRadius}}))
                                .overlay {
                                    RoundedRectangle(cornerRadius: {{n:fieldRadius}})
                                        .stroke(color.gradient.opacity(0.35), lineWidth: 2)
                                }
                        }
                        VStack(alignment: .leading, spacing: CatalogLook.layer2) {
                            Text({{s:edit.tags.header}})
                                .catalogText(.note2)
                                .padding(.leading, CatalogLook.layer1)
                            CatalogTagsEditor(tags: $tags)
                                .padding(CatalogLook.layer3)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(CatalogLook.card.opacity(0.6))
                                .clipShape(RoundedRectangle(cornerRadius: {{n:fieldRadius}}))
                                .overlay {
                                    RoundedRectangle(cornerRadius: {{n:fieldRadius}})
                                        .stroke(color.gradient.opacity(0.2), lineWidth: 2)
                                }
                        }
                    }
                    .padding()
                    .padding(.trailing)
                }
                .scrollDismissesKeyboard(.interactively)
                .catalogTitle({{s:edit.title}})
                .presentationDetents({{n:edit}})
                .toolbar {
                    ToolbarItem(placement: CatalogPlacement.leading) {
                        Button({{s:cancel}}) { dismiss() }
                    }
                    ToolbarItem(placement: CatalogPlacement.trailing) {
                        if focused != nil {
                            Button {
                                focused = nil
                            } label: {
                                Label({{s:edit.keyboard}}, systemImage: {{sym:edit.keyboard}})
                                    .labelStyle(.iconOnly)
                            }
                        } else {
                            Button({{s:save}}) {
                                Task { await commit() }
                            }
                            .disabled(save == nil)
                        }
                    }
                }
                .sheet(isPresented: $choosing) {
                    CatalogSwatchesView(color: $color, name: $colorName)
                }
                .alert({{s:edit.failed}}, isPresented: $failed) {
                    Button({{s:ok}}, role: .cancel) {}
                }
            }
            .presentationBackground(
                LinearGradient(
                    stops: [
                        .init(color: CatalogLook.panel, location: {{n:gradientStart}}),
                        .init(color: color, location: {{n:gradientStop}}),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .tint(CatalogLook.accent)
        }

        /// A circle of the colour's gradient holding a white palette: it opens the swatches.
        private var colorButton: some View {
            Button {
                choosing = true
            } label: {
                ZStack {
                    Circle()
                        .fill(color.gradient)
                        .frame(width: {{n:swatchSize}}, height: {{n:swatchSize}})
                        .shadow(color: color.opacity(0.45), radius: 6)
                        .overlay {
                            Circle()
                                .strokeBorder(.white.opacity(0.25), lineWidth: 1.5)
                        }
                    Image(systemName: {{sym:edit.color}})
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text({{s:edit.color}}))
        }

        private func commit() async {
            guard let save else { return }
            let draft = CatalogCollectionDraft(id: entry.id, name: name.trimmingCharacters(in: .whitespaces), summary: summary,
                                               tags: tags, color: colorName, online: entry.online ?? true)
            do {
                try await save(draft)
                CatalogHaptic.success()
                dismiss()
            } catch {
                failed = true
            }
        }
    }

    #Preview {
        CollectionEditView(entry: CatalogEntry(collection: CatalogSamples.collections[0]), save: { _ in })
    }
    """##
}
