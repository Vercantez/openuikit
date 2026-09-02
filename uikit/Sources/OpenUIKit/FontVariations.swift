// FontVariations. Owner: text module.
//
// TrueType variable-font instancing: parses fvar/avar/glyf/loca/gvar and
// produces per-instance glyph outlines (as stbtt_vertex arrays) with the
// axis deltas applied. stb_truetype only renders the default instance of a
// variable font; real UIKit renders the proper optical-size (opsz = point
// size) and weight (wght) instance, so glyph shapes differ visibly for
// every non-default weight and for all text sizes != 28pt (SFNS's default
// opsz is 28). This file supplies the corrected outlines; rasterization is
// delegated back to stbtt_Rasterize so anti-aliasing matches the stb path.
//
// Spec references: OpenType fvar/avar/glyf/gvar tables. Only what SFNS,
// SFNSItalic and SFNSMono need is implemented (coordinate points, shared
// tuples, IUP, composite component offsets). Malformed data fails soft
// (returns nil → caller falls back to the default instance).

import CSTBTrueType

final class FontVariations {

    struct Axis {
        var tag: UInt32
        var minValue: Double
        var defaultValue: Double
        var maxValue: Double
    }

    private let bytes: UnsafePointer<UInt8>
    private let count: Int

    private(set) var axes: [Axis] = []
    /// Per axis: avar segment map (fromCoord, toCoord), sorted; empty = identity.
    private var avarMaps: [[(from: Double, to: Double)]] = []

    private var glyfOff = 0, glyfLen = 0
    private var locaOff = 0, locaLen = 0
    private var gvarOff = 0, gvarLen = 0
    private var locaLong = false
    private var numGlyphs = 0

    // MARK: - Byte reads (bounds-checked, big-endian)

    private func u8(_ o: Int) -> Int? { o >= 0 && o < count ? Int(bytes[o]) : nil }
    private func u16(_ o: Int) -> Int? {
        guard o >= 0, o + 1 < count else { return nil }
        return Int(bytes[o]) << 8 | Int(bytes[o + 1])
    }
    private func i16(_ o: Int) -> Int? {
        guard let v = u16(o) else { return nil }
        return v >= 0x8000 ? v - 0x10000 : v
    }
    private func u32(_ o: Int) -> Int? {
        guard o >= 0, o + 3 < count else { return nil }
        return Int(bytes[o]) << 24 | Int(bytes[o + 1]) << 16 | Int(bytes[o + 2]) << 8 | Int(bytes[o + 3])
    }
    private func f2dot14(_ o: Int) -> Double? {
        guard let v = i16(o) else { return nil }
        return Double(v) / 16384.0
    }
    private func fixed(_ o: Int) -> Double? {
        guard let v = u32(o) else { return nil }
        let signed = v >= 0x80000000 ? v - 0x100000000 : v
        return Double(signed) / 65536.0
    }

    // MARK: - Init: locate tables

