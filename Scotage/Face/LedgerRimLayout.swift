import CoreGraphics
import Foundation
import UIKit

/// Role: Face. Snapshot the collection reads. Live Lots only. The fold stays on Face.
struct LedgerFrame: Equatable, Sendable {
    var lots: [Lot]
    var aimedID: UUID?
    var aimedName: String?
    var cooledIDs: Set<UUID>
    var mysteryIDs: Set<UUID>
    var sharedDayIDs: Set<UUID>
    var liveLoad: Double
    var yearLoad: Double
    var scot: Double
    var cancelSavings: Double
    var currencyCode: String
    var precept: Precept
    var composing: Bool
    var status: String?
    var isFaulted: Bool

    static let empty = LedgerFrame(
        lots: [],
        aimedID: nil,
        aimedName: nil,
        cooledIDs: [],
        mysteryIDs: [],
        sharedDayIDs: [],
        liveLoad: 0,
        yearLoad: 0,
        scot: 0,
        cancelSavings: 0,
        currencyCode: "USD",
        precept: .vacant,
        composing: false,
        status: nil,
        isFaulted: false
    )

    var items: [LedgerItem] {
        lots.map { LedgerItem.lot($0.id) } + [.composer]
    }

    var canQuit: Bool {
        precept == .aimed && aimedID != nil
    }

    func lot(id: UUID) -> Lot? {
        lots.first { $0.id == id }
    }
}

enum LedgerSection: Hashable, Sendable {
    case face
}

enum LedgerItem: Hashable, Sendable {
    case lot(UUID)
    case composer
}

enum LedgerKinds {
    static let needle = "sct.needle"
    static let pin = "sct.pin"
    static let year = "sct.year"
}

/// Role: Face. One packed analog face. Needle, year, Scot pin, and each Lot own a frame.
struct LedgerPack: Equatable, Sendable {
    var lotFrames: [CGRect]
    var lotAngles: [CGFloat]
    var needle: CGRect
    var year: CGRect
    var pin: CGRect

    static let empty = LedgerPack(
        lotFrames: [],
        lotAngles: [],
        needle: .zero,
        year: .zero,
        pin: .zero
    )
}

/// Role: Face. Rim geometry for NSCollectionLayoutGroup.custom. Views never invent a second grid.
enum LedgerRimLayout {
    static func faceRect(in size: CGSize) -> CGRect {
        let pad = FaceSpace.inner
        return CGRect(
            x: pad,
            y: pad,
            width: max(FaceSpace.hit, size.width - pad * 2),
            height: max(FaceSpace.hit, size.height - pad * 2)
        )
    }

    static func pack(
        lots: Int,
        composing: Bool,
        in size: CGSize,
        aimedIndex: Int? = nil,
        pinAngle: CGFloat = -.pi / 2,
        trait: UITraitCollection = UITraitCollection()
    ) -> LedgerPack {
        guard size.width >= FaceSpace.hit, size.height >= FaceSpace.hit else {
            return .empty
        }
        let caption = FacePaint.typeFont(.caption, trait: trait)
        let display = FacePaint.typeFont(.display, trait: trait)
        let captionLine = max(12, ceil(caption.lineHeight))
        let displayLine = max(12, ceil(display.lineHeight))
        let composer = composing ? composerCard(in: size) : nil
        let work = lotWork(in: size, composer: composer)

        var needleSide = needleStartSide(in: work, displayLine: displayLine, captionLine: captionLine)
        var lotSize = lotStartSize(in: work, captionLine: captionLine)
        var packed = LedgerPack.empty

        for _ in 0 ..< 12 {
            packed = place(
                lots: lots,
                composing: composing,
                work: work,
                canvas: size,
                composer: composer,
                aimedIndex: aimedIndex,
                pinAngle: pinAngle,
                needleSide: needleSide,
                lotSize: lotSize,
                captionLine: captionLine
            )
            if !hasInteriorOverlap(packed) {
                return packed
            }
            needleSide = max(FaceSpace.hit * 2.2, needleSide * 0.9)
            lotSize.width = max(FaceSpace.hit * 2.2, lotSize.width * 0.94)
        }
        return separate(packed, work: work)
    }

