// Shared storyboard-runtime scenario. The SAME file is compiled into the iOS
// 26.1 simulator probe (Tools/oracle2/nibruntimeprobe, module NibRuntimeTests,
// real UIKit) and into this test target against OpenUIKit, and both load the
// SAME compiled artefact: fixtures/nibruntime/NibRuntimeProbe.storyboardc,
// `ibtool --compile` output of Tools/oracle2/nibruntimeprobe/
// NibRuntimeProbe.storyboard. The classes are named in that storyboard with
// customModule="NibRuntimeTests", so the archive says
// `_TtC15NibRuntimeTests23ProbeRootViewController` on both sides.
//
// Every observation is an entry in `NibProbe.events` (order matters: it is
// the measured order of init(coder:), outlet assignment, awakeFromNib,
// viewDidLoad and prepare(for:sender:)) or a value in the returned
// dictionary. Only JSON types are produced so the two transcripts compare
// with `==`.
#if canImport(ObjectiveC)
#if canImport(OpenUIKit)
import OpenUIKit
import Foundation
#else
import UIKit
#endif

@MainActor
enum NibProbe {
    static var events: [String] = []
    static func log(_ event: String) { events.append(event) }

    static func round(_ value: CGFloat) -> Double {
        (Double(value) * 1000).rounded() / 1000
    }

    static func rect(_ r: CGRect) -> [Double] {
        [round(r.origin.x), round(r.origin.y), round(r.size.width), round(r.size.height)]
    }

    static func color(_ c: UIColor?) -> [Double]? {
        guard let c else { return nil }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        return [r, g, b, a].map { (Double($0) * 1000).rounded() / 1000 }
    }

    static func name(_ object: Any?) -> String {
        guard let object else { return "nil" }
        return String(describing: type(of: object))
    }

    /// A view and its archive-authored descendants. Controls are leaves:
    /// their private subview trees are implementation detail on both sides.
    static func dump(_ view: UIView) -> [String: Any] {
        var out: [String: Any] = [
            "class": name(view),
            "frame": rect(view.frame),
            "hidden": view.isHidden,
            "alpha": round(view.alpha),
            "tag": view.tag,
            "autoresizing": Int(view.autoresizingMask.rawValue),
            "tamic": view.translatesAutoresizingMaskIntoConstraints,
            "userInteraction": view.isUserInteractionEnabled,
            "clips": view.clipsToBounds,
        ]
        if let bg = color(view.backgroundColor) { out["background"] = bg }
        if let label = view as? UILabel {
#if !canImport(OpenUIKit)
            // iOS only (the port's UIFont has no face names): which face a
            // missing custom font fell back to. Ignored by the comparison.
            out["ios.fontName"] = label.font.fontName
#endif
            out["text"] = label.text ?? "nil"
            out["pointSize"] = round(label.font.pointSize)
            out["textColor"] = color(label.textColor) ?? []
            out["alignment"] = label.textAlignment.rawValue
            out["lines"] = label.numberOfLines
        }
        if let button = view as? UIButton {
            out["title"] = button.title(for: .normal) ?? "nil"
            out["buttonType"] = button.buttonType.rawValue
        }
        if let toggle = view as? UISwitch { out["on"] = toggle.isOn }
        if let slider = view as? UISlider {
            out["value"] = Double(slider.value)
            out["range"] = [Double(slider.minimumValue), Double(slider.maximumValue)]
        }
        if let segments = view as? UISegmentedControl {
            out["segments"] = (0..<segments.numberOfSegments).map {
                segments.titleForSegment(at: $0) ?? "nil"
            }
            out["selected"] = segments.selectedSegmentIndex
        }
        if let field = view as? UITextField {
            out["placeholder"] = field.placeholder ?? "nil"
            out["borderStyle"] = field.borderStyle.rawValue
            out["pointSize"] = round((field.font as UIFont?)?.pointSize ?? -1)
        }
        // Leaves: a control's and a text view's subviews are private
        // implementation, as are a scroll view's `_`-prefixed indicators.
        if view is UIControl || view is UITextView || view is UIActivityIndicatorView { return out }
        out["subviews"] = view.subviews
            .filter { !(view is UIScrollView && name($0).hasPrefix("_")) }
            .map { dump($0) }
        return out
    }