    init?(bytes: UnsafePointer<UInt8>, count: Int, fontOffset: Int) {
        self.bytes = bytes
        self.count = count
        guard fontOffset >= 0, fontOffset + 12 <= count else { return nil }
        func ru16(_ o: Int) -> Int? {
            guard o >= 0, o + 1 < count else { return nil }
            return Int(bytes[o]) << 8 | Int(bytes[o + 1])
        }
        guard let numTables = ru16(fontOffset + 4) else { return nil }
        var tables: [UInt32: (Int, Int)] = [:]
        for i in 0..<numTables {
            let rec = fontOffset + 12 + 16 * i
            guard rec + 16 <= count else { return nil }
            let tag = UInt32(bytes[rec]) << 24 | UInt32(bytes[rec + 1]) << 16
                    | UInt32(bytes[rec + 2]) << 8 | UInt32(bytes[rec + 3])
            let off = Int(bytes[rec + 8]) << 24 | Int(bytes[rec + 9]) << 16
                    | Int(bytes[rec + 10]) << 8 | Int(bytes[rec + 11])
            let len = Int(bytes[rec + 12]) << 24 | Int(bytes[rec + 13]) << 16
                    | Int(bytes[rec + 14]) << 8 | Int(bytes[rec + 15])
            tables[tag] = (off, len)
        }
        func tag(_ s: StaticString) -> UInt32 {
            var v: UInt32 = 0
            s.withUTF8Buffer { buf in
                for b in buf { v = v << 8 | UInt32(b) }
            }
            return v
        }
        guard let fvar = tables[tag("fvar")],
              let glyf = tables[tag("glyf")],
              let loca = tables[tag("loca")],
              let gvar = tables[tag("gvar")],
              let head = tables[tag("head")],
              let maxp = tables[tag("maxp")] else { return nil }
        glyfOff = glyf.0; glyfLen = glyf.1
        locaOff = loca.0; locaLen = loca.1
        gvarOff = gvar.0; gvarLen = gvar.1
        guard let fmt = i16(head.0 + 50), let ng = u16(maxp.0 + 4) else { return nil }
        locaLong = fmt != 0
        numGlyphs = ng

        // fvar
        guard let axesArrayOffset = u16(fvar.0 + 4),
              let axisCount = u16(fvar.0 + 8),
              let axisSize = u16(fvar.0 + 10), axisSize >= 20 else { return nil }
        for i in 0..<axisCount {
            let a = fvar.0 + axesArrayOffset + i * axisSize
            guard let t = u32(a), let mn = fixed(a + 4), let df = fixed(a + 8),
                  let mx = fixed(a + 12) else { return nil }
            axes.append(Axis(tag: UInt32(t), minValue: mn, defaultValue: df, maxValue: mx))
        }
        avarMaps = Array(repeating: [], count: axisCount)

        // avar (optional)
        if let avar = tables[tag("avar")], let ac = u16(avar.0 + 6), ac == axisCount {
            var o = avar.0 + 8
            var ok = true
            var maps: [[(from: Double, to: Double)]] = []
            for _ in 0..<axisCount {
                guard let n = u16(o) else { ok = false; break }
                o += 2
                var seg: [(Double, Double)] = []
                seg.reserveCapacity(n)
                for _ in 0..<n {
                    guard let f = f2dot14(o), let t = f2dot14(o + 2) else { ok = false; break }
                    seg.append((f, t))
                    o += 4
                }
                if !ok { break }
                maps.append(seg)
            }
            if ok { avarMaps = maps }
        }
    }

    // MARK: - Coordinate normalization

    /// Normalized (post-avar) coordinates for user-space axis values keyed by tag.
    /// Missing axes stay at their default (0).
    func normalizedCoords(_ user: [UInt32: Double]) -> [Double] {
        var out: [Double] = []
        out.reserveCapacity(axes.count)
        for (i, ax) in axes.enumerated() {
            var n = 0.0
            if let v0 = user[ax.tag] {
                let v = Swift.max(ax.minValue, Swift.min(ax.maxValue, v0))
                if v > ax.defaultValue, ax.maxValue > ax.defaultValue {
                    n = (v - ax.defaultValue) / (ax.maxValue - ax.defaultValue)
                } else if v < ax.defaultValue, ax.defaultValue > ax.minValue {
                    n = (v - ax.defaultValue) / (ax.defaultValue - ax.minValue)
                }
            }
            n = (n * 16384).rounded() / 16384
            let seg = avarMaps[i]
            if seg.count >= 2 {
                if n <= seg[0].from {
                    n = seg[0].to
                } else if n >= seg[seg.count - 1].from {
                    n = seg[seg.count - 1].to
                } else {
                    for j in 1..<seg.count where n <= seg[j].from {
                        let (f0, t0) = seg[j - 1]
                        let (f1, t1) = seg[j]
                        n = f1 > f0 ? t0 + (t1 - t0) * (n - f0) / (f1 - f0) : t0
                        break
                    }
                }
                n = (n * 16384).rounded() / 16384
            }
            out.append(n)
        }
        return out
    }

    // MARK: - Glyph outline points

    struct Point {
        var x: Double
        var y: Double
        var onCurve: Bool
    }

