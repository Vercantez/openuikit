import UIKit
// firefox-ios §9.6 rows: UIToolbarDelegate / UIBarPosition, and
// NSCollectionLayoutAnchor inside NSCollectionLayoutSupplementaryItem.
// Each phase rewrites the JSON so a late crash keeps the earlier rows.
var rows: [String: Any] = [:]
func rect(_ r: CGRect) -> [Double] { [r.origin.x, r.origin.y, r.width, r.height].map(Double.init) }
func pt(_ p: CGPoint) -> [Double] { [Double(p.x), Double(p.y)] }
func save() {
 let data = try! JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted, .sortedKeys])
 try! data.write(to: URL(fileURLWithPath: NSHomeDirectory() + "/Documents/firefoxrows.json"))
}
func tree(_ v: UIView, depth: Int = 0) -> [[String: Any]] {
 var out: [[String: Any]] = []
 for s in v.subviews {
  var row: [String: Any] = ["class": String(describing: type(of: s)), "frame": rect(s.frame), "depth": depth,
                            "hidden": s.isHidden, "alpha": Double(s.alpha)]
  if let iv = s as? UIImageView { row["image"] = iv.image.map { "\(Int($0.size.width))x\(Int($0.size.height))" } ?? "nil" }
  if let bg = s.backgroundColor { row["bg"] = String(describing: bg) }
  out.append(row)
  if depth < 3 { out.append(contentsOf: tree(s, depth: depth + 1)) }
 }
 return out
}

/// Run-length colours down one column of the rendered host, in host points.
func columnRuns(_ host: UIView, x: Int, from y0: Int, to y1: Int) -> [[String: Any]] {
 let fmt = UIGraphicsImageRendererFormat(); fmt.scale = 1
 let img = UIGraphicsImageRenderer(bounds: host.bounds, format: fmt).image { _ in host.drawHierarchy(in: host.bounds, afterScreenUpdates: true) }
 guard let cg = img.cgImage, let data = cg.dataProvider?.data, let base = CFDataGetBytePtr(data) else { return [] }
 let bpr = cg.bytesPerRow, bpp = cg.bitsPerPixel / 8
 var runs: [[String: Any]] = []
 var last = ""; var start = y0
 for y in y0...y1 {
  let p = base + y * bpr + x * bpp
  let hex = String(format: "%02x%02x%02x%02x", p[0], p[1], p[2], p[3])
  if hex != last {
   if !last.isEmpty { runs.append(["y0": start, "y1": y - 1, "px": last]) }
   last = hex; start = y
  }
 }
 runs.append(["y0": start, "y1": y1, "px": last])
 return runs
}

// MARK: toolbar delegate
final class PosDelegate: NSObject, UIToolbarDelegate {
 let pos: UIBarPosition
 var calls = 0
 var seenBar: [String] = []
 init(_ p: UIBarPosition) { pos = p }
 func position(for bar: UIBarPositioning) -> UIBarPosition {
  calls += 1; seenBar.append(String(describing: type(of: bar))); return pos
 }
}
final class NoImplDelegate: NSObject, UIToolbarDelegate {}

