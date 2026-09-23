import UIKit

/// Role: Scot. Supplementary pin. Caption type. Marks the month the ratepayer can bear.
final class ScotPinSupplementary: UICollectionReusableView {
    static let reuse = "sct.pin.view"

    private let blur = UIVisualEffectView(effect: UIBlurEffect(style: FacePaint.blurStyle()))
    private let titleLabel = UILabel()
    private let amountLabel = UILabel()
    private let hairline = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        clipsToBounds = true
        layer.cornerRadius = FaceRadius.chip
        layer.cornerCurve = .continuous

        blur.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blur)

        titleLabel.numberOfLines = 1
        amountLabel.numberOfLines = 1
        amountLabel.adjustsFontForContentSizeCategory = true
        amountLabel.adjustsFontSizeToFitWidth = true
        amountLabel.minimumScaleFactor = 0.7

        let stack = UIStackView(arrangedSubviews: [titleLabel, amountLabel])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        hairline.translatesAutoresizingMaskIntoConstraints = false
        hairline.backgroundColor = .clear
        hairline.layer.borderWidth = FacePaint.hairline
        hairline.layer.cornerRadius = FaceRadius.chip
        hairline.layer.cornerCurve = .continuous
        addSubview(hairline)

        let inset = FaceSpace.inner
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: topAnchor),
            blur.leadingAnchor.constraint(equalTo: leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: FaceSpace.step(1)),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -FaceSpace.step(1)),
            hairline.topAnchor.constraint(equalTo: topAnchor),
            hairline.leadingAnchor.constraint(equalTo: leadingAnchor),
            hairline.trailingAnchor.constraint(equalTo: trailingAnchor),
            hairline.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        isAccessibilityElement = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    func apply(amount: Double, currencyCode: String, trait: UITraitCollection) {
        titleLabel.font = FacePaint.typeFont(.caption, trait: trait)
        amountLabel.font = FacePaint.typeFont(.caption, trait: trait)
        titleLabel.textColor = FacePaint.muted
        amountLabel.textColor = FacePaint.ink
        titleLabel.text = FaceCopy.scotCaption
        amountLabel.text = FaceFigures.money(amount, code: currencyCode)
        hairline.layer.borderColor = FacePaint.muted.withAlphaComponent(0.35).cgColor
        backgroundColor = FacePaint.surface.withAlphaComponent(0.7)
        accessibilityLabel = "\(FaceCopy.scotCaption) \(FaceFigures.money(amount, code: currencyCode))"
    }
}
