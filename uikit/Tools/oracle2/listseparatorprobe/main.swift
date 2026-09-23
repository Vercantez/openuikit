// Separators of an insetGrouped list of PLAIN UICollectionViewCells
// (NetNewsWire's feed list). VARIANT=nnw installs NetNewsWire's
// itemSeparatorHandler (MainFeedCollectionViewController.swift:284: bottom
// hidden, top visible from the second row on, top leading inset 48); VARIANT=
// default leaves the list's own separators. Prints every separator view the
// collection view holds (class, frame, colour, alpha, hidden), the cells, and
// the window drawHierarchy pixels across one separator. iPhone 16 / iOS 26.1.
import UIKit

final class Row: UICollectionViewCell {
    let label = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .secondarySystemGroupedBackground   // FeedCell's nib
        label.font = .preferredFont(forTextStyle: .body)
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15),
            contentView.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 15),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 48),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
}

final class VC: UICollectionViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int { 2 }
    override func collectionView(_ cv: UICollectionView, numberOfItemsInSection s: Int) -> Int { 4 }
    override func collectionView(_ cv: UICollectionView, cellForItemAt ip: IndexPath) -> UICollectionViewCell {
        let c = cv.dequeueReusableCell(withReuseIdentifier: "row", for: ip) as! Row
        c.label.text = "Row \(ip.section).\(ip.item)"
        return c
    }
}

func r(_ f: CGRect) -> String { String(format: "[%.2f, %.2f, %.2f, %.2f]", f.minX, f.minY, f.width, f.height) }

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let variant = ProcessInfo.processInfo.environment["VARIANT"] ?? "nnw"
        var cfg = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        if variant == "nnw" {
            cfg.itemSeparatorHandler = { indexPath, section in
                var c = section
                c.bottomSeparatorVisibility = .hidden
                c.topSeparatorVisibility = indexPath.row == 0 ? .hidden : .visible
                c.topSeparatorInsets = NSDirectionalEdgeInsets(top: 0, leading: 48, bottom: 0, trailing: 0)
                return c
            }
        }
        let vc = VC(collectionViewLayout: UICollectionViewCompositionalLayout.list(using: cfg))
        vc.collectionView.register(Row.self, forCellWithReuseIdentifier: "row")
        let w = UIWindow(frame: UIScreen.main.bounds)
        w.rootViewController = vc
        w.makeKeyAndVisible()
        window = w
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let cv = vc.collectionView!
            print("FACT variant=\(variant) offset=\(cv.contentOffset) scale=\(w.screen.scale)")
            for c in cv.visibleCells.sorted(by: { $0.frame.minY < $1.frame.minY }) {
                print("FACT cell \(cv.indexPath(for: c).map { "\($0)" } ?? "?") \(r(c.frame))")
            }
            var seps: [UIView] = []
            func walk(_ v: UIView, _ depth: Int) {
                for s in v.subviews {
                    let name = String(describing: type(of: s))
                    if name.contains("Separator") {
                        seps.append(s)
                        let f = s.convert(s.bounds, to: cv)
                        print("FACT separator \(name) parent=\(type(of: v)) frame=\(r(s.frame)) inCV=\(r(f)) bounds=\(r(s.bounds)) bg=\(s.backgroundColor.map { "\($0)" } ?? "nil") resolved=\(s.backgroundColor.map { "\($0.resolvedColor(with: s.traitCollection))" } ?? "nil") alpha=\(s.alpha) hidden=\(s.isHidden) layerBG=\(s.layer.backgroundColor.map { "\($0)" } ?? "nil") sublayers=\(s.layer.sublayers?.count ?? 0) subviews=\(s.subviews.map { "\(type(of: $0)) \(r($0.frame)) \($0.backgroundColor.map { "\($0)" } ?? "nil")" })")
                    }
                    if depth < 6 { walk(s, depth + 1) }
                }
            }
            walk(cv, 0)
            let format = UIGraphicsImageRendererFormat(for: w.traitCollection)
            format.scale = w.screen.scale
            format.preferredRange = .standard   // 8-bit sRGB bytes
            let image = UIGraphicsImageRenderer(bounds: w.bounds, format: format).image { _ in
                w.drawHierarchy(in: w.bounds, afterScreenUpdates: false)
            }
            if let cg = image.cgImage, let data = cg.dataProvider?.data, let bytes = CFDataGetBytePtr(data) {
                let bpr = cg.bytesPerRow, bpp = cg.bitsPerPixel / 8
                for s in seps.prefix(2) where !s.isHidden {
                    let f = s.convert(s.bounds, to: w)
                    let x = Int((f.midX) * format.scale)
                    let y0 = Int((f.minY * format.scale).rounded(.down)) - 2
                    var rows: [String] = []
                    for y in y0..<(y0 + 7) {
                        let o = y * bpr + x * bpp
                        rows.append("\(y):(\(bytes[o]),\(bytes[o + 1]),\(bytes[o + 2]),\(bytes[o + 3]))")
                    }
                    print("FACT pixels separator at \(r(f)) x=\(x) " + rows.joined(separator: " "))
                    let xl = Int((f.minX - 1) * format.scale), xr = Int((f.minX + 1) * format.scale)
                    let yy = Int((f.minY * format.scale).rounded(.down))
                    print("FACT pixels edge y=\(yy) x\(xl)=\(bytes[yy * bpr + xl * bpp]) x\(xr)=\(bytes[yy * bpr + xr * bpp]) bitmapInfo=\(cg.bitmapInfo.rawValue) space=\(cg.colorSpace.map { "\($0)" } ?? "nil")")
                }
            }
            print("DONE")
            exit(0)
        }
        return true
    }
}
