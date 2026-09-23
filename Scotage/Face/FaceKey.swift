import Foundation

/// Role: Face. Preference keys. Snapshot key is the assigned UserDefaults contract.
enum FaceKey {
    static let snapshot = "sct.face.v1"
    static let backup = "sct.face.v1.backup"
    static let demo = "sct.demo.v2"
}

/// Role: Face. Recoverable load outcome. Never crash on a corrupt snapshot.
enum FaceWarning: Equatable, Sendable {
    case recoveredFromBackup
    case startedEmpty
}
