// SwiftUI accessibility traits / heading levels as UIKit sees them, on a
// private iPhone 16 / iOS 26.1 (scripts/swiftui_a11y_probe_sim.sh). Hosts
// small views in a UIHostingController inside a key window and reads the
// accessibility elements UIKit exposes for them. One `key=value` per line.
import SwiftUI
import UIKit

func out(_ key: String, _ value: Any?) {
    if let value { print("\(key)=\(value)") } else { print("\(key)=nil") }
}

@MainActor
func elements(of view: UIView) -> [NSObject] {
    var found: [NSObject] = []
    func walk(_ o: NSObject, depth: Int) {
        guard depth < 12 else { return }
        if o.isAccessibilityElement { found.append(o) }
        if let els = o.accessibilityElements as? [NSObject] {
            for e in els { walk(e, depth: depth + 1) }
        }
        if let v = o as? UIView { for s in v.subviews { walk(s, depth: depth + 1) } }
    }
    walk(view, depth: 0)
    return found
}

@MainActor
func probe<V: View>(_ key: String, _ view: V, in window: UIWindow) {
    let host = UIHostingController(rootView: view)
    window.rootViewController = host
    window.makeKeyAndVisible()
    host.view.setNeedsLayout()
    host.view.layoutIfNeeded()
    RunLoop.main.run(until: Date().addingTimeInterval(0.5))
    let els = elements(of: host.view)
    out("\(key).count", els.count)
    for (i, e) in els.enumerated() {
        out("\(key).\(i)", "label=\(e.accessibilityLabel ?? "nil") traits=\(e.accessibilityTraits.rawValue)")
    }
}

@MainActor
func measure() {
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
    let traits: [(String, UIAccessibilityTraits)] = [
        ("none", .none), ("button", .button), ("link", .link), ("header", .header), ("searchField", .searchField),
        ("image", .image), ("selected", .selected), ("playsSound", .playsSound), ("keyboardKey", .keyboardKey),
        ("staticText", .staticText), ("summaryElement", .summaryElement), ("notEnabled", .notEnabled),
        ("updatesFrequently", .updatesFrequently), ("startsMediaSession", .startsMediaSession),
        ("adjustable", .adjustable), ("allowsDirectInteraction", .allowsDirectInteraction),
        ("causesPageTurn", .causesPageTurn), ("tabBar", .tabBar), ("toggleButton", .toggleButton),
        ("supportsZoom", .supportsZoom),
    ]
    for (n, t) in traits { out("uikit.\(n)", t.rawValue) }
    // SwiftUI builds its accessibility tree only while an assistive
    // technology is running; in a command-line process the element count is
    // 0 for every probe below (recorded, so the mapping is NOT measured).
    probe("plain", Text("Plain"), in: window)
    probe("staticText", Text("Static").accessibilityAddTraits(.isStaticText), in: window)
    probe("header", Text("Header").accessibilityAddTraits(.isHeader), in: window)
    probe("media", Color.gray.frame(width: 50, height: 50).accessibilityElement()
        .accessibilityLabel("Video").accessibilityAddTraits(.startsMediaSession), in: window)
    probe("headingH1", Text("H1").accessibilityHeading(.h1), in: window)
    probe("headingH1Header", Text("H1h").accessibilityAddTraits(.isHeader).accessibilityHeading(.h1), in: window)
    probe("headingUnspecified", Text("HU").accessibilityHeading(.unspecified), in: window)
    probe("backgroundStyle", Text("BG").padding().backgroundStyle(Color.gray), in: window)
}

MainActor.assumeIsolated { measure() }
print("done=1")