    /// Lets an animated push finish: without it a second push lands while
    /// the first transition is still in flight.
    static func settle() {
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 1.0))
    }

    /// The whole scenario, from `UIStoryboard(name:bundle:)` to three segues.
    static func run(storyboardName: String) -> [String: Any] {
        events = []
        var result: [String: Any] = [:]
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)

        // 1. Initial controller: the navigation controller and, archived
        //    inside the same nib, its root relationship.
        let initial = storyboard.instantiateInitialViewController()
        result["initial.class"] = name(initial)
        let nav = initial as? UINavigationController
        result["initial.viewControllers"] = nav?.viewControllers.map { name($0) } ?? []
        result["events.afterInstantiate"] = events
        guard let root = nav?.viewControllers.first as? ProbeRootViewController else {
            result["error"] = "no root"
            return result
        }
        result["root.beforeLoad"] = [
            "isViewLoaded": root.isViewLoaded,
            "title": root.title ?? "nil",
            "navigationItem.title": root.navigationItem.title ?? "nil",
            "nibName": root.nibName ?? "nil",
            "storyboardIsSame": root.storyboard === storyboard,
            "helperClass": name(root.helper),
            "helperLabelNil": root.helper?.label == nil,
            "parentIsNav": root.parent === nav,
            "navigationControllerIsNav": root.navigationController === nav,
        ] as [String: Any]

        // 2. View load: the view nib, its outlets, the embed segue.
        events.append("-- view load")
        root.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        root.view.layoutIfNeeded()
        result["root.afterLoad"] = [
            "children": root.children.map { name($0) },
            "childParentIsRoot": root.children.first?.parent === root,
            "labels": root.labels?.map { $0.text ?? "nil" } ?? [],
            "labelsTags": root.labels?.map { $0.tag } ?? [],
            "helperLabelIsTitle": root.helper?.label === root.titleLabel,
            "badgeCornerRadiusValue": Double(root.badgeView?.cornerRadiusValue ?? -1),
            "badgeGestures": root.badgeView?.gestureRecognizers?.map { name($0) } ?? [],
            "badgeAtInit": root.badgeView?.stateAtInit ?? [:],
            "titleLabelIsSubview": root.titleLabel?.superview === root.view,
            "childViewInContainer": root.children.first?.viewIfLoaded?.superview
                === root.containerViewForTest,
        ] as [String: Any]
        result["rootView"] = dump(root.view)

        // 3. Target-action through the archived connections.
        events.append("-- actions")
        root.actionButton?.sendActions(for: .touchUpInside)
        if let tap = root.badgeView?.gestureRecognizers?.first {
            result["tap.targetsBadge"] = tap.view === root.badgeView
        }

        // 4. Segues.
        events.append("-- performSegue ShowDetailManually")
        root.performSegue(withIdentifier: "ShowDetailManually", sender: nil)
        result["afterShowManual.viewControllers"] = nav?.viewControllers.map { name($0) } ?? []
        settle()
        events.append("-- pop")
        _ = nav?.popToRootViewController(animated: false)
        settle()
        events.append("-- control segue ShowNext")
        root.nextButton?.sendActions(for: .touchUpInside)
        result["afterShowNext.viewControllers"] = nav?.viewControllers.map { name($0) } ?? []
        settle()

        // 5. Identifier instantiation outside any navigation stack.
        events.append("-- instantiate Detail")
        let detail = storyboard.instantiateViewController(withIdentifier: "Detail")
        result["detail"] = [
            "class": name(detail),
            "isViewLoaded": detail.isViewLoaded,
            "nibName": detail.nibName ?? "nil",
            "storyboardIsSame": detail.storyboard === storyboard,
            "labelNilBeforeLoad": (detail as? ProbeDetailViewController)?.detailLabel == nil,
        ] as [String: Any]
        _ = detail.view
        result["detail.labelText"] = (detail as? ProbeDetailViewController)?.detailLabel?.text ?? "nil"
        result["events"] = events

        // 6. Framework defaults the archive results depend on, measured
        //    programmatically (no archive involved).
        let field = UITextField()
        let fieldDefault = field.clipsToBounds
        field.clipsToBounds = true
        result["defaults"] = [
            "textField.clips": fieldDefault,
            "textField.clipsAfterSetTrue": field.clipsToBounds,
            "segmented.clips": UISegmentedControl(items: ["A", "B"]).clipsToBounds,
            "imageView.userInteraction": UIImageView().isUserInteractionEnabled,
            "label.userInteraction": UILabel().isUserInteractionEnabled,
        ] as [String: Any]
        return result
    }
}

