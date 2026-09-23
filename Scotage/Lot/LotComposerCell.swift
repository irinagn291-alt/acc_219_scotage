import SwiftUI
import UIKit

/// Role: Lot. Snapshot cell for the add chip or the expanded composer. Same item identity.
final class LotComposerCell: UICollectionViewCell {
    static let reuse = "sct.lot.composer"

    private enum Mode: Equatable {
        case chip
        case form
    }

    private var mode: Mode?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        clipsToBounds = false
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = FaceRadius.card
        contentView.layer.cornerCurve = .continuous
        isAccessibilityElement = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        mode = nil
        contentConfiguration = nil
    }

    func apply(desk: FaceDesk, composing: Bool) {
        let next: Mode = composing ? .form : .chip
        guard mode != next else { return }
        mode = next
        if composing {
            contentView.layer.cornerRadius = FaceRadius.card
            contentConfiguration = UIHostingConfiguration {
                LotComposerForm(desk: desk)
            }
            .margins(.all, 0)
            .background(.clear)
        } else {
            contentView.layer.cornerRadius = FaceRadius.chip
            contentConfiguration = UIHostingConfiguration {
                LotAddChip { desk.beginCompose() }
            }
            .margins(.all, 0)
            .background(.clear)
        }
    }
}
