//  WHAT: `CatalogSwatchesView.swift`: the colour sheet: system colours as gradient circles in a grid, the chosen one
//        under a white check, the sheet's background running into it.

extension Template {
    static let catalogSwatchesView = ##"""
    import SwiftUI

    /// The colours a collection may take, as circles in a grid. "Done" keeps the chosen one; "Cancel" keeps the old.
    struct CatalogSwatchesView: View {
        @Binding var color: Color
        @Binding var name: String

        @Environment(\.dismiss) private var dismiss
        @State private var pending: CatalogSwatch?

        private let columns = Array(repeating: GridItem(.flexible()), count: {{n:swatchColumns}})

        init(color: Binding<Color>, name: Binding<String>) {
            _color = color
            _name = name
            _pending = State(initialValue: CatalogSwatch.all.first { $0.name == name.wrappedValue.lowercased() })
        }

        var body: some View {
            NavigationStack {
                LazyVGrid(columns: columns, spacing: CatalogLook.layer5) {
                    ForEach(CatalogSwatch.all) { swatch in
                        swatchButton(swatch)
                    }
                }
                .padding(CatalogLook.layer5)
                .padding(.top, CatalogLook.layer3)
                .catalogTitle({{s:edit.color}})
                .toolbar {
                    ToolbarItem(placement: CatalogPlacement.leading) {
                        Button({{s:cancel}}) { dismiss() }
                    }
                    ToolbarItem(placement: CatalogPlacement.trailing) {
                        Button({{s:done}}) {
                            if let pending {
                                color = pending.color
                                name = pending.name
                            }
                            dismiss()
                        }
                    }
                }
            }
            .presentationDetents({{n:color}})
            .presentationDragIndicator(.visible)
            .presentationCornerRadius({{n:colorRadius}})
            .presentationBackground(
                LinearGradient(
                    stops: [
                        .init(color: CatalogLook.panel, location: {{n:gradientStart}}),
                        .init(color: pending?.color ?? color, location: {{n:gradientStop}}),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .tint(CatalogLook.accent)
        }

        private func swatchButton(_ swatch: CatalogSwatch) -> some View {
            let selected = pending == swatch
            return Button {
                withAnimation({{m:tags}}) {
                    pending = swatch
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(swatch.color.gradient)
                        .frame(width: {{n:swatchSize}}, height: {{n:swatchSize}})
                        .shadow(color: swatch.color.opacity(selected ? 0.55 : 0.2), radius: selected ? 10 : 3)
                        .overlay {
                            Circle()
                                .strokeBorder(.white.opacity(selected ? 0.5 : 0.15), lineWidth: selected ? 2 : 1)
                        }
                    if selected {
                        Image(systemName: {{sym:swatch.check}})
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .buttonStyle(.plain)
            .animation({{m:tags}}, value: selected)
            .accessibilityLabel(Text(verbatim: swatch.name))
        }
    }

    #Preview {
        CatalogSwatchesView(color: .constant(.brown), name: .constant("brown"))
    }
    """##
}