@MainActor
final class ProbeHelperObject: NSObject {
    @IBOutlet var label: UILabel? { didSet { NibProbe.log("Helper.outlet.label") } }
    override init() {
        super.init()
        NibProbe.log("Helper.init()")
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        NibProbe.log("Helper.awakeFromNib")
    }
}

final class ProbeBadgeView: UIView {
    @objc var cornerRadiusValue: CGFloat = 0 {
        didSet { NibProbe.log("Badge.set cornerRadiusValue \(Int(cornerRadiusValue))") }
    }
    var stateAtInit: [String: Any] = [:]

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        stateAtInit = [
            "frame": NibProbe.rect(frame),
            "tag": tag,
            "background": NibProbe.color(backgroundColor) ?? [],
            "superviewNil": superview == nil,
            "gestures": gestureRecognizers?.count ?? 0,
        ]
        NibProbe.log("Badge.init(coder)")
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        NibProbe.log("Badge.init(frame)")
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        NibProbe.log("Badge.awakeFromNib superviewNil=\(superview == nil)")
    }
}

class ProbeLoggingViewController: UIViewController {
    var probeName: String { "VC" }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        NibProbe.log("\(probeName).init(coder) nibName=\(nibName ?? "nil") title=\(title ?? "nil") storyboardNil=\(storyboard == nil)")
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        NibProbe.log("\(probeName).awakeFromNib storyboardNil=\(storyboard == nil) parent=\(NibProbe.name(parent))")
    }
    override func loadView() {
        NibProbe.log("\(probeName).loadView begin")
        super.loadView()
        NibProbe.log("\(probeName).loadView end children=\(children.count)")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        NibProbe.log("\(probeName).viewDidLoad children=\(children.count)")
    }
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        NibProbe.log("\(probeName).willMove(toParent: \(NibProbe.name(parent)))")
    }
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        NibProbe.log("\(probeName).didMove(toParent: \(NibProbe.name(parent)))")
    }
}

final class ProbeRootViewController: ProbeLoggingViewController {
    override var probeName: String { "Root" }
    @IBOutlet var titleLabel: UILabel? { didSet { NibProbe.log("Root.outlet.titleLabel") } }
    @IBOutlet var actionButton: UIButton? { didSet { NibProbe.log("Root.outlet.actionButton") } }
    @IBOutlet var nextButton: UIButton? { didSet { NibProbe.log("Root.outlet.nextButton") } }
    @IBOutlet var badgeView: ProbeBadgeView? { didSet { NibProbe.log("Root.outlet.badgeView") } }
    @IBOutlet var helper: ProbeHelperObject? { didSet { NibProbe.log("Root.outlet.helper") } }
    @IBOutlet var toggle: UISwitch? { didSet { NibProbe.log("Root.outlet.toggle") } }
    @IBOutlet var slider: UISlider? { didSet { NibProbe.log("Root.outlet.slider") } }
    @IBOutlet var segments: UISegmentedControl? { didSet { NibProbe.log("Root.outlet.segments") } }
    @IBOutlet var nameField: UITextField? { didSet { NibProbe.log("Root.outlet.nameField") } }
    @IBOutlet var labels: [UILabel]? { didSet { NibProbe.log("Root.outlet.labels \(labels?.count ?? -1)") } }

