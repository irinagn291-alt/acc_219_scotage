import SwiftUI

/// Role: DesignSystem. Named colours from Assets.xcassets. Hex lives only in this accessor: #EAEFE7 #F3F6F3 #1D2A14 #1A9320 #526F3F.
enum FaceInk {
    enum Hex {
        static let background = "#EAEFE7"
        static let surface = "#F3F6F3"
        static let ink = "#1D2A14"
        static let accent = "#1A9320"
        static let muted = "#526F3F"
    }

    static var background: Color { Color("background") }
    static var surface: Color { Color("surface") }
    static var ink: Color { Color("ink") }
    static var accent: Color { Color("accent") }
    static var muted: Color { Color("muted") }
}
