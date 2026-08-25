// The @_cdecl entry points. Owner: abi module.
//
// Naming carries the ownership rule (Runtime.swift): `_create` returns +1,
// everything else returns +0. Nothing here may break that without changing
// its name.
//
// Every function takes and returns C scalars only. There is no `struct CGRect`
// in the ABI: rects come in as four doubles and go out through a caller-owned
// `double[4]`. Passing small structs by value across a hand-written ABI is the
// classic place a bridge acquires an architecture bug, and four doubles cost
// nothing next to a layout pass.

import COpenUIKitABI
import CPortableIO
import OpenCoreGraphics
import OpenUIKit

enum OUKLog {
    static func error(_ s: String) { s.withCString { cpio_log_stderr($0) } }
}

// MARK: - Creation (+1)

@_cdecl("openuikit_view_create")
public func openuikit_view_create() -> UnsafeMutableRawPointer { oukMain { oukRetained(OUKView()) } }

@_cdecl("openuikit_label_create")
public func openuikit_label_create() -> UnsafeMutableRawPointer { oukMain { oukRetained(OUKLabel()) } }

@_cdecl("openuikit_button_create")
public func openuikit_button_create(_ type: Int32) -> UnsafeMutableRawPointer {
    oukMain {
        oukRetained(OUKButton(type: type == 1 ? .system : .custom))
    }
}

@_cdecl("openuikit_viewcontroller_create")
public func openuikit_viewcontroller_create() -> UnsafeMutableRawPointer {
    oukMain {
        oukRetained(OUKViewController())
    }
}

/// The dynamic Swift class name, for `-description` and for asserting in tests
/// that the ObjC object really is fronting the Swift class it claims.
@_cdecl("openuikit_class_name")
public func openuikit_class_name(_ h: UnsafeMutableRawPointer?,
                                 _ buf: UnsafeMutablePointer<CChar>?,
                                 _ cap: Int32) -> Int32 {
    oukMain {
        guard let o: AnyObject = oukObject(h) else { return -1 }
        return oukWriteString("\(type(of: o))", buf, cap)
    }
}

// MARK: - UIView: geometry

@_cdecl("openuikit_view_set_frame")
public func openuikit_view_set_frame(_ h: UnsafeMutableRawPointer?,
                                     _ x: Double, _ y: Double,
                                     _ w: Double, _ hh: Double) {
    oukMain {
        guard let v: UIView = oukObject(h) else { return }
        v.frame = CGRect(x: x, y: y, width: w, height: hh)
    }
}

@_cdecl("openuikit_view_get_frame")
public func openuikit_view_get_frame(_ h: UnsafeMutableRawPointer?,
                                     _ out: UnsafeMutablePointer<Double>?) {
    oukMain {
        guard let v: UIView = oukObject(h), let out else { return }
        let f = v.frame
        out[0] = f.origin.x; out[1] = f.origin.y
        out[2] = f.size.width; out[3] = f.size.height
    }
}

@_cdecl("openuikit_view_set_bounds")
public func openuikit_view_set_bounds(_ h: UnsafeMutableRawPointer?,
                                      _ x: Double, _ y: Double,
                                      _ w: Double, _ hh: Double) {
    oukMain {
        guard let v: UIView = oukObject(h) else { return }
        v.bounds = CGRect(x: x, y: y, width: w, height: hh)
    }
}

@_cdecl("openuikit_view_get_bounds")
public func openuikit_view_get_bounds(_ h: UnsafeMutableRawPointer?,
                                      _ out: UnsafeMutablePointer<Double>?) {
    oukMain {
        guard let v: UIView = oukObject(h), let out else { return }
        let b = v.bounds
        out[0] = b.origin.x; out[1] = b.origin.y
        out[2] = b.size.width; out[3] = b.size.height
    }
}

@_cdecl("openuikit_view_set_center")
public func openuikit_view_set_center(_ h: UnsafeMutableRawPointer?, _ x: Double, _ y: Double) {
    oukMain {
        guard let v: UIView = oukObject(h) else { return }
        v.center = CGPoint(x: x, y: y)
    }
}

// MARK: - UIView: appearance

