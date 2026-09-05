import CoreFoundation
import Foundation

// SFUI metrics harvested from uikit/Sources/OpenUIKit/Resources/font_metrics_ios.json
// (Tools/oracle2/fontprobe, iOS 26.1). Advances are the iOS cut (.SFUI), already
// tighter than Catalyst .SFNS by T(size)*size/2048. Vertical metrics are the
// SFUI build: 17 pt regular ascender 16.1865234375, descender -4.1005859375.
// CTLine width of "Hello" at 17 pt is the sum of those five advances
// (38.814453125), matching FontEngine.measure / UILabel on the iOS cut.
// Glyph IDs are Unicode BMP code units because the harvest is per-character,
// not Apple cmap indexes (macOS .SFNS H was glyph 112; iOS cmap unobserved).

struct _SFUIFace {
    var pointSize: CGFloat
    var ascender: CGFloat
    var descender: CGFloat
    var leading: CGFloat
    var capHeight: CGFloat
    var xHeight: CGFloat
    var lineHeight: CGFloat
    var advances: [CGFloat]
}

enum _SFUITable {
    static let unitsPerEm: UInt32 = 2048
    static let familyName = ".AppleSystemUIFont"
    static let regularPostScript = ".SFUI-Regular"
    static let boldPostScript = ".SFUI-Bold"
    static let regularFullName = "System Font Regular"
    static let boldFullName = "System Font Bold"
    static let styleRegular = "Regular"
    static let styleBold = "Bold"

