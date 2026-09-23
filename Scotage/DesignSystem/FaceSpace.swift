import SwiftUI

/// Role: DesignSystem. One 4pt grid. Hits are 44pt. Views never pick a stray padding.
enum FaceSpace {
    static let unit: CGFloat = 4

    static func step(_ n: Int) -> CGFloat {
        unit * CGFloat(n)
    }

    static var hit: CGFloat { 44 }
    static var outer: CGFloat { step(6) }
    static var card: CGFloat { step(4) }
    static var inner: CGFloat { step(2) }
}