func toolbarCase(_ name: String, in host: UIView, delegate: UIToolbarDelegate?, calls: () -> Int) {
 let tb = UIToolbar(frame: CGRect(x: 0, y: 100, width: 393, height: 44))
 let ap = UIToolbarAppearance(); ap.configureWithOpaqueBackground()
 ap.backgroundColor = .red; ap.shadowColor = .blue
 tb.standardAppearance = ap; tb.scrollEdgeAppearance = ap
 tb.items = [UIBarButtonItem(systemItem: .add), UIBarButtonItem(systemItem: .flexibleSpace), UIBarButtonItem(systemItem: .done)]
 var r: [String: Any] = [:]
 r["delegateNilBefore"] = tb.delegate == nil
 r["posDetachedNoDelegate"] = tb.barPosition.rawValue
 tb.delegate = delegate
 r["callsAfterSet"] = calls()
 r["posDetachedWithDelegate"] = tb.barPosition.rawValue
 r["callsAfterDetachedRead"] = calls()
 host.addSubview(tb)
 r["callsAfterAdd"] = calls()
 tb.layoutIfNeeded()
 r["callsAfterLayout"] = calls()
 r["posInWindow"] = tb.barPosition.rawValue
 r["callsAfterInWindowRead"] = calls()
 tb.setNeedsLayout(); tb.layoutIfNeeded()
 r["callsAfterSecondLayout"] = calls()
 r["frame"] = rect(tb.frame)
 r["tree"] = tree(tb)
 r["sizeThatFits"] = [Double(tb.sizeThatFits(CGSize(width: 393, height: 0)).width), Double(tb.sizeThatFits(CGSize(width: 393, height: 0)).height)]
 r["intrinsic"] = [Double(tb.intrinsicContentSize.width), Double(tb.intrinsicContentSize.height)]
 r["column"] = columnRuns(host, x: 5, from: 90, to: 160)
 r["columnMid"] = columnRuns(host, x: 196, from: 90, to: 160)
 tb.removeFromSuperview()
 rows["toolbar." + name] = r
}

// MARK: anchors
let kind = "badge"
final class Badge: UICollectionReusableView {}
struct AnchorCase {
 let name: String
 let size: NSCollectionLayoutSize
 let container: NSCollectionLayoutAnchor
 let item: NSCollectionLayoutAnchor?
 let itemInsets: NSDirectionalEdgeInsets
 init(_ name: String, size: NSCollectionLayoutSize = NSCollectionLayoutSize(widthDimension: .absolute(20), heightDimension: .absolute(20)),
      container: NSCollectionLayoutAnchor, item: NSCollectionLayoutAnchor? = nil, itemInsets: NSDirectionalEdgeInsets = .zero) {
  self.name = name; self.size = size; self.container = container; self.item = item; self.itemInsets = itemInsets
 }
}
let cases: [AnchorCase] = [
 // firefox TabsSectionManager: full-width title at the bottom edge, no offset.
 AnchorCase("bottom.fullwidth", size: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(30)),
            container: NSCollectionLayoutAnchor(edges: [.bottom])),
 AnchorCase("topTrailing", container: NSCollectionLayoutAnchor(edges: [.top, .trailing])),
 AnchorCase("topTrailing.fractional.5", container: NSCollectionLayoutAnchor(edges: [.top, .trailing], fractionalOffset: CGPoint(x: 0.5, y: -0.5))),
 AnchorCase("topTrailing.absolute10", container: NSCollectionLayoutAnchor(edges: [.top, .trailing], absoluteOffset: CGPoint(x: 10, y: -10))),
 AnchorCase("none", container: NSCollectionLayoutAnchor(edges: [])),
 AnchorCase("leading.absolute5", container: NSCollectionLayoutAnchor(edges: [.leading], absoluteOffset: CGPoint(x: 5, y: 5))),
 AnchorCase("bottom.fractional0_5", container: NSCollectionLayoutAnchor(edges: [.bottom], fractionalOffset: CGPoint(x: 0, y: 0.5))),
 AnchorCase("leadingTrailing", container: NSCollectionLayoutAnchor(edges: [.leading, .trailing])),
 AnchorCase("all", container: NSCollectionLayoutAnchor(edges: .all)),
 AnchorCase("topTrailing.itemBottomLeading", container: NSCollectionLayoutAnchor(edges: [.top, .trailing]),
            item: NSCollectionLayoutAnchor(edges: [.bottom, .leading])),
 AnchorCase("topTrailing.itemBottomLeading.itemAbs3_4", container: NSCollectionLayoutAnchor(edges: [.top, .trailing]),
            item: NSCollectionLayoutAnchor(edges: [.bottom, .leading], absoluteOffset: CGPoint(x: 3, y: 4))),
 AnchorCase("topTrailing.itemNone.fractional", container: NSCollectionLayoutAnchor(edges: [.top, .trailing]),
            item: NSCollectionLayoutAnchor(edges: [], fractionalOffset: CGPoint(x: 0.5, y: 0.5))),
 AnchorCase("topTrailing.insets10", container: NSCollectionLayoutAnchor(edges: [.top, .trailing]),
            itemInsets: NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)),
 AnchorCase("bottomTrailing.fractionalSize", size: NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalHeight(0.25)),
            container: NSCollectionLayoutAnchor(edges: [.bottom, .trailing])),
 AnchorCase("top.absoluteY-7", container: NSCollectionLayoutAnchor(edges: [.top], absoluteOffset: CGPoint(x: 0, y: -7))),
]

