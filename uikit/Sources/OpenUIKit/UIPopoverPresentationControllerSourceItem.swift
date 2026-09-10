// UIPopoverPresentationControllerSourceItem (iOS 16) — the one anchor type
// `popoverPresentationController?.sourceItem = barButtonItem ?? view` takes.
// Owner: viewcontroller module. §9.6 BLOCKING row for WordPress-iOS (10
// uses) and signal-ios (1).
//
// The SDK declares the protocol with a single requirement, `frameInView:`
// (iOS 17), and conforms UIView, UILayoutGuide, UIBarButtonItem, UITabBarItem
// (and Catalyst's NSToolbarItem, UITab). In Swift the requirement is hidden
// (`__frame(in:)`) and the public spelling on every conformer is
// `frame(in:) -> CGRect?`; nothing in the ladder corpus writes its own
// conformer, so the port declares the public spelling as the requirement.
//
// MEASURED Tools/oracle2/wordpressrowsprobe, iPad (A16) 820×1180 / iOS 26.1
// (`ios-26.1-ipad-popover.json` base rows) and iPhone 16:
//   view in a window          `frame(in: window)` = its frame in the window
//   view NOT in a window      its own `frame` ([1, 2, 3, 4] → [1, 2, 3, 4])
//   layout guide              its layoutFrame converted ([10, 400, 50, 30])
//   bar button in a nav bar   the item's 36 pt content box, y 4 in the bar
//                             ([741.5, 36, 64.5, 36] in the window)
//   bar button in NO bar      [0, 0, 0, 0] — not nil
//   tab bar item in a bar     the item's content box ([412, 1101, 66, 36])

@preconcurrency @MainActor
public protocol UIPopoverPresentationControllerSourceItem: AnyObject {
    /// The item's frame in `referenceView`'s coordinate space.
    func frame(in referenceView: UIView) -> CGRect?
}

extension UIView: UIPopoverPresentationControllerSourceItem {
    /// MEASURED: a view in no window answers with its frame in its own
    /// root's coordinates ([1, 2, 3, 4] → [1, 2, 3, 4]); UIKit treats a
    /// window-less hierarchy as window space. The port's `convert` would
    /// drop the detached view's origin, so that case walks the frames.
    public func frame(in referenceView: UIView) -> CGRect? {
        if window == nil, referenceView !== self, !referenceView.isDescendant(of: self),
           !isDescendant(of: referenceView) {
            var r = frame
            var v = superview
            while let sv = v {
                r.origin.x += sv.frame.origin.x - sv.bounds.origin.x
                r.origin.y += sv.frame.origin.y - sv.bounds.origin.y
                v = sv.superview
            }
            return r
        }
        return convert(bounds, to: referenceView)
    }
}

extension UILayoutGuide: UIPopoverPresentationControllerSourceItem {
    public func frame(in referenceView: UIView) -> CGRect? {
        guard let owner = owningView else { return nil }
        return owner.convert(layoutFrame, to: referenceView)
    }
}

extension UIBarButtonItem: UIPopoverPresentationControllerSourceItem {
    /// MEASURED: an item in no bar reports `[0, 0, 0, 0]`, not nil.
    public func frame(in referenceView: UIView) -> CGRect? {
        guard let v = _bar?._view(for: self) else {
            return CGRect(x: 0, y: 0, width: 0, height: 0)
        }
        return v.convert(v.bounds, to: referenceView)
    }
}

extension UITabBarItem: UIPopoverPresentationControllerSourceItem {
    public func frame(in referenceView: UIView) -> CGRect? {
        guard let bar = _bar, let v = bar.itemViews.first(where: { $0.item === self }) else {
            return CGRect(x: 0, y: 0, width: 0, height: 0)
        }
        return v.convert(v.bounds, to: referenceView)
    }
}
