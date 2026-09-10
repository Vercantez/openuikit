// UIBarPosition / UIBarPositioning / UIBarPositioningDelegate / UIToolbarDelegate.
// Owner: viewcontroller module (M13 "bars & appearance").
//
// MEASURED (real iOS 26.1, iPhone 16 — Tools/oracle2/firefoxrowsprobe,
// transcript ios-26.1-iphone16.json):
//
//   * raw values any/bottom/top/topAttached = 0/1/2/3;
//   * a toolbar's `barPosition` is `.bottom` with no delegate, with a
//     delegate that does not implement `position(for:)`, and with a delegate
//     answering `.any`; it is `.top` / `.topAttached` when the delegate says
//     so — but only once the bar is in a superview;
//   * `position(for:)` is asked exactly ONCE, when the bar is added to its
//     superview (`callsAfterAdd` 1). Setting the delegate on a detached bar,
//     reading `barPosition` detached, and every later layout pass ask
//     nothing (`callsAfterSet` 0, `callsAfterDetachedRead` 0,
//     `callsAfterSecondLayout` 1). The bar passed is the toolbar itself;
//   * a detached bar with a `.top` delegate still reads `.bottom`
//     (`posDetachedWithDelegate` 1);
//   * on iOS 26 the position has NO pixel-observable effect on a standalone
//     toolbar: with `configureWithOpaqueBackground`, red background and blue
//     shadow, render-server screenshots for every position show only the
//     glass platters — no red band, no blue hairline, in any position.
//     `UINavigationBar` reads `.top` (2).
//
// firefox-ios demand (2 uses): `TabTrayViewController` conforms without
// implementing `position(for:)`, and `TestableUIToolbar` forwards a
// `UIToolbarDelegate?` property to a real toolbar's `delegate`.

public enum UIBarPosition: Int, Sendable, Hashable {
    case any = 0
    case bottom = 1
    case top = 2
    case topAttached = 3
}

@preconcurrency @MainActor
public protocol UIBarPositioning: AnyObject {
    var barPosition: UIBarPosition { get }
}

@preconcurrency @MainActor
public protocol UIBarPositioningDelegate: AnyObject {
    /// Optional in UIKit; the default answers `.any`, which a toolbar reads
    /// back as `.bottom` (measured).
    func position(for bar: UIBarPositioning) -> UIBarPosition
}

public extension UIBarPositioningDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition { .any }
}

@preconcurrency @MainActor
public protocol UIToolbarDelegate: UIBarPositioningDelegate {}