    private func glyphRange(_ glyph: Int) -> (Int, Int)? {
        guard glyph >= 0, glyph < numGlyphs else { return nil }
        if locaLong {
            guard let a = u32(locaOff + glyph * 4), let b = u32(locaOff + glyph * 4 + 4),
                  b >= a else { return nil }
            return (glyfOff + a, glyfOff + b)
        }
        guard let a = u16(locaOff + glyph * 2), let b = u16(locaOff + glyph * 2 + 2),
              b >= a else { return nil }
        return (glyfOff + a * 2, glyfOff + b * 2)
    }

    /// Fully instanced outline points (+ contour end indices) for a glyph at
    /// normalized coords. Empty arrays = empty glyph. nil = parse failure.
    func instancedPoints(glyph: Int, coords: [Double], depth: Int = 0)
        -> (points: [Point], ends: [Int])? {
        guard depth < 5, let (start, end) = glyphRange(glyph) else { return nil }
        if start == end { return ([], []) }
        guard let ncont = i16(start) else { return nil }
        if ncont >= 0 {
            return simpleGlyph(glyph: glyph, at: start, contours: ncont, coords: coords)
        }
        return compositeGlyph(glyph: glyph, at: start, coords: coords, depth: depth)
    }

    private func simpleGlyph(glyph: Int, at start: Int, contours: Int, coords: [Double])
        -> (points: [Point], ends: [Int])? {
        var o = start + 10
        var ends: [Int] = []
        ends.reserveCapacity(contours)
        for _ in 0..<contours {
            guard let e = u16(o) else { return nil }
            ends.append(e)
            o += 2
        }
        let npts = (ends.last ?? -1) + 1
        if npts <= 0 { return ([], []) }
        guard npts <= 10000 else { return nil }
        guard let insLen = u16(o) else { return nil }
        o += 2 + insLen
        // flags
        var flags: [UInt8] = []
        flags.reserveCapacity(npts)
        while flags.count < npts {
            guard let f = u8(o) else { return nil }
            o += 1
            flags.append(UInt8(f))
            if f & 8 != 0 {  // repeat
                guard let r = u8(o) else { return nil }
                o += 1
                for _ in 0..<r where flags.count < npts { flags.append(UInt8(f)) }
            }
        }
        // x coords
        var xs: [Double] = []
        xs.reserveCapacity(npts)
        var x = 0
        for f in flags {
            if f & 2 != 0 {
                guard let d = u8(o) else { return nil }
                o += 1
                x += (f & 16 != 0) ? d : -d
            } else if f & 16 == 0 {
                guard let d = i16(o) else { return nil }
                o += 2
                x += d
            }
            xs.append(Double(x))
        }
        var ys: [Double] = []
        ys.reserveCapacity(npts)
        var y = 0
        for f in flags {
            if f & 4 != 0 {
                guard let d = u8(o) else { return nil }
                o += 1
                y += (f & 32 != 0) ? d : -d
            } else if f & 32 == 0 {
                guard let d = i16(o) else { return nil }
                o += 2
                y += d
            }
            ys.append(Double(y))
        }
        var pts: [Point] = []
        pts.reserveCapacity(npts)
        for i in 0..<npts {
            pts.append(Point(x: xs[i], y: ys[i], onCurve: flags[i] & 1 != 0))
        }
        if let deltas = gvarDeltas(glyph: glyph, coords: coords, pointCount: npts, ends: ends,
                                   origPoints: pts) {
            for i in 0..<npts {
                pts[i].x += deltas[i].0
                pts[i].y += deltas[i].1
            }
        }
        return (pts, ends)
    }

