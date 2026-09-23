import Foundation

/// Role: Face. Precept ADT over live Lots: Vacant, Bare, Aimed, Eased. A fifth case is a defect.
enum Precept: String, Codable, Equatable, Sendable, CaseIterable {
    case vacant
    case bare
    case aimed
    case eased
}

/// Role: Face. Faults the fold can raise. Views never invent a second error vocabulary.
enum FaceFault: Error, Equatable, Sendable {
    case vacant
    case quitOnBare
    case alreadyAimed
    case noOverrun
    case unknownLot
    case blankLot
    case negativeAmount
    case notAimed
}

/// Role: Face. Local reminder stored with the document. Settings writes this. Views never touch UserDefaults.
struct FaceReminder: Hashable, Sendable, Equatable {
    var isOn: Bool
    var hour: Int
    var minute: Int

    static let off = FaceReminder(isOn: false, hour: 9, minute: 0)
}

/// Role: Face. The fold. Aim writes a Hand on the largest overrun Lot. Quit writes a QuitMark only on that Lot. A miss writes a HoldMark and keeps the Hand.
struct Face: Equatable, Sendable {
    var lots: [Lot]
    var scot: Scot
    var hand: Hand?
    var quitMarks: [QuitMark]
    var holdMarks: [HoldMark]
    var precept: Precept
    var currencyCode: String
    var reminder: FaceReminder
    var onboardingComplete: Bool

    static let empty = Face(
        lots: [],
        scot: .vacant,
        hand: nil,
        quitMarks: [],
        holdMarks: [],
        precept: .vacant,
        currencyCode: "USD",
        reminder: .off,
        onboardingComplete: false
    )

    func liveLots(at date: Date, calendar: Calendar) -> [Lot] {
        lots.filter { $0.billsThisMonth(at: date, calendar: calendar) }
    }

    func liveLoad(at date: Date, calendar: Calendar) -> Double {
        liveLots(at: date, calendar: calendar).reduce(0) { $0 + $1.monthlyEquivalent }
    }

    func yearInscription(at date: Date, calendar: Calendar) -> Double {
        liveLoad(at: date, calendar: calendar) * 12
    }

    var cancelSavings: Double {
        quitMarks.reduce(0) { $0 + $1.monthAmount }
    }

    func leftoverOverrun(at date: Date, calendar: Calendar) -> Double {
        max(0, liveLoad(at: date, calendar: calendar) - scot.amount)
    }

    func mysteryLots(at date: Date, calendar: Calendar) -> [Lot] {
        let pool = liveLots(at: date, calendar: calendar)
        let dayCounts = Dictionary(grouping: pool, by: \.nextChargeDay).mapValues(\.count)
        return pool.filter { lot in
            lot.period == .unspecified || (dayCounts[lot.nextChargeDay] ?? 0) > 1
        }
    }

