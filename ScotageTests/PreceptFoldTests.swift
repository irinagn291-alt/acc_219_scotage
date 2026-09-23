import XCTest
@testable import Scotage

final class PreceptFoldTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        utc.locale = Locale(identifier: "en_US_POSIX")
        calendar = utc
    }

    func test_foldHasOnlyVacantBareAimedEased() {
        XCTAssertEqual(Precept.allCases, [.vacant, .bare, .aimed, .eased])
        XCTAssertEqual(Face.empty.precept, .vacant)
        XCTAssertNil(Face.empty.hand)
    }

    func test_quitAimed_emptyPopulatedInvalid() throws {
        let now = day(2026, 9, 19)
        var face = Face.empty
        XCTAssertTrue(face.lots.isEmpty)
        XCTAssertThrowsError(try face.aiming(at: now, calendar: calendar)) { error in
            XCTAssertEqual(error as? FaceFault, .vacant)
        }
        XCTAssertThrowsError(try face.tapping(FaceSeed.stream, at: now, calendar: calendar)) { error in
            XCTAssertEqual(error as? FaceFault, .vacant)
        }

        face = try face.adding(lot(FaceSeed.cloud, amount: 40, period: .monthly), at: now, calendar: calendar)
        face = try face.adding(lot(FaceSeed.stream, amount: 12, period: .weekly), at: now, calendar: calendar)
        XCTAssertEqual(face.precept, .bare)
        XCTAssertFalse(face.canQuitAimed)
        XCTAssertThrowsError(try face.tapping(FaceSeed.stream, at: now, calendar: calendar)) { error in
            XCTAssertEqual(error as? FaceFault, .quitOnBare)
        }

        XCTAssertThrowsError(
            try face.adding(lot(UUID(), name: "   ", amount: 10, period: .monthly), at: now, calendar: calendar)
        ) { error in
            XCTAssertEqual(error as? FaceFault, .blankLot)
        }
        XCTAssertThrowsError(
            try face.adding(lot(UUID(), amount: -3, period: .monthly), at: now, calendar: calendar)
        ) { error in
            XCTAssertEqual(error as? FaceFault, .negativeAmount)
        }

        let aimed = try face.aiming(at: now, calendar: calendar)
        XCTAssertEqual(aimed.precept, .aimed)
        XCTAssertEqual(aimed.hand?.lotID, FaceSeed.stream)
        XCTAssertTrue(aimed.canQuitAimed)
        XCTAssertEqual(aimed.largestOverrunLot(at: now, calendar: calendar)?.id, FaceSeed.stream)

        let quitted = try aimed.tapping(FaceSeed.stream, at: now, calendar: calendar)
        XCTAssertEqual(quitted.quitMarks.count, 1)
        XCTAssertEqual(try XCTUnwrap(quitted.quitMarks.first).monthAmount, 12 * (52.0 / 12.0), accuracy: 1e-12)
        XCTAssertEqual(quitted.quitMarks.first?.dayKey, 20260919)
        XCTAssertFalse(quitted.lots.contains(where: { $0.id == FaceSeed.stream }))
        XCTAssertEqual(quitted.cancelSavings, 12 * (52.0 / 12.0), accuracy: 1e-12)
    }

    func test_secondAimWhileAimedIsRefused() throws {
        let now = day(2026, 9, 19)
        let aimed = try Face.empty
            .adding(lot(FaceSeed.cloud, amount: 40, period: .monthly), at: now, calendar: calendar)
            .adding(lot(FaceSeed.stream, amount: 12, period: .weekly), at: now, calendar: calendar)
            .settingScot(Scot(amount: 50), at: now, calendar: calendar)
            .aiming(at: now, calendar: calendar)
        XCTAssertThrowsError(try aimed.aiming(at: now, calendar: calendar)) { error in
            XCTAssertEqual(error as? FaceFault, .alreadyAimed)
        }
        XCTAssertEqual(aimed.precept, .aimed)
        XCTAssertEqual(aimed.hand?.lotID, FaceSeed.stream)
    }

    func test_quitOnBareIsRefused() throws {
        let now = day(2026, 9, 19)
        let bare = try Face.empty
            .adding(lot(FaceSeed.cloud, amount: 40, period: .monthly), at: now, calendar: calendar)
        XCTAssertEqual(bare.precept, .bare)
        XCTAssertThrowsError(try bare.tapping(FaceSeed.cloud, at: now, calendar: calendar)) { error in
            XCTAssertEqual(error as? FaceFault, .quitOnBare)
        }
    }

    func test_missWritesHoldMarkAndKeepsHand() throws {
        let now = day(2026, 9, 19)
        let aimed = try Face.empty
            .adding(lot(FaceSeed.cloud, amount: 40, period: .monthly), at: now, calendar: calendar)
            .adding(lot(FaceSeed.stream, amount: 12, period: .weekly), at: now, calendar: calendar)
            .settingScot(Scot(amount: 50), at: now, calendar: calendar)
            .aiming(at: now, calendar: calendar)
        let missed = try aimed.tapping(
            FaceSeed.cloud,
            at: now,
            calendar: calendar,
            markID: FaceSeed.press
        )
        XCTAssertEqual(missed.precept, .aimed)
        XCTAssertEqual(missed.hand?.lotID, FaceSeed.stream)
        XCTAssertEqual(missed.holdMarks.map(\.lotID), [FaceSeed.cloud])
        XCTAssertEqual(missed.quitMarks.count, 0)
        XCTAssertEqual(missed.lots.count, 2)
    }

    func test_lastTrueQuitFoldsAimedToEased() throws {
        let now = day(2026, 9, 19)
        let aimed = try Face.empty
            .adding(lot(FaceSeed.cloud, amount: 40, period: .monthly), at: now, calendar: calendar)
            .adding(lot(FaceSeed.stream, amount: 12, period: .weekly), at: now, calendar: calendar)
            .settingScot(Scot(amount: 80), at: now, calendar: calendar)
            .aiming(at: now, calendar: calendar)
        XCTAssertEqual(aimed.liveLoad(at: now, calendar: calendar), 92, accuracy: 1e-12)
        let eased = try aimed.tapping(FaceSeed.stream, at: now, calendar: calendar)
        XCTAssertEqual(eased.precept, .eased)
        XCTAssertNil(eased.hand)
        XCTAssertEqual(eased.liveLoad(at: now, calendar: calendar), 40, accuracy: 1e-12)
        XCTAssertEqual(eased.leftoverOverrun(at: now, calendar: calendar), 0, accuracy: 1e-12)
        XCTAssertThrowsError(try eased.tapping(FaceSeed.cloud, at: now, calendar: calendar)) { error in
            XCTAssertEqual(error as? FaceFault, .notAimed)
        }
    }

    func test_quitThatLeavesOverrunReaimsLargestRemaining() throws {
        let now = day(2026, 9, 19)
        let aimed = try Face.empty
            .adding(lot(FaceSeed.cloud, amount: 50, period: .monthly), at: now, calendar: calendar)
            .adding(lot(FaceSeed.press, amount: 40, period: .monthly), at: now, calendar: calendar)
            .adding(lot(FaceSeed.stream, amount: 12, period: .weekly), at: now, calendar: calendar)
            .settingScot(Scot(amount: 80), at: now, calendar: calendar)
            .aiming(at: now, calendar: calendar)
        XCTAssertEqual(aimed.hand?.lotID, FaceSeed.stream)
        let next = try aimed.tapping(FaceSeed.stream, at: now, calendar: calendar)
        XCTAssertEqual(next.precept, .aimed)
        XCTAssertEqual(next.hand?.lotID, FaceSeed.cloud)
        XCTAssertEqual(next.quitMarks.count, 1)
    }

    func test_seededFaceEnablesQuitAndSitsPastScot() {
        let now = day(2026, 9, 19)
        let seeded = FaceSeed.face(now: now, calendar: calendar)
        XCTAssertEqual(seeded.precept, .aimed)
        XCTAssertTrue(seeded.canQuitAimed)
        XCTAssertTrue(seeded.onboardingComplete)
        XCTAssertEqual(seeded.hand?.lotID, FaceSeed.stream)
        XCTAssertGreaterThan(seeded.liveLoad(at: now, calendar: calendar), seeded.scot.amount)
        XCTAssertEqual(seeded.aimedLot(at: now, calendar: calendar)?.id, FaceSeed.stream)
        XCTAssertFalse(seeded.liveLots(at: now, calendar: calendar).contains(where: { $0.id == FaceSeed.drift }))
        XCTAssertTrue(seeded.mysteryLots(at: now, calendar: calendar).contains(where: { $0.id == FaceSeed.openCharge }))
        XCTAssertTrue(seeded.mysteryLots(at: now, calendar: calendar).contains(where: { $0.id == FaceSeed.press }))
        XCTAssertTrue(seeded.mysteryLots(at: now, calendar: calendar).contains(where: { $0.id == FaceSeed.harbor }))
        XCTAssertEqual(seeded.quitMarks.map(\.lotName), ["Studio seat"])
        XCTAssertEqual(seeded.holdMarks.map(\.lotID), [FaceSeed.harbor])
        XCTAssertEqual(seeded.cancelSavings, 22, accuracy: 1e-12)
        XCTAssertGreaterThan(seeded.leftoverOverrun(at: now, calendar: calendar), 0)
    }

    func test_emptyLiveStackWritesVacant() throws {
        let now = day(2026, 9, 19)
        let aimed = try Face.empty
            .adding(lot(FaceSeed.stream, amount: 12, period: .weekly), at: now, calendar: calendar)
            .settingScot(Scot(amount: 10), at: now, calendar: calendar)
            .aiming(at: now, calendar: calendar)
        let vacant = try aimed.tapping(FaceSeed.stream, at: now, calendar: calendar)
        XCTAssertEqual(vacant.precept, .vacant)
        XCTAssertNil(vacant.hand)
        XCTAssertTrue(vacant.lots.isEmpty)
    }

    private func lot(
        _ id: UUID,
        name: String = "Lot",
        amount: Double,
        period: LotPeriod,
        nextChargeDay: Int = 20260919
    ) -> Lot {
        Lot(id: id, name: name, amount: amount, period: period, nextChargeDay: nextChargeDay)
    }

    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        return calendar.date(from: parts) ?? Date(timeIntervalSince1970: 0)
    }
}