    private func compositeGlyph(glyph: Int, at start: Int, coords: [Double], depth: Int)
        -> (points: [Point], ends: [Int])? {
        struct Component {
            var glyph: Int
            var dx: Double
            var dy: Double
            var xx: Double, xy: Double, yx: Double, yy: Double
        }
        var comps: [Component] = []
        var o = start + 10
        while true {
            guard let flags = u16(o), let gi = u16(o + 2) else { return nil }
            o += 4
            var dx = 0.0, dy = 0.0
            if flags & 1 != 0 {  // words
                guard let a = i16(o), let b = i16(o + 2) else { return nil }
                o += 4
                if flags & 2 != 0 { dx = Double(a); dy = Double(b) }
            } else {
                guard let a = u8(o), let b = u8(o + 1) else { return nil }
                o += 2
                if flags & 2 != 0 {
                    dx = Double(Int8(bitPattern: UInt8(a)))
                    dy = Double(Int8(bitPattern: UInt8(b)))
                }
            }
            var xx = 1.0, xy = 0.0, yx = 0.0, yy = 1.0
            if flags & 8 != 0 {  // simple scale
                guard let s = f2dot14(o) else { return nil }
                o += 2
                xx = s; yy = s
            } else if flags & 0x40 != 0 {  // x & y scale
                guard let sx = f2dot14(o), let sy = f2dot14(o + 2) else { return nil }
                o += 4
                xx = sx; yy = sy
            } else if flags & 0x80 != 0 {  // 2x2
                guard let a = f2dot14(o), let b = f2dot14(o + 2),
                      let c = f2dot14(o + 4), let d = f2dot14(o + 6) else { return nil }
                o += 8
                xx = a; xy = b; yx = c; yy = d
            }
            if flags & 2 != 0 {  // ARGS_ARE_XY_VALUES only (point matching unsupported)
                comps.append(Component(glyph: gi, dx: dx, dy: dy, xx: xx, xy: xy, yx: yx, yy: yy))
            }
            if flags & 0x20 == 0 { break }
        }
        // gvar deltas for composite: one "point" per component (offset deltas).
        var compPts = comps.map { Point(x: $0.dx, y: $0.dy, onCurve: true) }
        if let deltas = gvarDeltas(glyph: glyph, coords: coords, pointCount: comps.count,
                                   ends: nil, origPoints: compPts) {
            for i in 0..<comps.count {
                compPts[i].x += deltas[i].0
                compPts[i].y += deltas[i].1
            }
        }
        var allPts: [Point] = []
        var allEnds: [Int] = []
        for (i, c) in comps.enumerated() {
            guard let (pts, ends) = instancedPoints(glyph: c.glyph, coords: coords,
                                                    depth: depth + 1) else { continue }
            let base = allPts.count
            for p in pts {
                // TrueType composite transform [a b c d]: x' = a*x + c*y, y' = b*x + d*y
                let tx = c.xx * p.x + c.yx * p.y + compPts[i].x
                let ty = c.xy * p.x + c.yy * p.y + compPts[i].y
                allPts.append(Point(x: tx, y: ty, onCurve: p.onCurve))
            }
            for e in ends { allEnds.append(base + e) }
        }
        return (allPts, allEnds)
    }

    // MARK: - gvar

    private struct GvarHeader {
        var axisCount = 0
        var sharedTupleCount = 0
        var sharedTuplesOffset = 0
        var glyphCount = 0
        var longOffsets = false
        var dataArrayOffset = 0
    }
    private var gvarHeader: GvarHeader?

    private func loadGvarHeader() -> GvarHeader? {
        if let h = gvarHeader { return h }
        guard let axisCount = u16(gvarOff + 4),
              let stc = u16(gvarOff + 6),
              let sto = u32(gvarOff + 8),
              let gc = u16(gvarOff + 12),
              let flags = u16(gvarOff + 14),
              let dao = u32(gvarOff + 16) else { return nil }
        let h = GvarHeader(axisCount: axisCount, sharedTupleCount: stc,
                           sharedTuplesOffset: gvarOff + sto, glyphCount: gc,
                           longOffsets: flags & 1 != 0, dataArrayOffset: gvarOff + dao)
        gvarHeader = h
        return h
    }