    /// The container the embed segue targets: the view the child's view is
    /// added to (found structurally, not by outlet — none is archived).
    var containerViewForTest: UIView? { children.first?.viewIfLoaded?.superview }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        NibProbe.log("Root.prepare \(segue.identifier ?? "nil") \(NibProbe.name(segue)) src=\(NibProbe.name(segue.source)) dst=\(NibProbe.name(segue.destination)) sender=\(NibProbe.name(sender)) rootViewLoaded=\(isViewLoaded) dstViewLoaded=\(segue.destination.isViewLoaded)")
    }
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        NibProbe.log("Root.shouldPerformSegue \(identifier) sender=\(NibProbe.name(sender))")
        return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
    }
    @IBAction func buttonTapped(_ sender: UIButton) {
        NibProbe.log("Root.buttonTapped sender=\(NibProbe.name(sender)) isActionButton=\(sender === actionButton)")
    }
    @IBAction func badgeTapped(_ sender: UITapGestureRecognizer) {
        NibProbe.log("Root.badgeTapped")
    }
}

final class ProbeChildViewController: ProbeLoggingViewController {
    override var probeName: String { "Child" }
    @IBOutlet var childLabel: UILabel? { didSet { NibProbe.log("Child.outlet.childLabel") } }
    override func viewDidLoad() {
        super.viewDidLoad()
        NibProbe.log("Child.view frame=\(NibProbe.rect(view.frame)) autoresizing=\(view.autoresizingMask.rawValue)")
    }
}

// MARK: - Second scenario: stack views, prototype cells, tabs, a xib

extension NibProbe {
    static func stackName(_ d: UIStackView.Distribution) -> String {
        if d == .fill { return "fill" }
        if d == .fillEqually { return "fillEqually" }
        if d == .fillProportionally { return "fillProportionally" }
        if d == .equalSpacing { return "equalSpacing" }
        if d == .equalCentering { return "equalCentering" }
        return "other"
    }

    static func stackName(_ a: UIStackView.Alignment) -> String {
        if a == .fill { return "fill" }
        if a == .leading { return "leading" }
        if a == .center { return "center" }
        if a == .trailing { return "trailing" }
        if a == .firstBaseline { return "firstBaseline" }
        if a == .lastBaseline { return "lastBaseline" }
        return "other"
    }

    static func describe(_ stack: UIStackView?) -> [String: Any] {
        guard let stack else { return ["nil": true] }
        return [
            "vertical": stack.axis == .vertical,
            "spacing": round(stack.spacing),
            "distribution": stackName(stack.distribution),
            "alignment": stackName(stack.alignment),
            "arranged": stack.arrangedSubviews.map { name($0) },
        ]
    }

    static func runExtended(storyboardName: String) -> [String: Any] {
        events = []
        var result: [String: Any] = [:]
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)

        // Stack views, safe-area constraints, an activity indicator.
        let stack = storyboard.instantiateViewController(withIdentifier: "Stack")
        stack.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        stack.view.layoutIfNeeded()
        let probe = stack as? ProbeStackViewController
        result["stack.class"] = name(stack)
        result["stack.outer"] = describe(probe?.stack)
        result["stack.inner"] = describe(probe?.innerStack)
        result["stack.spinnerAnimating"] = probe?.spinner?.isAnimating ?? false
        result["stack.view"] = dump(stack.view)

        // A table view controller whose view nib archives a prototype cell.
        let table = storyboard.instantiateViewController(withIdentifier: "Table")
        result["table.class"] = name(table)
        if let tableVC = table as? UITableViewController, let tableView = tableVC.tableView {
            result["table.isView"] = tableVC.view === tableView
            result["table.dataSourceIsController"] = tableView.dataSource === tableVC
            // In a window, as an app shows it (cell margins follow the
            // window's layout, not an off-screen default).
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
            window.rootViewController = tableVC
            window.isHidden = false
            tableView.reloadData()
            window.layoutIfNeeded()
            tableView.layoutIfNeeded()
            result["table.frame"] = rect(tableView.frame)
            result["table.visibleCells"] = tableView.visibleCells.map { cell -> [String: Any] in
                [
                    "class": name(cell),
                    "frame": rect(cell.frame),
                    "reuseIdentifier": cell.reuseIdentifier ?? "nil",
                    "label": (cell as? ProbeCell)?.label?.text ?? "nil",
                    "labelFrame": (cell as? ProbeCell)?.label.map { rect($0.frame) } ?? [],
                    "contentSubviews": cell.contentView.subviews.map { name($0) },
                ]
            }
            let fresh = tableView.dequeueReusableCell(withIdentifier: "Custom")
            result["table.dequeued"] = [
                "class": name(fresh),
                "labelText": (fresh as? ProbeCell)?.label?.text ?? "nil",
                "reuseIdentifier": fresh?.reuseIdentifier ?? "nil",
            ] as [String: Any]
        }

