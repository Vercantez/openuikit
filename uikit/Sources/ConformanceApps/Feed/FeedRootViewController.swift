// Feed's root screen: a compositional UICollectionView with a stories
// strip, a card list, a refresh control and a selection highlight.
import UIKit

/// One card in the vertical section. A plain value type, the way a
/// social-feed app models a post.
struct FeedCard {
    let title: String
    let body: String
}

final class FeedRootViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    private static let storyIdentifier = "FeedStory"
    private static let cardIdentifier = "FeedCard"
    private static let headerIdentifier = "FeedHeader"

    /// 72 pt circles — the stories section's item size, also the letter
    /// overlay's circle radius.
    static let storySize: CGFloat = 72
    /// Gap between story circles.
    static let storySpacing: CGFloat = 12
    /// Insets around the stories strip (leading/trailing also apply to
    /// the card section).
    static let sectionInsets = NSDirectionalEdgeInsets(top: 8, leading: 16,
                                                           bottom: 8, trailing: 16)
    /// Gap between cards.
    static let cardSpacing: CGFloat = 16
    /// Title + two-line body + vertical padding below the 16:9 image.
    /// 12 (image→title) + 22 (headline) + 4 (title→body) + 40 (two lines)
    /// + 12 (below).
    static let cardTextBlock: CGFloat = 90

    private let stories: [String] = ["A", "B", "C", "D", "E", "F", "G", "H"]
    private let cards: [FeedCard] = [
        FeedCard(title: "Morning briefing",
                 body: "A quiet start, then a run of meetings. The 16:9 art is generated, not an asset."),
        FeedCard(title: "Studio notes",
                 body: "Compositional layout keeps the stories strip scrolling sideways while the cards stay a vertical list."),
        FeedCard(title: "Refresh control",
                 body: "Pull to refresh spins above the first section. The script captures mid-spin and the settled rest."),
        FeedCard(title: "Selection highlight",
                 body: "Selecting a card raises selectedBackgroundView. The same source runs on the simulator and the port."),
        FeedCard(title: "Orthogonal stories",
                 body: "Eight 72 pt circles. scroll-stories uses scrollToItem so UIKit's nested scroller and the port agree."),
        FeedCard(title: "Generated art",
                 body: "Each card paints a solid-to-dark gradient UIImage. No catalog, no file, both sides draw the same bytes."),
        FeedCard(title: "Section headers",
                 body: "A boundary supplementary view titles Stories and Today. Header spacing is a measured fidelity gap."),
        FeedCard(title: "The last card",
                 body: "Enough height to scroll 300 pt and still have a card under the fold, so scroll-300 is a layout test."),
    ]

    private(set) var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Feed"
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .always

        let layout = UICollectionViewCompositionalLayout { [weak self] section, environment in
            self?.layoutSection(section, environment: environment)
        }
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .systemBackground
        cv.alwaysBounceVertical = true
        cv.dataSource = self
        cv.delegate = self
        cv.register(FeedStoryCell.self, forCellWithReuseIdentifier: Self.storyIdentifier)
        cv.register(FeedCardCell.self, forCellWithReuseIdentifier: Self.cardIdentifier)
        cv.register(FeedHeaderView.self,
                    forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                    withReuseIdentifier: Self.headerIdentifier)
        cv.refreshControl = UIRefreshControl()
        view.addSubview(cv)
        NSLayoutConstraint.activate([
            cv.topAnchor.constraint(equalTo: view.topAnchor),
            cv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cv.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cv.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        collectionView = cv
        // OpenUIKit's navigation bar has no automatic content-scroll-view
        // detection (UIViewController.setContentScrollView is explicit-only);
        // real UIKit accepts the same call and already tracks this collection.
        setContentScrollView(cv)
    }

    private func layoutSection(_ section: Int,
                               environment: NSCollectionLayoutEnvironment)
        -> NSCollectionLayoutSection {
        if section == 0 {
            return storiesSection()
        }
        return cardsSection(environment: environment)
    }

    private func storiesSection() -> NSCollectionLayoutSection {
        let size = NSCollectionLayoutSize(
            widthDimension: .absolute(Self.storySize),
            heightDimension: .absolute(Self.storySize))
        let item = NSCollectionLayoutItem(layoutSize: size)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = Self.storySpacing
        section.contentInsets = Self.sectionInsets
        section.boundarySupplementaryItems = [Self.headerItem(height: 32)]
        return section
    }

    private func cardsSection(environment: NSCollectionLayoutEnvironment)
        -> NSCollectionLayoutSection {
        let inner = environment.container.effectiveContentSize.width
            - Self.sectionInsets.leading - Self.sectionInsets.trailing
        let imageHeight = inner * 9.0 / 16.0
        let cardHeight = imageHeight + Self.cardTextBlock
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(cardHeight))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = Self.cardSpacing
        section.contentInsets = Self.sectionInsets
        section.boundarySupplementaryItems = [Self.headerItem(height: 32)]
        return section
    }

    private static func headerItem(height: CGFloat) -> NSCollectionLayoutBoundarySupplementaryItem {
        NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(height)),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top)
    }

    // MARK: Data source

    func numberOfSections(in collectionView: UICollectionView) -> Int { 2 }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        section == 0 ? stories.count : cards.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: Self.storyIdentifier, for: indexPath) as! FeedStoryCell
            cell.configure(letter: stories[indexPath.item], index: indexPath.item)
            return cell
        }
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: Self.cardIdentifier, for: indexPath) as! FeedCardCell
        cell.configure(card: cards[indexPath.item], index: indexPath.item)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind, withReuseIdentifier: Self.headerIdentifier,
            for: indexPath) as! FeedHeaderView
        view.configure(title: indexPath.section == 0 ? "Stories" : "Today")
        return view
    }

    // MARK: Scripted steps (FeedApp.perform)

    /// What a programmatic scroll of the main collection does.
    func scrollMain(to y: CGFloat) {
        collectionView.setContentOffset(CGPoint(x: 0, y: y), animated: false)
    }

    /// What a pull-to-refresh that has tripped does: reveal the control
    /// and start the spinner. The script captures +0.3 s later.
    func beginFeedRefresh() {
        let top = collectionView.adjustedContentInset.top
        collectionView.setContentOffset(CGPoint(x: 0, y: -top - 60), animated: false)
        collectionView.refreshControl?.beginRefreshing()
    }

    func endFeedRefresh() {
        collectionView.refreshControl?.endRefreshing()
        let top = collectionView.adjustedContentInset.top
        collectionView.setContentOffset(CGPoint(x: 0, y: -top), animated: false)
    }

    /// What a card tap does. Card 1 is "Studio notes" at the start of the
    /// timeline.
    func selectCard(at item: Int) {
        collectionView.selectItem(at: IndexPath(item: item, section: 1),
                                   animated: false, scrollPosition: [])
    }

    /// What a horizontal flick on the stories strip does: centred on
    /// story E (item 4), via the public scrollToItem API so UIKit's
    /// nested orthogonal scroller and the port's section offset agree.
    func scrollStories() {
        collectionView.scrollToItem(at: IndexPath(item: 4, section: 0),
                                      at: .centeredHorizontally, animated: false)
    }
}

