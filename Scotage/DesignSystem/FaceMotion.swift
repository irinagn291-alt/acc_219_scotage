import SwiftUI

/// Role: DesignSystem. Snap motion. Press 0.97 in 140 to 180ms. Reduce Motion is opacity only.
enum FaceSnap {
    static let pressScale: CGFloat = 0.97
    static let duration: Double = 0.16
    static let fade: Double = 0.14
    static let stagger: Double = 0.05
    static let staggerCap: Double = 0.36
}

enum FaceMotion {
    static func snap(_ reduceMotion: Bool) -> Animation {
        .easeOut(duration: reduceMotion ? FaceSnap.fade : FaceSnap.duration)
    }

    static func pressScale(_ reduceMotion: Bool) -> CGFloat {
        reduceMotion ? 1 : FaceSnap.pressScale
    }

    static func staggerDelay(index: Int, reduceMotion: Bool) -> Double {
        if reduceMotion { return 0 }
        return min(Double(index) * FaceSnap.stagger, FaceSnap.staggerCap)
    }
}

/// Role: DesignSystem. Grouped reveal. Reduce Motion shows the group at once with a fade.
struct FaceReveal: ViewModifier {
    let index: Int
    let reduceMotion: Bool
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : FaceSpace.inner)
            .onAppear {
                if reduceMotion {
                    withAnimation(.easeOut(duration: FaceSnap.fade)) {
                        shown = true
                    }
                    return
                }
                let delay = FaceMotion.staggerDelay(index: index, reduceMotion: false)
                withAnimation(.easeOut(duration: FaceSnap.duration).delay(delay)) {
                    shown = true
                }
            }
    }
}