final class Source: NSObject, UICollectionViewDataSource {
 func numberOfSections(in collectionView: UICollectionView) -> Int { cases.count }
 func collectionView(_ c: UICollectionView, numberOfItemsInSection s: Int) -> Int { 2 }
 func collectionView(_ c: UICollectionView, cellForItemAt p: IndexPath) -> UICollectionViewCell { c.dequeueReusableCell(withReuseIdentifier: "cell", for: p) }
 func collectionView(_ c: UICollectionView, viewForSupplementaryElementOfKind k: String, at p: IndexPath) -> UICollectionReusableView {
  c.dequeueReusableSupplementaryView(ofKind: k, withReuseIdentifier: "badge", for: p)
 }
}
let source = Source()

func makeLayout(rtl: Bool) -> UICollectionViewCompositionalLayout {
 let cfg = UICollectionViewCompositionalLayoutConfiguration(); cfg.interSectionSpacing = 40
 return UICollectionViewCompositionalLayout(sectionProvider: { s, _ in
  let c = cases[s]
  let supp = c.item.map { NSCollectionLayoutSupplementaryItem(layoutSize: c.size, elementKind: kind, containerAnchor: c.container, itemAnchor: $0) }
   ?? NSCollectionLayoutSupplementaryItem(layoutSize: c.size, elementKind: kind, containerAnchor: c.container)
  let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .absolute(100), heightDimension: .absolute(100)), supplementaryItems: [supp])
  item.contentInsets = c.itemInsets
  // MEASURED: `subitems: [item, item]` throws NSInternalInconsistencyException
  // "Every supplementary must have a unique elementKind: duplicates detected"
  // in -[NSCollectionLayoutSection _checkForDuplicateSupplementaryItemKindsAndThrowIfFound];
  // firefox's `subitem:count:` (repeating) form is the one that is legal.
  let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(100)), subitem: item, count: 2)
  group.interItemSpacing = .fixed(20)
  let section = NSCollectionLayoutSection(group: group)
  section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 30, bottom: 20, trailing: 0)
  return section
 }, configuration: cfg)
}