    /// Accumulated (dx, dy) per outline point for `glyph` at `coords`.
    /// `ends` nil → composite (no IUP). Returns nil when no variation data.
    private func gvarDeltas(glyph: Int, coords: [Double], pointCount: Int, ends: [Int]?,
                            origPoints: [Point]) -> [(Double, Double)]? {
        guard let h = loadGvarHeader(), glyph < h.glyphCount,
              h.axisCount == axes.count else { return nil }
        let idxOff = gvarOff + 20
        var dataStart = 0, dataEnd = 0
        if h.longOffsets {
            guard let a = u32(idxOff + glyph * 4), let b = u32(idxOff + glyph * 4 + 4) else { return nil }
            dataStart = a; dataEnd = b
        } else {
            guard let a = u16(idxOff + glyph * 2), let b = u16(idxOff + glyph * 2 + 2) else { return nil }
            dataStart = a * 2; dataEnd = b * 2
        }
        guard dataEnd > dataStart else { return nil }
        let gv = h.dataArrayOffset + dataStart

        guard let tvcRaw = u16(gv), let dataOff = u16(gv + 2) else { return nil }
        let sharedPoints = tvcRaw & 0x8000 != 0
        let tupleCount = tvcRaw & 0x0FFF
        var serial = gv + dataOff

        let totalPoints = pointCount + 4  // incl. phantom points

        var sharedPointNumbers: [Int]? = nil
        if sharedPoints {
            guard let (nums, next) = packedPoints(at: serial, totalPoints: totalPoints) else { return nil }
            sharedPointNumbers = nums
            serial = next
        }

        var deltas = [(Double, Double)](repeating: (0, 0), count: pointCount)
        var header = gv + 4
        for _ in 0..<tupleCount {
            guard let size = u16(header), let tupleIndex = u16(header + 2) else { return nil }
            var ho = header + 4
            var peak: [Double] = []
            if tupleIndex & 0x8000 != 0 {  // embedded peak
                for a in 0..<h.axisCount {
                    guard let v = f2dot14(ho + a * 2) else { return nil }
                    peak.append(v)
                }
                ho += h.axisCount * 2
            } else {
                let idx = tupleIndex & 0x0FFF
                guard idx < h.sharedTupleCount else { return nil }
                let so = h.sharedTuplesOffset + idx * h.axisCount * 2
                for a in 0..<h.axisCount {
                    guard let v = f2dot14(so + a * 2) else { return nil }
                    peak.append(v)
                }
            }
            var start: [Double] = [], endT: [Double] = []
            if tupleIndex & 0x4000 != 0 {  // intermediate
                for a in 0..<h.axisCount {
                    guard let v = f2dot14(ho + a * 2) else { return nil }
                    start.append(v)
                }
                ho += h.axisCount * 2
                for a in 0..<h.axisCount {
                    guard let v = f2dot14(ho + a * 2) else { return nil }
                    endT.append(v)
                }
                ho += h.axisCount * 2
            }
            let nextHeader = ho
            let dataAt = serial
            serial += size

            // scalar
            var scalar = 1.0
            for a in 0..<h.axisCount {
                let p = peak[a]
                if p == 0 { continue }
                let v = coords[a]
                if v == p { continue }
                if tupleIndex & 0x4000 != 0 {
                    let s = start[a], e = endT[a]
                    if s > p || p > e { continue }
                    if s < 0, e > 0, p != 0 { continue }
                    if v < s || v > e { scalar = 0; break }
                    if v < p {
                        if p != s { scalar *= (v - s) / (p - s) }
                    } else if v > p {
                        if p != e { scalar *= (e - v) / (e - p) }
                    }
                } else {
                    if v == 0 || v < Swift.min(0, p) || v > Swift.max(0, p) { scalar = 0; break }
                    scalar *= v / p
                }
            }
            header = nextHeader
            if scalar == 0 { continue }

            // deltas for this tuple
            var o = dataAt
            var pointNumbers: [Int]
            if tupleIndex & 0x2000 != 0 {  // private point numbers
                guard let (nums, next) = packedPoints(at: o, totalPoints: totalPoints) else { return nil }
                pointNumbers = nums
                o = next
            } else if let sp = sharedPointNumbers {
                pointNumbers = sp
            } else {
                pointNumbers = Array(0..<totalPoints)
            }
            let n = pointNumbers.isEmpty ? totalPoints : pointNumbers.count
            let refs = pointNumbers.isEmpty ? Array(0..<totalPoints) : pointNumbers
            guard let (dxs, o2) = packedDeltas(at: o, count: n) else { return nil }
            guard let (dys, _) = packedDeltas(at: o2, count: n) else { return nil }

            if refs.count == totalPoints {
                // all points referenced: direct apply
                for (k, pn) in refs.enumerated() where pn < pointCount {
                    deltas[pn].0 += scalar * dxs[k]
                    deltas[pn].1 += scalar * dys[k]
                }
            } else {
                // sparse: apply + IUP for unreferenced (simple glyphs only)
                var dmap = [Int: (Double, Double)]()
                dmap.reserveCapacity(refs.count)
                for (k, pn) in refs.enumerated() { dmap[pn] = (dxs[k], dys[k]) }
                if let ends {
                    let interp = iup(dmap: dmap, ends: ends, points: origPoints)
                    for i in 0..<pointCount {
                        deltas[i].0 += scalar * interp[i].0
                        deltas[i].1 += scalar * interp[i].1
                    }
                } else {
                    for i in 0..<pointCount {
                        if let d = dmap[i] {
                            deltas[i].0 += scalar * d.0
                            deltas[i].1 += scalar * d.1
                        }
                    }
                }
            }
        }
        return deltas
    }

