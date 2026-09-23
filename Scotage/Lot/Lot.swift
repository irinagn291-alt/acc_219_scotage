import Foundation

/// Role: Lot. One recurring charge on the Face. monthlyEquivalent is amount times period.occurrencesPerMonth.
struct Lot: Identifiable, Hashable, Sendable, Equatable {
    var id: UUID
    var name: String
    var amount: Double
    var period: LotPeriod
    var nextChargeDay: Int

    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        period: LotPeriod,
        nextChargeDay: Int
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.period = period
        self.nextChargeDay = nextChargeDay
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var monthlyEquivalent: Double {
        amount * period.occurrencesPerMonth
    }

    func billsThisMonth(at date: Date, calendar: Calendar) -> Bool {
        FaceDay.monthKey(dayKey: nextChargeDay) == FaceDay.monthKey(for: date, calendar: calendar)
    }
}

/// Role: Lot. Cadence factor for period-normalized month amount. Weekly is 52/12. Unspecified contributes nothing.
enum LotPeriod: String, Codable, Equatable, Sendable, CaseIterable {
    case weekly
    case monthly
    case yearly
    case unspecified

    var occurrencesPerMonth: Double {
        switch self {
        case .weekly:
            return 52.0 / 12.0
        case .monthly:
            return 1
        case .yearly:
            return 1.0 / 12.0
        case .unspecified:
            return 0
        }
    }
}
