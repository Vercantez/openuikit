// Tests for the C ABI half of the Objective-C bridge (docs/OBJC_FACADE.md).
//
// These run under `swift test` on macOS AND Linux with no Objective-C anywhere:
// the hook vtable is filled with `@convention(c)` Swift functions, which is
// exactly the shape the ObjC facade installs. So the whole callback path —
// including "an override calls super" — is covered by the normal gate, and the
// Docker/GNUstep run (scripts/objc_facade_verify.sh) is left to prove the one
// thing this cannot: that a real Objective-C runtime can drive it.

import COpenUIKitABI
import OpenCoreGraphics
import OpenUIKit
import XCTest

@testable import OpenUIKitC

// `@convention(c)` functions cannot capture, so the recording state is global —
// the same constraint the ObjC facade lives under.
nonisolated(unsafe) var layoutCalls: [UnsafeMutableRawPointer] = []
nonisolated(unsafe) var drawCalls: [(UnsafeMutableRawPointer, Double, Double, Double, Double)] = []
nonisolated(unsafe) var actionCalls: [(String, Int32, Bool)] = []
nonisolated(unsafe) var orphanCalls = 0
/// When set, the layout hook calls back into `super` for this peer, modelling
/// an ObjC override that ends with `[super layoutSubviews]`.
nonisolated(unsafe) var superOnLayoutFor: UnsafeMutableRawPointer?
nonisolated(unsafe) var superOnLayoutHandle: UnsafeMutableRawPointer?

private func hookLayout(_ peer: UnsafeMutableRawPointer?) {
    guard let peer else { return }
    layoutCalls.append(peer)
    if peer == superOnLayoutFor, let h = superOnLayoutHandle {
        openuikit_view_super_layout_subviews(h)
    }
}

private func hookDraw(_ peer: UnsafeMutableRawPointer?, _ x: Double, _ y: Double,
                      _ w: Double, _ h: Double) {
    guard let peer else { return }
    drawCalls.append((peer, x, y, w, h))
}

private func hookAction(_ peer: UnsafeMutableRawPointer?, _ name: UnsafePointer<CChar>?,
                        _ sender: UnsafeMutableRawPointer?, _ arity: Int32) {
    actionCalls.append((name.map { String(cString: $0) } ?? "", arity, sender != nil))
}

private func hookOrphan(_ peer: UnsafeMutableRawPointer?) { orphanCalls += 1 }

/// Deliberately NOT `@MainActor`, unlike the rest of the suite. Every
/// `@_cdecl` entry point is nonisolated — a C function cannot be isolated —
/// and this file exercises them from nonisolated code for exactly that
/// reason: if one of them ever stops being callable without an actor hop, the
/// C ABI has silently stopped being a C ABI and this file fails to compile.
/// The crossing lives inside the entry points, in `oukMain`
/// (Sources/OpenUIKitC/Runtime.swift). The two `MainActor.assumeIsolated`
/// calls below are the two places a test reaches past the ABI and touches
/// OpenUIKit's main-actor API directly.
final class ABITests: XCTestCase {

    override func setUp() {
        super.setUp()
        layoutCalls = []; drawCalls = []; actionCalls = []; orphanCalls = 0
        superOnLayoutFor = nil; superOnLayoutHandle = nil
        OUKDiagnostics.violations = []
        OUKDiagnostics.strict = false
        var hooks = openuikit_objc_hooks()
        hooks.size = UInt32(MemoryLayout<openuikit_objc_hooks>.size)
        hooks.layout_subviews = hookLayout
        hooks.draw_rect = hookDraw
        hooks.perform_action = hookAction
        hooks.peer_orphaned = hookOrphan
        withUnsafePointer(to: &hooks) { openuikit_set_objc_hooks($0) }
    }

    override func tearDown() {
        openuikit_set_objc_hooks(nil)
        super.tearDown()
    }

    /// A stand-in for an ObjC object: the ABI only ever sees an opaque pointer.
    private func fakePeer(_ box: inout Int) -> UnsafeMutableRawPointer {
        withUnsafeMutablePointer(to: &box) { UnsafeMutableRawPointer($0) }
    }

