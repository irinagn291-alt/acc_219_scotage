import UIKit

/// Role: Hand. Supplementary needle. Display type is the month total. The short hand aims at the overrun lot.
final class NeedleSupplementary: UICollectionReusableView {
    static let reuse = "sct.needle.view"

    private let disc = UIImageView()
    private let amountLabel = UILabel()
    private let savingsLabel = UILabel()
    private let handView = UIView()
    private let blur = UIVisualEffectView(effect: UIBlurEffect(style: FacePaint.blurStyle()))

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        clipsToBounds = true

        blur.translatesAutoresizingMaskIntoConstraints = false
        blur.clipsToBounds = true
        addSubview(blur)

        disc.image = UIImage(named: FaceArt.controlFace)
        disc.contentMode = .scaleAspectFit
        disc.translatesAutoresizingMaskIntoConstraints = false
        disc.isAccessibilityElement = false
        addSubview(disc)

        amountLabel.numberOfLines = 1
        amountLabel.textAlignment = .center
        amountLabel.adjustsFontForContentSizeCategory = true
        amountLabel.adjustsFontSizeToFitWidth = true
        amountLabel.minimumScaleFactor = 0.7
        amountLabel.translatesAutoresizingMaskIntoConstraints = false

        savingsLabel.numberOfLines = 2
        savingsLabel.textAlignment = .center
        savingsLabel.adjustsFontForContentSizeCategory = true
        savingsLabel.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [amountLabel, savingsLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = FaceSpace.step(1)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        handView.backgroundColor = FacePaint.accent
        handView.layer.cornerRadius = FaceRadius.chip
        handView.layer.cornerCurve = .continuous
        handView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(handView)

        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: topAnchor),
            blur.leadingAnchor.constraint(equalTo: leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: bottomAnchor),
            disc.centerXAnchor.constraint(equalTo: centerXAnchor),
            disc.centerYAnchor.constraint(equalTo: centerYAnchor),
            disc.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.72),
            disc.heightAnchor.constraint(equalTo: disc.widthAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: FaceSpace.inner),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -FaceSpace.inner),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            handView.widthAnchor.constraint(equalToConstant: FaceSpace.step(1)),
            handView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.28),
            handView.centerXAnchor.constraint(equalTo: centerXAnchor),
            handView.bottomAnchor.constraint(equalTo: centerYAnchor),
        ])
        isAccessibilityElement = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2
        clipsToBounds = true
        blur.layer.cornerRadius = bounds.width / 2
        blur.clipsToBounds = true
        handView.layer.anchorPoint = CGPoint(x: 0.5, y: 1)
    }

    func apply(frame: LedgerFrame, angle: CGFloat, reduceMotion: Bool, trait: UITraitCollection) {
        amountLabel.font = FacePaint.typeFont(.display, trait: trait)
        savingsLabel.font = FacePaint.typeFont(.caption, trait: trait)
        amountLabel.textColor = FacePaint.ink
        savingsLabel.textColor = FacePaint.muted
        amountLabel.text = FaceFigures.money(frame.liveLoad, code: frame.currencyCode)
        savingsLabel.text = "\(FaceCopy.savedCaption) \(FaceFigures.money(frame.cancelSavings, code: frame.currencyCode))"
        handView.isHidden = frame.aimedID == nil
        let rotation = angle + .pi / 2
        let applyTransform = {
            self.handView.transform = CGAffineTransform(rotationAngle: rotation)
        }
        if reduceMotion {
            applyTransform()
        } else {
            UIView.animate(withDuration: FaceSnap.duration, delay: 0, options: .curveEaseOut, animations: applyTransform)
        }
        accessibilityLabel = [
            FaceCopy.monthCaption,
            FaceFigures.money(frame.liveLoad, code: frame.currencyCode),
            FaceCopy.savedCaption,
            FaceFigures.money(frame.cancelSavings, code: frame.currencyCode),
        ].joined(separator: ". ")
    }
}
