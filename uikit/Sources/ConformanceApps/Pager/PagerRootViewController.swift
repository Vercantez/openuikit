// Pager's root screen: a scroll-style UIPageViewController, a paging
// UIScrollView of 200 pt cards, a large activity indicator, and a
// UIRefreshControl hosted in a small scroll view so beginRefreshing is
// visible without disturbing the paging offset.
import UIKit

final class PagerRootViewController: UIViewController, UIPageViewControllerDataSource {

    static let pageHeight: CGFloat = 280
    static let cardWidth: CGFloat = 200
    static let cardHeight: CGFloat = 88
    static let cardCount = 4
    /// Fling lands two pages over (400 pt). Page width of the scroller is
    /// the card width, so isPagingEnabled snaps on the same pitch.
    static let flingOffset: CGFloat = cardWidth * 2

    private let pageColors: [UIColor] = [
        UIColor(red: 0.85, green: 0.25, blue: 0.25, alpha: 1),
        UIColor(red: 0.20, green: 0.65, blue: 0.35, alpha: 1),
        UIColor(red: 0.20, green: 0.40, blue: 0.85, alpha: 1),
    ]
    private let pageTitles = ["One", "Two", "Three"]
    private let cardTitles = ["Card A", "Card B", "Card C", "Card D"]
    private let cardColors: [UIColor] = [
        UIColor(red: 0.95, green: 0.70, blue: 0.25, alpha: 1),
        UIColor(red: 0.55, green: 0.35, blue: 0.75, alpha: 1),
        UIColor(red: 0.15, green: 0.55, blue: 0.60, alpha: 1),
        UIColor(red: 0.70, green: 0.30, blue: 0.45, alpha: 1),
    ]

    private var pages: [UIViewController] = []
    private var pageIndex = 0
    private var pageVC: UIPageViewController!
    private(set) var pagingScrollView: UIScrollView!
    private var spinner: UIActivityIndicatorView!
    private var refreshHost: UIScrollView!
    private var refreshControl: UIRefreshControl!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        for (i, title) in pageTitles.enumerated() {
            let page = PagerPageViewController()
            page.heading = title
            page.fill = pageColors[i]
            pages.append(page)
        }

