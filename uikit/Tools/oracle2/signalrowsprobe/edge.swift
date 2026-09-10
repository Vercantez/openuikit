// UIScrollEdgeElementContainerInteraction appearance oracle, Signal's exact
// pattern: containers with content, interaction attached once at setup,
// scroll view inset by the container heights. Each phase leaves the app idle
// for the driving script to take a render-server screenshot.
import UIKit

var rows: [String: Any] = [:]
func rect(_ r: CGRect) -> [Double] { [r.origin.x, r.origin.y, r.width, r.height].map(Double.init) }
func marker(_ name: String) { FileManager.default.createFile(atPath: NSHomeDirectory() + "/Documents/\(name).marker", contents: Data()) }
func waitAck(_ name: String, then: @escaping () -> Void) {
    if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/\(name).ack") { then(); return }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { waitAck(name, then: then) }
}
func describe(_ v: UIView, _ scroll: UIScrollView) -> [String: Any] {
    ["frame": rect(v.frame), "subviews": v.subviews.map { [String(describing: type(of: $0)), rect($0.frame)] as [Any] },
     "sublayers": (v.layer.sublayers ?? []).map { String(describing: type(of: $0)) },
     "interactions": v.interactions.map { String(describing: type(of: $0)) },
     "scrollSubviews": scroll.subviews.map { String(describing: type(of: $0)) }.filter { $0 != "UIView" },
     "siblings": (v.superview?.subviews ?? []).map { [String(describing: type(of: $0)), rect($0.frame)] as [Any] },
     "offset": [Double(scroll.contentOffset.x), Double(scroll.contentOffset.y)],
     "inset": [Double(scroll.contentInset.top), Double(scroll.contentInset.bottom)],
     "topStyle": String(describing: scroll.topEdgeEffect.style), "topHidden": scroll.topEdgeEffect.isHidden]
}

final class Root: UIViewController {
    let scroll = UIScrollView()
    let header = UIView()
    let footer = UIView()
    var top: UIScrollEdgeElementContainerInteraction!
    var bottom: UIScrollEdgeElementContainerInteraction!
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        scroll.frame = view.bounds
        scroll.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scroll.contentInsetAdjustmentBehavior = .never
        scroll.contentSize = CGSize(width: view.bounds.width, height: 3000)
        for i in 0..<75 {
            let band = UIView(frame: CGRect(x: 0, y: CGFloat(i) * 40, width: view.bounds.width, height: 40))
            band.backgroundColor = i % 2 == 0 ? .black : .red
            scroll.addSubview(band)
        }
        view.addSubview(scroll)
        header.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 160)
        header.autoresizingMask = [.flexibleWidth]
        let label = UILabel(frame: CGRect(x: 20, y: 90, width: 200, height: 40))
        label.text = "Header"; label.textColor = .white; label.font = .boldSystemFont(ofSize: 28)
        header.addSubview(label)
        view.addSubview(header)
        footer.frame = CGRect(x: 0, y: view.bounds.height - 120, width: view.bounds.width, height: 120)
        footer.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        let footLabel = UILabel(frame: CGRect(x: 20, y: 20, width: 200, height: 40))
        footLabel.text = "Footer"; footLabel.textColor = .white; footLabel.font = .boldSystemFont(ofSize: 28)
        footer.addSubview(footLabel)
        view.addSubview(footer)
        // Signal's order: interaction configured and attached at setup.
        top = UIScrollEdgeElementContainerInteraction(); top.edge = .top; top.scrollView = scroll; header.addInteraction(top)
        bottom = UIScrollEdgeElementContainerInteraction(); bottom.edge = .bottom; bottom.scrollView = scroll; footer.addInteraction(bottom)
        scroll.contentInset = UIEdgeInsets(top: 160, left: 0, bottom: 120, right: 0)
        scroll.contentOffset = CGPoint(x: 0, y: -160)
    }
}

final class App: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions o: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        rows["os"] = UIDevice.current.systemVersion
        let root = Root()
        let w = UIWindow(frame: UIScreen.main.bounds); w.rootViewController = root; w.makeKeyAndVisible(); window = w
        var phases: [(String, () -> Void)] = []
        phases.append(("rest", {}))
        phases.append(("under60", { root.scroll.contentOffset = CGPoint(x: 0, y: -60) }))
        phases.append(("under0", { root.scroll.contentOffset = CGPoint(x: 0, y: 0) }))
        phases.append(("under100", { root.scroll.contentOffset = CGPoint(x: 0, y: 100) }))
        phases.append(("bottomUnder", { root.scroll.contentOffset = CGPoint(x: 0, y: 3000 - 852 + 120 - 60) }))
        phases.append(("bottomRest", { root.scroll.contentOffset = CGPoint(x: 0, y: 3000 - 852 + 120) }))
        phases.append(("reattach", { root.scroll.contentOffset = CGPoint(x: 0, y: 100); root.header.removeInteraction(root.top); root.header.addInteraction(root.top) }))
        phases.append(("hard", { root.scroll.topEdgeEffect.style = .hard }))
        phases.append(("automaticAgain", { root.scroll.topEdgeEffect.style = .automatic }))
        phases.append(("hiddenEdge", { root.scroll.topEdgeEffect.isHidden = true }))
        phases.append(("shownEdge", { root.scroll.topEdgeEffect.isHidden = false }))
        phases.append(("darkContent", { root.view.overrideUserInterfaceStyle = .dark }))
        phases.append(("noContent", { root.view.overrideUserInterfaceStyle = .unspecified; root.header.subviews.forEach { $0.removeFromSuperview() } }))
        var index = 0
        func next() {
            guard index < phases.count else {
                let data = try! JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted, .sortedKeys])
                try! data.write(to: URL(fileURLWithPath: NSHomeDirectory() + "/Documents/edge.json"))
                marker("done"); return
            }
            let (name, action) = phases[index]; index += 1
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                rows[name] = ["header": describe(root.header, root.scroll), "footer": describe(root.footer, root.scroll)]
                marker(name); waitAck(name) { next() }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { next() }
        return true
    }
}
UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(App.self))