@_cdecl("openuikit_view_set_background_color")
public func openuikit_view_set_background_color(_ h: UnsafeMutableRawPointer?,
                                                _ r: Double, _ g: Double,
                                                _ b: Double, _ a: Double) {
    oukMain {
        guard let v: UIView = oukObject(h) else { return }
        v.backgroundColor = oukColor(r, g, b, a)
    }
}

@_cdecl("openuikit_view_clear_background_color")
public func openuikit_view_clear_background_color(_ h: UnsafeMutableRawPointer?) {
    oukMain {
        guard let v: UIView = oukObject(h) else { return }
        v.backgroundColor = nil
    }
}

@_cdecl("openuikit_view_set_alpha")
public func openuikit_view_set_alpha(_ h: UnsafeMutableRawPointer?, _ a: Double) {
    oukMain {
        (oukObject(h) as UIView?)?.alpha = a
    }
}

@_cdecl("openuikit_view_set_hidden")
public func openuikit_view_set_hidden(_ h: UnsafeMutableRawPointer?, _ hidden: Int32) {
    oukMain {
        (oukObject(h) as UIView?)?.isHidden = hidden != 0
    }
}

@_cdecl("openuikit_view_set_opaque")
public func openuikit_view_set_opaque(_ h: UnsafeMutableRawPointer?, _ o: Int32) {
    oukMain {
        (oukObject(h) as UIView?)?.isOpaque = o != 0
    }
}

@_cdecl("openuikit_view_set_clips_to_bounds")
public func openuikit_view_set_clips_to_bounds(_ h: UnsafeMutableRawPointer?, _ c: Int32) {
    oukMain {
        (oukObject(h) as UIView?)?.clipsToBounds = c != 0
    }
}

@_cdecl("openuikit_view_set_corner_radius")
public func openuikit_view_set_corner_radius(_ h: UnsafeMutableRawPointer?, _ r: Double) {
    oukMain {
        (oukObject(h) as UIView?)?.layer.cornerRadius = r
    }
}

@_cdecl("openuikit_view_set_tag")
public func openuikit_view_set_tag(_ h: UnsafeMutableRawPointer?, _ t: Int64) {
    oukMain {
        (oukObject(h) as UIView?)?.tag = Int(t)
    }
}

@_cdecl("openuikit_view_get_tag")
public func openuikit_view_get_tag(_ h: UnsafeMutableRawPointer?) -> Int64 {
    oukMain {
        Int64((oukObject(h) as UIView?)?.tag ?? 0)
    }
}

// MARK: - UIView: hierarchy

@_cdecl("openuikit_view_add_subview")
public func openuikit_view_add_subview(_ parent: UnsafeMutableRawPointer?,
                                       _ child: UnsafeMutableRawPointer?) {
    oukMain {
        guard let p: UIView = oukObject(parent), let c: UIView = oukObject(child) else { return }
        p.addSubview(c)
    }
}

@_cdecl("openuikit_view_insert_subview_at")
public func openuikit_view_insert_subview_at(_ parent: UnsafeMutableRawPointer?,
                                             _ child: UnsafeMutableRawPointer?,
                                             _ index: Int32) {
    oukMain {
        guard let p: UIView = oukObject(parent), let c: UIView = oukObject(child) else { return }
        p.insertSubview(c, at: Int(index))
    }
}

@_cdecl("openuikit_view_remove_from_superview")
public func openuikit_view_remove_from_superview(_ h: UnsafeMutableRawPointer?) {
    oukMain {
        (oukObject(h) as UIView?)?.removeFromSuperview()
    }
}

