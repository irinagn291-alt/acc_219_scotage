import Foundation

/// Role: Face. Memory is the source of truth. UserDefaults is the projection. Views never touch UserDefaults.
actor FaceStore {
    private let vault: FaceVault
    private let writeDelayNanoseconds: UInt64

    private var latest: Face = .empty
    private var dirty = false
    private var writeTask: Task<Void, Never>?
    private(set) var warning: FaceWarning?
    private(set) var lastWriteError: String?

    init(
        directory: URL,
        suiteName: String? = nil,
        writeDelayNanoseconds: UInt64 = 300_000_000
    ) {
        self.vault = FaceVault(directory: directory, suiteName: suiteName)
        self.writeDelayNanoseconds = writeDelayNanoseconds
    }

    static func applicationSupportStore() -> FaceStore {
        let directory: URL
        do {
            directory = try FaceVault.supportDirectory()
        } catch {
            directory = FileManager.default.temporaryDirectory.appendingPathComponent(
                "Scotage",
                isDirectory: true
            )
        }
        return FaceStore(directory: directory)
    }

    func load() async -> (face: Face, warning: FaceWarning?) {
        let loaded = vault.load()
        latest = loaded.face
        warning = loaded.warning
        dirty = false
        lastWriteError = nil
        return loaded
    }

    func face() -> Face {
        latest
    }

    func addLot(_ lot: Lot, at date: Date, calendar: Calendar) async throws -> Face {
        latest = try latest.adding(lot, at: date, calendar: calendar)
        try persistNow()
        return latest
    }

    func aim(at date: Date, calendar: Calendar) async throws -> Face {
        latest = try latest.aiming(at: date, calendar: calendar)
        return latest
    }

    func tap(lotID: UUID, at date: Date, calendar: Calendar) async throws -> Face {
        let next = try latest.tapping(lotID, at: date, calendar: calendar)
        latest = next
        try persistNow()
        return latest
    }

    func setScot(_ scot: Scot, at date: Date, calendar: Calendar) async throws -> Face {
        latest = try latest.settingScot(scot, at: date, calendar: calendar)
        try persistNow()
        return latest
    }

    func setCurrency(_ code: String) async throws -> Face {
        latest = try latest.settingCurrency(code)
        schedulePersist()
        return latest
    }

    func setReminder(_ reminder: FaceReminder) async throws -> Face {
        latest = latest.settingReminder(reminder)
        schedulePersist()
        return latest
    }

    func setOnboardingComplete(_ done: Bool) async throws -> Face {
        latest = latest.settingOnboardingComplete(done)
        schedulePersist()
        return latest
    }

    func flush() async throws {
        writeTask?.cancel()
        writeTask = nil
        if dirty {
            try persistNow()
        }
    }

    func resetAllData() async throws {
        writeTask?.cancel()
        writeTask = nil
        latest = .empty
        dirty = false
        warning = nil
        lastWriteError = nil
        try vault.wipe()
    }

    func seedDemoIfNeeded(now: Date, calendar: Calendar) async throws -> Face? {
        #if targetEnvironment(simulator)
        if vault.demoPlanted() { return nil }
        latest = FaceSeed.face(now: now, calendar: calendar)
        try persistNow()
        vault.markDemoPlanted()
        return latest
        #else
        return nil
        #endif
    }

    private func schedulePersist() {
        dirty = true
        writeTask?.cancel()
        let delay = writeDelayNanoseconds
        writeTask = Task { [weak self] in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            guard !Task.isCancelled else { return }
            await self?.flushIfNeeded()
        }
    }

    private func flushIfNeeded() async {
        writeTask = nil
        do {
            if dirty {
                try persistNow()
            }
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    private func persistNow() throws {
        try vault.save(latest)
        dirty = false
        lastWriteError = nil
    }
}
