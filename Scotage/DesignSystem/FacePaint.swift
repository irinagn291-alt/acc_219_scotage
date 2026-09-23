import SwiftUI
import UIKit

/// Role: DesignSystem. UIKit paints from FaceInk. Hex never appears in cells.
enum FacePaint {
    static var background: UIColor { UIColor(FaceInk.background) }
    static var surface: UIColor { UIColor(FaceInk.surface) }
    static var ink: UIColor { UIColor(FaceInk.ink) }
    static var accent: UIColor { UIColor(FaceInk.accent) }
    static var muted: UIColor { UIColor(FaceInk.muted) }

    static let hairline: CGFloat = 1

    static func blurStyle() -> UIBlurEffect.Style {
        .systemThinMaterial
    }

    static func typeFont(_ step: FaceType.Step, trait: UITraitCollection) -> UIFont {
        let category = trait.preferredContentSizeCategory
        let style: UIFont.TextStyle
        switch step {
        case .display:
            if category >= .accessibilityExtraExtraExtraLarge {
                style = .title1
            } else {
                style = .largeTitle
            }
        case .title:
            style = .title2
        case .headline:
            style = .title3
        case .body:
            style = .body
        case .caption:
            style = .footnote
        case .micro:
            style = .caption1
        }
        let base = UIFont.preferredFont(forTextStyle: style, compatibleWith: trait)
        if step == .display {
            return UIFont.monospacedDigitSystemFont(ofSize: base.pointSize, weight: .regular)
        }
        return base
    }
}
