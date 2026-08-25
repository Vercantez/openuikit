// OpenUIKitC — the C ABI half of the Objective-C bridge. Owner: abi module.
//
// WHY THIS EXISTS
// ---------------
// Swift's Objective-C interop does not work off Darwin and cannot be made to
// (docs/OBJC_RUNTIME.md: an interop stdlib needs an ObjC Foundation and
// CoreFoundation that do not exist on Linux). So OpenUIKit does not try to be
// an ObjC framework. Instead it exports a plain C ABI — `@_cdecl`, which Swift
// supports on Linux today with no flags — and a *real* Objective-C facade
// (ObjCFacade/, compiled by clang against libobjc2 + gnustep-base) sits on top
// of it. Neither side needs the other's internals, which is exactly why the
// Apple-Foundation-internals problem never arises.
//
// THE OWNERSHIP RULE — read this before adding an entry point
// -----------------------------------------------------------
// One rule, no exceptions, and it is one an ObjC programmer already knows:
//
//   *** The Core Foundation Create Rule. ***
//
//   * A function with `_create` in its name returns a handle you OWN (+1).
//     `openuikit_release` balances it.
//   * Every other handle-returning function returns a BORROWED handle (+0),
//     valid only while something else keeps the object alive.
//
// And its dual, for the other direction:
//
//   *** Swift never owns an Objective-C object. ***
//
//   A Swift object stores at most one `peer` — an UNOWNED raw pointer to the
//   ObjC object that fronts it — set by `openuikit_set_peer`. Swift never
//   retains, releases or messages it except through the hook vtable.
//
// Those two clauses have a consequence the facade MUST honour, and it is the
// single thing that would rot this bridge if left implicit:
//
//   *** The ObjC ownership graph must dominate the Swift one. ***
//
//   If Swift object A retains Swift object B, then A's peer must retain B's
//   peer. Otherwise B's peer can die while B is still alive and still being
//   laid out, and the unowned back-pointer dangles. In practice this means
//   the facade's `-addSubview:` retains, mirroring `UIView.subviews`; the
//   facade does exactly that.
//
//   This is CHECKED, not just documented: when a peered Swift object is
//   deallocated its peer gets `peer_orphaned`, and when a peer deallocates
//   while its Swift object is still alive and still parented,
//   `openuikit_clear_peer` reports a violation (fatal under
//   OPENUIKIT_ABI_STRICT=1). A bridge that cannot detect its own rule
//   breaking is a bridge that breaks silently.

import COpenUIKitABI
import OpenCoreGraphics
import OpenUIKit

// MARK: - Handles

@inline(__always)
func oukRetained(_ o: AnyObject) -> UnsafeMutableRawPointer {
    Unmanaged.passRetained(o).toOpaque()
}

@inline(__always)
func oukBorrowed(_ o: AnyObject?) -> UnsafeMutableRawPointer? {
    guard let o else { return nil }
    return Unmanaged.passUnretained(o).toOpaque()
}

/// Resolve a handle. A nil or mistyped handle is a programming error on the
/// ObjC side; it returns nil rather than trapping so the facade can report it.
@inline(__always)
func oukObject<T: AnyObject>(_ h: UnsafeMutableRawPointer?, as: T.Type = T.self) -> T? {
    guard let h else { return nil }
    return Unmanaged<AnyObject>.fromOpaque(h).takeUnretainedValue() as? T
}