    // MARK: - Handles and the Create Rule

    func testCreateReturnsPlusOneAndReleaseBalancesIt() {
        // The Create Rule is only observable through the object's lifetime, so
        // watch the Swift object itself: a +1 handle keeps it alive with no
        // other reference, and the matching release ends it.
        var seen: UIView?
        do {
            let h = openuikit_view_create()
            seen = oukObject(h) as UIView?
            XCTAssertNotNil(seen, "the handle must resolve while it is owned")
            openuikit_view_set_tag(h, 42)
            XCTAssertEqual(openuikit_view_get_tag(h), 42)
            openuikit_release(h)
        }
        // `seen` is our own strong reference, so the object is still valid —
        // asserting anything about the freed case would be undefined behaviour,
        // which is precisely why the rule is documented rather than probed.
        XCTAssertEqual(MainActor.assumeIsolated { seen?.tag }, 42)
    }

    func testRetainAndReleaseArePaired() {
        let h = openuikit_view_create()
        _ = openuikit_retain(h)
        openuikit_release(h)
        XCTAssertEqual(openuikit_view_get_tag(h), 0, "still alive after the extra release")
        openuikit_release(h)
    }

    func testBorrowedHandlesIdentifyTheSameObject() {
        let parent = openuikit_view_create()
        let child = openuikit_view_create()
        defer { openuikit_release(parent); openuikit_release(child) }
        openuikit_view_add_subview(parent, child)
        XCTAssertEqual(openuikit_view_subview_count(parent), 1)
        XCTAssertEqual(openuikit_view_subview_at(parent, 0), child)
        XCTAssertEqual(openuikit_view_superview(child), parent)
        openuikit_view_remove_from_superview(child)
        XCTAssertEqual(openuikit_view_subview_count(parent), 0)
        XCTAssertNil(openuikit_view_superview(child))
    }

    // MARK: - Geometry marshalling

    func testFrameAndBoundsRoundTripAsFourDoubles() {
        let h = openuikit_view_create()
        defer { openuikit_release(h) }
        openuikit_view_set_frame(h, 12.5, -3, 100, 40)
        var out = [Double](repeating: .nan, count: 4)
        openuikit_view_get_frame(h, &out)
        XCTAssertEqual(out, [12.5, -3, 100, 40])
        openuikit_view_get_bounds(h, &out)
        XCTAssertEqual(out, [0, 0, 100, 40])
    }

    func testSizeThatFitsUsesTheTwoDoubleOutParameter() {
        let h = openuikit_label_create()
        defer { openuikit_release(h) }
        openuikit_label_set_text(h, "Hello")
        openuikit_label_set_font(h, 17, Int32(OUKFontWeightRegular))
        var out = [Double](repeating: 0, count: 2)
        openuikit_view_size_that_fits(h, 1000, 1000, &out)
        XCTAssertGreaterThan(out[0], 0)
        XCTAssertGreaterThan(out[1], 0)
    }

    // MARK: - The UTF-8 out-parameter convention

    func testStringGetterReportsFullLengthAndTruncatesSafely() {
        let h = openuikit_label_create()
        defer { openuikit_release(h) }
        openuikit_label_set_text(h, "hello world")

        var big = [CChar](repeating: 0, count: 64)
        XCTAssertEqual(openuikit_label_get_text(h, &big, 64), 11)
        XCTAssertEqual(String(cString: big), "hello world")

        // Too small: the full length is still reported, and what lands in the
        // buffer is NUL-terminated.
        var small = [CChar](repeating: 0x7F, count: 5)
        XCTAssertEqual(openuikit_label_get_text(h, &small, 5), 11)
        XCTAssertEqual(String(cString: small), "hell")

        // Sizing call: no buffer at all.
        XCTAssertEqual(openuikit_label_get_text(h, nil, 0), 11)
    }

    func testStringGetterReportsNilAsMinusOne() {
        let h = openuikit_label_create()
        defer { openuikit_release(h) }
        var buf = [CChar](repeating: 0, count: 8)
        XCTAssertEqual(openuikit_label_get_text(h, &buf, 8), -1)
    }

