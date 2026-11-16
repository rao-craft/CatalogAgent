//  WHAT: The end of `CatalogLook.swift`, after the roles `LookEmitter` writes: the helpers the roles' defaults and
//        hex colours use.

extension Template {
    static let catalogLookTail = ##"""

        // MARK: Helpers

        /// A size in the look's design: `CatalogLook.font(22)`, `CatalogLook.font(14, .light)`.
        static func font(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight, design: design)
        }

        /// `light` in light mode and `dark` in dark mode, each `0xRRGGBB` at its opacity.
        static func dynamic(light: UInt32, lightOpacity: Double = 1, dark: UInt32, darkOpacity: Double = 1) -> Color {
            #if os(iOS)
            return Color(uiColor: UIColor { traits in
                let isDark = traits.userInterfaceStyle == .dark
                let hex = isDark ? dark : light
                return UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                               blue: CGFloat(hex & 0xFF) / 255, alpha: CGFloat(isDark ? darkOpacity : lightOpacity))
            })
            #else
            return Color(nsColor: NSColor(name: nil) { appearance in
                let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                let hex = isDark ? dark : light
                return NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                               blue: CGFloat(hex & 0xFF) / 255, alpha: CGFloat(isDark ? darkOpacity : lightOpacity))
            })
            #endif
        }

        /// The colours the system defines, on either platform.
        enum SystemColor { case background, card, panel }

        static func system(_ role: SystemColor) -> Color {
            #if os(iOS)
            switch role {
            case .background: return Color(uiColor: .systemBackground)
            case .card: return Color(uiColor: .secondarySystemGroupedBackground)
            case .panel: return Color(uiColor: .systemBackground)
            }
            #else
            switch role {
            case .background: return Color(nsColor: .windowBackgroundColor)
            case .card: return Color(nsColor: .controlBackgroundColor)
            case .panel: return Color(nsColor: .windowBackgroundColor)
            }
            #endif
        }
    }
    """##
}
