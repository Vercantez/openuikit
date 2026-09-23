// popToViewController / popToRootViewController result order (spawned
// command-line probe on the iPhone 16 / iOS 26.1 simulator; run.sh step 2).
import UIKit

final class Named: UIViewController {
    let n: String
    init(_ n: String) { self.n = n; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }
}
func names(_ vcs: [UIViewController]?) -> String {
    vcs.map { "[" + $0.map { ($0 as? Named)?.n ?? "?" }.joined(separator: " ") + "]" } ?? "nil"
}
MainActor.assumeIsolated {
    let a = Named("a"), b = Named("b"), c = Named("c"), d = Named("d")
    let nav = UINavigationController(rootViewController: a)
    for v in [b, c, d] { nav.pushViewController(v, animated: false) }
    print("FACT popToViewController(b) returned=\(names(nav.popToViewController(b, animated: false))) stack=\(names(nav.viewControllers))")
    for v in [c, d] { nav.pushViewController(v, animated: false) }
    print("FACT popToRootViewController returned=\(names(nav.popToRootViewController(animated: false))) stack=\(names(nav.viewControllers))")
    print("FACT popToRootViewController at root returned=\(names(nav.popToRootViewController(animated: false)))")
    nav.pushViewController(b, animated: false)
    print("FACT popToViewController(b) when b is top returned=\(names(nav.popToViewController(b, animated: false)))")
    print("FACT popToViewController(a) animated returned=\(names(nav.popToViewController(a, animated: true))) stack=\(names(nav.viewControllers))")
}
