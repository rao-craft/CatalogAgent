//  WHAT: `CatalogValue.swift`: every mapped field made the views' type, whatever the app declared it as, and the few
//        ways the views write a number, a date and a match.

extension Template {
    static let catalogValue = ##"""
    import Foundation
    import SwiftUI

    /// Reads the app's values as the catalog views show them. A conformance wraps every right side in one of these, so
    /// a field compiles whatever its type: a `Date` or an ISO string, a list of tags or one string with commas.
    enum CatalogValue {
        // MARK: Text

        static func text(_ value: String) -> String { value }
        static func text(_ value: String?) -> String { value ?? "" }
        static func text(_ value: Substring) -> String { String(value) }
        static func text(_ value: URL) -> String { value.absoluteString }
        static func text(_ value: URL?) -> String { value?.absoluteString ?? "" }
        static func text(_ value: UUID) -> String { value.uuidString }
        static func text(_ value: UUID?) -> String { value?.uuidString ?? "" }
        static func text<Number: BinaryInteger>(_ value: Number) -> String { String(value) }
        static func text<Number: BinaryInteger>(_ value: Number?) -> String { value.map { String($0) } ?? "" }

        static func optionalText(_ value: String?) -> String? {
            guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            return value
        }
        static func optionalText(_ value: Substring?) -> String? { optionalText(value.map { String($0) }) }
        static func optionalText(_ value: URL?) -> String? { value?.absoluteString }
        static func optionalText(_ value: UUID?) -> String? { value?.uuidString }
        static func optionalText<Number: BinaryInteger>(_ value: Number?) -> String? { value.map { String($0) } }

        // MARK: Ids

        static func id(_ value: String) -> String { value }
        static func id(_ value: String?) -> String { value ?? "" }
        static func id(_ value: Substring) -> String { String(value) }
        static func id(_ value: UUID) -> String { value.uuidString }
        static func id(_ value: URL) -> String { value.absoluteString }
        static func id<Number: BinaryInteger>(_ value: Number) -> String { String(value) }

        /// An `id` as the closures are handed it: as text.
        static func key<ID: Hashable>(_ id: ID) -> String {
            if let text = id as? String { return text }
            if let uuid = id as? UUID { return uuid.uuidString }
            return String(describing: id)
        }

        // MARK: Numbers

        static func optionalInt<Number: BinaryInteger>(_ value: Number?) -> Int? { value.map { Int(truncatingIfNeeded: $0) } }
        static func optionalInt(_ value: Double?) -> Int? { value.map { Int($0.rounded()) } }
        static func optionalInt(_ value: String?) -> Int? { value.flatMap { Int($0.trimmingCharacters(in: .whitespaces)) } }

        static func number<Number: BinaryInteger>(_ value: Number?) -> Double? { value.map { Double($0) } }
        static func number(_ value: Double?) -> Double? { value }
        static func number(_ value: Float?) -> Double? { value.map { Double($0) } }
        static func number(_ value: Decimal?) -> Double? { value.map { NSDecimalNumber(decimal: $0).doubleValue } }
        static func number(_ value: String?) -> Double? { value.flatMap { Double($0.trimmingCharacters(in: .whitespaces)) } }

        // MARK: Tags and keys

        static func tags(_ value: [String]) -> [String] {
            value.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        }
        static func tags(_ value: [String]?) -> [String] { tags(value ?? []) }
        static func tags(_ value: [Substring]) -> [String] { tags(value.map { String($0) }) }
        static func tags(_ value: Set<String>) -> [String] { tags(value.sorted()) }
        static func tags(_ value: String?) -> [String] { tags((value ?? "").components(separatedBy: ",")) }

        static func keys(_ value: [String]) -> [String] { tags(value) }
        static func keys(_ value: [String]?) -> [String] { tags(value ?? []) }
        static func keys(_ value: [UUID]) -> [String] { value.map(\.uuidString) }
        static func keys<Number: BinaryInteger>(_ value: [Number]) -> [String] { value.map { String($0) } }
        static func keys(_ value: Set<String>) -> [String] { tags(value.sorted()) }
        static func keys(_ value: String?) -> [String] { tags(value) }

        // MARK: Flags