@_cdecl("openuikit_retain")
public func openuikit_retain(_ h: UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer? {
    guard let h else { return nil }
    _ = Unmanaged<AnyObject>.fromOpaque(h).retain()
    return h
}

@_cdecl("openuikit_release")
public func openuikit_release(_ h: UnsafeMutableRawPointer?) {
    guard let h else { return }
    Unmanaged<AnyObject>.fromOpaque(h).release()
}

// MARK: - Diagnostics

public enum OUKDiagnostics {
    /// Set from the ObjC side (or the env, by the facade) to make ownership
    /// violations fatal instead of a warning on stderr.
    public static var strict = false
    /// Every violation reported so far, so a test can assert on them without
    /// scraping stderr.
    public static var violations: [String] = []

    static func violation(_ message: String) {
        violations.append(message)
        OUKLog.error("openuikit ABI violation: " + message)
        if strict { fatalError("openuikit ABI violation: " + message) }
    }
}

@_cdecl("openuikit_set_strict")
public func openuikit_set_strict(_ on: Int32) { OUKDiagnostics.strict = on != 0 }

@_cdecl("openuikit_violation_count")
public func openuikit_violation_count() -> Int32 { Int32(OUKDiagnostics.violations.count) }

// MARK: - The ObjC callback vtable

/// The single point through which Swift calls Objective-C. Every hook takes
/// the peer pointer; the ObjC implementation is a one-line `objc_msgSend`, so
/// the ObjC runtime does the polymorphism and this table never grows when a
/// new UIKit subclass is added.
public enum OUKHooks {
    nonisolated(unsafe) static var table = openuikit_objc_hooks()
    nonisolated(unsafe) static var installed = false

    @inline(__always) static var layoutSubviews: (@convention(c) (UnsafeMutableRawPointer?) -> Void)? {
        installed ? table.layout_subviews : nil
    }
    @inline(__always) static var drawRect: (@convention(c) (UnsafeMutableRawPointer?, Double, Double, Double, Double) -> Void)? {
        installed ? table.draw_rect : nil
    }
    @inline(__always) static var performAction: (@convention(c) (UnsafeMutableRawPointer?, UnsafePointer<CChar>?, UnsafeMutableRawPointer?, Int32) -> Void)? {
        installed ? table.perform_action : nil
    }
    @inline(__always) static var loadView: (@convention(c) (UnsafeMutableRawPointer?) -> Void)? {
        installed ? table.load_view : nil
    }
    @inline(__always) static var viewDidLoad: (@convention(c) (UnsafeMutableRawPointer?) -> Void)? {
        installed ? table.view_did_load : nil
    }
    @inline(__always) static var peerOrphaned: (@convention(c) (UnsafeMutableRawPointer?) -> Void)? {
        installed ? table.peer_orphaned : nil
    }
}

@_cdecl("openuikit_set_objc_hooks")
public func openuikit_set_objc_hooks(_ p: UnsafePointer<openuikit_objc_hooks>?) {
    guard let p else { OUKHooks.installed = false; return }
    let incoming = p.pointee
    // Forward/backward compatibility: the caller states the size it compiled
    // against. A caller older than us leaves trailing members zeroed (we hold
    // a zeroed struct and copy only what it sent); a caller NEWER than us has
    // members we do not know about, which is fine — we ignore them.
    let mine = UInt32(MemoryLayout<openuikit_objc_hooks>.size)
    if incoming.size == 0 {
        OUKDiagnostics.violation("openuikit_set_objc_hooks: hooks.size is 0 (set it to sizeof(openuikit_objc_hooks))")
        return
    }
    if incoming.size != mine {
        OUKLog.error("openuikit: hook vtable size \(incoming.size) != \(mine); using the common prefix")
    }
    OUKHooks.table = incoming
    OUKHooks.installed = true
}

// MARK: - Peering

/// A Swift object that can be fronted by an Objective-C peer.
///
/// The peer pointer is stored, not looked up in a side table: `layoutSubviews`
/// runs on every view in every layout pass, and a hash lookup there is a tax
/// on the whole engine. The cost is that only OpenUIKitC's own subclasses can
/// be peered — see `openuikit_set_peer`.
protocol OUKPeered: AnyObject {
    var oukPeer: UnsafeMutableRawPointer? { get set }
    /// Invoke the Swift superclass implementation, so an ObjC override can
    /// call `super`.
    func oukSuperLayoutSubviews()
    func oukSuperDraw(_ rect: CGRect)
}

@_cdecl("openuikit_set_peer")
public func openuikit_set_peer(_ h: UnsafeMutableRawPointer?, _ peer: UnsafeMutableRawPointer?) -> Int32 {
    guard let o: AnyObject = oukObject(h) else { return 0 }
    guard let p = o as? OUKPeered else {
        OUKDiagnostics.violation("openuikit_set_peer on a non-peerable object (\(type(of: o)))")
        return 0
    }
    p.oukPeer = peer
    return 1
}

@_cdecl("openuikit_get_peer")
public func openuikit_get_peer(_ h: UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer? {
    guard let o: AnyObject = oukObject(h), let p = o as? OUKPeered else { return nil }
    return p.oukPeer
}

/// Called from the ObjC peer's `-dealloc`. Detaches the back-pointer and
/// checks the domination rule.
///
/// The test is "does a LIVE ObjC superview still own this Swift view?", not
/// merely "does it still have a superview". The distinction is forced by a
/// property of the engine that this prototype discovered and that
/// docs/OBJC_FACADE.md records: `UIView.superview` is a STRONG reference in
/// OpenUIKit (UIKit's is not), so a view hierarchy is a reference cycle and a
/// parent stays allocated after its last external owner lets go. Testing
/// `superview != nil` would therefore fire on every orderly teardown. Testing
/// whether the superview still has a peer does not: a parent whose own
/// `-dealloc` has run has already cleared its peer, so its children unwind in
/// silence, while a child that dies under a LIVE ObjC parent is caught.
@_cdecl("openuikit_clear_peer")
public func openuikit_clear_peer(_ h: UnsafeMutableRawPointer?) {
    guard let o: AnyObject = oukObject(h), let p = o as? OUKPeered else { return }
    p.oukPeer = nil
    if let v = o as? UIView, let parent = v.superview,
       let pp = parent as? OUKPeered, pp.oukPeer != nil {
        OUKDiagnostics.violation(
            "an ObjC peer deallocated while a live ObjC superview still owned its "
            + "Swift view — the ObjC object graph must retain wherever the Swift "
            + "graph retains (\(type(of: o)))")
    }
}

// MARK: - Small helpers shared by the entry points

@inline(__always)
func oukString(_ p: UnsafePointer<CChar>?) -> String? {
    guard let p else { return nil }
    return String(cString: p)
}

/// UTF-8 out-parameter convention, used by every getter that returns text.
/// Writes at most `cap` bytes INCLUDING a NUL terminator and returns the full
/// byte length the string needs (excluding NUL), so the caller can size a
/// buffer and retry; returns -1 when the property is nil.
@inline(__always)
func oukWriteString(_ s: String?, _ buf: UnsafeMutablePointer<CChar>?, _ cap: Int32) -> Int32 {
    guard let s else { return -1 }
    let bytes = Array(s.utf8)
    let full = Int32(bytes.count)
    guard let buf, cap > 0 else { return full }
    let n = Swift.min(Int(cap) - 1, bytes.count)
    bytes.withUnsafeBufferPointer { src in
        buf.withMemoryRebound(to: UInt8.self, capacity: Int(cap)) { dst in
            if n > 0 { dst.update(from: src.baseAddress!, count: n) }
            dst[n] = 0
        }
    }
    return full
}

@inline(__always)
func oukColor(_ r: Double, _ g: Double, _ b: Double, _ a: Double) -> UIColor {
    UIColor(red: r, green: g, blue: b, alpha: a)
}

func oukFontWeight(_ raw: Int32) -> UIFont.Weight {
    switch raw {
    case 0: return .ultraLight
    case 1: return .thin
    case 2: return .light
    case 4: return .medium
    case 5: return .semibold
    case 6: return .bold
    case 7: return .heavy
    case 8: return .black
    default: return .regular
    }
}

func oukTextAlignment(_ raw: Int32) -> NSTextAlignment {
    switch raw {
    case 0: return .left
    case 1: return .center
    case 2: return .right
    case 3: return .justified
    default: return .natural
    }
}
