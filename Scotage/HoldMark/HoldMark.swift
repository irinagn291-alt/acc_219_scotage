import Foundation

/// Role: HoldMark. A miss on a Lot that is not the aimed Lot. Cools that arc and keeps the Hand.
struct HoldMark: Identifiable, Hashable, Sendable, Equatable {
    var id: UUID
    var lotID: UUID
    var lotName: String
    var dayKey: Int
    var filedAt: Date

    init(
        id: UUID = UUID(),
        lotID: UUID,
        lotName: String,
        dayKey: Int,
        filedAt: Date
    ) {
        self.id = id
        self.lotID = lotID
        self.lotName = lotName
        self.dayKey = dayKey
        self.filedAt = filedAt
    }
}