        // A tab bar controller with two relationship children.
        let tabs = storyboard.instantiateViewController(withIdentifier: "Tabs")
        result["tabs.class"] = name(tabs)
        if let tabsVC = tabs as? UITabBarController {
            result["tabs.viewControllers"] = tabsVC.viewControllers?.map { name($0) } ?? []
            result["tabs.titles"] = tabsVC.viewControllers?.map { $0.tabBarItem?.title ?? "nil" } ?? []
            result["tabs.childParents"] = tabsVC.viewControllers?.map { $0.parent === tabsVC } ?? []
            result["tabs.selectedIndex"] = tabsVC.selectedIndex
            result["tabs.children"] = tabsVC.children.count
            tabsVC.loadViewIfNeeded()
            result["tabs.selectedIndexAfterLoad"] = tabsVC.selectedIndex
            result["tabs.selectedAfterLoad"] = name(tabsVC.selectedViewController)
        }

        // A plain xib with a custom File's Owner and two top-level views.
        let owner = ProbeXibOwner()
        let objects = UINib(nibName: "ProbeXibView", bundle: nil).instantiate(withOwner: owner, options: nil)
        result["xib.topLevel"] = objects.map { name($0) }
        result["xib.ownerViewIsFirst"] = owner.xibView === (objects.first as AnyObject?)
        result["xib.captionShared"] = owner.caption === owner.xibView?.caption
        if let view = owner.xibView {
            view.layoutIfNeeded()
            result["xib.view"] = dump(view)
        }
        let bundleOwner = ProbeXibOwner()
        let loaded = Bundle.main.loadNibNamed("ProbeXibView", owner: bundleOwner, options: nil) ?? []
        result["xib.bundleLoad"] = loaded.map { name($0) }
        result["xib.bundleLoadOwnerSet"] = bundleOwner.xibView === (loaded.first as AnyObject?)
        result["events"] = events
        return result
    }
}

final class ProbeStackViewController: ProbeLoggingViewController {
    override var probeName: String { "Stack" }
    @IBOutlet var stack: UIStackView?
    @IBOutlet var innerStack: UIStackView?
    @IBOutlet var spinner: UIActivityIndicatorView?
}

final class ProbeCell: UITableViewCell {
    @IBOutlet var label: UILabel?
    override func awakeFromNib() {
        super.awakeFromNib()
        NibProbe.log("Cell.awakeFromNib reuse=\(reuseIdentifier ?? "nil") label=\(label?.text ?? "nil")")
    }
}

final class ProbeTableViewController: UITableViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 3 }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Custom", for: indexPath)
        (cell as? ProbeCell)?.label?.text = "Row \(indexPath.row)"
        return cell
    }
}

@MainActor
final class ProbeXibOwner: NSObject {
    @IBOutlet var xibView: ProbeXibView? { didSet { NibProbe.log("XibOwner.outlet.xibView") } }
    @IBOutlet var caption: UILabel? { didSet { NibProbe.log("XibOwner.outlet.caption") } }
}

final class ProbeXibView: UIView {
    @IBOutlet var caption: UILabel? { didSet { NibProbe.log("XibView.outlet.caption") } }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        NibProbe.log("XibView.init(coder) frame=\(NibProbe.rect(frame)) subviews=\(subviews.count)")
    }
    override init(frame: CGRect) { super.init(frame: frame) }
    override func awakeFromNib() {
        super.awakeFromNib()
        NibProbe.log("XibView.awakeFromNib caption=\(caption?.text ?? "nil")")
    }
}

final class ProbeDetailViewController: ProbeLoggingViewController {
    override var probeName: String { "Detail" }
    @IBOutlet var detailLabel: UILabel? { didSet { NibProbe.log("Detail.outlet.detailLabel") } }
}
#endif
