// quartz_draw.swift -- the Swift twin of machorun tests/src/15_quartz.c.
//
// Same 256x256 bitmap, same nine drawing stages, same FNV-1a per-stage
// checksums and probe pixels, same PNG. The point is to exercise, together and
// under machorun: the Swift runtime, Swift->C interop over the Darwin ABI
// (including QZRect / QZPoint structs passed BY VALUE across the boundary), and
// the quartz rasteriser -- and to prove the PNG is byte-identical to a native
// macOS run.
//
// Coordinates and colours are copied verbatim from 15_quartz.c so the two
// programs are the same picture, differing only in source language.

import Quartz

let W = 256
let H = 256

// A raw Double buffer -- see the note at stage 5 for why we avoid [Double].
func buf(_ n: Int) -> UnsafeMutablePointer<Double> {
    UnsafeMutablePointer<Double>.allocate(capacity: n)
}

func fnv1a(_ p: UnsafePointer<UInt8>, _ n: Int) -> UInt64 {
    var h: UInt64 = 1469598103934665603
    for i in 0..<n { h ^= UInt64(p[i]); h = h &* 1099511628211 }
    return h
}

// Foundation-free formatting: zero-padded hex, and a left-justified field.
func hex(_ v: UInt64, _ width: Int) -> String {
    var s = String(v, radix: 16)
    while s.count < width { s = "0" + s }
    return s
}
func hex2(_ v: UInt8) -> String { hex(UInt64(v), 2) }
func padRight(_ s: String, _ width: Int) -> String {
    var t = s
    while t.count < width { t += " " }
    return t
}

var stageNo = 0
func stage(_ ctx: QZContextRef, _ what: String) {
    let px = QZBitmapContextGetData(ctx)!.assumingMemoryBound(to: UInt8.self)
    let bpr = QZBitmapContextGetBytesPerRow(ctx)
    let probeX: [Int] = [8, 64, 128, 200, 40]
    let probeY: [Int] = [8, 64, 128, 60, 210]
    stageNo += 1
    var line = "stage \(stageNo) \(padRight(what, 18)) fnv1a=\(hex(fnv1a(px, bpr * H), 16))"
    for i in 0..<probeX.count {
        let q = px + probeY[i] * bpr + probeX[i] * 4
        line += "  \(hex2(q[0]))\(hex2(q[1]))\(hex2(q[2]))\(hex2(q[3]))"
    }
    print(line)
}

