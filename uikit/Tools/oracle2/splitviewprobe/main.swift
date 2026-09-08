import UIKit

@MainActor var rows: [String] = []
@MainActor func log(_ s: String) { rows.append(s); try! rows.joined(separator: "\n").write(to: URL.documentsDirectory.appending(path: "splitview.txt"), atomically: true, encoding: .utf8) }
@MainActor func name(_ v: UIViewController?) -> String { guard let v else { return "nil" }; if let n = v as? UINavigationController { return "nav[" + n.viewControllers.map { name($0) }.joined(separator: ",") + "]" }; return v.title ?? String(describing: type(of: v)) }
@MainActor class Child: UIViewController {
 init(_ title: String) { super.init(nibName: nil, bundle: nil); self.title = title }
 required init?(coder: NSCoder) { fatalError() }
 override func willMove(toParent parent: UIViewController?) { log("event \(title!) willMove \(name(parent))") }
 override func didMove(toParent parent: UIViewController?) { log("event \(title!) didMove \(name(parent))") }
 override func loadView() { log("event \(title!) load"); view = UIView(); view.backgroundColor = .red }
}
@MainActor func snap(_ label: String, _ s: UISplitViewController) {
 log("\(label) style=\(s.style.rawValue) loaded=\(s.isViewLoaded) collapsed=\(s.isCollapsed) mode=\(s.displayMode.rawValue) preferred=\(s.preferredDisplayMode.rawValue) behavior=\(s.style == .unspecified ? "n/a" : "\(s.splitBehavior.rawValue)/\(s.preferredSplitBehavior.rawValue)") vcs=\(s.viewControllers.map { name($0) }) children=\(s.children.map { name($0) }) primary=\(s.primaryColumnWidth) supplementary=\(s.style != .tripleColumn ? -1 : s.supplementaryColumnWidth)")
}
@MainActor func configs(_ s: UISplitViewController) {
 if s.style == .unspecified {
 log("config legacy auto=\(UISplitViewController.automaticDimension) gesture=\(s.presentsWithGesture) edge=\(s.primaryEdge.rawValue) background=\(s.primaryBackgroundStyle.rawValue) primary=\(s.preferredPrimaryColumnWidthFraction),\(s.minimumPrimaryColumnWidth),\(s.maximumPrimaryColumnWidth)")
 return
 }
 log("config auto=\(UISplitViewController.automaticDimension) gesture=\(s.presentsWithGesture) edge=\(s.primaryEdge.rawValue) background=\(s.primaryBackgroundStyle.rawValue) button=\(s.displayModeButtonVisibility.rawValue) secondaryOnly=\(s.showsSecondaryOnlyButton) primary=\(s.preferredPrimaryColumnWidthFraction),\(s.preferredPrimaryColumnWidth),\(s.minimumPrimaryColumnWidth),\(s.maximumPrimaryColumnWidth) supplementary=\(s.style == .tripleColumn ? "\(s.preferredSupplementaryColumnWidthFraction),\(s.preferredSupplementaryColumnWidth),\(s.minimumSupplementaryColumnWidth),\(s.maximumSupplementaryColumnWidth)" : "n/a") secondary=\(s.preferredSecondaryColumnWidthFraction),\(s.preferredSecondaryColumnWidth),\(s.minimumSecondaryColumnWidth) inspector=\(s.preferredInspectorColumnWidthFraction),\(s.preferredInspectorColumnWidth),\(s.minimumInspectorColumnWidth),\(s.maximumInspectorColumnWidth)")
}
@MainActor func columns(_ label: String, _ s: UISplitViewController) {
 let cols: [UISplitViewController.Column] = s.style == .tripleColumn ? [.primary, .supplementary, .secondary, .compact, .inspector] : [.primary, .secondary, .compact, .inspector]
 log(label + " " + cols.map { c in "\(c.rawValue):\(name(s.viewController(for: c))):\(s.isShowing(c))" }.joined(separator: " "))
}
@MainActor func tree(_ label: String, _ s: UISplitViewController) {
 snap(label, s)
 for child in s.children { log("container \(name(child)) frame=\(child.view.frame) absolute=\(child.view.convert(child.view.bounds, to: s.view))") }
 for v in s.viewControllers { log("frame \(name(v)) \(v.view.frame) child=\(String(describing: (v as? UINavigationController)?.topViewController?.view.frame)) parent=\(name(v.parent))") }
}
@MainActor final class Delegate: NSObject, UISplitViewControllerDelegate {
 var handled = true
 func splitViewController(_ s: UISplitViewController, show vc: UIViewController, sender: Any?) -> Bool { log("delegate show \(name(vc)) handled=\(handled)"); return handled }
 func splitViewController(_ s: UISplitViewController, showDetail vc: UIViewController, sender: Any?) -> Bool { log("delegate detail \(name(vc)) handled=\(handled)"); return handled }
 func splitViewController(_ s: UISplitViewController, willChangeTo mode: UISplitViewController.DisplayMode) { log("delegate mode \(mode.rawValue)") }
 func splitViewControllerDidCollapse(_ s: UISplitViewController) { log("delegate collapsed") }
 func splitViewControllerDidExpand(_ s: UISplitViewController) { log("delegate expanded") }
}
@MainActor final class RoutingController: UIViewController {
 override func present(_ vc: UIViewController, animated: Bool, completion: (() -> Void)? = nil) { log("route present animated=\(animated)"); completion?() }
}
@MainActor final class App: UIResponder, UIApplicationDelegate {
 var window: UIWindow?
 let observer = Delegate()
 var queue: [(String, UISplitViewController)] = []
 func application(_ application: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
  log("oracle iOS=\(UIDevice.current.systemVersion) model=\(UIDevice.current.model) screen=\(UIScreen.main.bounds) scale=\(UIScreen.main.scale)")
  log("enum style=\([UISplitViewController.Style.unspecified,.doubleColumn,.tripleColumn].map(\.rawValue)) mode=\([UISplitViewController.DisplayMode.automatic,.secondaryOnly,.oneBesideSecondary,.oneOverSecondary,.twoBesideSecondary,.twoOverSecondary,.twoDisplaceSecondary].map(\.rawValue)) column=\([UISplitViewController.Column.primary,.supplementary,.secondary,.compact,.inspector].map(\.rawValue)) behavior=\([UISplitViewController.SplitBehavior.automatic,.tile,.overlay,.displace].map(\.rawValue)) edge=\([UISplitViewController.PrimaryEdge.leading,.trailing].map(\.rawValue)) background=\([UISplitViewController.BackgroundStyle.none,.sidebar].map(\.rawValue)) button=\([UISplitViewController.DisplayModeButtonVisibility.automatic,.never,.always].map(\.rawValue))")
  switch CommandLine.arguments.last {
  case "legacy-splitBehavior": log("invalid legacy-splitBehavior"); _ = UISplitViewController().splitBehavior; exit(0)
  case "double-supplementaryWidth": log("invalid double-supplementaryWidth"); _ = UISplitViewController(style: .doubleColumn).supplementaryColumnWidth; exit(0)
  case "duplicate-column":
   let split = UISplitViewController(), a = UIViewController(), b = UIViewController()
   split.viewControllers = [a,b]; log("invalid duplicate-column"); split.viewControllers = [b]; exit(0)
  default: break
  }
  if CommandLine.arguments.last == "detail-routing" {
   let root = UIViewController()
   window = UIWindow(frame: UIScreen.main.bounds); window!.rootViewController = root; window!.makeKeyAndVisible()
   DispatchQueue.main.asyncAfter(deadline: .now()+0.3) {
    let detail = UIViewController(); root.showDetailViewController(detail, sender: nil)
    DispatchQueue.main.asyncAfter(deadline: .now()+0.7) { log("route presented=\(root.presentedViewController === detail)"); exit(0) }
   }
   return true
  }
  let weakSplit = UISplitViewController()
  do { let temporary = Delegate(); weakSplit.delegate = temporary }
  log("weakDelegate nil=\(weakSplit.delegate == nil)")
  for style in [UISplitViewController.Style.unspecified,.doubleColumn,.tripleColumn] {
   let s = style == .unspecified ? UISplitViewController() : UISplitViewController(style: style)
   snap("defaults", s); configs(s)
   let a = Child("A"), b = Child("B")
   if style == .unspecified {
    s.viewControllers = [a,b]; snap("arrayAB", s)
    s.viewControllers = [a,b]; snap("sameAB", s)
    s.viewControllers = [a]; snap("arrayA", s)
    s.viewControllers = []; snap("arrayEmpty", s)
    s.viewControllers = [a,b]
   } else {
    columns("empty", s)
    s.setViewController(a, for: .primary); snap("setPrimaryA", s); columns("setPrimaryA", s)
    s.setViewController(b, for: .secondary); snap("setSecondaryB", s); columns("setSecondaryB", s)
    log("ancestry A=\(name(a.parent)) splitSelf=\(s.splitViewController === s) childSplit=\(a.splitViewController === s)")
    s.setViewController(b, for: .secondary); snap("sameSecondaryB", s)
    s.setViewController(nil, for: .secondary); snap("clearSecondary", s); columns("clearSecondary", s)
    s.setViewController(b, for: .secondary)
    let compact = Child("C")
    s.setViewController(compact, for: .compact); snap("setCompactC", s); columns("setCompactC", s)
    s.setViewController(nil, for: .compact); snap("clearCompact", s)
    if style == .tripleColumn { s.setViewController(Child("S"), for: .supplementary) }
   }
   if s.style != .unspecified { s.preferredPrimaryColumnWidth = 280 }; s.preferredPrimaryColumnWidthFraction = 0.4
   s.minimumPrimaryColumnWidth = 200; s.maximumPrimaryColumnWidth = 420
   snap("mutatedWidths", s); configs(s)
   if s.style != .unspecified { s.preferredPrimaryColumnWidth = UISplitViewController.automaticDimension }
   s.preferredPrimaryColumnWidthFraction = UISplitViewController.automaticDimension
   s.minimumPrimaryColumnWidth = UISplitViewController.automaticDimension
   s.maximumPrimaryColumnWidth = UISplitViewController.automaticDimension
   s.delegate = observer
   s.show(Child("HandledShow"), sender: nil)
   s.showDetailViewController(Child("HandledDetail"), sender: nil)
   snap("handled", s)
   queue.append(("style\(style.rawValue)", s))
  }
  window = UIWindow(frame: UIScreen.main.bounds)
  runNext()
  return true
 }
 func runNext() {
  guard !queue.isEmpty else { log("DONE"); exit(0) }
  let (label,s) = queue.removeFirst()
  window!.rootViewController = s; window!.makeKeyAndVisible()
  DispatchQueue.main.asyncAfter(deadline: .now()+0.6) {
   s.view.layoutIfNeeded(); tree(label+" defaultWindow", s)
   if s.style != .unspecified { columns("window",s) }
   s.preferredDisplayMode = .oneBesideSecondary; s.view.layoutIfNeeded()
   tree(label+" beside",s)
   if s.style != .unspecified { s.preferredPrimaryColumnWidth = 280 }; s.view.layoutIfNeeded(); tree(label+" absolute280",s)
   if s.style != .unspecified { s.preferredPrimaryColumnWidth = UISplitViewController.automaticDimension }; s.preferredPrimaryColumnWidthFraction = 0.4; s.view.layoutIfNeeded(); tree(label+" fraction0.4",s)
   s.minimumPrimaryColumnWidth = 400; s.maximumPrimaryColumnWidth = 500; s.view.layoutIfNeeded(); snap(label+" minimum400",s)
   s.minimumPrimaryColumnWidth = UISplitViewController.automaticDimension; s.maximumPrimaryColumnWidth = 300; s.view.layoutIfNeeded(); snap(label+" maximum300",s)
   s.maximumPrimaryColumnWidth = UISplitViewController.automaticDimension
   s.primaryEdge = .trailing; s.view.layoutIfNeeded(); tree(label+" trailing",s)
   let modes: [UISplitViewController.DisplayMode] = s.style == .tripleColumn ? [.secondaryOnly,.oneBesideSecondary,.oneOverSecondary,.twoBesideSecondary,.twoOverSecondary,.twoDisplaceSecondary] : [.secondaryOnly,.oneBesideSecondary,.oneOverSecondary]
   for mode in modes { s.preferredDisplayMode = mode; s.view.layoutIfNeeded(); snap(label+" mode\(mode.rawValue)",s) }
   if s.style != .unspecified {
    s.hide(.primary); s.view.layoutIfNeeded(); snap(label+" hidePrimary",s); columns("hidePrimary",s)
    s.show(.primary); s.view.layoutIfNeeded(); snap(label+" showPrimary",s); columns("showPrimary",s)
   }
   if s.style == .unspecified { s.viewControllers.first?.showDetailViewController(Child("ChildDetail"), sender: nil); snap(label+" childDetail",s) }
   self.runNext()
  }
 }
}
UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(App.self))