    func testUTF8SurvivesTheBoundary() {
        let h = openuikit_label_create()
        defer { openuikit_release(h) }
        openuikit_label_set_text(h, "Ünïcøde ✓")
        var buf = [CChar](repeating: 0, count: 64)
        _ = openuikit_label_get_text(h, &buf, 64)
        XCTAssertEqual(String(cString: buf), "Ünïcøde ✓")
    }

    // MARK: - Peering

    func testPeerRoundTripsAndClears() {
        var box = 0
        let peer = fakePeer(&box)
        let h = openuikit_view_create()
        defer { openuikit_release(h) }
        XCTAssertEqual(openuikit_set_peer(h, peer), 1)
        XCTAssertEqual(openuikit_get_peer(h), peer)
        openuikit_clear_peer(h)
        XCTAssertNil(openuikit_get_peer(h))
    }

    func testPeeringANonPeerableObjectIsReportedNotIgnored() {
        // A UIButton's private title label is created by the engine, not by the
        // ABI, so it has nowhere to store a peer. The bridge says so.
        let b = openuikit_button_create(1)
        defer { openuikit_release(b) }
        guard let title = openuikit_button_title_label(b) else {
            return XCTFail("titleLabel handle missing")
        }
        var box = 0
        XCTAssertEqual(openuikit_set_peer(title, fakePeer(&box)), 0)
        XCTAssertEqual(OUKDiagnostics.violations.count, 1)
    }

    // MARK: - Bidirectional dispatch

    func testLayoutSubviewsCallsBackThroughTheHook() {
        var box = 0
        let peer = fakePeer(&box)
        let h = openuikit_view_create()
        defer { openuikit_release(h) }
        _ = openuikit_set_peer(h, peer)
        openuikit_view_set_frame(h, 0, 0, 50, 50)
        openuikit_view_layout_if_needed(h)
        XCTAssertEqual(layoutCalls, [peer], "the override point must reach the peer")
    }

    func testOverrideCanCallSuperWithoutRecursing() {
        var box = 0
        let peer = fakePeer(&box)
        let h = openuikit_view_create()
        defer { openuikit_release(h) }
        _ = openuikit_set_peer(h, peer)
        superOnLayoutFor = peer
        superOnLayoutHandle = h
        openuikit_view_set_frame(h, 0, 0, 50, 50)
        openuikit_view_layout_if_needed(h)
        // Exactly one call: `super` reaches OpenUIKit's implementation, never
        // the override. A recursive design would blow the stack here.
        XCTAssertEqual(layoutCalls.count, 1)
    }

    func testUnpeeredViewsUseTheEngineImplementation() {
        let h = openuikit_view_create()
        defer { openuikit_release(h) }
        openuikit_view_set_frame(h, 0, 0, 50, 50)
        openuikit_view_layout_if_needed(h)
        XCTAssertTrue(layoutCalls.isEmpty)
    }

    func testDrawRectCallsBackWithTheViewBounds() {
        var box = 0
        let peer = fakePeer(&box)
        let h = openuikit_view_create()
        defer { openuikit_release(h) }
        _ = openuikit_set_peer(h, peer)
        openuikit_view_set_frame(h, 0, 0, 20, 10)
        openuikit_view_set_background_color(h, 1, 1, 1, 1)
        guard let v: UIView = oukObject(h) else { return XCTFail("bad handle") }
        _ = MainActor.assumeIsolated { UIRenderer.render(v, scale: 1) }
        XCTAssertEqual(drawCalls.count, 1)
        XCTAssertEqual(drawCalls.first?.3, 20)
        XCTAssertEqual(drawCalls.first?.4, 10)
    }

    // MARK: - Target-action

