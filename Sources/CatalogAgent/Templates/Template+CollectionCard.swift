//  WHAT: `CollectionCard.swift`: one collection as a card: a spine in its colour, the name and the online dot, the
//        summary, a hairline, the count and date over against the earnings, and the tags; pressed, it springs.

extension Template {
    static let collectionCard = ##"""
    import SwiftUI

    /// One of my collections as a card. A tap opens it; pressed, the card scales on its spring; as it appears the
    /// earnings rise in and the online dot starts to breathe.
    struct CollectionCard: View {
        let entry: CatalogEntry
        var open: (@MainActor () -> Void)? = nil

        @State private var pulsing = false
        @State private var shown = false

        var body: some View {
            Button {
                CatalogHaptic.soft()
                open?()
            } label: {
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill((entry.color ?? CatalogLook.accent).opacity(0.72))
                        .frame(width: 4)
                        .padding(.vertical, 16)
                        .padding(.leading, 14)
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .top) {
                            Text(verbatim: entry.name)
                                .font(CatalogLook.font(22))
                                .foregroundStyle(CatalogLook.ink.opacity(0.85))
                                .lineLimit(1)
                            Spacer()
                            if let online = entry.online {
                                CatalogPulsingDot(alive: online, pulsing: pulsing)
                            }
                        }
                        if let summary = entry.summary {
                            Text(verbatim: summary)
                                .catalogText(.note2)
                                .lineLimit(2)
                                .padding(.top, 4)
                        }
                        Rectangle()
                            .frame(height: 0.5)
                            .foregroundStyle(CatalogLook.ink.opacity(0.1))
                            .padding(.top, 10)
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 5) {
                                    Text(verbatim: String(entry.count ?? 0))
                                        .font(CatalogLook.font(16, .medium))
                                        .foregroundStyle(CatalogLook.ink.opacity(0.75))
                                    Text(verbatim: entry.count == 1 ? {{s:card.documents.one}} : {{s:card.documents.other}})
                                        .font(CatalogLook.font(14, .light))
                                        .foregroundStyle(CatalogLook.ink.opacity(0.45))
                                }
                                if let updated = entry.updated {
                                    Text(verbatim: CatalogValue.cardDate(updated))
                                        .font(CatalogLook.font(12, .light))
                                        .foregroundStyle(CatalogLook.ink.opacity(0.33))
                                }
                            }
                            Spacer()
                            if let earnings = entry.earnings {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(verbatim: CatalogValue.amount(earnings))
                                        .font(CatalogLook.font(20, .light))
                                        .foregroundStyle(CatalogLook.positive.opacity(0.82))
                                        .opacity(shown ? 1 : 0)
                                        .offset(y: shown ? 0 : {{n:earningsRise}})
                                    Text({{s:card.earnings}})
                                        .font(CatalogLook.font(11, .light))
                                        .foregroundStyle(CatalogLook.ink.opacity(0.33))
                                }
                                .animation({{m:earnings}}, value: shown)
                            }
                        }
                        .padding(.top, 10)
                        if !entry.tags.isEmpty {
                            CatalogTagRow(tags: entry.tags)
                                .padding(.top, 6)
                        }
                    }
                    .padding(.leading, 12)
                    .padding(.trailing, 14)
                    .padding(.vertical, 14)
                }
            }
            .buttonStyle(CatalogCardStyle())
            .onAppear {
                pulsing = true
                shown = true
            }
        }
    }

    /// The online dot: a small dot in a halo that breathes while the collection is online.
    struct CatalogPulsingDot: View {
        let alive: Bool
        let pulsing: Bool

        var body: some View {
            ZStack {
                Circle()
                    .fill(alive ? CatalogLook.positive.opacity(0.22) : CatalogLook.inactive.opacity(0.12))
                    .frame(width: 20, height: 20)
                    .scaleEffect(pulsing ? {{n:pulseScale}} : 1.0)
                    .animation(alive ? {{m:pulse}} : .default, value: pulsing)
                Circle()
                    .fill(alive ? CatalogLook.positive : CatalogLook.inactive.opacity(0.38))
                    .frame(width: 8, height: 8)
            }
            .accessibilityElement()
            .accessibilityLabel(alive ? Text({{s:card.online}}) : Text({{s:card.offline}}))
        }
    }

    /// The card's surface: the card colour, rounded, a thin dark outline, a soft shadow, and a spring when pressed.
    struct CatalogCardStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(CatalogLook.card)
                .clipShape(.rect(cornerRadius: {{n:cardRadius}}))
                .overlay {
                    RoundedRectangle(cornerRadius: {{n:cardRadius}})
                        .stroke(Color.black.gradient.opacity(0.35), lineWidth: 1)
                }
                .shadow(color: CatalogLook.cardShadow, radius: 2, x: 0, y: 4)
                .scaleEffect(configuration.isPressed ? {{n:pressScale}} : 1.0)
                .animation({{m:press}}, value: configuration.isPressed)
        }
    }

    #Preview {
        VStack(spacing: 14) {
            ForEach(CatalogSamples.collections.map { CatalogEntry(collection: $0) }) { entry in
                CollectionCard(entry: entry)
            }
        }
        .padding(20)
    }
    """##
}
