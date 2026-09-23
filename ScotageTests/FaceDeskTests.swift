import XCTest
@testable import Scotage

final class FaceDeskTests: XCTestCase {
    private var directory: URL!
    private var suiteName: String!
    private var calendar: Calendar!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        suiteName = "sct.desk.\(UUID().uuidString)"
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        utc.locale = Locale(identifier: "en_US_POSIX")
        calendar = utc
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
        if let suiteName {
            UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        }
        directory = nil
        suiteName = nil
    }

    @MainActor
    func test_reviewKeysOpenDifferentSheets() async throws {
        let today = await booted(arguments: ["-ReviewScreen", "today"])
        XCTAssertNil(today.sheet)
        XCTAssertFalse(today.showsOnboarding)
        XCTAssertFalse(today.showsTwist)

        let log = await booted(arguments: ["-ReviewScreen", "log"])
        XCTAssertEqual(log.sheet, .insights)

        let goals = await booted(arguments: ["-ReviewScreen", "goals"])
        XCTAssertEqual(goals.sheet, .settings)

        let insights = await booted(arguments: ["-ReviewScreen", "insights"])
        XCTAssertEqual(insights.sheet, .insights)

        let settings = await booted(arguments: ["-ReviewScreen", "settings"])
        XCTAssertEqual(settings.sheet, .settings)

        let twist = await booted(arguments: ["-ReviewScreen", "twist"])
        XCTAssertTrue(twist.showsTwist)
        XCTAssertNil(twist.sheet)
        XCTAssertFalse(twist.showsOnboarding)

        let onboarding = await booted(arguments: ["-ReviewScreen", "onboarding"])
        XCTAssertTrue(onboarding.showsOnboarding)
    }

    @MainActor
    func test_reviewIsConsumedOnce() async throws {
        let desk = await booted(arguments: ["-ReviewScreen", "log"])
        XCTAssertEqual(desk.sheet, .insights)
        desk.sheet = nil
        desk.applyReviewIfNeeded(["-ReviewScreen", "goals"])
        XCTAssertNil(desk.sheet)
    }

    @MainActor
    func test_onboardingIncompleteSkipsReview() async {
        let desk = makeDesk()
        await desk.boot(arguments: ["-ReviewScreen", "log"])
        XCTAssertTrue(desk.showsOnboarding)
        XCTAssertNil(desk.sheet)
    }

    @MainActor
    func test_tapAimedFilesQuitAndMissCools() async throws {
        let store = makeStore()
        let stamp = day(2026, 9, 19)
        _ = try await store.addLot(
            Lot(id: FaceSeed.cloud, name: "Cloud", amount: 40, period: .monthly, nextChargeDay: 20260919),
            at: stamp,
            calendar: calendar
        )
        _ = try await store.addLot(
            Lot(id: FaceSeed.stream, name: "Stream", amount: 12, period: .weekly, nextChargeDay: 20260919),
            at: stamp,
            calendar: calendar
        )
        _ = try await store.setScot(Scot(amount: 50), at: stamp, calendar: calendar)
        _ = try await store.setOnboardingComplete(true)
        try await store.flush()

        let desk = FaceDesk(
            store: store,
            calendar: calendar,
            now: { stamp },
            plantsDemo: false
        )
        await desk.boot(arguments: ["-ReviewScreen", "today"])
        XCTAssertTrue(desk.quitEnabled)
        XCTAssertEqual(desk.face.precept, .aimed)
        XCTAssertEqual(desk.face.hand?.lotID, FaceSeed.stream)
        XCTAssertEqual(desk.ledgerFrame.aimedID, FaceSeed.stream)

        await desk.tapLot(FaceSeed.cloud)
        XCTAssertEqual(desk.face.holdMarks.map(\.lotID), [FaceSeed.cloud])
        XCTAssertEqual(desk.face.hand?.lotID, FaceSeed.stream)
        XCTAssertEqual(desk.face.quitMarks.count, 0)
        XCTAssertEqual(desk.status, FaceCopy.cooled("Cloud"))

        await desk.tapLot(FaceSeed.stream)
        XCTAssertEqual(desk.face.quitMarks.count, 1)
        XCTAssertEqual(desk.face.quitMarks.first?.lotID, FaceSeed.stream)
        XCTAssertEqual(desk.commitPulse, 1)
        XCTAssertFalse(desk.face.lots.contains(where: { $0.id == FaceSeed.stream }))
    }

    @MainActor
    func test_autoAimFromBareEnablesPrimaryVerb() async throws {
        let store = makeStore()
        let stamp = day(2026, 9, 19)
        _ = try await store.addLot(
            Lot(id: FaceSeed.stream, name: "Stream", amount: 12, period: .weekly, nextChargeDay: 20260919),
            at: stamp,
            calendar: calendar
        )
        _ = try await store.setOnboardingComplete(true)
        try await store.flush()
        let desk = FaceDesk(
            store: store,
            calendar: calendar,
            now: { stamp },
            plantsDemo: false
        )
        await desk.boot(arguments: [])
        XCTAssertEqual(desk.face.precept, .aimed)
        XCTAssertTrue(desk.quitEnabled)
        XCTAssertEqual(desk.face.hand?.lotID, FaceSeed.stream)
    }

    @MainActor
    func test_addDraftWritesLotAndResetShowsOnboarding() async throws {
        let desk = await booted(arguments: [])
        desk.draftName = "Shelf"
        desk.draftAmountText = "25"
        desk.draftPeriod = .monthly
        desk.draftCharge = day(2026, 9, 19)
        desk.beginCompose()
        await desk.addDraft()
        XCTAssertTrue(desk.face.lots.contains(where: { $0.name == "Shelf" }))
        XCTAssertFalse(desk.isComposing)

        await desk.resetAllData()
        XCTAssertTrue(desk.showsOnboarding)
        XCTAssertTrue(desk.face.lots.isEmpty)
        XCTAssertTrue(desk.settingsIsEmpty)
    }

    @MainActor
    func test_copyHasNoEmDash() {
        XCTAssertFalse(FaceCopy.jobLine.contains("\u{2014}"))
        XCTAssertFalse(FaceCopy.jobLine.contains("\u{2013}"))
        XCTAssertFalse(FaceCopy.twistBody.contains("\u{2014}"))
        XCTAssertFalse(FaceCopy.twistStay.contains("\u{2013}"))
        XCTAssertEqual(FaceCopy.preceptWord(.aimed), "Aimed")
        XCTAssertEqual(FaceCopy.aimedJob("Stream"), "Tap Stream to file it quit.")
        XCTAssertEqual(
            FaceCopy.rimCaption(period: .weekly, aimed: true, cooled: false),
            "Weekly, Aimed"
        )
        XCTAssertEqual(
            FaceCopy.rimCaption(period: .monthly, aimed: false, cooled: false),
            "Monthly"
        )
        XCTAssertEqual(
            FaceCopy.rimCaption(period: .unspecified, aimed: false, cooled: false),
            "No period"
        )
        XCTAssertFalse(FaceCopy.rimCaption(period: .monthly, aimed: false, cooled: false).contains("Shared"))
        XCTAssertEqual(FaceCopy.seeFace, "See the face")
        XCTAssertEqual(FaceCopy.inspectLot, "Inspect this lot")
        XCTAssertFalse(FaceCopy.leftoverLine.contains("\u{2014}"))
    }

    @MainActor
    func test_blankAmountIsRefused() async {
        let desk = await booted(arguments: [])
        desk.draftName = "Shelf"
        desk.draftAmountText = ""
        await desk.addDraft()
        XCTAssertEqual(desk.fault, FaceCopy.fault(FaceFault.negativeAmount))
        XCTAssertTrue(desk.face.lots.isEmpty)
    }

    @MainActor
    private func booted(arguments: [String]) async -> FaceDesk {
        let store = makeStore()
        _ = try? await store.setOnboardingComplete(true)
        try? await store.flush()
        let stamp = day(2026, 9, 19)
        let desk = FaceDesk(
            store: store,
            calendar: calendar,
            now: { stamp },
            plantsDemo: false
        )
        await desk.boot(arguments: arguments)
        return desk
    }

    @MainActor
    private func makeDesk() -> FaceDesk {
        let stamp = day(2026, 9, 19)
        return FaceDesk(
            store: makeStore(),
            calendar: calendar,
            now: { stamp },
            plantsDemo: false
        )
    }

    private func makeStore() -> FaceStore {
        FaceStore(
            directory: directory,
            suiteName: suiteName,
            writeDelayNanoseconds: 0
        )
    }

    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        return calendar.date(from: parts) ?? Date(timeIntervalSince1970: 0)
    }
}
