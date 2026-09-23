#if canImport(ObjectiveC)
import XCTest
import ObjectiveC
@testable import OpenUIKit

/// UIApplication.sendAction with a Selector (NetNewsWire RSCore
/// UIResponder+RSCore.swift:27 `currentFirstResponder`). MEASURED iPhone 16 /
/// iOS 26.1: Tools/oracle2/sendactionprobe/transcript-ios26.1.txt.
@MainActor
final class SelectorSendActionTests: XCTestCase {
    func testSelectorSendActionRoutesLikeUIKit() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        let root = UIViewController()
        let field = UITextField(frame: CGRect(x: 20, y: 100, width: 200, height: 40))
        root.view.addSubview(field)
        window.rootViewController = root
        window.makeKeyAndVisible()
        let app = UIApplication.shared
        let find = #selector(UIResponder.sendActionProbeFind(sender:))
        func run(_ body: () -> Bool) -> String {
            SendActionProbeHits.hits = []
            return "returned=\(body()) hits=\(SendActionProbeHits.hits)"
        }
        XCTAssertEqual(run { app.sendAction(find, to: nil, from: nil, for: nil) }, "returned=false hits=[]",
                       "no first responder: nobody, no key-window fallback")
        XCTAssertEqual(run { app.sendAction(find, to: nil, from: field, for: nil) },
                       #"returned=true hits=["UITextField sender=UITextField"]"#)
        XCTAssertTrue(field.becomeFirstResponder())
        XCTAssertEqual(run { app.sendAction(find, to: nil, from: nil, for: nil) },
                       #"returned=true hits=["UITextField sender=nil"]"#)
        _ = field.resignFirstResponder()
        let t = SendActionProbeTarget()
        XCTAssertEqual(run { app.sendAction(#selector(SendActionProbeTarget.ping(_:)), to: t, from: root, for: nil) },
                       #"returned=true hits=["Target.ping sender=UIViewController"]"#)
        XCTAssertEqual(run { app.sendAction(NSSelectorFromString("noSuchAction:"), to: nil, from: nil, for: nil) },
                       "returned=false hits=[]")
    }
}

enum SendActionProbeHits { nonisolated(unsafe) static var hits: [String] = [] }

extension UIResponder {
    @objc func sendActionProbeFind(sender: AnyObject?) {
        SendActionProbeHits.hits.append("\(type(of: self)) sender=\(sender.map { "\(type(of: $0))" } ?? "nil")")
    }
}

final class SendActionProbeTarget: NSObject {
    @objc func ping(_ sender: Any?) {
        SendActionProbeHits.hits.append("Target.ping sender=\(sender.map { "\(type(of: $0))" } ?? "nil")")
    }
}
#endif
