import XCTest
@testable import Scotage

/// Family subscription_load: monthlyEquivalent = amount × period.occurrencesPerMonth (weekly = 52/12).
final class FamilyInvariantTests: XCTestCase {
    func test_monthlyEquivalent_isAmountTimesOccurrencesPerMonth() {
        XCTAssertEqual(LotPeriod.weekly.occurrencesPerMonth, 52.0 / 12.0, accuracy: 1e-12)
        XCTAssertEqual(LotPeriod.monthly.occurrencesPerMonth, 1, accuracy: 1e-12)
        XCTAssertEqual(LotPeriod.yearly.occurrencesPerMonth, 1.0 / 12.0, accuracy: 1e-12)
        XCTAssertEqual(LotPeriod.unspecified.occurrencesPerMonth, 0, accuracy: 1e-12)

        let weekly = Lot(name: "Stream", amount: 12, period: .weekly, nextChargeDay: 20260919)
        XCTAssertEqual(
            weekly.monthlyEquivalent,
            weekly.amount * weekly.period.occurrencesPerMonth,
            accuracy: 1e-12
        )
        XCTAssertEqual(weekly.monthlyEquivalent, 52, accuracy: 1e-12)

        let monthly = Lot(name: "Cloud", amount: 29, period: .monthly, nextChargeDay: 20260919)
        XCTAssertEqual(
            monthly.monthlyEquivalent,
            monthly.amount * monthly.period.occurrencesPerMonth,
            accuracy: 1e-12
        )
        XCTAssertEqual(monthly.monthlyEquivalent, 29, accuracy: 1e-12)

        let yearly = Lot(name: "Plate", amount: 120, period: .yearly, nextChargeDay: 20260919)
        XCTAssertEqual(
            yearly.monthlyEquivalent,
            yearly.amount * yearly.period.occurrencesPerMonth,
            accuracy: 1e-12
        )
        XCTAssertEqual(yearly.monthlyEquivalent, 10, accuracy: 1e-12)
    }

    func test_forecastChargesOnlyInTheChargeMonthNotSmeared() {
        let calendar = posixCalendar()
        let now = day(2026, 9, 19, calendar: calendar)
        let thisMonth = Lot(
            id: FaceSeed.stream,
            name: "Stream",
            amount: 12,
            period: .weekly,
            nextChargeDay: 20260919
        )
        let nextMonth = Lot(
            id: FaceSeed.drift,
            name: "Drift",
            amount: 40,
            period: .monthly,
            nextChargeDay: 20261005
        )
        XCTAssertTrue(thisMonth.billsThisMonth(at: now, calendar: calendar))
        XCTAssertFalse(nextMonth.billsThisMonth(at: now, calendar: calendar))

        let face = Face(
            lots: [thisMonth, nextMonth],
            scot: Scot(amount: 20),
            hand: nil,
            quitMarks: [],
            holdMarks: [],
            precept: .bare,
            currencyCode: "USD",
            reminder: .off,
            onboardingComplete: true
        )
        let live = face.liveLots(at: now, calendar: calendar)
        XCTAssertEqual(live.map(\.id), [thisMonth.id])
        XCTAssertEqual(face.liveLoad(at: now, calendar: calendar), thisMonth.monthlyEquivalent, accuracy: 1e-12)
        XCTAssertFalse(live.contains(where: { $0.id == nextMonth.id }))
        XCTAssertNotEqual(
            face.liveLoad(at: now, calendar: calendar),
            thisMonth.monthlyEquivalent + nextMonth.monthlyEquivalent,
            accuracy: 1e-12
        )
    }

    func test_unspecifiedMonthAmountRendersBilledAmountNotUnknown() {
        let lot = Lot(name: "Open charge", amount: 15, period: .unspecified, nextChargeDay: 20260919)
        XCTAssertEqual(lot.monthlyEquivalent, 0, accuracy: 1e-12)
        XCTAssertEqual(FaceFigures.visibleMonthValue(lot), 15, accuracy: 1e-12)
        XCTAssertEqual(FaceFigures.monthAmount(lot, code: "USD"), FaceFigures.money(15, code: "USD"))
        XCTAssertNotEqual(FaceFigures.monthAmount(lot, code: "USD"), FaceFigures.money(0, code: "USD"))
        XCTAssertFalse(FaceFigures.monthAmount(lot, code: "USD").localizedCaseInsensitiveContains("unknown"))
    }

    private func posixCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }

    private func day(_ year: Int, _ month: Int, _ day: Int, calendar: Calendar) -> Date {
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        return calendar.date(from: parts) ?? Date(timeIntervalSince1970: 0)
    }
}
