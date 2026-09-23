// Guest (machorun + objc4) check of the storyboard runtime: a storyboard
// naming classes in THIS module is loaded; the custom controller and view are
// found by their archived `_TtC13NibGuestProbe…` names at run time, built
// through init(coder:), outlets are connected, the embed segue runs, and a
// button's archived action reaches the controller.
import Foundation
import OpenUIKit

final class GuestNibView: UIView {
    var initFrame = CGRect.zero
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initFrame = frame
    }
    override init(frame: CGRect) { super.init(frame: frame) }
}

final class GuestNibController: UIViewController {
    @IBOutlet var label: UILabel?
    @IBOutlet var badge: GuestNibView?
    @IBOutlet var button: UIButton?
    var taps = 0
    var prepared: [String] = []
    var didLoad = false
    override func viewDidLoad() {
        super.viewDidLoad()
        didLoad = true
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        prepared.append(segue.identifier ?? "nil")
    }
    @IBAction func tapped(_ sender: UIButton) { taps += 1 }
}

@main
struct NibGuestProbe {
    @MainActor static func main() {
        let dir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
        OpenUIKitRuntime.nibSearchPaths = [dir]
        // The measured palettes (system colours: `labelColor`) load from the
        // resource root, which is cwd-relative by default.
        if CommandLine.arguments.count > 2 { OpenUIKitRuntime.resourceRoot = CommandLine.arguments[2] }
        let storyboard = UIStoryboard(name: "NibGuest", bundle: nil)
        let initial = storyboard.instantiateInitialViewController()
        guard let controller = initial as? GuestNibController else {
            print("NIB_GUEST_RUNTIME_FAIL initial=\(initial.map { String(describing: type(of: $0)) } ?? "nil") unhandled=\(UINib.unhandledKeys)")
            return
        }
        let view = controller.view!
        controller.button?.sendActions(for: .touchUpInside)
        let child = controller.children.first
        let badgeFrame = controller.badge.map { "\($0.initFrame)" } ?? "nil"
        let ok = controller.label?.text == "Guest" && controller.badge != nil
            && controller.badge?.initFrame == CGRect(x: 10, y: 20, width: 30, height: 40)
            && controller.taps == 1 && controller.prepared == ["Embed"] && child != nil
            && child?.view.superview != nil && controller.didLoad
            && controller.storyboard === storyboard && UINib.unhandledKeys.isEmpty
        print("\(ok ? "NIB_GUEST_RUNTIME_OK" : "NIB_GUEST_RUNTIME_FAIL") class=\(type(of: controller)) label=\(controller.label?.text ?? "nil") badgeInitFrame=\(badgeFrame) taps=\(controller.taps) prepared=\(controller.prepared) child=\(child.map { String(describing: type(of: $0)) } ?? "nil") subviews=\(view.subviews.count) unhandled=\(UINib.unhandledKeys)")
    }
}