    private func packedPoints(at start: Int, totalPoints: Int) -> ([Int], Int)? {
        var o = start
        guard let b0 = u8(o) else { return nil }
        o += 1
        var count = b0
        if b0 == 0 { return ([], o) }  // all points
        if b0 & 0x80 != 0 {
            guard let b1 = u8(o) else { return nil }
            o += 1
            count = (b0 & 0x7F) << 8 | b1
        }
        var nums: [Int] = []
        nums.reserveCapacity(count)
        var acc = 0
        while nums.count < count {
            guard let control = u8(o) else { return nil }
            o += 1
            let runCount = (control & 0x7F) + 1
            let words = control & 0x80 != 0
            for _ in 0..<runCount {
                if nums.count >= count { break }
                if words {
                    guard let v = u16(o) else { return nil }
                    o += 2
                    acc += v
                } else {
                    guard let v = u8(o) else { return nil }
                    o += 1
                    acc += v
                }
                nums.append(acc)
            }
        }
        return (nums, o)
    }

    private func packedDeltas(at start: Int, count: Int) -> ([Double], Int)? {
        var o = start
        var out: [Double] = []
        out.reserveCapacity(count)
        while out.count < count {
            guard let control = u8(o) else { return nil }
            o += 1
            let runCount = (control & 0x3F) + 1
            if control & 0x80 != 0 {  // zeros
                for _ in 0..<runCount where out.count < count { out.append(0) }
            } else if control & 0x40 != 0 {  // words
                for _ in 0..<runCount where out.count < count {
                    guard let v = i16(o) else { return nil }
                    o += 2
                    out.append(Double(v))
                }
            } else {
                for _ in 0..<runCount where out.count < count {
                    guard let v = u8(o) else { return nil }
                    o += 1
                    out.append(Double(Int8(bitPattern: UInt8(v))))
                }
            }
        }
        return (out, o)
    }

    /// Interpolate Untouched Points, per contour, x and y independently.
    private func iup(dmap: [Int: (Double, Double)], ends: [Int], points: [Point])
        -> [(Double, Double)] {
        var out = [(Double, Double)](repeating: (0, 0), count: points.count)
        var contourStart = 0
        for e in ends {
            let contourEnd = e
            guard contourEnd >= contourStart, contourEnd < points.count else { break }
            let idxs = Array(contourStart...contourEnd)
            let refs = idxs.filter { dmap[$0] != nil }
            if refs.isEmpty {
                contourStart = contourEnd + 1
                continue
            }
            if refs.count == idxs.count {
                for i in idxs { out[i] = dmap[i]! }
                contourStart = contourEnd + 1
                continue
            }
            if refs.count == 1 {
                let d = dmap[refs[0]]!
                for i in idxs { out[i] = d }
                contourStart = contourEnd + 1
                continue
            }
            let n = idxs.count
            for (k, i) in idxs.enumerated() {
                if let d = dmap[i] {
                    out[i] = d
                    continue
                }
                // nearest referenced neighbors in cyclic order
                var pk = k, nk = k
                var prevRef = -1, nextRef = -1
                for _ in 0..<n {
                    pk = (pk + n - 1) % n
                    if dmap[idxs[pk]] != nil { prevRef = idxs[pk]; break }
                }
                for _ in 0..<n {
                    nk = (nk + 1) % n
                    if dmap[idxs[nk]] != nil { nextRef = idxs[nk]; break }
                }
                guard prevRef >= 0, nextRef >= 0 else { continue }
                let d1 = dmap[prevRef]!, d2 = dmap[nextRef]!
                out[i] = (iupComponent(points[i].x, points[prevRef].x, points[nextRef].x, d1.0, d2.0),
                          iupComponent(points[i].y, points[prevRef].y, points[nextRef].y, d1.1, d2.1))
            }
            contourStart = contourEnd + 1
        }
        return out
    }

