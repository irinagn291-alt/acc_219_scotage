import XCTest
@testable import Scotage

final class LedgerRimLayoutTests: XCTestCase {
    func test_framesStayInsideBoundsAndMeetHitSize() {
        let size = CGSize(width: 390, height: 520)
        let frames = LedgerRimLayout.frames(lots: 6, composing: false, in: size)
        XCTAssertEqual(frames.count, 7)
        let bounds = CGRect(origin: .zero, size: size).insetBy(dx: -1, dy: -1)
        for frame in frames {
            XCTAssertGreaterThanOrEqual(frame.width, FaceSpace.hit)
            XCTAssertGreaterThanOrEqual(frame.height, FaceSpace.hit)
            XCTAssertTrue(bounds.contains(frame))
        }
    }

    func test_composerExpandsAtTheBottomOfTheSameSnapshot() {
        let size = CGSize(width: 390, height: 640)
        let frames = LedgerRimLayout.frames(lots: 4, composing: true, in: size)
        XCTAssertEqual(frames.count, 5)
        let composer = frames[4]
        let card = LedgerRimLayout.composerCard(in: size)
        XCTAssertEqual(composer.origin.x, card.origin.x, accuracy: 0.5)
        XCTAssertGreaterThan(composer.maxY, frames[0].maxY)
        XCTAssertGreaterThanOrEqual(composer.height, FaceSpace.hit)
    }

    func test_needleAndPinSitOnTheFace() {
        let size = CGSize(width: 390, height: 520)
        let face = LedgerRimLayout.faceRect(in: size)
        let pack = LedgerRimLayout.pack(lots: 6, composing: false, in: size, pinAngle: -.pi / 2)
        XCTAssertTrue(face.contains(CGPoint(x: pack.needle.midX, y: pack.needle.midY)))
        XCTAssertTrue(face.contains(CGPoint(x: pack.year.midX, y: pack.year.midY)) || pack.year.intersects(face))
        XCTAssertGreaterThanOrEqual(pack.pin.width, FaceSpace.hit)
        XCTAssertGreaterThanOrEqual(pack.pin.height, FaceSpace.hit)
        XCTAssertEqual(LedgerRimLayout.scotAngle(scot: 0, liveLoad: 100), -.pi / 2, accuracy: 0.001)
    }

    func test_aimedLotIsLargerThanNeighbors() {
        let size = CGSize(width: 390, height: 520)
        let frames = LedgerRimLayout.frames(lots: 6, composing: false, in: size, aimedIndex: 0)
        XCTAssertEqual(frames.count, 7)
        XCTAssertGreaterThan(frames[0].width * frames[0].height, frames[1].width * frames[1].height)
        XCTAssertGreaterThanOrEqual(frames[0].width, FaceSpace.hit)
        XCTAssertGreaterThanOrEqual(frames[0].height, FaceSpace.hit)
    }

    func test_lotFramesFitThreeCaptionLines() {
        let trait = UITraitCollection(preferredContentSizeCategory: .large)
        let line = max(12, ceil(FacePaint.typeFont(.caption, trait: trait).lineHeight))
        let needed = line * 3 + FaceSpace.step(1) * 2 + FaceSpace.inner * 2
        let size = CGSize(width: 390, height: 520)
        let frames = LedgerRimLayout.frames(lots: 6, composing: false, in: size, trait: trait)
        XCTAssertEqual(frames.count, 7)
        for frame in frames.dropLast() {
            XCTAssertGreaterThanOrEqual(frame.height, needed - 0.5)
            XCTAssertGreaterThanOrEqual(frame.width, FaceSpace.hit * 2)
        }
    }

    func test_snapshotItemsAreLotsThenComposer() {
        var frame = LedgerFrame.empty
        frame.lots = [
            Lot(id: FaceSeed.stream, name: "Stream", amount: 12, period: .weekly, nextChargeDay: 20260919),
        ]
        XCTAssertEqual(frame.items, [.lot(FaceSeed.stream), .composer])
    }

    func test_needleYearPinAndLotsOwnSeparateFrames() {
        let size = CGSize(width: 390, height: 640)
        let pinAngle = LedgerRimLayout.scotAngle(scot: 90, liveLoad: 118)
        let pack = LedgerRimLayout.pack(
            lots: 6,
            composing: false,
            in: size,
            aimedIndex: 4,
            pinAngle: pinAngle
        )
        XCTAssertEqual(pack.lotFrames.count, 7)
        XCTAssertFalse(LedgerRimLayout.interiorsOverlap(pack.needle, pack.year))
        XCTAssertFalse(LedgerRimLayout.interiorsOverlap(pack.needle, pack.pin))
        XCTAssertFalse(LedgerRimLayout.interiorsOverlap(pack.year, pack.pin))
        for (index, lot) in pack.lotFrames.enumerated() {
            XCTAssertFalse(LedgerRimLayout.interiorsOverlap(lot, pack.needle), "lot \(index) overlaps needle")
            XCTAssertFalse(LedgerRimLayout.interiorsOverlap(lot, pack.year), "lot \(index) overlaps year")
            XCTAssertFalse(LedgerRimLayout.interiorsOverlap(lot, pack.pin), "lot \(index) overlaps pin")
            for other in pack.lotFrames.enumerated() where other.offset > index {
                XCTAssertFalse(
                    LedgerRimLayout.interiorsOverlap(lot, other.element),
                    "lot \(index) overlaps lot \(other.offset)"
                )
            }
        }
    }

    func test_iPadLotsUseTheWiderFace() {
        let phone = LedgerRimLayout.pack(
            lots: 6,
            composing: false,
            in: CGSize(width: 390, height: 640),
            aimedIndex: 4,
            pinAngle: LedgerRimLayout.scotAngle(scot: 90, liveLoad: 118)
        )
        let pad = LedgerRimLayout.pack(
            lots: 6,
            composing: false,
            in: CGSize(width: 834, height: 1112),
            aimedIndex: 4,
            pinAngle: LedgerRimLayout.scotAngle(scot: 90, liveLoad: 118)
        )
        let phoneLot = phone.lotFrames[0]
        let padLot = pad.lotFrames[0]
        XCTAssertGreaterThan(padLot.width, phoneLot.width)
        XCTAssertFalse(LedgerRimLayout.interiorsOverlap(pad.needle, pad.pin))
        for lot in pad.lotFrames {
            XCTAssertFalse(LedgerRimLayout.interiorsOverlap(lot, pad.needle))
            XCTAssertFalse(LedgerRimLayout.interiorsOverlap(lot, pad.pin))
        }
    }
}
