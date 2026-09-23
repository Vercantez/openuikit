// Does UIKit's UICollectionViewController itself answer the data-source
// requirements? A storyboard collection controller is the collection's data
// source (outlet) until the app installs its own (NetNewsWire replaces it with
// a diffable data source in viewDidLoad), and -setFrame: during view load
// already asks the flow layout to prepare. iPhone 16 / iOS 26.1.
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let vc = UICollectionViewController(collectionViewLayout: UICollectionViewFlowLayout())
        let items = NSSelectorFromString("collectionView:numberOfItemsInSection:")
        let cell = NSSelectorFromString("collectionView:cellForItemAtIndexPath:")
        let sections = NSSelectorFromString("numberOfSectionsInCollectionView:")
        let supp = NSSelectorFromString("collectionView:viewForSupplementaryElementOfKind:atIndexPath:")
        print("FACT responds items=\(vc.responds(to: items)) cell=\(vc.responds(to: cell)) sections=\(vc.responds(to: sections)) supplementary=\(vc.responds(to: supp))")
        let cv = vc.collectionView!
        print("FACT dataSource=\(cv.dataSource === vc) numberOfSections=\(cv.numberOfSections) items0=\(cv.numberOfItems(inSection: 0))")
        if vc.responds(to: items) {
            print("FACT direct items=\(vc.collectionView(cv, numberOfItemsInSection: 0))")
        }
        cv.frame = CGRect(x: 0, y: 0, width: 300, height: 500)
        cv.layoutIfNeeded()
        print("FACT after frame+layout visibleCells=\(cv.visibleCells.count)")
        let w = UIWindow(frame: UIScreen.main.bounds)
        w.rootViewController = vc
        w.makeKeyAndVisible()
        window = w
        print("DONE")
        exit(0)
    }
}