func anchorRows(rtl: Bool, into key: String) {
 let cv = UICollectionView(frame: CGRect(x: 0, y: 0, width: 300, height: 600), collectionViewLayout: makeLayout(rtl: rtl))
 if rtl { cv.semanticContentAttribute = .forceRightToLeft }
 cv.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
 cv.register(Badge.self, forSupplementaryViewOfKind: kind, withReuseIdentifier: "badge")
 cv.dataSource = source
 cv.layoutIfNeeded()
 var out: [String: Any] = [:]
 for (s, c) in cases.enumerated() {
  var r: [String: Any] = [:]
  for i in 0..<2 {
   let p = IndexPath(item: i, section: s)
   let ia = cv.layoutAttributesForItem(at: p)
   let sa = cv.layoutAttributesForSupplementaryElement(ofKind: kind, at: p)
   r["item\(i)"] = ["frame": rect(ia?.frame ?? .null), "z": ia?.zIndex ?? -999]
   r["supp\(i)"] = ["frame": rect(sa?.frame ?? .null), "z": sa?.zIndex ?? -999, "kind": sa?.representedElementKind ?? "nil",
                    "indexPath": [sa?.indexPath.section ?? -1, sa?.indexPath.item ?? -1]]
  }
  out[c.name] = r
 }
 out["contentSize"] = [Double(cv.contentSize.width), Double(cv.contentSize.height)]
 // Visible tiling of the first section: which views exist and where.
 func sortRects(_ a: [Double], _ b: [Double]) -> Bool { a[1] == b[1] ? a[0] < b[0] : a[1] < b[1] }
 let badgeFrames: [[Double]] = cv.visibleSupplementaryViews(ofKind: kind).map { rect($0.frame) }
 out["visibleBadges"] = badgeFrames.sorted(by: sortRects)
 let cellFrames: [[Double]] = cv.visibleCells.map { rect($0.frame) }
 out["visibleCells"] = cellFrames.sorted(by: sortRects)
 let elems = cv.collectionViewLayout.layoutAttributesForElements(in: CGRect(x: 0, y: 0, width: 300, height: 200)) ?? []
 out["elementsIn200"] = elems.map { ["kind": $0.representedElementKind ?? "cell", "ip": [$0.indexPath.section, $0.indexPath.item], "frame": rect($0.frame), "z": $0.zIndex] }
 rows[key] = out
}