        static func flag(_ value: Bool?) -> Bool? { value }
        static func flag<Number: BinaryInteger>(_ value: Number?) -> Bool? { value.map { $0 != 0 } }
        static func flag(_ value: String?) -> Bool? {
            guard let word = value?.trimmingCharacters(in: .whitespaces).lowercased() else { return nil }
            switch word {
            case "true", "yes", "1", "on", "online", "available", "live", "public": return true
            case "false", "no", "0", "off", "offline", "restricted", "hidden", "private": return false
            default: return nil
            }
        }

        // MARK: Colours

        static func color(_ value: Color?) -> Color? { value }
        static func color(_ value: String?) -> Color? { named(value) }
        static func colorName(_ value: String?) -> String? { optionalText(value) }
        static func colorName(_ value: Color?) -> String? { nil }

        /// A system colour by its name, or a colour by its hex: "brown", "#AE9060", "#AE9060CC".
        static func named(_ name: String?) -> Color? {
            guard let raw = name?.trimmingCharacters(in: .whitespaces).lowercased(), !raw.isEmpty else { return nil }
            switch raw {
            case "red": return .red
            case "orange": return .orange
            case "yellow": return .yellow
            case "green": return .green
            case "mint": return .mint
            case "teal": return .teal
            case "cyan": return .cyan
            case "blue": return .blue
            case "indigo": return .indigo
            case "purple": return .purple
            case "pink": return .pink
            case "brown": return .brown
            case "gray", "grey": return .gray
            case "black": return .black
            case "white": return .white
            default: break
            }
            let hex = raw.hasPrefix("#") ? String(raw.dropFirst()) : raw
            guard hex.count == 6 || hex.count == 8, let number = UInt64(hex, radix: 16) else { return nil }
            let rgb = hex.count == 8 ? number >> 8 : number
            let alpha = hex.count == 8 ? Double(number & 0xFF) / 255 : 1
            return Color(.sRGB, red: Double((rgb >> 16) & 0xFF) / 255, green: Double((rgb >> 8) & 0xFF) / 255,
                         blue: Double(rgb & 0xFF) / 255, opacity: alpha)
        }

        // MARK: Dates

        static func date(_ value: Date?) -> Date? { value }
        static func date(_ value: Double?) -> Date? { value.map { Date(timeIntervalSince1970: $0) } }
        static func date(_ value: Int?) -> Date? { value.map { Date(timeIntervalSince1970: TimeInterval($0)) } }
        static func date(_ value: String?) -> Date? {
            guard let value else { return nil }
            let formatter = ISO8601DateFormatter()
            if let date = formatter.date(from: value) { return date }
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: value) { return date }
            formatter.formatOptions = [.withFullDate]
            return formatter.date(from: value)
        }

        // MARK: What the views write

        /// A number at the call's decimals: "18.42".
        static func amount(_ value: Double) -> String { String(format: "%.{{n:decimals}}f", value) }

        /// The time zone every date is drawn in: the call's, in US English; nil draws in the device's zone and language.
        static let dateZone: TimeZone? = {{n:dateZone}}

        /// `date` in a date format, in US English and the call's zone: "November 12, 2026 · 9:05:00 AM".
        static func formatted(_ date: Date, _ format: String) -> String {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US")
            if let dateZone { formatter.timeZone = dateZone }
            formatter.dateFormat = format
            return formatter.string(from: date)
        }

        /// `date` in a date and a time style: in the call's zone and US English when it names one, else the device's.
        static func formatted(_ date: Date, date dateStyle: Date.FormatStyle.DateStyle, time timeStyle: Date.FormatStyle.TimeStyle) -> String {
            guard let dateZone else { return date.formatted(date: dateStyle, time: timeStyle) }
            let style = Date.FormatStyle(date: dateStyle, time: timeStyle, locale: Locale(identifier: "en_US"),
                                         calendar: Calendar(identifier: .gregorian), timeZone: dateZone)
            return date.formatted(style)
        }

        /// A card's date.
        static func cardDate(_ date: Date) -> String {
            {{date:card}}
        }

        /// A document row's date.
        static func rowDate(_ date: Date) -> String {
            {{date:row}}
        }

        /// Whether `key` names the entry: its key or its name, in any case.
        static func matches(_ key: String?, _ entry: CatalogEntry) -> Bool {
            guard let key = key?.trimmingCharacters(in: .whitespaces).lowercased(), !key.isEmpty else { return false }
            return key == entry.id.lowercased() || key == entry.name.lowercased()
        }
    }
    """##
}
