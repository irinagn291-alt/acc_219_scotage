import Foundation

/// Role: Face. Projects FaceDocument to UserDefaults plus an atomic Application Support file.
struct FaceVault {
    var directory: URL
    var suiteName: String?

    init(directory: URL, suiteName: String? = nil) {
        self.directory = directory
        self.suiteName = suiteName
    }

    static func supportDirectory() throws -> URL {
        let root = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return root.appendingPathComponent("Scotage", isDirectory: true)
    }

    func load() -> (face: Face, warning: FaceWarning?) {
        if let face = decode(box().data(forKey: FaceKey.snapshot)) {
            return (face, nil)
        }
        if let face = decode(read(fileURL)) {
            return (face, nil)
        }
        if let face = decode(box().data(forKey: FaceKey.backup)) {
            return (face, .recoveredFromBackup)
        }
        if let face = decode(read(backupURL)) {
            return (face, .recoveredFromBackup)
        }
        let hadPayload = box().data(forKey: FaceKey.snapshot) != nil
            || FileManager.default.fileExists(atPath: fileURL.path)
        return (.empty, hadPayload ? .startedEmpty : nil)
    }

    func save(_ face: Face) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try FaceCodec.encode(FaceDocument.envelope(from: face))
        let defaults = box()
        if let current = defaults.data(forKey: FaceKey.snapshot) {
            defaults.set(current, forKey: FaceKey.backup)
        }
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try? FileManager.default.removeItem(at: backupURL)
            try? FileManager.default.copyItem(at: fileURL, to: backupURL)
        }
        defaults.set(data, forKey: FaceKey.snapshot)
        try data.write(to: fileURL, options: .atomic)
        excludeCacheIfPresent()
    }

    func wipe() throws {
        let defaults = box()
        defaults.removeObject(forKey: FaceKey.snapshot)
        defaults.removeObject(forKey: FaceKey.backup)
        defaults.removeObject(forKey: FaceKey.demo)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
        if FileManager.default.fileExists(atPath: backupURL.path) {
            try FileManager.default.removeItem(at: backupURL)
        }
        if FileManager.default.fileExists(atPath: cacheURL.path) {
            try FileManager.default.removeItem(at: cacheURL)
        }
    }

    func demoPlanted() -> Bool {
        box().object(forKey: FaceKey.demo) != nil
    }

    func markDemoPlanted() {
        box().set(true, forKey: FaceKey.demo)
    }

    private func decode(_ data: Data?) -> Face? {
        guard let data else { return nil }
        return try? FaceCodec.decode(data).asFace()
    }

    private func read(_ url: URL) -> Data? {
        try? Data(contentsOf: url)
    }

    private var fileURL: URL {
        directory.appendingPathComponent("face.json", isDirectory: false)
    }

    private var backupURL: URL {
        directory.appendingPathComponent("face.json.backup", isDirectory: false)
    }

    private var cacheURL: URL {
        directory.appendingPathComponent("face-net-cache.json", isDirectory: false)
    }

    private func excludeCacheIfPresent() {
        guard FileManager.default.fileExists(atPath: cacheURL.path) else { return }
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var url = cacheURL
        try? url.setResourceValues(values)
    }

    private func box() -> UserDefaults {
        if let suiteName {
            return UserDefaults(suiteName: suiteName) ?? UserDefaults()
        }
        return .standard
    }
}
