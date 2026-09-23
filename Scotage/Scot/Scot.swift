import Foundation

/// Role: Scot. Pin on the Face for the month the ratepayer can bear. Live load past this pin is overrun.
struct Scot: Hashable, Sendable, Equatable {
    var amount: Double

    init(amount: Double) {
        self.amount = amount
    }

    static let vacant = Scot(amount: 0)
}
