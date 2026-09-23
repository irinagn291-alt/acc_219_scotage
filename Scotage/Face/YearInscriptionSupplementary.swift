import UIKit

/// Role: Face. Year inscription supplementary. Caption. Twelve times the needle.
final class YearInscriptionSupplementary: UICollectionReusableView {
    static let reuse = "sct.year.view"

    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        label.numberOfLines = 1
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        isAccessibilityElement = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    func apply(amount: Double, currencyCode: String, trait: UITraitCollection) {
        label.font = FacePaint.typeFont(.caption, trait: trait)
        label.textColor = FacePaint.muted
        let money = FaceFigures.money(amount, code: currencyCode)
        label.text = "\(FaceCopy.yearCaption) \(money)"
        accessibilityLabel = "\(FaceCopy.yearCaption) \(money)"
    }
}