    func testTargetActionCarriesNameArityAndSender() {
        var box = 0
        let peer = fakePeer(&box)
        let b = openuikit_button_create(1)
        defer { openuikit_release(b) }
        let token = openuikit_control_add_target_action(
            b, peer, "buttonTapped:", OUKControlEventTouchUpInside)
        XCTAssertNotEqual(token, 0)
        openuikit_control_send_actions(b, OUKControlEventTouchUpInside)
        XCTAssertEqual(actionCalls.count, 1)
        XCTAssertEqual(actionCalls.first?.0, "buttonTapped:")
        XCTAssertEqual(actionCalls.first?.1, 1, "one trailing colon means arity 1")
        XCTAssertEqual(actionCalls.first?.2, true, "the sender handle must cross")
    }

    func testZeroArityActionSendsNoSender() {
        var box = 0
        let b = openuikit_button_create(1)
        defer { openuikit_release(b) }
        _ = openuikit_control_add_target_action(
            b, fakePeer(&box), "tapped", OUKControlEventTouchUpInside)
        openuikit_control_send_actions(b, OUKControlEventTouchUpInside)
        XCTAssertEqual(actionCalls.first?.1, 0)
    }

    func testRemovedTargetStopsFiring() {
        var box = 0
        let b = openuikit_button_create(1)
        defer { openuikit_release(b) }
        let token = openuikit_control_add_target_action(
            b, fakePeer(&box), "tapped", OUKControlEventTouchUpInside)
        openuikit_control_remove_target(b, token)
        openuikit_control_send_actions(b, OUKControlEventTouchUpInside)
        XCTAssertTrue(actionCalls.isEmpty)
    }

    // MARK: - The ownership rule's self-check

    func testClearingAPeerUnderALiveParentIsReportedAsAViolation() {
        var pbox = 0, cbox = 0
        let parent = openuikit_view_create()
        let child = openuikit_view_create()
        defer { openuikit_release(parent); openuikit_release(child) }
        _ = openuikit_set_peer(parent, fakePeer(&pbox))
        _ = openuikit_set_peer(child, fakePeer(&cbox))
        openuikit_view_add_subview(parent, child)

        openuikit_clear_peer(child)
        XCTAssertEqual(OUKDiagnostics.violations.count, 1,
                       "a peer dying under a live ObjC parent breaks the domination rule")
    }

    func testOrderlyTeardownReportsNoViolation() {
        var pbox = 0, cbox = 0
        let parent = openuikit_view_create()
        let child = openuikit_view_create()
        defer { openuikit_release(parent); openuikit_release(child) }
        _ = openuikit_set_peer(parent, fakePeer(&pbox))
        _ = openuikit_set_peer(child, fakePeer(&cbox))
        openuikit_view_add_subview(parent, child)

        // The parent goes first, as ObjC's -dealloc order guarantees.
        openuikit_clear_peer(parent)
        openuikit_clear_peer(child)
        XCTAssertTrue(OUKDiagnostics.violations.isEmpty,
                      "unwinding a hierarchy top-down must be silent")
    }

    func testDeallocatedSwiftObjectNotifiesItsPeer() {
        var box = 0
        let h = openuikit_view_create()
        _ = openuikit_set_peer(h, fakePeer(&box))
        openuikit_release(h)
        XCTAssertEqual(orphanCalls, 1)
    }

    // MARK: - Vtable versioning

    func testHooksWithZeroSizeAreRejectedAndLeaveTheOldTableInPlace() {
        var hooks = openuikit_objc_hooks()   // size left at 0
        withUnsafePointer(to: &hooks) { openuikit_set_objc_hooks($0) }
        XCTAssertEqual(OUKDiagnostics.violations.count, 1)
        // Rejected, not adopted: a caller that forgot `size` must not be able
        // to blank the vtable and silently turn every override into a no-op.
        XCTAssertTrue(OUKHooks.installed)
        var box = 0
        let peer = fakePeer(&box)
        let h = openuikit_view_create()
        defer { openuikit_release(h) }
        _ = openuikit_set_peer(h, peer)
        openuikit_view_set_frame(h, 0, 0, 10, 10)
        openuikit_view_layout_if_needed(h)
        XCTAssertEqual(layoutCalls, [peer])
    }

    func testSwiftAndCAgreeOnTheVtableSize() {
        XCTAssertEqual(UInt32(MemoryLayout<openuikit_objc_hooks>.size),
                       openuikit_abi_hooks_size())
    }
}