var holdDelegate: PosDelegate?
final class App: UIResponder, UIApplicationDelegate {
 var window: UIWindow?
 func application(_ application: UIApplication, didFinishLaunchingWithOptions o: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
  rows["os"] = UIDevice.current.systemVersion
  // `probe --hold <any|bottom|top|topAttached|none>`: leave one toolbar on
  // screen (red opaque background, blue shadow) so the script can take a
  // render-server screenshot; drawHierarchy does not capture iOS 26 bars.
  if let i = CommandLine.arguments.firstIndex(of: "--hold"), i + 1 < CommandLine.arguments.count {
   let which = CommandLine.arguments[i + 1]
   let root = UIViewController(); root.view.backgroundColor = .white
   let w = UIWindow(frame: UIScreen.main.bounds); w.rootViewController = root; w.makeKeyAndVisible(); window = w
   let tb = UIToolbar(frame: CGRect(x: 0, y: 300, width: 393, height: 44))
   let ap = UIToolbarAppearance(); ap.configureWithOpaqueBackground(); ap.backgroundColor = .red; ap.shadowColor = .blue
   tb.standardAppearance = ap; tb.scrollEdgeAppearance = ap; tb.compactAppearance = ap
   tb.items = [UIBarButtonItem(systemItem: .add), UIBarButtonItem(systemItem: .flexibleSpace), UIBarButtonItem(systemItem: .done)]
   let map: [String: UIBarPosition] = ["any": .any, "bottom": .bottom, "top": .top, "topAttached": .topAttached]
   if let p = map[which] { let d = PosDelegate(p); tb.delegate = d; holdDelegate = d }
   root.view.addSubview(tb)
   return true
  }
  rows["barPosition.raw"] = ["any": UIBarPosition.any.rawValue, "bottom": UIBarPosition.bottom.rawValue, "top": UIBarPosition.top.rawValue, "topAttached": UIBarPosition.topAttached.rawValue]
  rows["rectEdge.raw"] = ["top": NSDirectionalRectEdge.top.rawValue, "leading": NSDirectionalRectEdge.leading.rawValue, "bottom": NSDirectionalRectEdge.bottom.rawValue, "trailing": NSDirectionalRectEdge.trailing.rawValue, "all": NSDirectionalRectEdge.all.rawValue]
  // Anchor model readback.
  let a1 = NSCollectionLayoutAnchor(edges: [.top, .trailing])
  let a2 = NSCollectionLayoutAnchor(edges: [.top, .trailing], absoluteOffset: CGPoint(x: 10, y: -10))
  let a3 = NSCollectionLayoutAnchor(edges: [.bottom], fractionalOffset: CGPoint(x: 0.5, y: -0.5))
  func anchorRow(_ a: NSCollectionLayoutAnchor) -> [String: Any] {
   ["edges": a.edges.rawValue, "offset": pt(a.offset), "isAbsolute": a.isAbsoluteOffset, "isFractional": a.isFractionalOffset]
  }
  rows["anchor.edgesOnly"] = anchorRow(a1); rows["anchor.absolute"] = anchorRow(a2); rows["anchor.fractional"] = anchorRow(a3)
  let sz = NSCollectionLayoutSize(widthDimension: .absolute(20), heightDimension: .absolute(20))
  let s1 = NSCollectionLayoutSupplementaryItem(layoutSize: sz, elementKind: kind, containerAnchor: a1)
  let s2 = NSCollectionLayoutSupplementaryItem(layoutSize: sz, elementKind: kind, containerAnchor: a1, itemAnchor: a3)
  rows["supp.defaults"] = ["zIndex": s1.zIndex, "itemAnchorNil": s1.itemAnchor == nil, "containerIsSame": s1.containerAnchor === a1,
                           "s2ItemIsSame": s2.itemAnchor === a3, "elementKind": s1.elementKind,
                           "insets": [Double(s1.contentInsets.top), Double(s1.contentInsets.leading), Double(s1.contentInsets.bottom), Double(s1.contentInsets.trailing)]]
  let it = NSCollectionLayoutItem(layoutSize: sz, supplementaryItems: [s1, s2])
  rows["item.supplementaryItems"] = ["count": it.supplementaryItems.count, "plainCount": NSCollectionLayoutItem(layoutSize: sz).supplementaryItems.count]
  save()
  let root = UIViewController(); root.view.backgroundColor = .white
  let w = UIWindow(frame: UIScreen.main.bounds); w.rootViewController = root; w.makeKeyAndVisible(); window = w
  DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
   rows["screen"] = rect(UIScreen.main.bounds)
   let host = root.view!
   toolbarCase("noDelegate", in: host, delegate: nil, calls: { 0 })
   let noImpl = NoImplDelegate(); toolbarCase("delegateNoImpl", in: host, delegate: noImpl, calls: { 0 })
   for (n, p) in [("any", UIBarPosition.any), ("bottom", .bottom), ("top", .top), ("topAttached", .topAttached)] {
    let d = PosDelegate(p); toolbarCase("delegate." + n, in: host, delegate: d, calls: { d.calls })
    rows["toolbar.delegate.\(n).seenBar"] = d.seenBar
   }
   // Same but with a default (unconfigured) appearance: which views exist.
   do {
    let tb = UIToolbar(frame: CGRect(x: 0, y: 100, width: 393, height: 44))
    let d = PosDelegate(.top); tb.delegate = d; host.addSubview(tb); tb.layoutIfNeeded()
    rows["toolbar.defaultAppearance.top"] = ["tree": tree(tb), "pos": tb.barPosition.rawValue, "calls": d.calls]
    tb.removeFromSuperview()
    let tb2 = UIToolbar(frame: CGRect(x: 0, y: 100, width: 393, height: 44)); host.addSubview(tb2); tb2.layoutIfNeeded()
    rows["toolbar.defaultAppearance.none"] = ["tree": tree(tb2), "pos": tb2.barPosition.rawValue]
    tb2.removeFromSuperview()
   }
   // Navigation bar default for comparison (one row, not a firefox demand).
   let nb = UINavigationBar(frame: CGRect(x: 0, y: 100, width: 393, height: 44)); host.addSubview(nb); nb.layoutIfNeeded()
   rows["navbar.pos"] = nb.barPosition.rawValue; nb.removeFromSuperview()
   save()
   anchorRows(rtl: false, into: "anchors.ltr")
   save()
   anchorRows(rtl: true, into: "anchors.rtl")
   save()
   exit(0)
  }
  return true
 }
}
UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(App.self))