@_cdecl("quartz_draw")
public func quartzDraw(_ outC: UnsafePointer<CChar>) -> Int32 {
    let out = String(cString: outC)

    guard let ctx = QZBitmapContextCreate(nil, W, H, 8, W * 4,
                                          kQZImageAlphaPremultipliedLast) else {
        print("QZBitmapContextCreate failed"); return 2
    }

    print("quartz fixture \(QZBitmapContextGetWidth(ctx))x\(QZBitmapContextGetHeight(ctx)) bpr=\(QZBitmapContextGetBytesPerRow(ctx))")

    // 1 -- background
    QZContextSetRGBFillColor(ctx, 0.09, 0.11, 0.16, 1.0)
    QZContextFillRect(ctx, QZRectMake(0, 0, Double(W), Double(H)))
    stage(ctx, "background")

    // 2 -- opaque axis-aligned rects on integer boundaries
    QZContextSetRGBFillColor(ctx, 0.85, 0.24, 0.20, 1.0)
    QZContextFillRect(ctx, QZRectMake(16, 16, 48, 32))
    QZContextSetRGBFillColor(ctx, 0.20, 0.70, 0.35, 1.0)
    QZContextFillRect(ctx, QZRectMake(72, 16, 48, 32))
    stage(ctx, "rects")

    // 3 -- translucent overlapping rects (source-over)
    QZContextSetRGBFillColor(ctx, 0.95, 0.80, 0.10, 0.55)
    QZContextFillRect(ctx, QZRectMake(40.5, 32.25, 60, 40))
    QZContextSetRGBFillColor(ctx, 0.10, 0.45, 0.95, 0.45)
    QZContextFillRect(ctx, QZRectMake(70.75, 44.5, 60, 40))
    stage(ctx, "alpha-rects")

    // 4 -- cubic bezier, filled non-zero
    QZContextBeginPath(ctx)
    QZContextMoveToPoint(ctx, 20, 120)
    QZContextAddCurveToPoint(ctx, 60, 200, 120, 60, 160, 140)
    QZContextAddCurveToPoint(ctx, 180, 180, 120, 210, 60, 190)
    QZContextClosePath(ctx)
    QZContextSetRGBFillColor(ctx, 0.55, 0.35, 0.85, 0.90)
    QZContextFillPath(ctx)
    stage(ctx, "bezier-fill")

    // 5 -- dashed stroke, round caps and joins.
    // NOTE: gradient/dash arguments use raw Double buffers, not Swift [Double]
    // literals. Under machorun the runtime instantiation of a non-prespecialized
    // generic class metadata (Array<Double>'s storage) currently crashes in
    // swift_initClassMetadataImpl; Array<Int> is prespecialized and is fine, but
    // Array<Double> is not. UnsafeMutablePointer<Double> sidesteps the storage
    // class entirely, so the drawing itself -- the point of this program -- runs.
    let dash = UnsafeMutablePointer<Double>.allocate(capacity: 2)
    dash[0] = 9.0; dash[1] = 5.0
    QZContextSetLineDash(ctx, 2.0, dash, 2)
    QZContextSetLineWidth(ctx, 5.5)
    QZContextSetLineCap(ctx, kQZLineCapRound)
    QZContextSetLineJoin(ctx, kQZLineJoinRound)
    QZContextSetRGBStrokeColor(ctx, 1.0, 0.55, 0.10, 1.0)
    QZContextBeginPath(ctx)
    QZContextMoveToPoint(ctx, 12, 100)
    QZContextAddLineToPoint(ctx, 90, 108)
    QZContextAddLineToPoint(ctx, 140, 70)
    QZContextAddLineToPoint(ctx, 240, 104)
    QZContextStrokePath(ctx)
    QZContextSetLineDash(ctx, 0, nil, 0)
    dash.deallocate()
    stage(ctx, "dashed-stroke")

    // 6 -- linear gradient, clipped to a rect
    do {
        let locs = buf(3)
        locs[0] = 0.0; locs[1] = 0.5; locs[2] = 1.0
        let comps = buf(12)
        comps[0] = 1.00; comps[1] = 0.20; comps[2] = 0.30; comps[3] = 1.0
        comps[4] = 0.20; comps[5] = 0.90; comps[6] = 0.90; comps[7] = 1.0
        comps[8] = 0.15; comps[9] = 0.20; comps[10] = 0.80; comps[11] = 1.0
        let g = QZGradientCreate(locs, comps, 3)
        QZContextSaveGState(ctx)
        QZContextClipToRect(ctx, QZRectMake(150, 150, 90, 40))
        QZContextDrawLinearGradient(ctx, g, QZPointMake(150, 150), QZPointMake(240, 190), 0)
        QZContextRestoreGState(ctx)
        QZGradientRelease(g)
        locs.deallocate(); comps.deallocate()
    }
    stage(ctx, "linear-gradient")

    // 7 -- radial gradient, clipped to an ellipse
    do {
        let locs = buf(2)
        locs[0] = 0.0; locs[1] = 1.0
        let comps = buf(8)
        comps[0] = 1.0; comps[1] = 1.0; comps[2] = 0.85; comps[3] = 1.0
        comps[4] = 0.30; comps[5] = 0.10; comps[6] = 0.45; comps[7] = 0.0
        let g = QZGradientCreate(locs, comps, 2)
        QZContextSaveGState(ctx)
        QZContextBeginPath(ctx)
        QZContextAddEllipseInRect(ctx, QZRectMake(150, 30, 90, 90))
        QZContextClip(ctx)
        QZContextDrawRadialGradient(ctx, g, QZPointMake(195, 75), 2.0,
                                    QZPointMake(195, 75), 46.0, 0)
        QZContextRestoreGState(ctx)
        QZGradientRelease(g)
        locs.deallocate(); comps.deallocate()
    }
    stage(ctx, "radial-gradient")

    // 8 -- the transcendental stage: rotate through cos/sin
    QZContextSaveGState(ctx)
    QZContextTranslateCTM(ctx, 196, 196)
    QZContextRotateCTM(ctx, 0.5235987755982988 /* pi/6 */)
    QZContextSetRGBFillColor(ctx, 0.95, 0.95, 0.98, 0.85)
    QZContextFillRect(ctx, QZRectMake(-34, -20, 68, 40))
    QZContextSetRGBStrokeColor(ctx, 0.10, 0.10, 0.12, 1.0)
    QZContextSetLineWidth(ctx, 2.0)
    QZContextStrokeRect(ctx, QZRectMake(-34, -20, 68, 40))
    QZContextRestoreGState(ctx)
    stage(ctx, "rotated")

    // 9 -- even-odd clip: two overlapping circles, XOR region filled
    QZContextSaveGState(ctx)
    QZContextBeginPath(ctx)
    QZContextAddEllipseInRect(ctx, QZRectMake(20, 200, 60, 46))
    QZContextAddEllipseInRect(ctx, QZRectMake(50, 200, 60, 46))
    QZContextEOClip(ctx)
    QZContextSetRGBFillColor(ctx, 0.20, 0.95, 0.70, 1.0)
    QZContextFillRect(ctx, QZRectMake(0, 190, 140, 66))
    QZContextRestoreGState(ctx)
    stage(ctx, "eo-clip")

    if QZContextWritePNG(ctx, out) == 0 {
        print("QZContextWritePNG(\(out)) failed")
        QZContextRelease(ctx)
        return 3
    }
    print("wrote \(out)")
    QZContextRelease(ctx)
    return 0
}
