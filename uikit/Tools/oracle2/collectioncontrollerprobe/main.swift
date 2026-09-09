import UIKit
// Rows the collectionblockingprobe transcript does not pin: a bare
// collection's background, view-before-collection access, custom loadView,
// coder initialization, the standard reordering gesture, and getters that
// must not load the view. Each phase rewrites the JSON so a late crash
// keeps the earlier rows.
var rows: [String: Any] = [:]
func rect(_ r: CGRect) -> [Double] { [r.origin.x, r.origin.y, r.width, r.height].map(Double.init) }
func color(_ c: UIColor?) -> String { c.map { String(describing: $0) } ?? "nil" }
func types(_ v: [UIView]) -> [String] { v.map { String(describing: type(of: $0)) } }
func gestures(_ v: UIView?) -> [String] { (v?.gestureRecognizers ?? []).map { String(describing: type(of: $0)) } }
func save() {
 let data = try! JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted, .sortedKeys])
 try! data.write(to: URL(fileURLWithPath: NSHomeDirectory() + "/Documents/collectioncontroller.json"))
}
class ItemController: UICollectionViewController {
 var didLoadRow: [String: Any] = [:]
 override func viewDidLoad() {
  super.viewDidLoad()
  didLoadRow = ["loaded": isViewLoaded, "collectionNil": collectionView == nil, "superviewIsView": collectionView?.superview === view,
                "frame": rect(collectionView?.frame ?? .null), "viewFrame": rect(view.frame), "background": color(collectionView?.backgroundColor)]
  collectionView?.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
 }
 override func collectionView(_ c: UICollectionView, numberOfItemsInSection s: Int) -> Int { 2 }
 override func collectionView(_ c: UICollectionView, cellForItemAt p: IndexPath) -> UICollectionViewCell { c.dequeueReusableCell(withReuseIdentifier: "cell", for: p) }
}
final class MovableController: ItemController {
 override func collectionView(_ c: UICollectionView, canMoveItemAt p: IndexPath) -> Bool { true }
 override func collectionView(_ c: UICollectionView, moveItemAt s: IndexPath, to d: IndexPath) {}
}
final class PlainLoadView: ItemController {
 override func loadView() { view = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 60)) }
}
final class CollectionLoadView: ItemController {
 let own = UICollectionViewFlowLayout()
 override func loadView() { view = UICollectionView(frame: CGRect(x: 0, y: 0, width: 70, height: 80), collectionViewLayout: own) }
}
final class SubviewLoadView: ItemController {
 override func loadView() {
  let v = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 60))
  v.addSubview(UICollectionView(frame: v.bounds, collectionViewLayout: UICollectionViewFlowLayout()))
  view = v
 }
}
final class App: UIResponder, UIApplicationDelegate {
 var window: UIWindow?
 func application(_ application: UIApplication, didFinishLaunchingWithOptions o: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
  rows["os"] = UIDevice.current.systemVersion
  let bare = UICollectionView(frame: CGRect(x: 0, y: 0, width: 100, height: 100), collectionViewLayout: UICollectionViewFlowLayout())
  rows["bare"] = ["background": color(bare.backgroundColor), "translates": bare.translatesAutoresizingMaskIntoConstraints,
                  "bounceV": bare.alwaysBounceVertical, "gestures": gestures(bare), "insetAdjustment": bare.contentInsetAdjustmentBehavior.rawValue]
  let plainView = UIView(); rows["bareView.background"] = color(plainView.backgroundColor)
  // Getters and setters that must not load the view.
  let lazyVC = ItemController(collectionViewLayout: UICollectionViewFlowLayout())
  _ = lazyVC.collectionViewLayout; let afterLayout = lazyVC.isViewLoaded
  lazyVC.clearsSelectionOnViewWillAppear = false; lazyVC.installsStandardGestureForInteractiveMovement = false
  lazyVC.useLayoutToLayoutNavigationTransitions = true; let afterFlags = lazyVC.isViewLoaded
  rows["lazy"] = ["afterLayoutGetter": afterLayout, "afterFlagSetters": afterFlags]
  // Accessing `view` before `collectionView`.
  let vf = ItemController(collectionViewLayout: UICollectionViewFlowLayout())
  let v = vf.view!
  rows["viewFirst"] = ["loaded": vf.isViewLoaded, "subviews": types(v.subviews), "viewFrame": rect(v.frame), "viewAutoresize": v.autoresizingMask.rawValue,
                       "wrapperBackground": color(v.backgroundColor), "wrapperTranslates": v.translatesAutoresizingMaskIntoConstraints,
                       "collectionFrame": rect(vf.collectionView.frame), "collectionBackground": color(vf.collectionView.backgroundColor),
                       "collectionTranslates": vf.collectionView.translatesAutoresizingMaskIntoConstraints,
                       "insetAdjustment": vf.collectionView.contentInsetAdjustmentBehavior.rawValue, "gestures": gestures(vf.collectionView)]
  rows["viewDidLoad"] = vf.didLoadRow
  save()
  // Custom loadView variants.
  let plain = PlainLoadView(collectionViewLayout: UICollectionViewFlowLayout()); _ = plain.view
  rows["loadView.plain"] = ["subviews": types(plain.view.subviews), "collectionNil": plain.collectionView == nil, "loaded": plain.isViewLoaded, "viewFrame": rect(plain.view.frame)]
  let coll = CollectionLoadView(collectionViewLayout: UICollectionViewFlowLayout()); _ = coll.view
  rows["loadView.collection"] = ["sameView": coll.collectionView === coll.view, "collectionNil": coll.collectionView == nil,
                                 "datasource": (coll.view as? UICollectionView)?.dataSource === coll, "delegate": (coll.view as? UICollectionView)?.delegate === coll,
                                 "layoutIsOwn": coll.collectionViewLayout === coll.own, "viewFrame": rect(coll.view.frame), "viewType": String(describing: type(of: coll.view!)),
                                 "autoresize": coll.view.autoresizingMask.rawValue, "background": color(coll.view.backgroundColor)]
  let sub = SubviewLoadView(collectionViewLayout: UICollectionViewFlowLayout()); _ = sub.view
  rows["loadView.subview"] = ["collectionNil": sub.collectionView == nil, "subviews": types(sub.view.subviews),
                              "datasource": (sub.view.subviews.first as? UICollectionView)?.dataSource === sub]
  save()
  // Reordering gesture, detached.
  let mv = MovableController(collectionViewLayout: UICollectionViewFlowLayout()); mv.view.layoutIfNeeded()
  let mvOff = MovableController(collectionViewLayout: UICollectionViewFlowLayout()); mvOff.installsStandardGestureForInteractiveMovement = false; mvOff.view.layoutIfNeeded()
  let fixed = ItemController(collectionViewLayout: UICollectionViewFlowLayout()); fixed.view.layoutIfNeeded()
  rows["gesture.detached"] = ["movable": gestures(mv.collectionView), "movableOff": gestures(mvOff.collectionView), "fixed": gestures(fixed.collectionView)]
  save()
  let w = UIWindow(frame: UIScreen.main.bounds); w.rootViewController = mv; w.makeKeyAndVisible(); window = w
  DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
   rows["gesture.window.movable"] = ["gestures": gestures(mv.collectionView), "viewBackground": color(mv.view.backgroundColor), "collectionBackground": color(mv.collectionView.backgroundColor)]
   let mvLate = MovableController(collectionViewLayout: UICollectionViewFlowLayout()); mvLate.installsStandardGestureForInteractiveMovement = false
   w.rootViewController = mvLate; mvLate.view.layoutIfNeeded()
   let before = gestures(mvLate.collectionView); mvLate.installsStandardGestureForInteractiveMovement = true
   rows["gesture.window.toggle"] = ["off": before, "onAfterLoad": gestures(mvLate.collectionView)]
   w.rootViewController = fixed; fixed.view.layoutIfNeeded()
   rows["gesture.window.fixed"] = gestures(fixed.collectionView)
   save()
   // Coder initialization: empty keyed archive, then a round trip.
   do {
    let ar = NSKeyedArchiver(requiringSecureCoding: false); ar.finishEncoding()
    let un = try NSKeyedUnarchiver(forReadingFrom: ar.encodedData); un.requiresSecureCoding = false
    let base = UIViewController(coder: un)
    rows["coder.empty.base"] = ["nonNil": base != nil, "loaded": base?.isViewLoaded ?? false, "nibName": base?.nibName ?? "nil"]
    let un2 = try NSKeyedUnarchiver(forReadingFrom: ar.encodedData); un2.requiresSecureCoding = false
    let vc = UICollectionViewController(coder: un2)
    rows["coder.empty"] = ["nonNil": vc != nil, "loaded": vc?.isViewLoaded ?? false, "layoutNil": vc?.value(forKey: "collectionViewLayout") == nil,
                           "clear": vc?.clearsSelectionOnViewWillAppear as Any? ?? NSNull(), "install": vc?.installsStandardGestureForInteractiveMovement as Any? ?? NSNull(),
                           "transitions": vc?.useLayoutToLayoutNavigationTransitions as Any? ?? NSNull()]
    save()
    let src = UICollectionViewController(collectionViewLayout: UICollectionViewFlowLayout())
    src.clearsSelectionOnViewWillAppear = false; src.installsStandardGestureForInteractiveMovement = false; src.useLayoutToLayoutNavigationTransitions = true
    let data = try NSKeyedArchiver.archivedData(withRootObject: src, requiringSecureCoding: false)
    let un3 = try NSKeyedUnarchiver(forReadingFrom: data); un3.requiresSecureCoding = false
    let back = un3.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? UICollectionViewController
    rows["coder.roundTrip"] = ["nonNil": back != nil, "loaded": back?.isViewLoaded ?? false, "layoutType": (back?.value(forKey: "collectionViewLayout")).map { String(describing: type(of: $0)) } ?? "nil",
                               "clear": back?.clearsSelectionOnViewWillAppear as Any? ?? NSNull(), "install": back?.installsStandardGestureForInteractiveMovement as Any? ?? NSNull(),
                               "transitions": back?.useLayoutToLayoutNavigationTransitions as Any? ?? NSNull(), "bytes": data.count]
   } catch { rows["coder.error"] = String(describing: error) }
   save(); exit(0)
  }
  return true
 }
}
UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(App.self))
