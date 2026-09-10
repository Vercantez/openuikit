// UIEditMenu's measured descriptor and non-presenting interaction surface.
// Oracle: Tools/oracle2/editmenuprobe/main.swift, iPhone 16 / iOS 26.1,
// 393 x 852 @3x; fixtures/oracles/editmenu-ios26.1.json.
//
// LIMITATION: the edit-menu renderer, responder-chain suggested actions and
// UIKit's three private gesture recognizers are not implemented. Requests
// retain their configuration and consult the delegate, but never report a
// presentation, dismissal or completed animation that did not happen. The
// vertical context-menu platter is not the horizontal edit-menu oracle.

#if canImport(Foundation)
import Foundation
#elseif canImport(FoundationEssentials)
import FoundationEssentials
#endif
#if canImport(ObjectiveC)
import ObjectiveC
#endif

/// MEASURED `configuration`: automatic/up/down/left/right round-trip as
/// 0/1/2/3/4; newly constructed configurations select automatic.
public enum UIEditMenuArrowDirection: Int, Sendable {
    case automatic = 0
    case up = 1
    case down = 2
    case left = 3
    case right = 4
}

private struct _UIEditMenuIdentifier: Hashable, CustomStringConvertible {
    private let value = UUID()
    var description: String { value.uuidString }
}

@preconcurrency @MainActor
open class UIEditMenuConfiguration: NSObject {
    public let identifier: AnyHashable
    public let sourcePoint: CGPoint
    public var preferredArrowDirection: UIEditMenuArrowDirection = .automatic

    public init(identifier: AnyHashable?, sourcePoint: CGPoint) {
        if let identifier {
            // MEASURED `copyIdentifier`: NSMutableString("before") remains
            // "before" after appending "-after" to the caller's object.
            #if canImport(Foundation)
            if let copying = identifier.base as? NSCopying,
               let copied = copying.copy(with: nil) as? AnyHashable {
                self.identifier = copied
            } else {
                self.identifier = identifier
            }
            #else
            self.identifier = identifier
            #endif
        } else {
            // MEASURED `configuration`: nil produces distinct opaque values
            // with UUID-form descriptions, unequal to those String values
            // and not dynamically castable to UUID. Keep that opacity.
            self.identifier = AnyHashable(_UIEditMenuIdentifier())
        }
        // MEASURED `configuration`: (70,90) and (-2.25,3.5) are unchanged.
        self.sourcePoint = sourcePoint
        super.init()
    }
}

@preconcurrency @MainActor
public protocol UIEditMenuInteractionAnimating: AnyObject {
    func addAnimations(_ animations: @escaping () -> Void)
    func addCompletion(_ completion: @escaping () -> Void)
}

@preconcurrency @MainActor
public protocol UIEditMenuInteractionDelegate: AnyObject {
    func editMenuInteraction(_ interaction: UIEditMenuInteraction,
                             menuFor configuration: UIEditMenuConfiguration,
                             suggestedActions: [UIMenuElement]) -> UIMenu?
    func editMenuInteraction(_ interaction: UIEditMenuInteraction,
                             targetRectFor configuration: UIEditMenuConfiguration) -> CGRect
    func editMenuInteraction(_ interaction: UIEditMenuInteraction,
                             willPresentMenuFor configuration: UIEditMenuConfiguration,
                             animator: UIEditMenuInteractionAnimating)
    func editMenuInteraction(_ interaction: UIEditMenuInteraction,
                             willDismissMenuFor configuration: UIEditMenuConfiguration,
                             animator: UIEditMenuInteractionAnimating)
}

