import SwiftUI
import UIKit

/// Role: Face. One UIKit UICollectionView. Compositional custom group places Lots as rim arcs. Wrapped once.
struct LedgerBoard: UIViewControllerRepresentable {
    var desk: FaceDesk
    var reduceMotion: Bool

    func makeUIViewController(context: Context) -> LedgerBoardController {
        let controller = LedgerBoardController()
        controller.reduceMotion = reduceMotion
        controller.desk = desk
        controller.apply(desk.ledgerFrame)
        return controller
    }

    func updateUIViewController(_ controller: LedgerBoardController, context: Context) {
        controller.reduceMotion = reduceMotion
        controller.desk = desk
        controller.apply(desk.ledgerFrame)
    }
}

/// Role: Face. Owns the collection, snapshot, needle, Scot pin, and year inscription.
@MainActor
final class LedgerBoardController: UIViewController, UICollectionViewDelegate {
    let collectionView: UICollectionView
    var frame: LedgerFrame = .empty
    var desk: FaceDesk?
    var reduceMotion = false
    private var dataSource: UICollectionViewDiffableDataSource<LedgerSection, LedgerItem>?
    private var lastSize: CGSize = .zero
    private var lastItems: [LedgerItem] = []
    private var lastComposing = false
    private var lastAimed: UUID?
    private var packed: LedgerPack = .empty
    private var backdrop = UIImageView()