/// +0 — borrowed. See the Create Rule in Runtime.swift.
@_cdecl("openuikit_view_superview")
public func openuikit_view_superview(_ h: UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer? {
    oukMain {
        oukBorrowed((oukObject(h) as UIView?)?.superview)
    }
}

@_cdecl("openuikit_view_subview_count")
public func openuikit_view_subview_count(_ h: UnsafeMutableRawPointer?) -> Int32 {
    oukMain {
        Int32((oukObject(h) as UIView?)?.subviews.count ?? 0)
    }
}

/// +0 — borrowed.
@_cdecl("openuikit_view_subview_at")
public func openuikit_view_subview_at(_ h: UnsafeMutableRawPointer?,
                                      _ i: Int32) -> UnsafeMutableRawPointer? {
    oukMain {
        guard let v: UIView = oukObject(h), i >= 0, Int(i) < v.subviews.count else { return nil }
        return oukBorrowed(v.subviews[Int(i)])
    }
}

// MARK: - UIView: layout & display

@_cdecl("openuikit_view_set_needs_layout")
public func openuikit_view_set_needs_layout(_ h: UnsafeMutableRawPointer?) {
    oukMain {
        (oukObject(h) as UIView?)?.setNeedsLayout()
    }
}

@_cdecl("openuikit_view_layout_if_needed")
public func openuikit_view_layout_if_needed(_ h: UnsafeMutableRawPointer?) {
    oukMain {
        (oukObject(h) as UIView?)?.layoutIfNeeded()
    }
}

@_cdecl("openuikit_view_set_needs_display")
public func openuikit_view_set_needs_display(_ h: UnsafeMutableRawPointer?) {
    oukMain {
        (oukObject(h) as UIView?)?.setNeedsDisplay()
    }
}

/// The `super` half of bidirectional dispatch: an ObjC `-layoutSubviews`
/// override calls this to reach the Swift superclass implementation.
@_cdecl("openuikit_view_super_layout_subviews")
public func openuikit_view_super_layout_subviews(_ h: UnsafeMutableRawPointer?) {
    oukMain {
        guard let o: AnyObject = oukObject(h), let p = o as? OUKPeered else { return }
        p.oukSuperLayoutSubviews()
    }
}

@_cdecl("openuikit_view_super_draw_rect")
public func openuikit_view_super_draw_rect(_ h: UnsafeMutableRawPointer?,
                                           _ x: Double, _ y: Double,
                                           _ w: Double, _ hh: Double) {
    oukMain {
        guard let o: AnyObject = oukObject(h), let p = o as? OUKPeered else { return }
        p.oukSuperDraw(CGRect(x: x, y: y, width: w, height: hh))
    }
}

@_cdecl("openuikit_view_size_to_fit")
public func openuikit_view_size_to_fit(_ h: UnsafeMutableRawPointer?) {
    oukMain {
        (oukObject(h) as UIView?)?.sizeToFit()
    }
}

@_cdecl("openuikit_view_size_that_fits")
public func openuikit_view_size_that_fits(_ h: UnsafeMutableRawPointer?,
                                          _ w: Double, _ hh: Double,
                                          _ out: UnsafeMutablePointer<Double>?) {
    oukMain {
        guard let v: UIView = oukObject(h), let out else { return }
        let s = v.sizeThatFits(CGSize(width: w, height: hh))
        out[0] = s.width; out[1] = s.height
    }
}

// MARK: - UILabel

@_cdecl("openuikit_label_set_text")
public func openuikit_label_set_text(_ h: UnsafeMutableRawPointer?,
                                     _ text: UnsafePointer<CChar>?) {
    oukMain {
        guard let l: UILabel = oukObject(h) else { return }
        l.text = oukString(text)
    }
}

@_cdecl("openuikit_label_get_text")
public func openuikit_label_get_text(_ h: UnsafeMutableRawPointer?,
                                     _ buf: UnsafeMutablePointer<CChar>?,
                                     _ cap: Int32) -> Int32 {
    oukMain {
        guard let l: UILabel = oukObject(h) else { return -1 }
        return oukWriteString(l.text, buf, cap)
    }
}

@_cdecl("openuikit_label_set_text_color")
public func openuikit_label_set_text_color(_ h: UnsafeMutableRawPointer?,
                                           _ r: Double, _ g: Double,
                                           _ b: Double, _ a: Double) {
    oukMain {
        (oukObject(h) as UILabel?)?.textColor = oukColor(r, g, b, a)
    }
}

@_cdecl("openuikit_label_set_font")
public func openuikit_label_set_font(_ h: UnsafeMutableRawPointer?,
                                     _ size: Double, _ weight: Int32) {
    oukMain {
        (oukObject(h) as UILabel?)?.font = .systemFont(ofSize: size, weight: oukFontWeight(weight))
    }
}

@_cdecl("openuikit_label_set_text_alignment")
public func openuikit_label_set_text_alignment(_ h: UnsafeMutableRawPointer?, _ a: Int32) {
    oukMain {
        (oukObject(h) as UILabel?)?.textAlignment = oukTextAlignment(a)
    }
}

@_cdecl("openuikit_label_set_number_of_lines")
public func openuikit_label_set_number_of_lines(_ h: UnsafeMutableRawPointer?, _ n: Int32) {
    oukMain {
        (oukObject(h) as UILabel?)?.numberOfLines = Int(n)
    }
}

// MARK: - UIButton

@_cdecl("openuikit_button_set_title")
public func openuikit_button_set_title(_ h: UnsafeMutableRawPointer?,
                                       _ title: UnsafePointer<CChar>?,
                                       _ state: UInt32) {
    oukMain {
        guard let b: UIButton = oukObject(h) else { return }
        b.setTitle(oukString(title), for: UIControl.State(rawValue: UInt(state)))
    }
}

@_cdecl("openuikit_button_get_title")
public func openuikit_button_get_title(_ h: UnsafeMutableRawPointer?,
                                       _ state: UInt32,
                                       _ buf: UnsafeMutablePointer<CChar>?,
                                       _ cap: Int32) -> Int32 {
    oukMain {
        guard let b: UIButton = oukObject(h) else { return -1 }
        return oukWriteString(b.title(for: UIControl.State(rawValue: UInt(state))), buf, cap)
    }
}

@_cdecl("openuikit_button_set_title_color")
public func openuikit_button_set_title_color(_ h: UnsafeMutableRawPointer?,
                                             _ r: Double, _ g: Double,
                                             _ b: Double, _ a: Double,
                                             _ state: UInt32) {
    oukMain {
        guard let btn: UIButton = oukObject(h) else { return }
        btn.setTitleColor(oukColor(r, g, b, a), for: UIControl.State(rawValue: UInt(state)))
    }
}

/// +0 — borrowed. The title label is owned by the button.
@_cdecl("openuikit_button_title_label")
public func openuikit_button_title_label(_ h: UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer? {
    oukMain {
        oukBorrowed((oukObject(h) as UIButton?)?.titleLabel)
    }
}

// MARK: - UIControl: target-action

/// UIKit's `-addTarget:action:forControlEvents:`, expressed for a world with a
/// real ObjC runtime on the far side. `target` is the ObjC peer pointer and
/// `action` is a selector NAME; when the control fires, Swift calls the
/// `perform_action` hook and the facade does `objc_msgSend`. So an ObjC app
/// writes `@selector(tapped:)` with no dispatch table — the cost Swift app
/// authors pay (docs/OBJC_RUNTIME.md, `SelectorDispatching`) does not exist on
/// this side of the bridge.
///
/// OWNERSHIP: `target` is held UNOWNED, exactly like UIKit's weak target.
/// The facade is responsible for calling `openuikit_control_remove_target`
/// from the target's `-dealloc` if the control can outlive it.
@_cdecl("openuikit_control_add_target_action")
public func openuikit_control_add_target_action(_ h: UnsafeMutableRawPointer?,
                                                _ target: UnsafeMutableRawPointer?,
                                                _ action: UnsafePointer<CChar>?,
                                                _ events: UInt32) -> Int64 {
    oukMain {
        guard let c: UIControl = oukObject(h), let target,
              let name = oukString(action) else { return 0 }
        let arity = Int32(name.utf8.filter { $0 == UInt8(ascii: ":") }.count)
        let token = c.addTarget(for: UIControl.Event(rawValue: UInt(events))) { sender, _ in
            guard let hook = OUKHooks.performAction else { return }
            name.withCString { hook(target, $0, oukBorrowed(sender), arity) }
        }
        return Int64(token)
    }
}

@_cdecl("openuikit_control_remove_target")
public func openuikit_control_remove_target(_ h: UnsafeMutableRawPointer?, _ token: Int64) {
    oukMain {
        (oukObject(h) as UIControl?)?.removeTarget(Int(token))
    }
}

@_cdecl("openuikit_control_send_actions")
public func openuikit_control_send_actions(_ h: UnsafeMutableRawPointer?, _ events: UInt32) {
    oukMain {
        (oukObject(h) as UIControl?)?.sendActions(for: UIControl.Event(rawValue: UInt(events)))
    }
}

@_cdecl("openuikit_control_set_enabled")
public func openuikit_control_set_enabled(_ h: UnsafeMutableRawPointer?, _ on: Int32) {
    oukMain {
        (oukObject(h) as UIControl?)?.isEnabled = on != 0
    }
}

// MARK: - UIViewController

/// +0 — borrowed; the controller owns its view. Loads it on first access,
/// exactly like `-[UIViewController view]`.
@_cdecl("openuikit_viewcontroller_view")
public func openuikit_viewcontroller_view(_ h: UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer? {
    oukMain {
        guard let vc: UIViewController = oukObject(h) else { return nil }
        return oukBorrowed(vc.view)
    }
}

@_cdecl("openuikit_viewcontroller_set_view")
public func openuikit_viewcontroller_set_view(_ h: UnsafeMutableRawPointer?,
                                              _ view: UnsafeMutableRawPointer?) {
    oukMain {
        guard let vc: UIViewController = oukObject(h) else { return }
        vc.view = oukObject(view) as UIView?
    }
}

@_cdecl("openuikit_viewcontroller_view_if_loaded")
public func openuikit_viewcontroller_view_if_loaded(_ h: UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer? {
    oukMain {
        oukBorrowed((oukObject(h) as UIViewController?)?.viewIfLoaded)
    }
}

@_cdecl("openuikit_viewcontroller_load_view_if_needed")
public func openuikit_viewcontroller_load_view_if_needed(_ h: UnsafeMutableRawPointer?) {
    oukMain {
        (oukObject(h) as UIViewController?)?.loadViewIfNeeded()
    }
}

@_cdecl("openuikit_viewcontroller_super_load_view")
public func openuikit_viewcontroller_super_load_view(_ h: UnsafeMutableRawPointer?) {
    oukMain {
        (oukObject(h) as OUKViewController?)?.oukSuperLoadView()
    }
}

@_cdecl("openuikit_viewcontroller_super_view_did_load")
public func openuikit_viewcontroller_super_view_did_load(_ h: UnsafeMutableRawPointer?) {
    oukMain {
        (oukObject(h) as OUKViewController?)?.oukSuperViewDidLoad()
    }
}

@_cdecl("openuikit_viewcontroller_set_title")
public func openuikit_viewcontroller_set_title(_ h: UnsafeMutableRawPointer?,
                                               _ t: UnsafePointer<CChar>?) {
    oukMain {
        (oukObject(h) as UIViewController?)?.title = oukString(t)
    }
}

@_cdecl("openuikit_viewcontroller_add_child")
public func openuikit_viewcontroller_add_child(_ h: UnsafeMutableRawPointer?,
                                               _ child: UnsafeMutableRawPointer?) {
    oukMain {
        guard let vc: UIViewController = oukObject(h),
              let c: UIViewController = oukObject(child) else { return }
        vc.addChild(c)
    }
}

// MARK: - Drawing, for -drawRect:

/// UIKit's `UIGraphicsGetCurrentContext()` reduced to what a C caller can use:
/// the drawing verbs act on the context the render pass pushed before calling
/// `draw(_:)`, so they are only meaningful inside a `-drawRect:` callback.
/// Outside one they are no-ops (not crashes) — a C ABI has nowhere to throw.

/// UIKit's `[color setFill]` — sets the CURRENT context's implicit fill
/// color, so the ObjC facade can spell `-drawRect:` bodies the UIKit way
/// (`[[UIColor redColor] setFill]; UIRectFill(rect);`) instead of threading
/// a color through every drawing verb.
@_cdecl("openuikit_gc_set_fill_color")
public func openuikit_gc_set_fill_color(_ r: Double, _ g: Double, _ b: Double, _ a: Double) {
    oukMain {
        oukColor(r, g, b, a).setFill()
    }
}

/// UIKit's `UIRectFill(rect)`: fill with the current fill color.
@_cdecl("openuikit_gc_fill_rect_current")
public func openuikit_gc_fill_rect_current(_ x: Double, _ y: Double,
                                           _ w: Double, _ h: Double) {
    oukMain {
        guard let c = UIGraphicsGetCurrentContext() else { return }
        c.fill(rect: CGRect(x: x, y: y, width: w, height: h),
               color: UIGraphicsCurrentFillColor())
    }
}

@_cdecl("openuikit_gc_fill_rect")
public func openuikit_gc_fill_rect(_ x: Double, _ y: Double, _ w: Double, _ h: Double,
                                   _ r: Double, _ g: Double, _ b: Double, _ a: Double) {
    oukMain {
        guard let c = UIGraphicsGetCurrentContext() else { return }
        c.fill(rect: CGRect(x: x, y: y, width: w, height: h),
               color: CGColor(red: r, green: g, blue: b, alpha: a))
    }
}

@_cdecl("openuikit_gc_fill_rounded_rect")
public func openuikit_gc_fill_rounded_rect(_ x: Double, _ y: Double, _ w: Double, _ h: Double,
                                           _ radius: Double,
                                           _ r: Double, _ g: Double, _ b: Double, _ a: Double) {
    oukMain {
        guard let c = UIGraphicsGetCurrentContext() else { return }
        c.fill(.roundedRect(CGRect(x: x, y: y, width: w, height: h), cornerRadius: radius),
               color: CGColor(red: r, green: g, blue: b, alpha: a))
    }
}

@_cdecl("openuikit_gc_stroke_rect")
public func openuikit_gc_stroke_rect(_ x: Double, _ y: Double, _ w: Double, _ h: Double,
                                     _ lineWidth: Double,
                                     _ r: Double, _ g: Double, _ b: Double, _ a: Double) {
    oukMain {
        guard let c = UIGraphicsGetCurrentContext() else { return }
        c.stroke(.rect(CGRect(x: x, y: y, width: w, height: h)),
                 color: CGColor(red: r, green: g, blue: b, alpha: a), lineWidth: lineWidth)
    }
}

// MARK: - Rendering

/// Lay out and render `root` to a PNG file. Returns 1 on success.
///
/// This is the same `UIRenderer.render` the whole oracle suite goes through —
/// the bridge adds no rendering code of its own, which is what makes an
/// ObjC-built hierarchy comparable byte-for-byte with a Swift-built one.
@_cdecl("openuikit_render_png")
public func openuikit_render_png(_ h: UnsafeMutableRawPointer?,
                                 _ scale: Double,
                                 _ path: UnsafePointer<CChar>?) -> Int32 {
    oukMain {
        guard let v: UIView = oukObject(h), let path = oukString(path) else { return 0 }
        v.layoutIfNeeded()
        let bitmap = UIRenderer.render(v, scale: scale)
        guard let png = ImageCodec.encodePNG(bitmap) else { return 0 }
        var ok: Int32 = 0
        png.withUnsafeBufferPointer { buf in
            path.withCString { p in
                ok = Int32(cpio_write_file(p, buf.baseAddress, buf.count))
            }
        }
        return ok
    }
}

/// Select the render backend, mirroring OPENUIKIT_BACKEND for openrender.
/// 0 = swift, 1 = quartz.
@_cdecl("openuikit_set_backend")
public func openuikit_set_backend(_ backend: Int32) {
    oukMain {
        OpenUIKitRuntime.renderBackend = (backend == 1) ? .quartz : .swift
    }
}

/// Point the font/metrics resource loader at a directory (the ObjC app is not
/// launched by SPM, so it has no `.build` layout to infer one from).
@_cdecl("openuikit_set_resource_root")
public func openuikit_set_resource_root(_ p: UnsafePointer<CChar>?) {
    oukMain {
        guard let s = oukString(p) else { return }
        OpenUIKitRuntime.resourceRoot = s
    }
}

/// The C form of openrender's OPENUIKIT_FONT_DIR handling: `key` is
/// "system" / "mono" / "italic". Off Darwin there is no system SF to fall
/// back to, so an ObjC app that renders text must set these exactly as
/// openrender does — otherwise the two renders could differ for reasons that
/// have nothing to do with the bridge.
@_cdecl("openuikit_set_font_path")
public func openuikit_set_font_path(_ key: UnsafePointer<CChar>?,
                                    _ path: UnsafePointer<CChar>?) {
    oukMain {
        guard let k = oukString(key), let p = oukString(path) else { return }
        OpenUIKitRuntime.fontPaths[k] = p
    }
}
