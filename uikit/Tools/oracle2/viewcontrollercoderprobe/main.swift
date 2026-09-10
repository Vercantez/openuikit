import UIKit
// UIViewController.init?(coder:) base rows: what an empty keyed archive
// yields for the base class, a subclass with its own designated initializer,
// and the container subclasses whose required initializer must chain to it.
// Each phase rewrites the JSON so a late crash keeps the earlier rows.
var rows: [String: Any] = [:]
func rect(_ r: CGRect) -> [Double] { [r.origin.x, r.origin.y, r.width, r.height].map(Double.init) }
func color(_ c: UIColor?) -> String { c.map { String(describing: $0) } ?? "nil" }
func save() {
 let data = try! JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted, .sortedKeys])
 try! data.write(to: URL(fileURLWithPath: NSHomeDirectory() + "/Documents/viewcontrollercoder.json"))
}
func emptyCoder() -> NSKeyedUnarchiver {
 let ar = NSKeyedArchiver(requiringSecureCoding: false); ar.finishEncoding()
 let un = try! NSKeyedUnarchiver(forReadingFrom: ar.encodedData); un.requiresSecureCoding = false
 return un
}
/// Everything readable on a controller before and after its view loads.
func describe(_ vc: UIViewController?) -> [String: Any] {
 guard let vc else { return ["nonNil": false] }
 var r: [String: Any] = ["nonNil": true, "loadedBefore": vc.isViewLoaded, "nibName": vc.nibName ?? "nil",
                         "nibBundleIsMain": vc.nibBundle === Bundle.main, "nibBundleNil": vc.nibBundle == nil,
                         "title": vc.title ?? "nil", "viewIfLoadedNil": vc.viewIfLoaded == nil,
                         "storyboardNil": vc.storyboard == nil, "restorationId": vc.restorationIdentifier ?? "nil"]
 let v = vc.view!
 r["loadedAfter"] = vc.isViewLoaded
 r["viewClass"] = String(describing: type(of: v))
 r["viewFrame"] = rect(v.frame)
 r["viewBackground"] = color(v.backgroundColor)
 r["viewAutoresizing"] = Int(v.autoresizingMask.rawValue)
 r["viewSubviews"] = v.subviews.count
 return r
}
/// A subclass shaped like an app's programmatic controller: one designated
/// initializer of its own plus the required coder initializer chaining up.
class FramedController: UIViewController {
 let frame: CGRect
 var loadCount = 0
 init(frame: CGRect) { self.frame = frame; super.init(nibName: nil, bundle: nil) }
 required init?(coder: NSCoder) { frame = CGRect(x: 1, y: 2, width: 3, height: 4); super.init(coder: coder) }
 override func viewDidLoad() { super.viewDidLoad(); loadCount += 1 }
}
/// Same shape, but the class name matches no nib and nibName is queried
/// from inside loadView (Apple's default loadView consults it).
final class TitledController: FramedController {
 override init(frame: CGRect) { super.init(frame: frame); title = "programmatic" }
 required init?(coder: NSCoder) { super.init(coder: coder) }
}
autoreleasepool {
 rows["base.coder"] = describe(UIViewController(coder: emptyCoder()))
 rows["base.programmatic"] = describe(UIViewController())
 rows["base.nilnil"] = describe(UIViewController(nibName: nil, bundle: nil))
 save()
 let framed = FramedController(coder: emptyCoder())
 var fr = describe(framed)
 fr["frame"] = framed.map { rect($0.frame) } ?? []
 fr["viewDidLoadCount"] = framed?.loadCount ?? -1
 rows["subclass.coder"] = fr
 let framedP = FramedController(frame: CGRect(x: 5, y: 6, width: 7, height: 8))
 var frp = describe(framedP)
 frp["frame"] = rect(framedP.frame); frp["viewDidLoadCount"] = framedP.loadCount
 rows["subclass.programmatic"] = frp
 rows["subclass.titled.coder"] = describe(TitledController(coder: emptyCoder()))
 save()
 // Container subclasses on the same empty archive.
 let table = UITableViewController(coder: emptyCoder())
 var t = describe(table)
 t["style"] = table?.tableView.style.rawValue ?? -1
 t["clearsSelection"] = table?.clearsSelectionOnViewWillAppear ?? false
 t["refreshControlNil"] = table?.refreshControl == nil
 t["tableIsView"] = table?.tableView === table?.view
 rows["table.coder"] = t
 let tableP = UITableViewController(style: .plain)
 var tp = describe(tableP); tp["style"] = tableP.tableView.style.rawValue
 rows["table.programmatic"] = tp
 save()
 let coll = UICollectionViewController(coder: emptyCoder())
 rows["collection.coder"] = ["nonNil": coll != nil, "loadedBefore": coll?.isViewLoaded ?? false,
                             "layoutNil": coll?.value(forKey: "collectionViewLayout") == nil, "nibName": coll?.nibName ?? "nil",
                             "title": coll?.title ?? "nil"]
 save()
 let nav = UINavigationController(coder: emptyCoder())
 var n = describe(nav)
 n["viewControllers"] = nav?.viewControllers.count ?? -1
 n["navigationBarClass"] = nav.map { String(describing: type(of: $0.navigationBar)) } ?? "nil"
 n["toolbarClass"] = nav.map { String(describing: type(of: $0.toolbar)) } ?? "nil"
 n["isNavigationBarHidden"] = nav?.isNavigationBarHidden ?? false
 rows["navigation.coder"] = n
 let tab = UITabBarController(coder: emptyCoder())
 var tb = describe(tab)
 tb["viewControllersNil"] = tab?.viewControllers == nil
 tb["viewControllers"] = tab?.viewControllers?.count ?? -1
 tb["selectedIndex"] = tab?.selectedIndex ?? -1
 rows["tab.coder"] = tb
 save()
 let split = UISplitViewController(coder: emptyCoder())
 var sp = describe(split)
 sp["viewControllers"] = split?.viewControllers.count ?? -1
 sp["style"] = split?.style.rawValue ?? -1
 rows["split.coder"] = sp
 let page = UIPageViewController(coder: emptyCoder())
 var pg = describe(page)
 pg["viewControllersNil"] = page?.viewControllers == nil
 pg["transitionStyle"] = page?.transitionStyle.rawValue ?? -1
 pg["orientation"] = page?.navigationOrientation.rawValue ?? -1
 rows["page.coder"] = pg
 save()
 let alert = UIAlertController(coder: emptyCoder())
 rows["alert.coder"] = ["nonNil": alert != nil, "loadedBefore": alert?.isViewLoaded ?? false,
                        "title": alert?.title ?? "nil", "message": alert?.message ?? "nil",
                        "style": alert?.preferredStyle.rawValue ?? -1, "actions": alert?.actions.count ?? -1]
 save()
 let search = UISearchController(coder: emptyCoder())
 rows["search.coder"] = ["nonNil": search != nil, "loadedBefore": search?.isViewLoaded ?? false,
                         "resultsNil": search?.searchResultsController == nil]
 save()
 // Round trip of a programmatic controller with a title: which keys survive.
 let src = UIViewController(); src.title = "kept"; src.restorationIdentifier = "rid"
 let data = try! NSKeyedArchiver.archivedData(withRootObject: src, requiringSecureCoding: false)
 let un = try! NSKeyedUnarchiver(forReadingFrom: data); un.requiresSecureCoding = false
 let back = un.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? UIViewController
 var rt = describe(back); rt["bytes"] = data.count
 rows["base.roundTrip"] = rt
 save()
}
print("viewcontrollercoder probe done")
exit(0)