    static func frames(
        lots: Int,
        composing: Bool,
        in size: CGSize,
        aimedIndex: Int? = nil,
        trait: UITraitCollection = UITraitCollection(),
        pinAngle: CGFloat = -.pi / 2
    ) -> [CGRect] {
        pack(
            lots: lots,
            composing: composing,
            in: size,
            aimedIndex: aimedIndex,
            pinAngle: pinAngle,
            trait: trait
        ).lotFrames
    }

    @MainActor
    static func customItems(
        lots: Int,
        composing: Bool,
        aimedIndex: Int?,
        in size: CGSize,
        trait: UITraitCollection = UITraitCollection(),
        pinAngle: CGFloat = -.pi / 2
    ) -> [NSCollectionLayoutGroupCustomItem] {
        pack(
            lots: lots,
            composing: composing,
            in: size,
            aimedIndex: aimedIndex,
            pinAngle: pinAngle,
            trait: trait
        ).lotFrames
            .enumerated()
            .map { index, rect in
                let z = (aimedIndex == index) ? 8 : 1
                return NSCollectionLayoutGroupCustomItem(frame: rect, zIndex: z)
            }
    }

    static func angleForLot(
        index: Int,
        lots: Int,
        composing: Bool,
        pinAngle: CGFloat = -.pi / 2,
        in size: CGSize = CGSize(width: 390, height: 520),
        trait: UITraitCollection = UITraitCollection()
    ) -> CGFloat {
        let packed = pack(
            lots: lots,
            composing: composing,
            in: size,
            pinAngle: pinAngle,
            trait: trait
        )
        guard packed.lotAngles.indices.contains(index) else {
            return angle(index: index, count: max(composing ? lots : lots + 1, 1), horseshoe: composing)
        }
        return packed.lotAngles[index]
    }

    static func needleRect(
        in size: CGSize,
        lots: Int = 6,
        composing: Bool = false,
        aimedIndex: Int? = nil,
        pinAngle: CGFloat = -.pi / 2,
        trait: UITraitCollection = UITraitCollection()
    ) -> CGRect {
        pack(
            lots: lots,
            composing: composing,
            in: size,
            aimedIndex: aimedIndex,
            pinAngle: pinAngle,
            trait: trait
        ).needle
    }

    static func yearRect(
        in size: CGSize,
        lots: Int = 6,
        composing: Bool = false,
        aimedIndex: Int? = nil,
        pinAngle: CGFloat = -.pi / 2,
        trait: UITraitCollection = UITraitCollection()
    ) -> CGRect {
        pack(
            lots: lots,
            composing: composing,
            in: size,
            aimedIndex: aimedIndex,
            pinAngle: pinAngle,
            trait: trait
        ).year
    }

    static func pinRect(
        in size: CGSize,
        angle: CGFloat,
        lots: Int = 6,
        composing: Bool = false,
        aimedIndex: Int? = nil,
        trait: UITraitCollection = UITraitCollection()
    ) -> CGRect {
        pack(
            lots: lots,
            composing: composing,
            in: size,
            aimedIndex: aimedIndex,
            pinAngle: angle,
            trait: trait
        ).pin
    }

    static func scotAngle(scot: Double, liveLoad: Double) -> CGFloat {
        let cap = max(liveLoad, scot, 1)
        let fraction = min(1, max(0, scot / cap))
        return -.pi / 2 + (2 * .pi) * CGFloat(fraction)
    }

    static func composerCard(in size: CGSize) -> CGRect {
        let outer = FaceSpace.outer
        let height = min(FaceSpace.step(72), max(FaceSpace.step(44), size.height * 0.38))
        let width = max(FaceSpace.hit * 4, size.width - outer * 2)
        let y = max(FaceSpace.inner, size.height - height - FaceSpace.card)
        return CGRect(x: outer, y: y, width: width, height: height)
    }

    static func interiorsOverlap(_ a: CGRect, _ b: CGRect) -> Bool {
        let hit = a.intersection(b)
        return hit.width > 0.5 && hit.height > 0.5
    }

