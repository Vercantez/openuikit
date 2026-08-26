// boxes_render.swift -- builds the boxes_basic view tree with the vendored
// OpenUIKit slice and renders it to PNG bytes. Mirrors ~/uikit
// Sources/openrender/SceneBuilder.swift: a scene-sized `host` UIView wraps a
// 0x0 `container` root; the colored views are the container's subviews at their
// real frames; UIRenderer.render(host, scale: 2) rasterises through the .quartz
// backend. #RRGGBB -> UIColor(red:g:b:/255) matches parseColor.
//
// The slice's @MainActor annotations were stripped (single-threaded render;
// the Swift Concurrency runtime is not provisioned under machorun), so these
// entry points call the render code directly with no actor isolation.
import UIKitSlice

@_cdecl("slice_probe")
public func slice_probe() -> Int32 { 42 }

@_cdecl("slice_probe_pathelem")
public func slice_probe_pathelem() -> Int32 {
    // Array<Path.Element>: a generic Array over a CUSTOM enum -> non-prespecialized
    // __ContiguousArrayStorage class metadata, instantiated at runtime.
    let p = Path.rect(CGRect(x: 0, y: 0, width: 4, height: 4))
    var n = 0
    for _ in p.elements { n += 1 }
    return Int32(n)
}

@_cdecl("slice_probe_uint8arr")
public func slice_probe_uint8arr() -> Int32 {
    // Array<UInt8>: prespecialized in the shipped stdlib -> should work.
    var a = [UInt8](repeating: 0, count: 8)
    a.append(1)
    return Int32(a.count)
}

@_cdecl("slice_probe_pointarr")
public func slice_probe_pointarr() -> Int32 {
    // Array<CGPoint>: generic Array over a struct that is NOT prespecialized.
    var a = [CGPoint]()
    a.append(CGPoint(x: 1, y: 2))
    a.append(CGPoint(x: 3, y: 4))
    return Int32(a.count)
}

final class _Owner {}
final class _Holder { unowned let o: _Owner; init(_ o: _Owner) { self.o = o } }
protocol _P: AnyObject { func v() -> Int32 }
final class _Impl: _P { func v() -> Int32 { 11 } }

@_cdecl("slice_probe_unowned")
public func slice_probe_unowned() -> Int32 {
    let o = _Owner()
    let h = _Holder(o)                     // stores `unowned let o`
    return h.o === o ? 22 : -1
}

// The exact Canvas/backend shape: a class whose init stores a helper that
// captures `unowned self` before self is fully initialised.
final class _Cv { var b: _Holder2!; init() { self.b = _Holder2(self) } }
final class _Holder2 { unowned let c: _Cv; init(_ c: _Cv) { self.c = c } }

@_cdecl("slice_probe_unowned_self")
public func slice_probe_unowned_self() -> Int32 {
    let cv = _Cv()                         // captures `unowned self` during init
    return cv.b.c === cv ? 33 : -1
}

@_cdecl("slice_probe_existential")
public func slice_probe_existential() -> Int32 {
    let p: _P! = _Impl()                   // class -> protocol existential (IUO), like backend
    return p.v()
}

@_cdecl("slice_probe_bitmap")
public func slice_probe_bitmap() -> Int32 {
    let b = Bitmap(width: 4, height: 4)          // [UInt8] alloc
    let png = b.pngData()                        // PNG encode over [UInt8]
    return Int32(png.count)
}

@_cdecl("slice_probe_canvas")
public func slice_probe_canvas() -> Int32 {
    let b = Bitmap(width: 8, height: 8)
    let c = Canvas(bitmap: b, scale: 2)          // creates QuartzBackend (QZ ctx)
    return Int32(c.bitmap.width)
}

@_cdecl("slice_probe_canvas_swift")
public func slice_probe_canvas_swift() -> Int32 {
    CanvasBackendSelection.current = .swift      // pure-Swift rasterizer backend
    let b = Bitmap(width: 8, height: 8)
    let c = Canvas(bitmap: b, scale: 2)
    c.fill(.rect(CGRect(x: 0, y: 0, width: 4, height: 4)),
           color: CGColor(red: 1, green: 0, blue: 0, alpha: 1))
    return Int32(b.pngData().count)
}

@_cdecl("slice_probe_fill")
public func slice_probe_fill() -> Int32 {
    let b = Bitmap(width: 8, height: 8)
    let c = Canvas(bitmap: b, scale: 2)
    c.fill(.rect(CGRect(x: 0, y: 0, width: 4, height: 4)),
           color: CGColor(red: 1, green: 0, blue: 0, alpha: 1))
    return Int32(b.pngData().count)
}

@_cdecl("slice_probe_view")
public func slice_probe_view() -> Int32 {
    let host = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
    let v = UIView()
    v.frame = CGRect(x: 2, y: 2, width: 8, height: 8)
    v.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
    host.addSubview(v)
    return Int32(host.subviews.count)
}

private func hex(_ v: UInt32) -> UIColor {
    UIColor(red: CGFloat((v >> 16) & 0xFF) / 255,
            green: CGFloat((v >> 8) & 0xFF) / 255,
            blue: CGFloat(v & 0xFF) / 255, alpha: 1)
}

private func makeView(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat,
                      _ color: UInt32) -> UIView {
    let v = UIView()
    v.frame = CGRect(x: x, y: y, width: w, height: h)
    v.backgroundColor = hex(color)
    return v
}

private func buildBoxesBasic() -> (host: UIView, scale: CGFloat) {
    let host = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
    let container = UIView()               // root: frame nil -> 0x0, per SceneBuilder
    container.backgroundColor = hex(0xFFFFFF)

    container.addSubview(makeView(20, 20, 120, 80, 0xE03131))
    let v2 = makeView(100, 60, 120, 80, 0x1971C2)
    v2.addSubview(makeView(10, 10, 40, 30, 0xFFD43B))
    v2.addSubview(makeView(-20, 40, 60, 60, 0x2F9E44))
    container.addSubview(v2)
    container.addSubview(makeView(240, 150, 200, 200, 0x845EF7))

    host.addSubview(container)
    host.layoutIfNeeded()
    return (host, 2)
}

// Returns malloc'd PNG bytes; sets *outLen. Caller (C main) frees/writes.
@_cdecl("slice_render_boxes_png")
public func slice_render_boxes_png(_ outLen: UnsafeMutablePointer<Int>) -> UnsafeMutablePointer<UInt8>? {
    let (host, scale) = buildBoxesBasic()
    let bmp = UIRenderer.render(host, scale: scale)
    let png = bmp.pngData()
    outLen.pointee = png.count
    let buf = UnsafeMutablePointer<UInt8>.allocate(capacity: png.count)
    png.withUnsafeBufferPointer { buf.update(from: $0.baseAddress!, count: png.count) }
    return buf
}
