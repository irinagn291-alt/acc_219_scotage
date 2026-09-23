import SwiftUI

/// Role: DesignSystem. SF Pro via Font.system. One display size, then caption on the Ledger. Six steps. Never Font.custom, never below 12pt.
enum FaceType {
    static let face = "SF Pro"

    enum Step: CaseIterable {
        case display
        case title
        case headline
        case body
        case caption
        case micro
    }

    static func font(_ step: Step, size: DynamicTypeSize = .large) -> Font {
        switch step {
        case .display:
            if size >= .accessibility5 {
                return .system(.title, design: .default).monospacedDigit()
            }
            return .system(.largeTitle, design: .default).monospacedDigit()
        case .title:
            return .system(.title2, design: .default)
        case .headline:
            return .system(.title3, design: .default)
        case .body:
            return .system(.body, design: .default)
        case .caption:
            return .system(.footnote, design: .default)
        case .micro:
            return .system(.caption, design: .default)
        }
    }
}