    private static func lotWork(in size: CGSize, composer: CGRect?) -> CGRect {
        var work = faceRect(in: size)
        if let composer {
            let limit = composer.minY - FaceSpace.card
            work.size.height = max(FaceSpace.hit * 4, min(work.height, limit - work.minY))
        }
        return work
    }

    private static func needleStartSide(in work: CGRect, displayLine: CGFloat, captionLine: CGFloat) -> CGFloat {
        let typed = displayLine + captionLine * 2 + FaceSpace.inner * 4
        return min(
            work.width * 0.28,
            max(FaceSpace.hit * 2.4, typed)
        )
    }

    private static func lotStartSize(in work: CGRect, captionLine: CGFloat) -> CGSize {
        let width = min(
            FaceSpace.step(52),
            max(FaceSpace.hit * 2.2, work.width * 0.20)
        )
        let height = max(
            FaceSpace.hit,
            captionLine * 3 + FaceSpace.step(1) * 2 + FaceSpace.inner * 2
        )
        return CGSize(width: width, height: height)
    }

    private static func place(
        lots: Int,
        composing: Bool,
        work: CGRect,
        canvas: CGSize,
        composer: CGRect?,
        aimedIndex: Int?,
        pinAngle: CGFloat,
        needleSide: CGFloat,
        lotSize: CGSize,
        captionLine: CGFloat
    ) -> LedgerPack {
        let origin = CGPoint(x: work.midX, y: work.midY)
        let yearH = max(FaceSpace.step(8), captionLine + FaceSpace.step(1))
        let yearW = max(FaceSpace.hit * 3, needleSide * 0.92)
        let hubH = needleSide + FaceSpace.inner + yearH
        var needle = CGRect(
            x: origin.x - needleSide / 2,
            y: origin.y - hubH / 2,
            width: needleSide,
            height: needleSide
        )
        var year = CGRect(
            x: origin.x - yearW / 2,
            y: needle.maxY + FaceSpace.inner,
            width: yearW,
            height: yearH
        )
        if year.maxY > work.maxY {
            let shift = year.maxY - work.maxY
            needle.origin.y -= shift
            year.origin.y -= shift
        }
        if needle.minY < work.minY {
            let shift = work.minY - needle.minY
            needle.origin.y += shift
            year.origin.y += shift
        }
        needle = clamp(needle, in: work, minWidth: FaceSpace.hit, minHeight: FaceSpace.hit)
        year = clamp(year, in: work, minWidth: FaceSpace.hit, minHeight: year.height)

        let pinSize = CGSize(
            width: max(FaceSpace.hit * 2, FaceSpace.step(20)),
            height: max(FaceSpace.hit, captionLine * 2 + FaceSpace.step(1) * 2)
        )
        let dial = CGPoint(x: needle.midX, y: needle.midY)
        var pin = pinFrame(
            angle: pinAngle,
            around: dial,
            needle: needle,
            size: pinSize,
            work: work
        )
        pin = nudge(pin, awayFrom: [needle, year], around: dial, work: work)

        let rimCount = composing ? lots : lots + 1
        let angles = lotAngles(
            count: max(rimCount, 0),
            horseshoe: composing,
            pin: pin,
            origin: dial
        )
        let (rx, ry) = ellipseRadii(
            work: work,
            origin: dial,
            angles: angles,
            aimedIndex: aimedIndex,
            lotSize: lotSize
        )

        var frames: [CGRect] = []
        var usedAngles: [CGFloat] = []
        for index in 0 ..< rimCount {
            let aimed = aimedIndex == index
            let size = CGSize(
                width: min(work.width, lotSize.width + (aimed ? FaceSpace.inner : 0)),
                height: lotSize.height + (aimed ? FaceSpace.inner : 0)
            )
            let theta = angles.indices.contains(index) ? angles[index] : angle(
                index: index,
                count: max(rimCount, 1),
                horseshoe: composing
            )
            var rect = rectAt(origin: dial, rx: rx, ry: ry, angle: theta, size: size)
            rect = clamp(rect, in: work, minWidth: FaceSpace.hit, minHeight: FaceSpace.hit)
            frames.append(rect)
            usedAngles.append(theta)
        }

        if let composer {
            frames.append(composer)
            usedAngles.append(.pi / 2)
        }

        return LedgerPack(
            lotFrames: frames.map {
                clamp(
                    $0,
                    in: CGRect(origin: .zero, size: canvas),
                    minWidth: FaceSpace.hit,
                    minHeight: FaceSpace.hit
                )
            },
            lotAngles: usedAngles,
            needle: needle,
            year: year,
            pin: pin
        )
    }

