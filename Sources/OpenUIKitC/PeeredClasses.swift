// The Swift classes that can be fronted by an Objective-C peer.
// Owner: abi module. Read Runtime.swift's header first — the ownership rule
// lives there.
//
// BIDIRECTIONAL DISPATCH, in full:
//
//   ObjC:  @interface MyView : UIView       (ObjCFacade)
//          - (void)layoutSubviews { ...; [super layoutSubviews]; }
//
//   Swift: OUKView.layoutSubviews()  ->  hooks.layout_subviews(peer)
//   ObjC:  openuikit_dispatch_layout_subviews() -> [(id)peer layoutSubviews]
//                                              -> -[MyView layoutSubviews]
//          -[UIView layoutSubviews] (the facade's base) calls
//          openuikit_view_super_layout_subviews(handle)
//   Swift: OUKView.oukSuperLayoutSubviews() -> super.layoutSubviews()
//
// There is no recursion risk: `super.layoutSubviews()` reaches
// OpenUIKit.UIView's implementation, never the override. The cost is one C
// call + one objc_msgSend per view per layout pass even when the ObjC subclass
// overrides nothing — see docs/OBJC_FACADE.md for why we accepted that and how
// a generator would elide it.

import COpenUIKitABI
import OpenCoreGraphics
import OpenUIKit

/// Boilerplate every peered class repeats. It is six lines, and it is the
/// entire reason a generator is the right answer at scale (docs/OBJC_FACADE.md).
///
/// `deinit` notifies the peer that its Swift half is gone. Under the
/// domination rule this can only happen when the peer is itself being torn
/// down or has already released its handle, so it is a notification, not a
/// callback into a live object graph.

final class OUKView: UIView, OUKPeered {
    var oukPeer: UnsafeMutableRawPointer?
    override func layoutSubviews() {
        if let peer = oukPeer, let hook = OUKHooks.layoutSubviews { hook(peer) }
        else { super.layoutSubviews() }
    }
    override func draw(_ rect: CGRect) {
        if let peer = oukPeer, let hook = OUKHooks.drawRect {
            hook(peer, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)
        } else { super.draw(rect) }
    }
    func oukSuperLayoutSubviews() { super.layoutSubviews() }
    func oukSuperDraw(_ rect: CGRect) { super.draw(rect) }
    deinit { if let p = oukPeer { OUKHooks.peerOrphaned?(p) } }
}

final class OUKLabel: UILabel, OUKPeered {
    var oukPeer: UnsafeMutableRawPointer?
    override func layoutSubviews() {
        if let peer = oukPeer, let hook = OUKHooks.layoutSubviews { hook(peer) }
        else { super.layoutSubviews() }
    }
    override func draw(_ rect: CGRect) {
        if let peer = oukPeer, let hook = OUKHooks.drawRect {
            hook(peer, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)
        } else { super.draw(rect) }
    }
    func oukSuperLayoutSubviews() { super.layoutSubviews() }
    func oukSuperDraw(_ rect: CGRect) { super.draw(rect) }
    deinit { if let p = oukPeer { OUKHooks.peerOrphaned?(p) } }
}

final class OUKButton: UIButton, OUKPeered {
    var oukPeer: UnsafeMutableRawPointer?
    override func layoutSubviews() {
        if let peer = oukPeer, let hook = OUKHooks.layoutSubviews { hook(peer) }
        else { super.layoutSubviews() }
    }
    override func draw(_ rect: CGRect) {
        if let peer = oukPeer, let hook = OUKHooks.drawRect {
            hook(peer, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)
        } else { super.draw(rect) }
    }
    func oukSuperLayoutSubviews() { super.layoutSubviews() }
    func oukSuperDraw(_ rect: CGRect) { super.draw(rect) }
    deinit { if let p = oukPeer { OUKHooks.peerOrphaned?(p) } }
}

/// UIViewController is not a UIView, so it peers on the two hooks it actually
/// has. `loadView` is the interesting one: an ObjC subclass overriding it must
/// be able to install a view the Swift side then adopts.
final class OUKViewController: UIViewController, OUKPeered {
    var oukPeer: UnsafeMutableRawPointer?
    override func loadView() {
        if let peer = oukPeer, let hook = OUKHooks.loadView { hook(peer) }
        else { super.loadView() }
    }
    override func viewDidLoad() {
        if let peer = oukPeer, let hook = OUKHooks.viewDidLoad { hook(peer) }
        else { super.viewDidLoad() }
    }
    func oukSuperLoadView() { super.loadView() }
    func oukSuperViewDidLoad() { super.viewDidLoad() }
    // Not a view: these two are unreachable, and saying so is cheaper than
    // splitting the protocol for one class.
    func oukSuperLayoutSubviews() {}
    func oukSuperDraw(_ rect: CGRect) {}
    deinit { if let p = oukPeer { OUKHooks.peerOrphaned?(p) } }
}