    func largestOverrunLot(at date: Date, calendar: Calendar) -> Lot? {
        let live = liveLots(at: date, calendar: calendar)
        let load = live.reduce(0.0) { $0 + $1.monthlyEquivalent }
        guard load > scot.amount else { return nil }
        return live.max { lhs, rhs in
            if lhs.monthlyEquivalent != rhs.monthlyEquivalent {
                return lhs.monthlyEquivalent < rhs.monthlyEquivalent
            }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }

    var canQuitAimed: Bool {
        precept == .aimed && hand != nil
    }

    var canAim: Bool {
        precept == .bare
    }

    func aimedLot(at date: Date, calendar: Calendar) -> Lot? {
        guard precept == .aimed, let hand else { return nil }
        return liveLots(at: date, calendar: calendar).first { $0.id == hand.lotID }
    }

    func adding(_ lot: Lot, at date: Date, calendar: Calendar) throws -> Face {
        var prepared = lot
        prepared.name = prepared.trimmedName
        guard !prepared.name.isEmpty else { throw FaceFault.blankLot }
        guard prepared.amount > 0 else { throw FaceFault.negativeAmount }
        guard prepared.nextChargeDay > 0 else { throw FaceFault.blankLot }
        var next = self
        if let index = next.lots.firstIndex(where: { $0.id == prepared.id }) {
            next.lots[index] = prepared
        } else {
            next.lots.append(prepared)
        }
        let live = next.liveLots(at: date, calendar: calendar)
        let over = next.liveLoad(at: date, calendar: calendar) > next.scot.amount
        if live.isEmpty {
            next.precept = .vacant
            next.hand = nil
        } else if next.precept == .vacant {
            next.precept = .bare
        } else if next.precept == .eased, over {
            next.precept = .bare
            next.hand = nil
        } else if next.precept == .aimed {
            if let hand = next.hand, next.lots.contains(where: { $0.id == hand.lotID }) {
                next.hand = hand
            } else {
                next.precept = .bare
                next.hand = nil
            }
        }
        return next
    }

    func aiming(at date: Date, calendar: Calendar) throws -> Face {
        if precept == .aimed { throw FaceFault.alreadyAimed }
        let live = liveLots(at: date, calendar: calendar)
        guard !live.isEmpty else { throw FaceFault.vacant }
        guard let target = largestOverrunLot(at: date, calendar: calendar) else {
            throw FaceFault.noOverrun
        }
        var next = self
        next.hand = Hand(lotID: target.id)
        next.precept = .aimed
        return next
    }

    func tapping(
        _ lotID: UUID,
        at date: Date,
        calendar: Calendar,
        markID: UUID = UUID()
    ) throws -> Face {
        switch precept {
        case .vacant:
            throw FaceFault.vacant
        case .bare:
            throw FaceFault.quitOnBare
        case .eased:
            throw FaceFault.notAimed
        case .aimed:
            break
        }
        guard let lot = lots.first(where: { $0.id == lotID }) else {
            throw FaceFault.unknownLot
        }
        guard let hand, hand.lotID == lotID else {
            return holding(lot, at: date, calendar: calendar, markID: markID)
        }
        return quitting(lot, at: date, calendar: calendar, markID: markID)
    }

    func settingScot(_ scot: Scot, at date: Date, calendar: Calendar) throws -> Face {
        guard scot.amount >= 0 else { throw FaceFault.negativeAmount }
        var next = self
        next.scot = scot
        let live = next.liveLots(at: date, calendar: calendar)
        let over = next.liveLoad(at: date, calendar: calendar) > next.scot.amount
        if live.isEmpty {
            next.precept = .vacant
            next.hand = nil
        } else if over {
            if next.precept == .aimed,
               let hand = next.hand,
               live.contains(where: { $0.id == hand.lotID })
            {
                next.hand = hand
            } else {
                next.precept = .bare
                next.hand = nil
            }
        } else if next.precept == .aimed {
            next.precept = .eased
            next.hand = nil
        } else if next.precept != .eased {
            next.precept = .bare
            next.hand = nil
        }
        return next
    }

    func settingCurrency(_ code: String) throws -> Face {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw FaceFault.blankLot }
        var next = self
        next.currencyCode = trimmed
        return next
    }

    func settingReminder(_ reminder: FaceReminder) -> Face {
        var next = self
        var clamped = reminder
        clamped.hour = min(23, max(0, reminder.hour))
        clamped.minute = min(59, max(0, reminder.minute))
        next.reminder = clamped
        return next
    }

    func settingOnboardingComplete(_ done: Bool) -> Face {
        var next = self
        next.onboardingComplete = done
        return next
    }

    private func quitting(
        _ lot: Lot,
        at date: Date,
        calendar: Calendar,
        markID: UUID
    ) -> Face {
        var next = self
        next.lots.removeAll { $0.id == lot.id }
        next.quitMarks.append(
            QuitMark(
                id: markID,
                lotID: lot.id,
                lotName: lot.name,
                monthAmount: lot.monthlyEquivalent,
                dayKey: FaceDay.key(for: date, calendar: calendar),
                filedAt: date
            )
        )
        let live = next.liveLots(at: date, calendar: calendar)
        let load = next.liveLoad(at: date, calendar: calendar)
        if live.isEmpty {
            next.precept = .vacant
            next.hand = nil
        } else if load <= next.scot.amount {
            next.precept = .eased
            next.hand = nil
        } else if let target = next.largestOverrunLot(at: date, calendar: calendar) {
            next.precept = .aimed
            next.hand = Hand(lotID: target.id)
        } else {
            next.precept = .eased
            next.hand = nil
        }
        return next
    }

    private func holding(
        _ lot: Lot,
        at date: Date,
        calendar: Calendar,
        markID: UUID
    ) -> Face {
        var next = self
        let dayKey = FaceDay.key(for: date, calendar: calendar)
        if let index = next.holdMarks.firstIndex(where: { $0.lotID == lot.id }) {
            next.holdMarks[index].dayKey = dayKey
            next.holdMarks[index].filedAt = date
        } else {
            next.holdMarks.append(
                HoldMark(
                    id: markID,
                    lotID: lot.id,
                    lotName: lot.name,
                    dayKey: dayKey,
                    filedAt: date
                )
            )
        }
        return next
    }
}