    static let regular: [_SFUIFace] = [
        _SFUIFace(
            pointSize: 12.0,
            ascender: 11.42578125,
            descender: -2.89453125,
            leading: 0,
            capHeight: 8.455078125,
            xHeight: 6.31640625,
            lineHeight: 14.3203125,
            advances: [
        3.375, 3.732421875, 5.73046875, 7.55859375, 7.55859375, 11.103515625, 8.537109375, 3.5625,
        4.58203125, 4.58203125, 5.66015625, 7.55859375, 3.5625, 5.66015625, 3.5625, 3.65625,
        7.55859375, 5.56640625, 7.2421875, 7.5234375, 7.72265625, 7.41796875, 7.640625, 6.83203125,
        7.6640625, 7.640625, 3.5625, 3.5625, 7.55859375, 7.55859375, 7.55859375, 6.15234375,
        11.015625, 8.0859375, 7.88671875, 8.58984375, 8.71875, 7.1484375, 6.8671875, 8.958984375,
        8.90625, 3.2109375, 6.45703125, 7.904296875, 6.814453125, 10.48828125, 8.90625, 9.2578125,
        7.623046875, 9.2578125, 7.83984375, 7.646484375, 7.60546875, 8.84765625, 8.0859375,
        11.61328125, 8.14453125, 7.86328125, 7.939453125, 4.58203125, 3.65625, 4.58203125,
        7.55859375, 7.001953125, 6.0, 6.62109375, 7.37109375, 6.71484375, 7.37109375, 6.85546875,
        4.341796875, 7.3125, 7.060546875, 2.96484375, 2.958984375, 6.515625, 3.03515625,
        10.44140625, 7.001953125, 7.08984375, 7.32421875, 7.3125, 4.5703125, 6.28125, 4.359375,
        7.001953125, 6.50390625, 9.29296875, 6.29296875, 6.515625, 6.46875, 4.58203125, 3.10546875,
        4.58203125, 7.55859375
            ]
        ),
        _SFUIFace(
            pointSize: 13.0,
            ascender: 12.3779296875,
            descender: -3.1357421875,
            leading: 0,
            capHeight: 9.15966796875,
            xHeight: 6.8427734375,
            lineHeight: 15.513671875,
            advances: [
        3.580078125, 3.96728515625, 6.1318359375, 8.1123046875, 8.1123046875, 11.95263671875,
        9.17236328125, 3.783203125, 4.8876953125, 4.8876953125, 6.0556640625, 8.1123046875,
        3.783203125, 6.0556640625, 3.783203125, 3.884765625, 8.1123046875, 5.9541015625,
        7.76953125, 8.07421875, 8.2900390625, 7.9599609375, 8.201171875, 7.3251953125, 8.2265625,
        8.201171875, 3.783203125, 3.783203125, 8.1123046875, 8.1123046875, 8.1123046875,
        6.5888671875, 11.857421875, 8.68359375, 8.4677734375, 9.2294921875, 9.369140625,
        7.66796875, 7.36328125, 9.62939453125, 9.572265625, 3.40234375, 6.9189453125,
        8.48681640625, 7.30615234375, 11.2861328125, 9.572265625, 9.953125, 8.18212890625,
        9.953125, 8.4169921875, 8.20751953125, 8.1630859375, 9.5087890625, 8.68359375,
        12.5048828125, 8.7470703125, 8.4423828125, 8.52490234375, 4.8876953125, 3.884765625,
        4.8876953125, 8.1123046875, 7.50927734375, 6.423828125, 7.0966796875, 7.9091796875,
        7.1982421875, 7.9091796875, 7.3505859375, 4.62744140625, 7.845703125, 7.57275390625,
        3.1357421875, 3.12939453125, 6.982421875, 3.2119140625, 11.2353515625, 7.50927734375,
        7.6044921875, 7.8583984375, 7.845703125, 4.875, 6.728515625, 4.646484375, 7.50927734375,
        6.9697265625, 9.9912109375, 6.7412109375, 6.982421875, 6.931640625, 4.8876953125,
        3.2880859375, 4.8876953125, 8.1123046875
            ]
        ),
        _SFUIFace(
            pointSize: 17.0,
            ascender: 16.1865234375,
            descender: -4.1005859375,
            leading: 0,
            capHeight: 11.97802734375,
            xHeight: 8.9482421875,
            lineHeight: 20.287109375,
            advances: [
        4.349609375, 4.85595703125, 7.6865234375, 10.2763671875, 10.2763671875, 15.29833984375,
        11.66259765625, 4.615234375, 6.0595703125, 6.0595703125, 7.5869140625, 10.2763671875,
        4.615234375, 7.5869140625, 4.615234375, 4.748046875, 10.2763671875, 7.4541015625, 9.828125,
        10.2265625, 10.5087890625, 10.0771484375, 10.392578125, 9.2470703125, 10.42578125,
        10.392578125, 4.615234375, 4.615234375, 10.2763671875, 10.2763671875, 10.2763671875,
        8.2841796875, 15.173828125, 11.0234375, 10.7412109375, 11.7373046875, 11.919921875,
        9.6953125, 9.296875, 12.26025390625, 12.185546875, 4.1171875, 8.7158203125, 10.76611328125,
        9.22216796875, 14.4267578125, 12.185546875, 12.68359375, 10.36767578125, 12.68359375,
        10.6748046875, 10.40087890625, 10.3427734375, 12.1025390625, 11.0234375, 16.0205078125,
        11.1064453125, 10.7080078125, 10.81591796875, 6.0595703125, 4.748046875, 6.0595703125,
        10.2763671875, 9.48779296875, 8.068359375, 8.9482421875, 10.0107421875, 9.0810546875,
        10.0107421875, 9.2802734375, 5.71923828125, 9.927734375, 9.57080078125, 3.7685546875,
        3.76025390625, 8.798828125, 3.8681640625, 14.3603515625, 9.48779296875, 9.6123046875,
        9.9443359375, 9.927734375, 6.04296875, 8.466796875, 5.744140625, 9.48779296875,
        8.7822265625, 12.7333984375, 8.4833984375, 8.798828125, 8.732421875, 6.0595703125,
        3.9677734375, 6.0595703125, 10.2763671875
            ]
        )
    ]

