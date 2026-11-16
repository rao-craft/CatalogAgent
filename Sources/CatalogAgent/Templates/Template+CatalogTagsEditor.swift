//  WHAT: `CatalogTagsEditor.swift`: tags as chips that wrap, edited through one alert, and the flow layout that
//        wraps them.

extension Template {
    static let catalogTagsEditor = ##"""
    import SwiftUI

    /// Tags as chips that wrap. A tap on a chip edits it and its x removes it; the last chip adds one. Adding and
    /// editing go through one alert.
    struct CatalogTagsEditor: View {
        @Binding var tags: [String]

        @State private var editing: Int?
        @State private var text = ""
        @State private var asking = false

        var body: some View {
            CatalogFlow(spacing: CatalogLook.layer2) {
                ForEach(Array(tags.enumerated()), id: \.offset) { index, tag in
                    chip(tag, at: index)
                }
                addButton
            }
            .alert(editing == nil ? {{s:edit.tag.add}} : {{s:edit.tag.edit}}, isPresented: $asking) {
                TextField({{s:edit.tag.field}}, text: $text)
                    .autocorrectionDisabled()
                Button({{s:save}}) { commit() }
                Button({{s:cancel}}, role: .cancel) { editing = nil }
            }
        }

        private func chip(_ tag: String, at index: Int) -> some View {
            HStack(spacing: CatalogLook.layer1) {
                Text(verbatim: tag)
                    .font(CatalogLook.font(13, .light))
                    .onTapGesture {
                        text = tag
                        editing = index
                        asking = true
                    }
                Button {
                    withAnimation({{m:tags}}) {
                        if tags.indices.contains(index) { tags.remove(at: index) }
                    }
                } label: {
                    Image(systemName: {{sym:edit.tag.remove}})
                        .font(.system(size: 9, weight: .medium))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text({{s:edit.tag.remove|tag=tag}}))
            }
            .padding(.horizontal, CatalogLook.layer2)
            .padding(.vertical, 5)
            .background(CatalogLook.accent.opacity(0.10))
            .foregroundStyle(CatalogLook.accent.opacity(0.85))
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(CatalogLook.accent.opacity(0.2), lineWidth: 1))
        }

        private var addButton: some View {
            Button {
                text = ""
                editing = nil
                asking = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: {{sym:edit.tag.add}})
                        .font(.system(size: 10, weight: .medium))
                    Text({{s:edit.tags.add}})
                        .font(CatalogLook.font(13, .light))
                }
                .padding(.horizontal, CatalogLook.layer2)
                .padding(.vertical, 5)
                .background(.ultraThinMaterial)
                .foregroundStyle(CatalogLook.ink.opacity(0.45))
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(CatalogLook.ink.opacity(0.12), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }

        private func commit() {
            let trimmed = text.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else {
                editing = nil
                return
            }
            withAnimation({{m:tags}}) {
                if let editing, tags.indices.contains(editing) {
                    tags[editing] = trimmed
                } else {
                    tags.append(trimmed)
                }
            }
            editing = nil
        }
    }

    /// Chips in rows: a row breaks where the next chip would not fit.
    struct CatalogFlow: Layout {
        var spacing: CGFloat = 8

        struct Cache {
            var sizes: [CGSize] = []
        }

        func makeCache(subviews: Subviews) -> Cache { Cache() }

        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
            guard !subviews.isEmpty else { return .zero }
            cache.sizes = subviews.map { $0.sizeThatFits(.unspecified) }
            return place(cache.sizes, in: proposal.width ?? .infinity).size
        }

        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
            let sizes = cache.sizes.count == subviews.count ? cache.sizes : subviews.map { $0.sizeThatFits(.unspecified) }
            let placed = place(sizes, in: bounds.width)
            for (index, origin) in placed.origins.enumerated() {
                subviews[index].place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y),
                                      proposal: ProposedViewSize(sizes[index]))
            }
        }

        private func place(_ sizes: [CGSize], in width: CGFloat) -> (size: CGSize, origins: [CGPoint]) {
            var origins: [CGPoint] = []
            var x: CGFloat = 0
            var y: CGFloat = 0
            var row: CGFloat = 0
            var widest: CGFloat = 0
            for size in sizes {
                if x + size.width > width, x > 0 {
                    y += row + spacing
                    x = 0
                    row = 0
                }
                origins.append(CGPoint(x: x, y: y))
                row = max(row, size.height)
                widest = max(widest, x + size.width)
                x += size.width + spacing
            }
            return (CGSize(width: widest, height: y + row), origins)
        }
    }

    #Preview {
        CatalogTagsEditor(tags: .constant(["astronomy", "mars", "nasa"]))
            .padding(20)
    }
    """##
}
