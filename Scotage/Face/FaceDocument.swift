import Foundation

/// Role: Face. Codable envelope for UserDefaults sct.face.v1. Precept is stored as the ADT.
struct FaceDocument: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var lots: [LotRecord]
    var scotAmount: Double
    var handLotID: UUID?
    var quitMarks: [QuitMarkRecord]
    var holdMarks: [HoldMarkRecord]
    var precept: Precept
    var currencyCode: String
    var reminderOn: Bool
    var reminderHour: Int
    var reminderMinute: Int
    var onboardingComplete: Bool

    static func envelope(from face: Face) -> FaceDocument {
        FaceDocument(
            schemaVersion: FaceCodec.currentSchema,
            lots: face.lots.map { lot in
                LotRecord(
                    id: lot.id,
                    name: lot.name,
                    amount: lot.amount,
                    period: lot.period,
                    nextChargeDay: lot.nextChargeDay
                )
            },
            scotAmount: face.scot.amount,
            handLotID: face.hand?.lotID,
            quitMarks: face.quitMarks.map { mark in
                QuitMarkRecord(
                    id: mark.id,
                    lotID: mark.lotID,
                    lotName: mark.lotName,
                    monthAmount: mark.monthAmount,
                    dayKey: mark.dayKey,
                    filedEpoch: mark.filedAt.timeIntervalSince1970
                )
            },
            holdMarks: face.holdMarks.map { mark in
                HoldMarkRecord(
                    id: mark.id,
                    lotID: mark.lotID,
                    lotName: mark.lotName,
                    dayKey: mark.dayKey,
                    filedEpoch: mark.filedAt.timeIntervalSince1970
                )
            },
            precept: face.precept,
            currencyCode: face.currencyCode,
            reminderOn: face.reminder.isOn,
            reminderHour: face.reminder.hour,
            reminderMinute: face.reminder.minute,
            onboardingComplete: face.onboardingComplete
        )
    }

    func asFace() -> Face {
        Face(
            lots: lots.map { record in
                Lot(
                    id: record.id,
                    name: record.name,
                    amount: record.amount,
                    period: record.period,
                    nextChargeDay: record.nextChargeDay
                )
            },
            scot: Scot(amount: scotAmount),
            hand: handLotID.map { Hand(lotID: $0) },
            quitMarks: quitMarks.map { record in
                QuitMark(
                    id: record.id,
                    lotID: record.lotID,
                    lotName: record.lotName,
                    monthAmount: record.monthAmount,
                    dayKey: record.dayKey,
                    filedAt: Date(timeIntervalSince1970: record.filedEpoch)
                )
            },
            holdMarks: holdMarks.map { record in
                HoldMark(
                    id: record.id,
                    lotID: record.lotID,
                    lotName: record.lotName,
                    dayKey: record.dayKey,
                    filedAt: Date(timeIntervalSince1970: record.filedEpoch)
                )
            },
            precept: precept,
            currencyCode: currencyCode,
            reminder: FaceReminder(
                isOn: reminderOn,
                hour: reminderHour,
                minute: reminderMinute
            ),
            onboardingComplete: onboardingComplete
        )
    }
}

struct LotRecord: Codable, Equatable, Sendable {
    var id: UUID
    var name: String
    var amount: Double
    var period: LotPeriod
    var nextChargeDay: Int
}

struct QuitMarkRecord: Codable, Equatable, Sendable {
    var id: UUID
    var lotID: UUID
    var lotName: String
    var monthAmount: Double
    var dayKey: Int
    var filedEpoch: TimeInterval
}

struct HoldMarkRecord: Codable, Equatable, Sendable {
    var id: UUID
    var lotID: UUID
    var lotName: String
    var dayKey: Int
    var filedEpoch: TimeInterval
}

/// Role: Face. Schema switch. Domain types never decode this JSON themselves.
enum FaceCodec {
    static let currentSchema = 1

    enum Failure: Error, Equatable {
        case unsupportedSchema(Int)
        case corrupt
    }

    static func encode(_ document: FaceDocument) throws -> Data {
        var copy = document
        copy.schemaVersion = currentSchema
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(copy)
    }

    static func decode(_ data: Data) throws -> FaceDocument {
        let decoder = JSONDecoder()
        let probe: SchemaProbe
        do {
            probe = try decoder.decode(SchemaProbe.self, from: data)
        } catch {
            throw Failure.corrupt
        }
        switch probe.schemaVersion {
        case 1:
            do {
                var document = try decoder.decode(FaceDocument.self, from: data)
                document.schemaVersion = currentSchema
                return document
            } catch {
                throw Failure.corrupt
            }
        default:
            throw Failure.unsupportedSchema(probe.schemaVersion)
        }
    }
}

private struct SchemaProbe: Decodable {
    var schemaVersion: Int
}
