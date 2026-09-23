import UIKit

/// Role: Lot. Rim chip. Material elevation. Aimed wears accent. Period and aimed state are readable type.
final class LotRimCell: UICollectionViewCell {
    static let reuse = "sct.lot.rim"

    private let blur = UIVisualEffectView(effect: UIBlurEffect(style: FacePaint.blurStyle()))
    private let nameLabel = UILabel()
    private let amountLabel = UILabel()
    private let captionLabel = UILabel()
    private let hairline = UIView()

    private var usesCardRadius = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        clipsToBounds = false
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = FaceRadius.chip
        contentView.layer.cornerCurve = .continuous

        blur.translatesAutoresizingMaskIntoConstraints = false
        contentView.insertSubview(blur, at: 0)

        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 12 / 17
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        amountLabel.numberOfLines = 1
        amountLabel.adjustsFontForContentSizeCategory = true
        amountLabel.adjustsFontSizeToFitWidth = true
        amountLabel.minimumScaleFactor = 12 / 17
        amountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        amountLabel.setContentHuggingPriority(.required, for: .horizontal)

        captionLabel.numberOfLines = 1
        captionLabel.lineBreakMode = .byTruncatingTail
        captionLabel.adjustsFontForContentSizeCategory = true
        captionLabel.adjustsFontSizeToFitWidth = true
        captionLabel.minimumScaleFactor = 12 / 17
        captionLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        let stack = UIStackView(arrangedSubviews: [nameLabel, amountLabel, captionLabel])
        stack.axis = .vertical
        stack.spacing = FaceSpace.step(1)
        stack.alignment = .leading
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        hairline.translatesAutoresizingMaskIntoConstraints = false
        hairline.isUserInteractionEnabled = false
        contentView.addSubview(hairline)

        let inset = FaceSpace.inner
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: contentView.topAnchor),
            blur.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: inset),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -inset),
            hairline.topAnchor.constraint(equalTo: contentView.topAnchor),
            hairline.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            hairline.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            hairline.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        hairline.layer.cornerRadius = FaceRadius.chip
        hairline.layer.cornerCurve = .continuous
        hairline.layer.borderWidth = FacePaint.hairline
        hairline.backgroundColor = .clear
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyRadius()
    }

    func apply(
        lot: Lot,
        aimed: Bool,
        cooled: Bool,
        mystery: String?,
        currencyCode: String,
        trait: UITraitCollection
    ) {
        usesCardRadius = aimed
        applyRadius()
        let type = FacePaint.typeFont(.caption, trait: trait)
        let sized = max(12, type.pointSize)
        nameLabel.font = type
        amountLabel.font = UIFont.monospacedDigitSystemFont(ofSize: sized, weight: .regular)
        captionLabel.font = type
        nameLabel.minimumScaleFactor = min(1, 12 / sized)
        amountLabel.minimumScaleFactor = min(1, 12 / sized)
        captionLabel.minimumScaleFactor = min(1, 12 / sized)

        nameLabel.text = lot.name
        amountLabel.text = FaceFigures.monthAmount(lot, code: currencyCode)
        captionLabel.text = FaceCopy.rimCaption(period: lot.period, aimed: aimed, cooled: cooled)
        captionLabel.isHidden = false

        let ink = aimed ? FacePaint.surface : FacePaint.ink
        nameLabel.textColor = ink
        amountLabel.textColor = ink
        captionLabel.textColor = ink
        contentView.backgroundColor = aimed ? FacePaint.accent : FacePaint.surface.withAlphaComponent(0.92)
        hairline.layer.borderColor = (aimed ? FacePaint.accent : FacePaint.muted.withAlphaComponent(0.35)).cgColor
        blur.isHidden = aimed

        var parts = [
            lot.name,
            FaceFigures.monthAmount(lot, code: currencyCode),
            FaceCopy.periodWord(lot.period),
        ]
        if aimed { parts.append(FaceCopy.aimedCaption) }
        if cooled { parts.append(FaceCopy.cooledCaption) }
        if let mystery { parts.append(mystery) }
        accessibilityLabel = parts.joined(separator: ". ")
        accessibilityHint = aimed
            ? "Double tap to file this lot quit."
            : "Double tap to cool this lot. The hand stays."
    }

    private func applyRadius() {
        let radius = usesCardRadius ? FaceRadius.card : FaceRadius.chip
        contentView.layer.cornerRadius = radius
        hairline.layer.cornerRadius = radius
        blur.layer.cornerRadius = radius
        blur.clipsToBounds = true
    }

    func applyPressed(_ pressed: Bool, reduceMotion: Bool) {
        let scale: CGFloat = pressed && !reduceMotion ? FaceSnap.pressScale : 1
        let opacity: CGFloat = pressed ? 0.88 : 1
        UIView.animate(
            withDuration: reduceMotion ? FaceSnap.fade : FaceSnap.duration,
            delay: 0,
            options: [.curveEaseOut, .allowUserInteraction]
        ) {
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
            self.alpha = opacity
        }
    }
}