    static let bold17 =         _SFUIFace(
            pointSize: 17.0,
            ascender: 16.1865234375,
            descender: -4.1005859375,
            leading: 0,
            capHeight: 11.97802734375,
            xHeight: 9.13916015625,
            lineHeight: 20.287109375,
            advances: [
        3.951171875, 5.623779296875, 9.23876953125, 10.98193359375, 10.98193359375, 17.17431640625,
        12.222900390625, 5.478515625, 6.8564453125, 6.8564453125, 7.802734375, 10.98193359375,
        5.478515625, 7.802734375, 5.478515625, 5.25439453125, 11.2060546875, 8.267578125,
        10.50048828125, 10.9404296875, 11.24755859375, 10.844970703125, 11.189453125, 9.8447265625,
        11.36376953125, 11.189453125, 5.478515625, 5.478515625, 10.98193359375, 10.98193359375,
        10.98193359375, 9.03955078125, 15.327392578125, 12.01953125, 11.35546875, 12.1689453125,
        12.272705078125, 10.139404296875, 9.724365234375, 12.49267578125, 12.8828125, 4.98046875,
        9.78662109375, 11.625244140625, 9.6787109375, 14.978759765625, 12.62548828125,
        12.936767578125, 11.019287109375, 12.936767578125, 11.3720703125, 11.044189453125,
        10.791015625, 12.49267578125, 11.82861328125, 16.72607421875, 11.9697265625, 11.6044921875,
        11.052490234375, 6.8564453125, 5.25439453125, 6.8564453125, 10.98193359375,
        10.230712890625, 8.068359375, 9.591552734375, 10.6416015625, 9.55419921875, 10.6416015625,
        9.782470703125, 6.503662109375, 10.537841796875, 10.313720703125, 4.44921875,
        4.445068359375, 9.790771484375, 4.58203125, 15.41455078125, 10.230712890625,
        10.10205078125, 10.56689453125, 10.5751953125, 6.96435546875, 9.197265625, 6.58251953125,
        10.230712890625, 9.475341796875, 13.97021484375, 9.43798828125, 9.72021484375, 9.197265625,
        6.8564453125, 4.65673828125, 6.8564453125, 10.98193359375
            ]
        )

    static func isSystemName(_ name: String) -> Bool {
        if name.isEmpty { return false }
        if name == familyName { return true }
        if name == regularPostScript || name == boldPostScript { return true }
        if name == regularFullName || name == boldFullName { return true }
        if name == ".SFNS-Regular" || name == ".SFNS-Bold" { return true }
        if name == "System Font" { return true }
        return false
    }

    static func isBoldName(_ name: String) -> Bool {
        name == boldPostScript || name == boldFullName || name == ".SFNS-Bold"
    }

    static func face(size: CGFloat, bold: Bool) -> _SFUIFace {
        if bold {
            return scaled(bold17, to: size)
        }
        if let exact = regular.first(where: { abs($0.pointSize - size) < 1e-9 }) {
            return exact
        }
        let list = regular
        let lo = list.last(where: { $0.pointSize <= size })
        let hi = list.first(where: { $0.pointSize >= size })
        if let lo, let hi, lo.pointSize != hi.pointSize {
            let t = (size - lo.pointSize) / (hi.pointSize - lo.pointSize)
            return lerp(lo, hi, t, size: size)
        }
        let nearest = list.min(by: { abs($0.pointSize - size) < abs($1.pointSize - size) }) ?? list[list.count - 1]
        return scaled(nearest, to: size)
    }

    static func scaled(_ face: _SFUIFace, to size: CGFloat) -> _SFUIFace {
        guard face.pointSize > 0, abs(face.pointSize - size) > 1e-9 else { return face }
        let f = size / face.pointSize
        return _SFUIFace(
            pointSize: size,
            ascender: face.ascender * f,
            descender: face.descender * f,
            leading: face.leading * f,
            capHeight: face.capHeight * f,
            xHeight: face.xHeight * f,
            lineHeight: face.lineHeight * f,
            advances: face.advances.map { $0 * f }
        )
    }

    static func lerp(_ a: _SFUIFace, _ b: _SFUIFace, _ t: CGFloat, size: CGFloat) -> _SFUIFace {
        func mix(_ x: CGFloat, _ y: CGFloat) -> CGFloat { x + (y - x) * t }
        var adv: [CGFloat] = []
        adv.reserveCapacity(95)
        for i in 0..<95 {
            adv.append(mix(a.advances[i], b.advances[i]))
        }
        return _SFUIFace(
            pointSize: size,
            ascender: mix(a.ascender, b.ascender),
            descender: mix(a.descender, b.descender),
            leading: mix(a.leading, b.leading),
            capHeight: mix(a.capHeight, b.capHeight),
            xHeight: mix(a.xHeight, b.xHeight),
            lineHeight: mix(a.lineHeight, b.lineHeight),
            advances: adv
        )
    }

    static func advance(_ face: _SFUIFace, scalar: UInt32) -> CGFloat {
        if scalar >= 32 && scalar <= 126 {
            return face.advances[Int(scalar) - 32]
        }
        // Unharvested scalar: space-like fallback is dishonest; use the
        // 'x' advance as a named stand-in for unknown widths (xHeight-adjacent).
        return face.advances[120 - 32]
    }
}
