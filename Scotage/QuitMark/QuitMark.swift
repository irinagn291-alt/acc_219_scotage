import Foundation

/// Role: QuitMark. True Quit on the aimed Lot. Drops that Lot from the live stack. Month amount is frozen here.
struct QuitMark: Identifiable, Hashable, Sendable, Equatable {
    var id: UUID
    var lotID: UUID
    var lotName: String
    var monthAmount: Double
    var dayKey: Int
    var filedAt: Date

    init(
        id: UUID = UUID(),
        lotID: UUID,
        lotName: String,
        monthAmount: Double,
        dayKey: Int,
        filedAt: Date
    ) {
        self.id = id
        self.lotID = lotID
        self.lotName = lotName
        self.monthAmount = monthAmount
        self.dayKey = dayKey
        self.filedAt = filedAt
    }
}
