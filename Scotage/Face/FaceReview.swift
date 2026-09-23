import Foundation

/// Role: Face. Launch keys for live shots. today, log, and goals are arguments, not tabs.
enum FaceReview: Equatable, Sendable {
    case today
    case log
    case goals

    init?(slug: String) {
        switch slug {
        case "today":
            self = .today
        case "log":
            self = .log
        case "goals":
            self = .goals
        default:
            return nil
        }
    }

    /// Extra cover keys from this app's screens. today, log, and goals stay in `init?(slug:)`.
    static func isLedgerSlug(_ slug: String) -> Bool {
        switch slug.lowercased() {
        case "today", "ledger", "face", "home", "ledgerface":
            return true
        default:
            return false
        }
    }

    static func sheet(forSlug slug: String) -> FaceSheet? {
        switch slug.lowercased() {
        case "log", "insights", "insightssheet":
            return .insights
        case "goals", "settings", "settingssheet":
            return .settings
        default:
            return nil
        }
    }

    static func extraLaunch(forSlug slug: String) -> FaceLaunch? {
        switch slug.lowercased() {
        case "insights", "insightssheet":
            return .insights
        case "settings", "settingssheet":
            return .settings
        case "onboarding":
            return .onboarding
        case "twist", "twistsheet":
            return .twist
        default:
            return nil
        }
    }

    /// Reads ProcessInfo launch keys once, only after onboarding. Do not host a View here.
    static func consume(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        onboardingComplete: Bool,
        consumed: inout Bool
    ) -> FaceReview? {
        guard onboardingComplete, !consumed else { return nil }
        consumed = true
        guard let index = arguments.firstIndex(of: "-ReviewScreen") else { return nil }
        let next = arguments.index(after: index)
        guard arguments.indices.contains(next) else { return nil }
        return FaceReview(slug: arguments[next])
    }
}

/// Role: Face. Sheets that arrive over the locked Ledger. Not a tab bar.
enum FaceSheet: String, Identifiable, Equatable, Sendable {
    case insights
    case settings

    var id: String { rawValue }
}

/// Role: Face. Extra cover destinations when a slug is not today, log, or goals.
enum FaceLaunch: Equatable, Sendable {
    case insights
    case settings
    case onboarding
    case twist
}