    init() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: Self.placeholderLayout())
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        collectionView.keyboardDismissMode = .interactive
        collectionView.accessibilityIdentifier = "sct.ledger"
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.backgroundView = backdrop
        backdrop.image = UIImage(named: FaceArt.cardBackdrop)
        backdrop.contentMode = .scaleAspectFill
        backdrop.clipsToBounds = true
        backdrop.alpha = 0.35
        backdrop.isAccessibilityElement = false
        collectionView.register(LotRimCell.self, forCellWithReuseIdentifier: LotRimCell.reuse)
        collectionView.register(LotComposerCell.self, forCellWithReuseIdentifier: LotComposerCell.reuse)
        collectionView.register(
            NeedleSupplementary.self,
            forSupplementaryViewOfKind: LedgerKinds.needle,
            withReuseIdentifier: NeedleSupplementary.reuse
        )
        collectionView.register(
            ScotPinSupplementary.self,
            forSupplementaryViewOfKind: LedgerKinds.pin,
            withReuseIdentifier: ScotPinSupplementary.reuse
        )
        collectionView.register(
            YearInscriptionSupplementary.self,
            forSupplementaryViewOfKind: LedgerKinds.year,
            withReuseIdentifier: YearInscriptionSupplementary.reuse
        )
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        configureDataSource()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChange),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    nonisolated deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let size = collectionView.bounds.size
        guard abs(size.width - lastSize.width) > 1 || abs(size.height - lastSize.height) > 1 else {
            return
        }
        lastSize = size
        installLayout()
        applySnapshot(animated: false)
    }

    func apply(_ frame: LedgerFrame) {
        self.frame = frame
        guard isViewLoaded else { return }
        let items = frame.items
        let layoutChanged =
            items != lastItems
            || frame.composing != lastComposing
            || frame.aimedID != lastAimed
        lastItems = items
        lastComposing = frame.composing
        lastAimed = frame.aimedID
        if layoutChanged || lastSize != collectionView.bounds.size {
            lastSize = collectionView.bounds.size
            installLayout()
        }
        applySnapshot(animated: !reduceMotion)
        refreshVisible()
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        guard let item = dataSource?.itemIdentifier(for: indexPath) else { return }
        switch item {
        case .lot(let id):
            Task { await desk?.tapLot(id) }
        case .composer:
            if frame.composing { return }
            desk?.beginCompose()
        }
    }

    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        (collectionView.cellForItem(at: indexPath) as? LotRimCell)?.applyPressed(true, reduceMotion: reduceMotion)
    }

    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        (collectionView.cellForItem(at: indexPath) as? LotRimCell)?.applyPressed(false, reduceMotion: reduceMotion)
    }

    private func configureDataSource() {
        let source = UICollectionViewDiffableDataSource<LedgerSection, LedgerItem>(
            collectionView: collectionView
        ) { [weak self] collection, indexPath, item in
            self?.cell(in: collection, at: indexPath, item: item) ?? UICollectionViewCell()
        }
        source.supplementaryViewProvider = { [weak self] collection, kind, indexPath in
            self?.supplementary(in: collection, kind: kind, at: indexPath) ?? UICollectionReusableView()
        }
        dataSource = source
    }

    private func cell(
        in collection: UICollectionView,
        at indexPath: IndexPath,
        item: LedgerItem
    ) -> UICollectionViewCell {
        switch item {
        case .lot(let id):
            guard let cell = collection.dequeueReusableCell(
                withReuseIdentifier: LotRimCell.reuse,
                for: indexPath
            ) as? LotRimCell else {
                return UICollectionViewCell()
            }
            if let lot = frame.lot(id: id) {
                let mystery: String?
                if frame.mysteryIDs.contains(id) {
                    mystery = FaceCopy.mysteryReason(lot, sharedDay: frame.sharedDayIDs.contains(id))
                } else {
                    mystery = nil
                }
                cell.apply(
                    lot: lot,
                    aimed: frame.aimedID == id,
                    cooled: frame.cooledIDs.contains(id),
                    mystery: mystery,
                    currencyCode: frame.currencyCode,
                    trait: traitCollection
                )
            }
            return cell
        case .composer:
            guard let cell = collection.dequeueReusableCell(
                withReuseIdentifier: LotComposerCell.reuse,
                for: indexPath
            ) as? LotComposerCell else {
                return UICollectionViewCell()
            }
            if let desk {
                cell.apply(desk: desk, composing: frame.composing)
            }
            return cell
        }
    }

    private func supplementary(
        in collection: UICollectionView,
        kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView? {
        switch kind {
        case LedgerKinds.needle:
            guard let view = collection.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: NeedleSupplementary.reuse,
                for: indexPath
            ) as? NeedleSupplementary else {
                return UICollectionReusableView()
            }
            view.apply(
                frame: frame,
                angle: packedAimedAngle(),
                reduceMotion: reduceMotion,
                trait: traitCollection
            )
            return view
        case LedgerKinds.pin:
            guard let view = collection.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: ScotPinSupplementary.reuse,
                for: indexPath
            ) as? ScotPinSupplementary else {
                return UICollectionReusableView()
            }
            view.apply(amount: frame.scot, currencyCode: frame.currencyCode, trait: traitCollection)
            return view
        case LedgerKinds.year:
            guard let view = collection.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: YearInscriptionSupplementary.reuse,
                for: indexPath
            ) as? YearInscriptionSupplementary else {
                return UICollectionReusableView()
            }
            view.apply(amount: frame.yearLoad, currencyCode: frame.currencyCode, trait: traitCollection)
            return view
        default:
            return UICollectionReusableView()
        }
    }

    private func applySnapshot(animated: Bool) {
        guard let dataSource else { return }
        var snapshot = NSDiffableDataSourceSnapshot<LedgerSection, LedgerItem>()
        snapshot.appendSections([.face])
        snapshot.appendItems(frame.items, toSection: .face)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }

    private func refreshVisible() {
        for case let cell as LotRimCell in collectionView.visibleCells {
            guard let indexPath = collectionView.indexPath(for: cell),
                  let item = dataSource?.itemIdentifier(for: indexPath),
                  case .lot(let id) = item,
                  let lot = frame.lot(id: id)
            else { continue }
            let mystery: String?
            if frame.mysteryIDs.contains(id) {
                mystery = FaceCopy.mysteryReason(lot, sharedDay: frame.sharedDayIDs.contains(id))
            } else {
                mystery = nil
            }
            cell.apply(
                lot: lot,
                aimed: frame.aimedID == id,
                cooled: frame.cooledIDs.contains(id),
                mystery: mystery,
                currencyCode: frame.currencyCode,
                trait: traitCollection
            )
        }
        for case let cell as LotComposerCell in collectionView.visibleCells {
            if let desk {
                cell.apply(desk: desk, composing: frame.composing)
            }
        }
        for view in collectionView.visibleSupplementaryViews(ofKind: LedgerKinds.needle) {
            (view as? NeedleSupplementary)?.apply(
                frame: frame,
                angle: packedAimedAngle(),
                reduceMotion: reduceMotion,
                trait: traitCollection
            )
        }
        for view in collectionView.visibleSupplementaryViews(ofKind: LedgerKinds.pin) {
            (view as? ScotPinSupplementary)?.apply(
                amount: frame.scot,
                currencyCode: frame.currencyCode,
                trait: traitCollection
            )
        }
        for view in collectionView.visibleSupplementaryViews(ofKind: LedgerKinds.year) {
            (view as? YearInscriptionSupplementary)?.apply(
                amount: frame.yearLoad,
                currencyCode: frame.currencyCode,
                trait: traitCollection
            )
        }
    }

    private func installLayout() {
        let size = collectionView.bounds.size
        guard size.width > 1, size.height > 1 else { return }
        collectionView.setCollectionViewLayout(makeLayout(in: size), animated: false)
    }

    private func makeLayout(in size: CGSize) -> UICollectionViewCompositionalLayout {
        let lots = frame.lots.count
        let composing = frame.composing
        let aimedIndex = frame.lots.firstIndex(where: { $0.id == frame.aimedID })
        let pinAngle = LedgerRimLayout.scotAngle(scot: frame.scot, liveLoad: frame.liveLoad)
        let pack = LedgerRimLayout.pack(
            lots: lots,
            composing: composing,
            in: size,
            aimedIndex: aimedIndex,
            pinAngle: pinAngle,
            trait: traitCollection
        )
        packed = pack
        let custom = LedgerRimLayout.customItems(
            lots: lots,
            composing: composing,
            aimedIndex: aimedIndex,
            in: size,
            trait: traitCollection,
            pinAngle: pinAngle
        )
        let group = NSCollectionLayoutGroup.custom(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(size.height)
            )
        ) { _ in
            custom
        }
        group.supplementaryItems = [
            Self.anchored(kind: LedgerKinds.needle, rect: pack.needle, zIndex: 4),
            Self.anchored(kind: LedgerKinds.pin, rect: pack.pin, zIndex: 5),
            Self.anchored(kind: LedgerKinds.year, rect: pack.year, zIndex: 3),
        ]
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .zero
        return UICollectionViewCompositionalLayout(section: section)
    }

    private static func anchored(
        kind: String,
        rect: CGRect,
        zIndex: Int
    ) -> NSCollectionLayoutSupplementaryItem {
        let item = NSCollectionLayoutSupplementaryItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .absolute(max(1, rect.width)),
                heightDimension: .absolute(max(1, rect.height))
            ),
            elementKind: kind,
            containerAnchor: NSCollectionLayoutAnchor(
                edges: [.top, .leading],
                absoluteOffset: CGPoint(x: rect.minX, y: rect.minY)
            ),
            itemAnchor: NSCollectionLayoutAnchor(edges: [.top, .leading])
        )
        item.zIndex = zIndex
        return item
    }

    private static func placeholderLayout() -> UICollectionViewCompositionalLayout {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .fractionalHeight(1)
            )
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .fractionalHeight(1)
            ),
            subitems: [item]
        )
        return UICollectionViewCompositionalLayout(section: NSCollectionLayoutSection(group: group))
    }

    private func packedAimedAngle() -> CGFloat {
        guard let aimedID = frame.aimedID,
              let index = frame.lots.firstIndex(where: { $0.id == aimedID }),
              packed.lotAngles.indices.contains(index)
        else {
            return -.pi / 2
        }
        return packed.lotAngles[index]
    }

    @objc private func keyboardWillChange(_ note: Notification) {
        guard let end = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let local = view.convert(end, from: nil)
        let overlap = max(0, view.bounds.maxY - local.minY)
        collectionView.contentInset.bottom = overlap
        collectionView.verticalScrollIndicatorInsets.bottom = overlap
        if frame.composing {
            let card = LedgerRimLayout.composerCard(in: collectionView.bounds.size)
            collectionView.scrollRectToVisible(card.insetBy(dx: 0, dy: -FaceSpace.card), animated: !reduceMotion)
        }
    }

    @objc private func keyboardWillHide(_ note: Notification) {
        collectionView.contentInset.bottom = 0
        collectionView.verticalScrollIndicatorInsets.bottom = 0
    }
}