public extension UIEditMenuInteractionDelegate {
    func editMenuInteraction(_ interaction: UIEditMenuInteraction,
                             menuFor configuration: UIEditMenuConfiguration,
                             suggestedActions: [UIMenuElement]) -> UIMenu? { nil }
    func editMenuInteraction(_ interaction: UIEditMenuInteraction,
                             targetRectFor configuration: UIEditMenuConfiguration) -> CGRect {
        // The iOS 26.1 SDK's optional-callback default is an empty rect at
        // sourcePoint; the oracle's target sample is (70,90,0,0).
        CGRect(origin: configuration.sourcePoint, size: .zero)
    }
    func editMenuInteraction(_ interaction: UIEditMenuInteraction,
                             willPresentMenuFor configuration: UIEditMenuConfiguration,
                             animator: UIEditMenuInteractionAnimating) {}
    func editMenuInteraction(_ interaction: UIEditMenuInteraction,
                             willDismissMenuFor configuration: UIEditMenuConfiguration,
                             animator: UIEditMenuInteractionAnimating) {}
}

@preconcurrency @MainActor
open class UIEditMenuInteraction: NSObject, UIInteraction {
    public private(set) weak var delegate: UIEditMenuInteractionDelegate?
    public private(set) weak var view: UIView?
    private var configuration: UIEditMenuConfiguration?

    public init(delegate: UIEditMenuInteractionDelegate?) {
        // MEASURED `weakDelegate`: clearing the caller's only strong
        // reference clears interaction.delegate too.
        self.delegate = delegate
        super.init()
    }

    public func willMove(to view: UIView?) {}
    public func didMove(to view: UIView?) { self.view = view }

    public func presentEditMenu(with configuration: UIEditMenuConfiguration) {
        // MEASURED `detached.present.*`: zero delegate calls. An attached
        // view, even without a window, stores the source point and queries
        // menuFor once (`unwindowed.present.immediate`). Presentation is not
        // supported on Catalyst; keep this path under the iOS cut.
        guard OpenUIKitRuntime.systemFontCut == .iOS, let view else { return }
        self.configuration = configuration
        // MEASURED (Tools/oracle2/firefoxlastrowsprobe, iPhone 16 + iPad A16):
        // presenting builds the CONTEXT menu system first — `buildMenu(with:)`
        // reaches the source view, its controller, the window, the
        // application and the app delegate, in that order, before the
        // delegate's `menuFor` is asked. The built tree is not consulted
        // here (the platter passes no system actions, see below).
        UIMenuSystem.context._rebuild(startingAt: view)
        resolveRequestedMenu()
    }

    public func reloadVisibleMenu() {
        // MEASURED `nil.idleMethods` and `unwindowed.removed.idleMethods`:
        // an unsuccessful presentation retains its configuration; reload
        // queries menuFor once even after removal from the source view.
        guard OpenUIKitRuntime.systemFontCut == .iOS else { return }
        resolveRequestedMenu()
    }

    public func dismissMenu() {
        // MEASURED `nil.dismiss`: an unpresented request invokes no dismissal
        // callbacks and keeps location (70,90). No renderer owns a visible
        // edit menu here, so there is no dismissal to report.
    }

    public func updateVisibleMenuPosition(animated: Bool) {
        // MEASURED `nil.idleMethods`: no target-rect request without a visible
        // menu. This implementation never claims it has presented one.
    }

    public func location(in view: UIView?) -> CGPoint {
        // MEASURED all `*.present.*` and `removed` samples: (70,90) for
        // source/window/nil, even with source.frame.origin=(40,120). This is
        // the stored source point, not UIView coordinate conversion.
        if let configuration { return configuration.sourcePoint }
        // MEASURED `detached.initial`: nil destination returns the sentinel,
        // nonnil destinations return (0,0). `attached.initial` returns the
        // sentinel for every destination. The sentinel is DBL_MAX, not inf.
        if self.view == nil, view != nil { return .zero }
        return CGPoint(x: CGFloat.greatestFiniteMagnitude,
                       y: CGFloat.greatestFiniteMagnitude)
    }

    private func resolveRequestedMenu() {
        guard let configuration else { return }
        // The oracle supplies eight responder-chain menus, including Format
        // and Speech, on a plain view. No such command provider exists here;
        // pass no fabricated system actions and do not present the result.
        _ = delegate?.editMenuInteraction(self, menuFor: configuration,
                                          suggestedActions: [])
    }
}
