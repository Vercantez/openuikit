import Darwin
import Foundation
import UIKit

private let bundleIdentifier = "com.openuikit.focuslaunchcoreprobe"

@MainActor
private final class Transcript {
    private var lines: [String] = []
    private var failures: [String] = []

    func fact(_ key: String, _ value: String) { lines.append("\(key)=\(value)") }
    func check(_ key: String, _ value: @autoclosure () -> Bool) {
        let passed = value()
        fact(key, passed ? "true" : "false")
        if !passed { failures.append(key) }
    }

    func finish() -> Int32 {
        let output = (["ORACLE_BEGIN"] + lines
            + ["oracle.status=\(failures.isEmpty ? "PASS" : "FAIL")", "ORACLE_END"])
            .joined(separator: "\n") + "\n"
        let documents = FileManager.default.urls(for: .documentDirectory,
                                                  in: .userDomainMask)[0]
        try! output.write(to: documents.appendingPathComponent("focuslaunchcoreprobe.txt"),
                          atomically: true, encoding: .utf8)
        FileHandle.standardOutput.write(Data(output.utf8))
        return failures.isEmpty ? 0 : 1
    }
}

@MainActor
private final class ZoomDelegate: NSObject, UIScrollViewDelegate {
    let content: UIView
    var changed = 0
    init(content: UIView) { self.content = content }
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { content }
    func scrollViewDidZoom(_ scrollView: UIScrollView) { changed += 1 }
}

@main
@MainActor
private final class ProbeAppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        _ = application
        _ = launchOptions
        precondition(Bundle.main.bundleIdentifier == bundleIdentifier)
        let transcript = Transcript()

        let root = UIViewController()
        root.view.backgroundColor = .white
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = root
        window.makeKeyAndVisible()
        self.window = window

        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.accessoryType = .disclosureIndicator
        let accessory = UIView(frame: CGRect(x: 0, y: 0, width: 41, height: 23))
        cell.accessoryView = accessory
        cell.layoutIfNeeded()
        transcript.check("cell.accessory.identity", cell.accessoryView === accessory)
        transcript.check("cell.accessory.parent", accessory.superview === cell)
        transcript.check("cell.accessory.typePreserved", cell.accessoryType == .disclosureIndicator)

        var ordered = NSDiffableDataSourceSnapshot<String, Int>()
        ordered.appendSections(["middle"])
        ordered.insertSections(["first"], beforeSection: "middle")
        ordered.insertSections(["last"], afterSection: "middle")
        ordered.appendItems([3, 4], toSection: "middle")
        ordered.appendItems([1, 2], toSection: "first")
        ordered.appendItems([5], toSection: "last")
        ordered.moveItem(4, beforeItem: 2)
        transcript.fact("snapshot.sections", ordered.sectionIdentifiers.joined(separator: ","))
        transcript.fact("snapshot.items", ordered.itemIdentifiers.map(String.init).joined(separator: ","))

        let table = UITableView(frame: CGRect(x: 0, y: 0, width: 320, height: 260),
                                style: .plain)
        root.view.addSubview(table)
        var providerCalls = 0
        let dataSource = UITableViewDiffableDataSource<String, Int>(tableView: table) {
            _, _, item in
            providerCalls += 1
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = "\(item)"
            return cell
        }
        dataSource.defaultRowAnimation = .middle
        dataSource.apply(ordered, animatingDifferences: false)
        table.layoutIfNeeded()
        transcript.check("diffable.provider.called", providerCalls > 0)
        transcript.fact("diffable.snapshot.items",
                        dataSource.snapshot().itemIdentifiers.map(String.init)
                            .joined(separator: ","))

        let hierarchy = UIView()
        let a = UIView(), b = UIView(), c = UIView()
        hierarchy.addSubview(a)
        hierarchy.addSubview(b)
        hierarchy.insertSubview(c, belowSubview: b)
        hierarchy.insertSubview(a, aboveSubview: b)
        transcript.check("view.order.below", hierarchy.subviews[0] === c)
        transcript.check("view.order.above", hierarchy.subviews[2] === a)
        a.frame = CGRect(x: 0, y: 0, width: 5, height: 5)
        transcript.check("view.snapshot.nonNil", a.snapshotView(afterScreenUpdates: true) != nil)
        let replacement = UIView(frame: a.frame)
        UIView.transition(from: a, to: replacement, duration: 0,
                          options: .transitionCrossDissolve)
        transcript.check("view.transition.swapped",
                         a.superview == nil && replacement.superview === hierarchy)

        let navRoot = UIViewController()
        let nav = UINavigationController(rootViewController: navRoot)
        nav.loadViewIfNeeded()
        nav.setNavigationBarHidden(true, animated: false)
        transcript.check("navigation.hidden.state", nav.isNavigationBarHidden)
        transcript.check("navigation.hidden.view", nav.navigationBar.isHidden)
        let shown = UIViewController()
        navRoot.show(shown, sender: nil)
        transcript.check("navigation.show.push", nav.topViewController === shown)

        let scroll = UIScrollView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let zoomContent = UIView(frame: scroll.bounds)
        scroll.addSubview(zoomContent)
        let zoomDelegate = ZoomDelegate(content: zoomContent)
        scroll.delegate = zoomDelegate
        scroll.minimumZoomScale = 0.5
        scroll.maximumZoomScale = 3
        scroll.setZoomScale(2, animated: false)
        transcript.fact("scroll.zoom.scale", String(format: "%.1f", scroll.zoomScale))
        transcript.check("scroll.zoom.callback", zoomDelegate.changed > 0)
        transcript.check("scroll.zoom.notActive", !scroll.isZooming)

        transcript.fact("animation.allowUserInteraction.raw",
                        "\(UIView.AnimationOptions.allowUserInteraction.rawValue)")
        _ = UISpringTimingParameters(
            dampingRatio: 0.75, initialVelocity: CGVector(dx: 0, dy: 4))
        transcript.check("animation.spring.constructed", true)
        var propertyCompletions = 0
        weak var weakAnimator: UIViewPropertyAnimator?
        do {
            let animator = UIViewPropertyAnimator(duration: 0.05, curve: .easeOut) {
                replacement.alpha = 0.5
            }
            weakAnimator = animator
            animator.addCompletion { position in
                if position == .end { propertyCompletions += 1 }
            }
            animator.startAnimation()
        }
        transcript.check("animation.active.retained", weakAnimator != nil)

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.prepare()
        impact.impactOccurred()
        transcript.check("impact.surface.executed", true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            transcript.check("animation.completion.once", propertyCompletions == 1)
            let status = transcript.finish()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { Darwin.exit(status) }
        }
        return true
    }
}
