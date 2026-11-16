//  WHAT: `CatalogParts.swift`: every look the views repeat, each written once: the text roles, the bar's title, the
//        round close button, a tag capsule and its row, the name field, a document's badge, the empty tab, the button
//        that makes a grouping and the row that adds a collection; and the taps, placements and pull to refresh.

extension Template {
    static let catalogParts = ##"""
    import SwiftUI
    #if canImport(UIKit)
    import UIKit
    #endif

    // MARK: Type

    /// The five text roles: a font, and the ink at the role's opacity.
    enum CatalogText {
        case title, body, body2, note, note2

        var font: Font {
            switch self {
            case .title: return CatalogLook.title
            case .body: return CatalogLook.body
            case .body2: return CatalogLook.body2
            case .note: return CatalogLook.note
            case .note2: return CatalogLook.note2
            }
        }

        var opacity: Double {
            switch self {
            case .title, .body, .body2: return 0.75
            case .note, .note2: return 0.6
            }
        }
    }

    extension View {
        /// Text in one of the roles.
        func catalogText(_ role: CatalogText) -> some View {
            foregroundStyle(CatalogLook.ink.opacity(role.opacity)).font(role.font)
        }

        /// The bar's title: inline, centred, in the title role.
        func catalogTitle(_ title: String) -> some View {
            catalogInline()
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text(verbatim: title)
                            .catalogText(.title)
                    }
                }
        }

        @ViewBuilder
        func catalogInline() -> some View {
            #if os(iOS)
            navigationBarTitleDisplayMode(.inline)
            #else
            self
            #endif
        }

        /// An inset grouped list on the iPhone, an inset one on the Mac.
        @ViewBuilder
        func catalogInsetGrouped() -> some View {
            #if os(iOS)
            listStyle(.insetGrouped)
            #else
            listStyle(.inset)
            #endif
        }

        /// A field that writes no capitals of its own.
        @ViewBuilder
        func catalogNoCapitals() -> some View {
            #if os(iOS)
            textInputAutocapitalization(.never)
            #else
            self
            #endif
        }

        /// Pull to refresh, with a light tap, when the app can refresh; nothing to pull when it cannot.
        @ViewBuilder
        func catalogRefreshable(_ refresh: (@MainActor () async throws -> Void)?) -> some View {
            if let refresh {
                self.refreshable { await CatalogHaptic.refreshing(refresh) }
            } else {
                self
            }
        }

        /// The name field's look: padded, medium, on a diagonal gradient into `end`, outlined in it, a soft shadow.
        func catalogField(start: Color, end: Color) -> some View {
            padding()
                .fontWeight(.medium)
                .background(LinearGradient(colors: [start, end.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .clipShape(.rect(cornerRadius: {{n:fieldRadius}}))
                .shadow(color: CatalogLook.fieldShadow, radius: 2, x: 0, y: 4)
                .overlay {
                    RoundedRectangle(cornerRadius: {{n:fieldRadius}})
                        .stroke(end.gradient.opacity(0.5), lineWidth: 4)
                        .allowsHitTesting(false)
                }
        }

        /// A document's round badge: a soft diagonal gradient of the card colour, a faint rim, a subtle shadow.
        func catalogBadge() -> some View {
            background(
                LinearGradient(colors: [CatalogLook.card, CatalogLook.card.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .overlay {
                        Circle()
                            .strokeBorder(.quaternary, lineWidth: 1)
                    }
            )
            .clipShape(.circle)
            .shadow(color: CatalogLook.badgeShadow, radius: 2, x: 0, y: 2)
        }
    }

    // MARK: Taps and places

    /// The taps the views give on the iPhone; nothing elsewhere.
    enum CatalogHaptic {
        @MainActor static func light() { impact(.light) }
        @MainActor static func soft() { impact(.soft) }
        @MainActor static func medium() { impact(.medium) }

        @MainActor static func success() {
            #if os(iOS)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
        }

        /// A light tap, then the app's refresh.
        @MainActor static func refreshing(_ refresh: @MainActor () async throws -> Void) async {
            light()
            try? await refresh()
        }

        #if os(iOS)
        @MainActor private static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        }
        #else
        private enum Style { case light, soft, medium }

        @MainActor private static func impact(_ style: Style) {}
        #endif
    }

    /// Where the bar's buttons go: either end on the iPhone, the window's toolbar on the Mac.
    enum CatalogPlacement {
        static var leading: ToolbarItemPlacement {
            #if os(iOS)
            return .topBarLeading
            #else
            return .navigation
            #endif
        }

        static var trailing: ToolbarItemPlacement {
            #if os(iOS)
            return .topBarTrailing
            #else
            return .primaryAction
            #endif
        }
    }

    // MARK: Looks

    /// The round close button in a sheet's bar: an x in the tint, drawn in a glass circle by the bar on iOS 26.
    struct CatalogCloseButton: View {
        let action: @MainActor () -> Void

        var body: some View {
            Button({{s:close}}, systemImage: {{sym:close}}) {
                CatalogHaptic.light()
                action()
            }
            .imageScale(.large)
            .labelStyle(.iconOnly)
        }
    }

    /// A tag as the cards and the ranking draw it: a small capsule in the accent.
    struct CatalogTag: View {
        let text: String

        var body: some View {
            Text(verbatim: text)
                .font(CatalogLook.font(11, .light))
                .padding(.horizontal, CatalogLook.layer2)
                .padding(.vertical, 2)
                .background(CatalogLook.accent.opacity(0.10))
                .foregroundStyle(CatalogLook.accent.opacity(0.8))
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(CatalogLook.accent.opacity(0.2), lineWidth: 1))
        }
    }

    /// Tags in a row that scrolls sideways.
    struct CatalogTagRow: View {
        let tags: [String]

        var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: CatalogLook.layer1) {
                    ForEach(Array(tags.enumerated()), id: \.offset) { _, tag in
                        CatalogTag(text: tag)
                    }
                }
            }
        }
    }

    /// An empty tab: a large faint symbol, a title and a line, and under them what the tab can do instead.
    struct CatalogEmptyTab<Action: View>: View {
        let symbol: String
        let title: String
        let message: String
        @ViewBuilder let action: Action

        var body: some View {
            VStack(spacing: CatalogLook.layer4) {
                Spacer()
                VStack(spacing: CatalogLook.layer3) {
                    Image(systemName: symbol)
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(CatalogLook.ink.opacity(0.3))
                    Text(verbatim: title)
                        .font(CatalogLook.font(20, .light))
                        .foregroundStyle(CatalogLook.ink.opacity(0.7))
                    Text(verbatim: message)
                        .font(CatalogLook.font(15, .light))
                        .foregroundStyle(CatalogLook.ink.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, CatalogLook.layer7)
                }
                action
                    .padding(.horizontal, CatalogLook.layer4)
                Spacer()
            }
        }
    }

    /// The button that makes a grouping: a small plus and its words, centred, in the accent.
    struct CatalogNewButton: View {
        let title: String
        let action: @MainActor () -> Void

        var body: some View {
            Button {
                CatalogHaptic.light()
                action()
            } label: {
                HStack(spacing: CatalogLook.layer2) {
                    Image(systemName: {{sym:groupings.new}})
                        .font(.system(size: 13, weight: .light))
                    Text(verbatim: title)
                        .font(CatalogLook.font(15, .light))
                }
                .foregroundStyle(CatalogLook.accent)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    /// A row that adds a collection: its name over its summary, a plus in a circle trailing.
    struct CatalogAddRow: View {
        let name: String
        var summary: String? = nil
        let action: @MainActor () -> Void

        var body: some View {
            Button {
                CatalogHaptic.light()
                action()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: CatalogLook.layer1) {
                        Text(verbatim: name)
                            .catalogText(.body2)
                            .lineLimit(1)
                        if let summary {
                            Text(verbatim: summary)
                                .catalogText(.note2)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                    Image(systemName: {{sym:browse.add}})
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(CatalogLook.accent)
                }
            }
            .buttonStyle(.plain)
        }
    }

    #Preview {
        VStack(alignment: .leading, spacing: 24) {
            Text(verbatim: "Title").catalogText(.title)
            CatalogTagRow(tags: ["birds", "walks", "weather"])
            CatalogAddRow(name: "Field Notes", summary: "Birds, weather and long walks.") {}
            CatalogNewButton(title: "New group") {}
            CatalogCloseButton {}
        }
        .padding(20)
    }
    """##
}
