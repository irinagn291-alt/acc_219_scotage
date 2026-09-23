import Foundation

/// Role: Hand. Aim writes this on the live overrun Lot with the largest period-normalized month amount.
struct Hand: Hashable, Sendable, Equatable {
    var lotID: UUID

    init(lotID: UUID) {
        self.lotID = lotID
    }
}