    private static func lotAngles(
        count: Int,
        horseshoe: Bool,
        pin: CGRect,
        origin: CGPoint
    ) -> [CGFloat] {
        guard count > 0 else { return [] }
        if horseshoe {
            return (0 ..< count).map { angle(index: $0, count: count, horseshoe: true) }
        }
        let pinAngle = atan2(pin.midY - origin.y, pin.midX - origin.x)
        let pinRadius = max(hypot(pin.midX - origin.x, pin.midY - origin.y), 1)
        let pinHalf = atan2(max(pin.width, pin.height) / 2, pinRadius) + 0.22
        let wedge = min(.pi * 0.9, max(0.7, pinHalf * 2))
        let usable = 2 * .pi - wedge
        let step = usable / CGFloat(count)
        let start = pinAngle + wedge / 2
        return (0 ..< count).map { start + step * CGFloat($0) }
    }

    private static func ellipseRadii(
        work: CGRect,
        origin: CGPoint,
        angles: [CGFloat],
        aimedIndex: Int?,
        lotSize: CGSize
    ) -> (CGFloat, CGFloat) {
        let aimedExtra = FaceSpace.inner
        var rx = min(origin.x - work.minX, work.maxX - origin.x) - lotSize.width / 2 - aimedExtra
        var ry = min(origin.y - work.minY, work.maxY - origin.y) - lotSize.height / 2 - aimedExtra
        rx = max(FaceSpace.hit, rx)
        ry = max(FaceSpace.hit, ry)
        for _ in 0 ..< 10 {
            var fits = true
            for (index, theta) in angles.enumerated() {
                let aimed = aimedIndex == index
                let size = CGSize(
                    width: lotSize.width + (aimed ? FaceSpace.inner : 0),
                    height: lotSize.height + (aimed ? FaceSpace.inner : 0)
                )
                let rect = rectAt(origin: origin, rx: rx, ry: ry, angle: theta, size: size)
                if !work.insetBy(dx: -0.5, dy: -0.5).contains(rect) {
                    fits = false
                    break
                }
            }
            if fits { break }
            rx = max(FaceSpace.hit, rx * 0.94)
            ry = max(FaceSpace.hit, ry * 0.94)
        }
        return (rx, ry)
    }

    private static func pinFrame(
        angle: CGFloat,
        around origin: CGPoint,
        needle: CGRect,
        size: CGSize,
        work: CGRect
    ) -> CGRect {
        let radius = needle.width / 2 + FaceSpace.inner + max(size.width, size.height) / 2
        let rect = CGRect(
            x: origin.x + cos(angle) * radius - size.width / 2,
            y: origin.y + sin(angle) * radius - size.height / 2,
            width: size.width,
            height: size.height
        )
        return clamp(rect, in: work, minWidth: FaceSpace.hit, minHeight: FaceSpace.hit)
    }

    private static func nudge(
        _ rect: CGRect,
        awayFrom reserved: [CGRect],
        around origin: CGPoint,
        work: CGRect
    ) -> CGRect {
        var current = clamp(rect, in: work, minWidth: FaceSpace.hit, minHeight: FaceSpace.hit)
        let radius = hypot(current.midX - origin.x, current.midY - origin.y)
        var theta = atan2(current.midY - origin.y, current.midX - origin.x)
        for step in 0 ..< 18 {
            if !reserved.contains(where: { interiorsOverlap(current, $0) }) {
                return current
            }
            let delta = FaceSpace.inner / max(radius, 1) * (step.isMultiple(of: 2) ? 1 : -1)
            theta += delta * CGFloat(step + 1)
            current = clamp(
                CGRect(
                    x: origin.x + cos(theta) * radius - rect.width / 2,
                    y: origin.y + sin(theta) * radius - rect.height / 2,
                    width: rect.width,
                    height: rect.height
                ),
                in: work,
                minWidth: FaceSpace.hit,
                minHeight: FaceSpace.hit
            )
        }
        return current
    }