// MARK: - Cells

final class FeedStoryCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let letter = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = FeedRootViewController.storySize / 2
        contentView.addSubview(imageView)
        letter.translatesAutoresizingMaskIntoConstraints = false
        letter.textAlignment = .center
        letter.textColor = .white
        letter.font = .preferredFont(forTextStyle: .headline)
        contentView.addSubview(letter)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            letter.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            letter.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(letter: String, index: Int) {
        self.letter.text = letter
        imageView.image = FeedGradient.image(index: index,
                                              size: CGSize(width: FeedRootViewController.storySize,
                                                            height: FeedRootViewController.storySize))
    }
}

final class FeedCardCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()

    private var configuredIndex = 0
    private var lastImageWidth: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        let selected = UIView()
        selected.backgroundColor = .systemGray4
        selected.layer.cornerRadius = 12
        selectedBackgroundView = selected

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        contentView.addSubview(imageView)

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        bodyLabel.font = .preferredFont(forTextStyle: .subheadline)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 2
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bodyLabel)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor,
                                              multiplier: 9.0 / 16.0),
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            bodyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bodyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = contentView.bounds.width
        guard width > 1, abs(width - lastImageWidth) > 0.5 else { return }
        lastImageWidth = width
        imageView.image = FeedGradient.image(
            index: configuredIndex + 8,
            size: CGSize(width: width, height: width * 9.0 / 16.0))
    }

    func configure(card: FeedCard, index: Int) {
        titleLabel.text = card.title
        bodyLabel.text = card.body
        configuredIndex = index
        lastImageWidth = 0
        setNeedsLayout()
    }
}

final class FeedHeaderView: UICollectionReusableView {
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String) {
        label.text = title
    }
}

/// A generated solid/gradient UIImage. 16 horizontal bands, no assets.
enum FeedGradient {
    static func image(index: Int, size: CGSize) -> UIImage {
        let palette: [(CGFloat, CGFloat, CGFloat)] = [
            (0.25, 0.48, 0.85),
            (0.55, 0.35, 0.75),
            (0.90, 0.40, 0.35),
            (0.20, 0.65, 0.50),
            (0.95, 0.70, 0.25),
            (0.35, 0.55, 0.80),
            (0.70, 0.30, 0.45),
            (0.15, 0.55, 0.60),
        ]
        let c = palette[index % palette.count]
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            let bands = 16
            let bandH = size.height / CGFloat(bands)
            for i in 0..<bands {
                let t = CGFloat(i) / CGFloat(bands)
                UIColor(red: c.0 * (1 - 0.35 * t),
                        green: c.1 * (1 - 0.25 * t),
                        blue: c.2 * (1 - 0.15 * t),
                        alpha: 1).setFill()
                UIRectFill(CGRect(x: 0, y: bandH * CGFloat(i),
                                    width: size.width, height: bandH + 1))
            }
        }
    }
}
