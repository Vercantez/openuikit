// Batch B oracle for NetNewsWire's main feed / timeline code paths
// (iPhone 16 / iOS 26.1, run as an app: run.sh). Records
//  * UICollectionViewCell configuration lifecycle: when updateConfiguration
//    (using:) runs, the state it sees, backgroundConfiguration defaults, and
//    setNeedsUpdateConfiguration's timing;
//  * defaults of the scattered members NetNewsWire touches.
import UIKit

nonisolated(unsafe) var events: [String] = []
func log(_ s: String) { events.append(s); print("EV " + s) }

final class PlainCell: UICollectionViewCell {
    var tag0 = ""
    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        log("\(tag0).updateConfiguration selected=\(state.isSelected) highlighted=\(state.isHighlighted) disabled=\(state.isDisabled) editing=\(state.isEditing) window=\(window != nil) bg=\(backgroundConfiguration == nil ? "nil" : "set")")
    }
}

final class Controller: UICollectionViewController {
    init() {
        let layout = UICollectionViewCompositionalLayout.list(using: .init(appearance: .insetGrouped))
        super.init(collectionViewLayout: layout)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(PlainCell.self, forCellWithReuseIdentifier: "c")
    }
    override func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { 2 }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "c", for: indexPath) as! PlainCell
        cell.tag0 = "cell\(indexPath.item)"
        log("cellForItemAt \(indexPath.item) bg=\(cell.backgroundConfiguration == nil ? "nil" : "set")")
        return cell
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Probe.run(self)
    }
}

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let w = UIWindow(frame: UIScreen.main.bounds)
        w.rootViewController = UINavigationController(rootViewController: Controller())
        w.makeKeyAndVisible()
        window = w
        return true
    }
}

@MainActor enum Probe {
    static func run(_ c: Controller) {
        let cv = c.collectionView!
        let cell = cv.cellForItem(at: IndexPath(item: 0, section: 0)) as! PlainCell
        log("--- after appear: configurationState selected=\(cell.configurationState.isSelected) highlighted=\(cell.configurationState.isHighlighted)")
        log("setNeedsUpdateConfiguration begin")
        cell.setNeedsUpdateConfiguration()
        log("setNeedsUpdateConfiguration returned")
        cell.isSelected = true
        log("isSelected=true returned")
        cv.layoutIfNeeded()
        log("layoutIfNeeded returned")
        DispatchQueue.main.async {
            log("next turn")
            let fresh = UICollectionViewCell()
            print("FACT UICollectionViewCell().backgroundConfiguration=\(fresh.backgroundConfiguration == nil ? "nil" : "set") contentConfiguration=\(fresh.contentConfiguration == nil ? "nil" : "set") automaticallyUpdatesBackgroundConfiguration=\(fresh.automaticallyUpdatesBackgroundConfiguration) automaticallyUpdatesContentConfiguration=\(fresh.automaticallyUpdatesContentConfiguration)")
            print("FACT UICollectionViewListCell().backgroundConfiguration=\(UICollectionViewListCell().backgroundConfiguration == nil ? "nil" : "set")")
            var bg = UIBackgroundConfiguration.listCell()
            print("FACT listCell() backgroundColor=\(bg.backgroundColor.map { "\($0)" } ?? "nil") insets=\(bg.backgroundInsets) cornerRadius=\(bg.cornerRadius)")
            bg = UIBackgroundConfiguration.clear()
            print("FACT clear() backgroundColor=\(bg.backgroundColor.map { "\($0)" } ?? "nil")")
            print("FACT UIFont.systemFontSize=\(UIFont.systemFontSize) smallSystemFontSize=\(UIFont.smallSystemFontSize) labelFontSize=\(UIFont.labelFontSize) buttonFontSize=\(UIFont.buttonFontSize)")
            let l = UILabel()
            print("FACT UILabel isEnabled=\(l.isEnabled) highlightedTextColor=\(l.highlightedTextColor.map { "\($0)" } ?? "nil") isHighlighted=\(l.isHighlighted)")
            let sv = UIScrollView()
            print("FACT UIScrollView contentInsetAdjustmentBehavior=\(sv.contentInsetAdjustmentBehavior.rawValue) bouncesZoom=\(sv.bouncesZoom) zoomScale=\(sv.zoomScale) min=\(sv.minimumZoomScale) max=\(sv.maximumZoomScale)")
            print("FACT UIScrollView.ContentInsetAdjustmentBehavior automatic=\(UIScrollView.ContentInsetAdjustmentBehavior.automatic.rawValue) scrollableAxes=\(UIScrollView.ContentInsetAdjustmentBehavior.scrollableAxes.rawValue) never=\(UIScrollView.ContentInsetAdjustmentBehavior.never.rawValue) always=\(UIScrollView.ContentInsetAdjustmentBehavior.always.rawValue)")
            let vc = UIViewController()
            print("FACT definesPresentationContext=\(vc.definesPresentationContext) toolbarItems=\(vc.toolbarItems.map { "\($0.count)" } ?? "nil")")
            vc.setToolbarItems([UIBarButtonItem.flexibleSpace()], animated: false)
            print("FACT setToolbarItems -> toolbarItems=\(vc.toolbarItems?.count ?? -1)")
            let pan = UIPanGestureRecognizer()
            print("FACT pan.allowedScrollTypesMask=\(pan.allowedScrollTypesMask.rawValue) UIScrollTypeMask.all=\(UIScrollTypeMask.all.rawValue)")
            let sb = UISearchBar()
            print("FACT UISearchBar barTintColor=\(sb.barTintColor.map { "\($0)" } ?? "nil") scopeBarBackgroundImage=\(sb.scopeBarBackgroundImage == nil ? "nil" : "set") autocapitalizationType=\(sb.autocapitalizationType.rawValue)")
            let conf = UICollectionViewCompositionalLayoutConfiguration()
            print("FACT compositional contentInsetsReference=\(conf.contentInsetsReference.rawValue) safeArea=\(UIContentInsetsReference.safeArea.rawValue) automatic=\(UIContentInsetsReference.automatic.rawValue) none=\(UIContentInsetsReference.none.rawValue) layoutMargins=\(UIContentInsetsReference.layoutMargins.rawValue) readableContent=\(UIContentInsetsReference.readableContent.rawValue)")
            print("FACT UIAccessibility.Notification.announcement=\(UIAccessibility.Notification.announcement.rawValue) isVoiceOverRunning=\(UIAccessibility.isVoiceOverRunning)")
            UIAccessibility.post(notification: .announcement, argument: "x")
            print("FACT UIScene.didEnterBackgroundNotification=\(UIScene.didEnterBackgroundNotification.rawValue)")
            let pi = UIPointerInteraction(delegate: nil)
            print("FACT UIPointerInteraction delegate=\(pi.delegate == nil ? "nil" : "set") isEnabled=\(pi.isEnabled)")
            var snap = NSDiffableDataSourceSnapshot<Int, Int>()
            snap.appendSections([0]); snap.appendItems([1, 2])
            snap.reconfigureItems([1])
            print("FACT snapshot.reconfiguredItemIdentifiers=\(snap.reconfiguredItemIdentifiers) reloaded=\(snap.reloadedItemIdentifiers)")
            print("DONE")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { exit(0) }
        }
    }
}
