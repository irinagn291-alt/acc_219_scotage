import Foundation

/// Role: Face. Simulator demo. Live load sits past the Scot and the Hand is already aimed. Device never seeds.
enum FaceSeed {
    static let stream = uuid("aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")
    static let cloud = uuid("bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb")
    static let press = uuid("cccccccc-cccc-4ccc-8ccc-cccccccccccc")
    static let harbor = uuid("dddddddd-dddd-4ddd-8ddd-dddddddddddd")
    static let plate = uuid("eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee")
    static let drift = uuid("ffffffff-ffff-4fff-8fff-ffffffffffff")
    static let openCharge = uuid("12121212-1212-4121-8121-121212121212")
    static let studio = uuid("33333333-3333-4333-8333-333333333333")

    /// Seed identities are literals. Failure here is a programmer error.
    private static func uuid(_ raw: String) -> UUID {
        guard let value = UUID(uuidString: raw) else {
            fatalError("Demo seed UUID literal is invalid")
        }
        return value
    }

    static func face(now: Date, calendar: Calendar) -> Face {
        let start = calendar.startOfDay(for: now)
        let thisMonthDay = FaceDay.key(for: day(12, inMonthOf: start, calendar: calendar), calendar: calendar)
        let midMonthDay = FaceDay.key(for: day(19, inMonthOf: start, calendar: calendar), calendar: calendar)
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: start) ?? start
        let nextMonthDay = FaceDay.key(for: day(5, inMonthOf: nextMonth, calendar: calendar), calendar: calendar)
        let lots = [
            Lot(
                id: stream,
                name: "Stream week",
                amount: 12,
                period: .weekly,
                nextChargeDay: midMonthDay
            ),
            Lot(
                id: cloud,
                name: "Cloud shelf",
                amount: 29,
                period: .monthly,
                nextChargeDay: midMonthDay
            ),
            Lot(
                id: press,
                name: "Press seat",
                amount: 18,
                period: .monthly,
                nextChargeDay: thisMonthDay
            ),
            Lot(
                id: harbor,
                name: "Harbor seat",
                amount: 9,
                period: .monthly,
                nextChargeDay: thisMonthDay
            ),
            Lot(
                id: plate,
                name: "Year plate",
                amount: 120,
                period: .yearly,
                nextChargeDay: midMonthDay
            ),
            Lot(
                id: openCharge,
                name: "Open charge",
                amount: 15,
                period: .unspecified,
                nextChargeDay: midMonthDay
            ),
            Lot(
                id: drift,
                name: "Next drift",
                amount: 40,
                period: .monthly,
                nextChargeDay: nextMonthDay
            ),
        ]
        return Face(
            lots: lots,
            scot: Scot(amount: 90),
            hand: Hand(lotID: stream),
            quitMarks: [
                QuitMark(
                    id: studio,
                    lotID: studio,
                    lotName: "Studio seat",
                    monthAmount: 22,
                    dayKey: thisMonthDay,
                    filedAt: day(12, inMonthOf: start, calendar: calendar)
                ),
            ],
            holdMarks: [
                HoldMark(
                    id: harbor,
                    lotID: harbor,
                    lotName: "Harbor seat",
                    dayKey: thisMonthDay,
                    filedAt: day(12, inMonthOf: start, calendar: calendar)
                ),
            ],
            precept: .aimed,
            currencyCode: "USD",
            reminder: .off,
            onboardingComplete: true
        )
    }

    private static func day(_ day: Int, inMonthOf date: Date, calendar: Calendar) -> Date {
        var parts = calendar.dateComponents([.year, .month], from: calendar.startOfDay(for: date))
        parts.day = day
        return calendar.date(from: parts) ?? date
    }
}
