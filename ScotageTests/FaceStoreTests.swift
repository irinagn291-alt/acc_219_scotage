import XCTest
@testable import Scotage

final class FaceStoreTests: XCTestCase {
    private var directory: URL!
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var calendar: Calendar!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        suiteName = "sct.test.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
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
            defaults?.removePersistentDomain(forName: suiteName)
        }
        directory = nil
        defaults = nil
        suiteName = nil
    }

    func test_roundTrip_reloadPreservesPreceptAndQuitMarks() async throws {
        let store = makeStore()
        let now = day(2026, 9, 19)
        _ = try await store.addLot(
            Lot(id: FaceSeed.cloud, name: "Cloud", amount: 40, period: .monthly, nextChargeDay: 20260919),
            at: now,
            calendar: calendar
        )
        _ = try await store.addLot(
            Lot(id: FaceSeed.stream, name: "Stream", amount: 12, period: .weekly, nextChargeDay: 20260919),
            at: now,
            calendar: calendar
        )
        _ = try await store.setScot(Scot(amount: 50), at: now, calendar: calendar)
        _ = try await store.aim(at: now, calendar: calendar)
        _ = try await store.tap(lotID: FaceSeed.stream, at: now, calendar: calendar)

        let relaunched = makeStore()
        let loaded = await relaunched.load()
        XCTAssertNil(loaded.warning)
        XCTAssertEqual(loaded.face.precept, .eased)
        XCTAssertEqual(loaded.face.quitMarks.count, 1)
        XCTAssertEqual(loaded.face.quitMarks.first?.lotID, FaceSeed.stream)
        XCTAssertEqual(loaded.face.quitMarks.first?.dayKey, 20260919)
        XCTAssertFalse(loaded.face.lots.contains(where: { $0.id == FaceSeed.stream }))
        XCTAssertNotNil(defaults.data(forKey: FaceKey.snapshot))
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: directory.appendingPathComponent("face.json").path)
        )
    }

    func test_aimDoesNotWrite_refusedQuitDoesNotWrite() async throws {
        let store = makeStore()
        let now = day(2026, 9, 19)
        _ = try await store.addLot(
            Lot(id: FaceSeed.cloud, name: "Cloud", amount: 40, period: .monthly, nextChargeDay: 20260919),
            at: now,
            calendar: calendar
        )
        try await store.flush()
        let afterAdd = defaults.data(forKey: FaceKey.snapshot)

        _ = try await store.aim(at: now, calendar: calendar)
        XCTAssertEqual(defaults.data(forKey: FaceKey.snapshot), afterAdd)
        let aimedMemory = await store.face()
        XCTAssertEqual(aimedMemory.precept, .aimed)

        let coldAfterAim = await makeStore().load()
        XCTAssertEqual(coldAfterAim.face.precept, .bare)
        XCTAssertNil(coldAfterAim.face.hand)

        do {
            _ = try await store.tap(lotID: FaceSeed.press, at: now, calendar: calendar)
            XCTFail("expected unknown lot")
        } catch {
            XCTAssertEqual(error as? FaceFault, .unknownLot)
        }
        XCTAssertEqual(defaults.data(forKey: FaceKey.snapshot), afterAdd)
    }

    func test_trueQuitAndScotEditFlushImmediately() async throws {
        let store = makeStore()
        let now = day(2026, 9, 19)
        _ = try await store.addLot(
            Lot(id: FaceSeed.cloud, name: "Cloud", amount: 40, period: .monthly, nextChargeDay: 20260919),
            at: now,
            calendar: calendar
        )
        _ = try await store.addLot(
            Lot(id: FaceSeed.stream, name: "Stream", amount: 12, period: .weekly, nextChargeDay: 20260919),
            at: now,
            calendar: calendar
        )
        _ = try await store.setScot(Scot(amount: 50), at: now, calendar: calendar)
        let afterScot = await makeStore().load()
        XCTAssertEqual(afterScot.face.scot.amount, 50, accuracy: 1e-12)

        _ = try await store.aim(at: now, calendar: calendar)
        _ = try await store.tap(lotID: FaceSeed.stream, at: now, calendar: calendar)
        let cold = await makeStore().load()
        XCTAssertEqual(cold.face.precept, .eased)
        XCTAssertEqual(cold.face.quitMarks.count, 1)
    }

    func test_corruptSnapshotFallsBackToBackup() async throws {
        let store = makeStore()
        let now = day(2026, 9, 19)
        _ = try await store.addLot(
            Lot(id: FaceSeed.cloud, name: "Cloud", amount: 40, period: .monthly, nextChargeDay: 20260919),
            at: now,
            calendar: calendar
        )
        try await store.flush()
        if let good = defaults.data(forKey: FaceKey.snapshot) {
            defaults.set(good, forKey: FaceKey.backup)
        }
        let file = directory.appendingPathComponent("face.json")
        let backup = directory.appendingPathComponent("face.json.backup")
        if FileManager.default.fileExists(atPath: file.path) {
            try? FileManager.default.removeItem(at: backup)
            try FileManager.default.copyItem(at: file, to: backup)
        }
        defaults.set(Data("{not-json".utf8), forKey: FaceKey.snapshot)
        try Data("{not-json".utf8).write(to: file)

        let loaded = await makeStore().load()
        XCTAssertEqual(loaded.warning, .recoveredFromBackup)
        XCTAssertEqual(loaded.face.lots.map(\.id), [FaceSeed.cloud])
    }

    func test_corruptSnapshotWithoutBackupStartsEmpty() async throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defaults.set(Data("nope".utf8), forKey: FaceKey.snapshot)
        try Data("nope".utf8).write(to: directory.appendingPathComponent("face.json"))
        let loaded = await makeStore().load()
        XCTAssertEqual(loaded.warning, .startedEmpty)
        XCTAssertTrue(loaded.face.lots.isEmpty)
        XCTAssertEqual(loaded.face.precept, .vacant)
    }

    func test_codecSwitchesOnSchemaVersion() throws {
        let document = FaceDocument.envelope(
            from: FaceSeed.face(now: day(2026, 9, 19), calendar: calendar)
        )
        let data = try FaceCodec.encode(document)
        let decoded = try FaceCodec.decode(data)
        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertEqual(decoded.lots.count, 7)
        XCTAssertEqual(decoded.precept, .aimed)
        XCTAssertEqual(decoded.handLotID, FaceSeed.stream)
        XCTAssertTrue(decoded.onboardingComplete)

        let future = Data("{\"schemaVersion\":99}".utf8)
        XCTAssertThrowsError(try FaceCodec.decode(future)) { error in
            XCTAssertEqual(error as? FaceCodec.Failure, .unsupportedSchema(99))
        }
        XCTAssertThrowsError(try FaceCodec.decode(Data("[]".utf8))) { error in
            XCTAssertEqual(error as? FaceCodec.Failure, .corrupt)
        }
    }

    func test_resetAllDataClearsSnapshotAndFiles() async throws {
        let store = makeStore()
        let now = day(2026, 9, 19)
        _ = try await store.addLot(
            Lot(id: FaceSeed.cloud, name: "Cloud", amount: 40, period: .monthly, nextChargeDay: 20260919),
            at: now,
            calendar: calendar
        )
        try await store.flush()
        try await store.resetAllData()
        let loaded = await store.load()
        XCTAssertTrue(loaded.face.lots.isEmpty)
        XCTAssertNil(defaults.data(forKey: FaceKey.snapshot))
        XCTAssertNil(defaults.data(forKey: FaceKey.backup))
        let leftovers = (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )) ?? []
        XCTAssertTrue(leftovers.filter { $0.pathExtension == "json" }.isEmpty)
    }

    #if targetEnvironment(simulator)
    func test_simulatorSeedWritesOnce() async throws {
        let store = makeStore()
        let now = day(2026, 9, 19)
        let first = try await store.seedDemoIfNeeded(now: now, calendar: calendar)
        let second = try await store.seedDemoIfNeeded(now: now, calendar: calendar)
        XCTAssertNil(second)
        XCTAssertEqual(first?.lots.count, 7)
        XCTAssertEqual(first?.precept, .aimed)
        XCTAssertTrue(first?.canQuitAimed ?? false)
        XCTAssertEqual(first?.onboardingComplete, true)
        XCTAssertEqual(first?.hand?.lotID, FaceSeed.stream)
        XCTAssertEqual(first?.quitMarks.map(\.lotName), ["Studio seat"])
        XCTAssertEqual(first?.holdMarks.map(\.lotID), [FaceSeed.harbor])
        XCTAssertTrue(defaults.bool(forKey: FaceKey.demo))
        XCTAssertNotNil(defaults.data(forKey: FaceKey.snapshot))
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: directory.appendingPathComponent("face.json").path)
        )
    }
    #endif

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
