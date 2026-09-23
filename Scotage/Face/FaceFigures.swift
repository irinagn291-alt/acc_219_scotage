import Foundation

/// Role: Face. Locale numbers through NumberFormatter. Views never interpolate a month amount.
enum FaceFigures {
    static func money(_ value: Double, code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    static func monthAmount(_ lot: Lot, code: String) -> String {
        money(visibleMonthValue(lot), code: code)
    }

    /// Unspecified lots still contribute nothing to the needle. The chip shows the billed amount, never the word unknown.
    static func visibleMonthValue(_ lot: Lot) -> Double {
        if lot.period == .unspecified {
            return lot.amount
        }
        return lot.monthlyEquivalent
    }

    static func decimal(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    static func integer(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    static func parseAmount(_ raw: String) -> Double? {
        guard let value = parseNonNegative(raw), value > 0 else { return nil }
        return value
    }

    static func parseNonNegative(_ raw: String) -> Double? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return 0 }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        guard let number = formatter.number(from: trimmed) else { return nil }
        let value = number.doubleValue
        guard value.isFinite, value >= 0 else { return nil }
        return value
    }

    /// Live field filter. Allows an unfinished decimal so typing is not blocked.
    static func allowsAmountDraft(_ raw: String) -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return true }
        if trimmed.contains(where: { $0 == "-" || $0 == "+" }) { return false }
        if parseAmount(trimmed) != nil { return true }
        if let zero = NumberFormatter().number(from: trimmed), zero.doubleValue == 0 {
            return true
        }
        let sep = Locale.current.decimalSeparator ?? "."
        if trimmed == sep { return true }
        if trimmed.hasSuffix(sep) {
            let head = String(trimmed.dropLast())
            return head.isEmpty || NumberFormatter().number(from: head) != nil
        }
        return false
    }

    static func dayTitle(_ key: Int, calendar: Calendar = .current) -> String {
        let year = key / 10_000
        let month = (key / 100) % 100
        let day = key % 100
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        guard let date = calendar.date(from: parts) else {
            return integer(key)
        }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    static func clock(_ date: Date, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .current
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }

    static let currencyCodes = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF", "SEK"]
}