    private func iupComponent(_ c: Double, _ c1: Double, _ c2: Double,
                              _ d1: Double, _ d2: Double) -> Double {
        if c1 == c2 { return d1 == d2 ? d1 : 0 }
        var lo = c1, hi = c2, dlo = d1, dhi = d2
        if lo > hi {
            swap(&lo, &hi)
            swap(&dlo, &dhi)
        }
        if c <= lo { return dlo }
        if c >= hi { return dhi }
        return dlo + (dhi - dlo) * (c - lo) / (hi - lo)
    }

    // MARK: - stbtt vertices

    /// Instanced outline as stbtt vertices (nil = failed; empty = blank glyph).
    func instancedVertices(glyph: Int, coords: [Double]) -> [stbtt_vertex]? {
        guard let (pts, ends) = instancedPoints(glyph: glyph, coords: coords) else { return nil }
        if pts.isEmpty { return [] }
        var verts: [stbtt_vertex] = []
        verts.reserveCapacity(pts.count + ends.count * 2)
        func v16(_ d: Double) -> Int16 {
            let r = d.rounded()
            if r >= 32767 { return 32767 }
            if r <= -32768 { return -32768 }
            return Int16(r)
        }
        func emit(_ type: UInt8, _ x: Double, _ y: Double, _ cx: Double, _ cy: Double) {
            var v = stbtt_vertex()
            v.type = type
            v.x = v16(x); v.y = v16(y)
            v.cx = v16(cx); v.cy = v16(cy)
            verts.append(v)
        }
        let VMOVE: UInt8 = 1, VLINE: UInt8 = 2, VCURVE: UInt8 = 3
        var start = 0
        for e in ends {
            guard e >= start, e < pts.count else { break }
            let contour = Array(pts[start...e])
            start = e + 1
            guard contour.count >= 2 else { continue }
            // starting point
            var startPt: Point
            var order = contour
            if contour[0].onCurve {
                startPt = contour[0]
                order = Array(contour.dropFirst())
            } else if contour[contour.count - 1].onCurve {
                startPt = contour[contour.count - 1]
                order = Array(contour.dropLast())
            } else {
                startPt = Point(x: (contour[0].x + contour[contour.count - 1].x) / 2,
                                y: (contour[0].y + contour[contour.count - 1].y) / 2,
                                onCurve: true)
            }
            emit(VMOVE, startPt.x, startPt.y, 0, 0)
            var pendingOff: Point? = nil
            for p in order {
                if p.onCurve {
                    if let off = pendingOff {
                        emit(VCURVE, p.x, p.y, off.x, off.y)
                        pendingOff = nil
                    } else {
                        emit(VLINE, p.x, p.y, 0, 0)
                    }
                } else {
                    if let off = pendingOff {
                        let mx = (off.x + p.x) / 2, my = (off.y + p.y) / 2
                        emit(VCURVE, mx, my, off.x, off.y)
                    }
                    pendingOff = p
                }
            }
            if let off = pendingOff {
                emit(VCURVE, startPt.x, startPt.y, off.x, off.y)
            } else {
                emit(VLINE, startPt.x, startPt.y, 0, 0)
            }
        }
        return verts
    }
}