        let pvc = UIPageViewController(transitionStyle: .scroll,
                                       navigationOrientation: .horizontal)
        pvc.dataSource = self
        addChild(pvc)
        pvc.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pvc.view)
        pvc.didMove(toParent: self)
        pageVC = pvc

        let pager = UIScrollView()
        pager.translatesAutoresizingMaskIntoConstraints = false
        pager.isPagingEnabled = true
        pager.showsHorizontalScrollIndicator = false
        pager.showsVerticalScrollIndicator = false
        pager.backgroundColor = .secondarySystemBackground
        pager.clipsToBounds = true
        view.addSubview(pager)
        pagingScrollView = pager

        for i in 0..<Self.cardCount {
            let card = UIView()
            card.backgroundColor = cardColors[i]
            card.layer.cornerRadius = 12
            card.frame = CGRect(x: CGFloat(i) * Self.cardWidth, y: 0,
                                width: Self.cardWidth, height: Self.cardHeight)
            let label = UILabel()
            label.text = cardTitles[i]
            label.font = .preferredFont(forTextStyle: .headline)
            label.textColor = .white
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(label)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: card.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            ])
            pager.addSubview(card)
        }
        pager.contentSize = CGSize(width: Self.cardWidth * CGFloat(Self.cardCount),
                                   height: Self.cardHeight)

        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = false
        view.addSubview(indicator)
        spinner = indicator

        let host = UIScrollView()
        host.translatesAutoresizingMaskIntoConstraints = false
        host.alwaysBounceVertical = true
        host.showsVerticalScrollIndicator = false
        host.backgroundColor = .clear
        view.addSubview(host)
        refreshHost = host
        let rc = UIRefreshControl()
        host.refreshControl = rc
        refreshControl = rc

        NSLayoutConstraint.activate([
            pvc.view.topAnchor.constraint(equalTo: view.topAnchor),
            pvc.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pvc.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pvc.view.heightAnchor.constraint(equalToConstant: Self.pageHeight),

            pager.topAnchor.constraint(equalTo: pvc.view.bottomAnchor, constant: 16),
            pager.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pager.widthAnchor.constraint(equalToConstant: Self.cardWidth),
            pager.heightAnchor.constraint(equalToConstant: Self.cardHeight),

            indicator.topAnchor.constraint(equalTo: pager.bottomAnchor, constant: 24),
            indicator.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),

            host.centerYAnchor.constraint(equalTo: indicator.centerYAnchor),
            host.leadingAnchor.constraint(equalTo: indicator.trailingAnchor, constant: 32),
            host.widthAnchor.constraint(equalToConstant: 80),
            host.heightAnchor.constraint(equalToConstant: 80),
        ])

        pvc.setViewControllers([pages[0]], direction: .forward, animated: false)
        tintPageControl()
    }

    private func tintPageControl() {
        for sub in pageVC.view.subviews {
            if let control = sub as? UIPageControl {
                control.pageIndicatorTintColor = UIColor(white: 0.75, alpha: 1)
                control.currentPageIndicatorTintColor = UIColor(white: 0.20, alpha: 1)
            }
        }
    }

    // MARK: UIPageViewControllerDataSource

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController)
        -> UIViewController? {
        guard let i = pages.firstIndex(where: { $0 === viewController }), i > 0 else {
            return nil
        }
        return pages[i - 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController)
        -> UIViewController? {
        guard let i = pages.firstIndex(where: { $0 === viewController }),
              i + 1 < pages.count else { return nil }
        return pages[i + 1]
    }

    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        pages.count
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        pageIndex
    }

    // MARK: Scripted steps (PagerApp.perform)

    /// `setViewControllers` animated forward. Script captures frames 0, 6,
    /// 12, 18 of the transition and the rest state.
    func pageNext() {
        guard pageIndex + 1 < pages.count else { return }
        pageIndex += 1
        pageVC.setViewControllers([pages[pageIndex]], direction: .forward,
                                  animated: true, completion: nil)
        tintPageControl()
    }

    func pagePrevious() {
        guard pageIndex > 0 else { return }
        pageIndex -= 1
        pageVC.setViewControllers([pages[pageIndex]], direction: .reverse,
                                  animated: true, completion: nil)
        tintPageControl()
    }

    /// `setContentOffset(animated: true)` two pages over on the paging
    /// scroller. Script captures frames 0, 8, 16, 30 and rest; the
    /// presentation-layer offset is the paging curve.
    func fling() {
        pagingScrollView.setContentOffset(CGPoint(x: Self.flingOffset, y: 0),
                                          animated: true)
    }

    /// Start the large activity indicator and the UIRefreshControl at this
    /// named frame. The script captures +9 frames later (Feed t700's 32 pt²
    /// spinner-phase blob is the same clock).
    func startSpinners() {
        spinner.startAnimating()
        refreshHost.setContentOffset(CGPoint(x: 0, y: -60), animated: false)
        refreshControl.beginRefreshing()
    }
}

/// One coloured page with a centred title. `title` is a stored property
/// rather than a designated initializer: real UIKit's designated
/// initializer is `init(nibName:bundle:)` and OpenUIKit's is `init()`,
/// and one source file cannot spell both (NavFlowDetailViewController).
final class PagerPageViewController: UIViewController {
    var heading: String = ""
    var fill: UIColor = .systemBackground
    private let headingLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = fill
        headingLabel.text = heading
        headingLabel.font = .preferredFont(forTextStyle: .largeTitle)
        headingLabel.textColor = .white
        headingLabel.textAlignment = .center
        headingLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headingLabel)
        NSLayoutConstraint.activate([
            headingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            headingLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}
