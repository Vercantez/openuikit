// An insetGrouped list with supplementary section headers (NetNewsWire's
// feed list: .insetGrouped, headerMode .supplementary, a header whose label
// is pinned 8 pt top and bottom, plain UICollectionViewCell rows sized by
// Auto Layout). Frames of headers, rows and the section backgrounds, plus
// the separator and corner facts (CELL_BG=1: the cell also sets its own
// backgroundColor, as NetNewsWire's FeedCell nib does). iPhone 16 / iOS 26.1.
import UIKit

final class Header: UICollectionReusableView {
    let label = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        label.font = .preferredFont(forTextStyle: .headline)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
}

final class Row: UICollectionViewCell {
    let label = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
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

final class VC: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    override func numberOfSections(in collectionView: UICollectionView) -> Int { 2 }
    override func collectionView(_ cv: UICollectionView, numberOfItemsInSection s: Int) -> Int { 3 }
    override func collectionView(_ cv: UICollectionView, cellForItemAt ip: IndexPath) -> UICollectionViewCell {
        let c = cv.dequeueReusableCell(withReuseIdentifier: "row", for: ip) as! Row
        c.label.text = "Row \(ip.section).\(ip.item)"
        var bg = UIBackgroundConfiguration.listGroupedCell()
        bg.backgroundColor = .secondarySystemGroupedBackground
        c.backgroundConfiguration = bg
        if ProcessInfo.processInfo.environment["CELL_BG"] == "1" { c.backgroundColor = .secondarySystemGroupedBackground }
        return c
    }
    override func collectionView(_ cv: UICollectionView, viewForSupplementaryElementOfKind kind: String, at ip: IndexPath) -> UICollectionReusableView {
        let h = cv.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "hdr", for: ip) as! Header
        h.label.text = "Section \(ip.section)"
        return h
    }
}

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        var cfg = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        cfg.headerMode = .supplementary
        let vc = VC(collectionViewLayout: UICollectionViewCompositionalLayout.list(using: cfg))
        vc.collectionView.register(Row.self, forCellWithReuseIdentifier: "row")
        vc.collectionView.register(Header.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "hdr")
        let w = UIWindow(frame: UIScreen.main.bounds)
        w.rootViewController = vc
        w.makeKeyAndVisible()
        window = w
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let cv = vc.collectionView!
            print("FACT headerTopPadding=\(String(describing: cfg.headerTopPadding)) contentInset=\(cv.adjustedContentInset) contentSize=\(cv.contentSize)")
            for s in 0..<2 {
                if let h = cv.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: s)) {
                    print("FACT header\(s) frame=\(h.frame) label=\((h as! Header).label.frame)")
                }
                for i in 0..<3 {
                    if let c = cv.cellForItem(at: IndexPath(item: i, section: s)) {
                        let seps = c.subviews.filter { $0.frame.height < 1.5 && $0.frame.width > 10 }.map { "\(type(of: $0)) \($0.frame) \($0.backgroundColor.map { "\($0)" } ?? "nil")" }
                        print("FACT cell\(s).\(i) layer radius=\(c.layer.cornerRadius) curve=\(c.layer.cornerCurve.rawValue) clips=\(c.layer.masksToBounds) contentRadius=\(c.contentView.layer.cornerRadius) bgColor=\(c.backgroundColor.map { "\($0)" } ?? "nil") mask=\(c.layer.mask != nil) cornerCfg=\(String(describing: c.cornerConfiguration)) clipsView=\(c.clipsToBounds) subs=\(c.subviews.map { "\(type(of: $0)) r=\($0.layer.cornerRadius) m=\($0.layer.maskedCorners.rawValue) bg=\($0.backgroundColor != nil) cc=\(String(describing: $0.cornerConfiguration))" })")
                        print("FACT cell\(s).\(i) frame=\(c.frame) corner=\(c.layer.cornerRadius) masks=\(c.layer.maskedCorners.rawValue) bgView=\(c.backgroundView.map { "\(type(of: $0)) r=\($0.layer.cornerRadius) m=\($0.layer.maskedCorners.rawValue) \($0.frame)" } ?? "nil") seps=\(seps)")
                    }
                }
            }
            func dump(_ v: UIView, _ d: Int) {
                if d > 3 { return }
                for sub in v.subviews where !(sub is UICollectionViewCell) && !(sub is UICollectionReusableView) {
                    print("FACT cvsub \(String(repeating: " ", count: d))\(type(of: sub)) \(sub.frame) r=\(sub.layer.cornerRadius)")
                }
            }
            dump(cv, 0)
            // fixtures/nibsymbol/SymbolView.nib: SF Symbols chosen in Interface
            // Builder (archived as UISystemSymbolResourceName)
            if let root = UINib(nibName: "SymbolView", bundle: nil).instantiate(withOwner: nil).first as? UIView {
                for v in root.subviews {
                    let img = (v as? UIImageView)?.image ?? (v as? UIButton)?.image(for: .normal)
                    print("FACT nibsymbol \(type(of: v)) image=\(img != nil) symbol=\(img?.isSymbolImage ?? false) size=\(img?.size ?? .zero) equalsSystem=\(img.map { i in ["chevron.down", "line.3.horizontal.decrease"].contains { UIImage(systemName: $0)?.size == i.size } } ?? false)")
                }
            }
            print("DONE")
            exit(0)
        }
        return true
    }
}