    private static func separate(_ pack: LedgerPack, work: CGRect) -> LedgerPack {
        var next = pack
        let reserved = [pack.needle, pack.year, pack.pin]
        let origin = CGPoint(x: pack.needle.midX, y: pack.needle.midY)
        for index in next.lotFrames.indices {
            var rect = next.lotFrames[index]
            var radius = hypot(rect.midX - origin.x, rect.midY - origin.y)
            let theta = next.lotAngles.indices.contains(index) ? next.lotAngles[index] : atan2(
                rect.midY - origin.y,
                rect.midX - origin.x
            )
            var guardCount = 0
            while reserved.contains(where: { interiorsOverlap(rect, $0) })
                || next.lotFrames.enumerated().contains(where: { $0.offset != index && interiorsOverlap(rect, $0.element) })
            {
                radius += FaceSpace.inner
                rect = clamp(
                    rectAt(origin: origin, rx: radius, ry: radius, angle: theta, size: rect.size),
                    in: work,
                    minWidth: FaceSpace.hit,
                    minHeight: FaceSpace.hit
                )
                guardCount += 1
                if guardCount > 16 { break }
            }
            next.lotFrames[index] = rect
        }
        next.pin = nudge(next.pin, awayFrom: [next.needle, next.year] + next.lotFrames, around: origin, work: work)
        return next
    }

    private static func hasInteriorOverlap(_ pack: LedgerPack) -> Bool {
        let hubs = [pack.needle, pack.year, pack.pin]
        if interiorsOverlap(pack.needle, pack.year) { return true }
        if interiorsOverlap(pack.needle, pack.pin) { return true }
        if interiorsOverlap(pack.year, pack.pin) { return true }
        for (index, lot) in pack.lotFrames.enumerated() {
            if hubs.contains(where: { interiorsOverlap(lot, $0) }) {
                return true
            }
            for other in pack.lotFrames.enumerated() where other.offset > index {
                if interiorsOverlap(lot, other.element) {
                    return true
                }
            }
        }
        return false
    }

    private static func rectAt(
        origin: CGPoint,
        rx: CGFloat,
        ry: CGFloat,
        angle: CGFloat,
        size: CGSize
    ) -> CGRect {
        CGRect(
            x: origin.x + cos(angle) * rx - size.width / 2,
            y: origin.y + sin(angle) * ry - size.height / 2,
            width: size.width,
            height: size.height
        )
    }

    private static func clamp(
        _ rect: CGRect,
        in bounds: CGRect,
        minWidth: CGFloat,
        minHeight: CGFloat
    ) -> CGRect {
        var next = rect
        next.size.width = min(max(minWidth, next.width), max(minWidth, bounds.width))
        next.size.height = min(max(minHeight, next.height), max(minHeight, bounds.height))
        next.origin.x = min(max(bounds.minX, next.origin.x), max(bounds.minX, bounds.maxX - next.width))
        next.origin.y = min(max(bounds.minY, next.origin.y), max(bounds.minY, bounds.maxY - next.height))
        return next
    }

    private static func angle(index: Int, count: Int, horseshoe: Bool) -> CGFloat {
        if horseshoe {
            if count <= 1 {
                return -.pi / 2
            }
            let t = CGFloat(index) / CGFloat(count - 1)
            let start = -CGFloat.pi * 0.92
            let span = CGFloat.pi * 0.84
            return start + span * t
        }
        let step = (2 * .pi) / CGFloat(max(count, 1))
        return -.pi / 2 + step * CGFloat(index)
    }
}
