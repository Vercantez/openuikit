// UIImage system symbols — bounded, portable procedural subset.
//
// OpenUIKit does not ship Apple's SF Symbols font or copy its outlines.  This
// file supplies project-authored vector fallbacks for the exact six semantic
// names used by the unchanged Reminder example app.  Unknown names fail just
// as a missing native system symbol does; there is deliberately no textual,
// font, resource, or "close enough" lookup fallback.

#if canImport(Foundation)
import class Foundation.NSCoder
import protocol Foundation.NSCopying
import class Foundation.NSObject
import protocol Foundation.NSSecureCoding
import struct Foundation.NSZone
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
#endif

#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif

// UIImageConfiguration and UIImageSymbolConfiguration are Objective-C classes
// renamed by UIKit.apinotes to UIImage.Configuration and
// UIImage.SymbolConfiguration.  Pure Swift cannot declare a nested class and
// subclass it outside UIImage's body, so the implementation classes live at
// module scope and the public aliases below preserve the spelling app source
// sees.  The Foundation-hidden guest build intentionally omits Foundation's
// object/copy/archive protocols; the API used by the guest remains available.

#if canImport(Foundation)
@available(iOS 13.0, *)
open class _UIImageConfiguration: NSObject, @unchecked Sendable {
    @available(*, unavailable, message: "UIImage.Configuration cannot be created directly")
    public override convenience init() {
        self.init(coder: NSCoder())!
    }

    public required init?(coder: NSCoder) {
        _ = coder
        super.init()
    }

    open class var supportsSecureCoding: Bool { true }

    open func encode(with coder: NSCoder) {
        _ = coder
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return self
    }
}

@available(iOS 13.0, *)
extension _UIImageConfiguration: NSCopying, NSSecureCoding {}
#else
@available(iOS 13.0, *)
open class _UIImageConfiguration: @unchecked Sendable {
    internal init(_systemImageConfiguration: ()) {}
}
#endif

@available(iOS 13.0, *)
extension UIImage {
    /// UIKit's image-configuration base class.  The portable subset only has
    /// one concrete configuration: ``SymbolConfiguration``.
    public typealias Configuration = _UIImageConfiguration

    /// Raw values match UIImageSymbolWeight in the iOS 26.1 SDK.
    public enum SymbolWeight: Int, Sendable {
        case unspecified = 0
        case ultraLight = 1
        case thin = 2
        case light = 3
        case regular = 4
        case medium = 5
        case semibold = 6
        case bold = 7
        case heavy = 8
        case black = 9
    }

    /// Raw values match UIImageSymbolScale in the iOS 26.1 SDK
    /// (UIImageSymbolConfiguration.h: Unspecified=0, Small=1, Medium=2, Large=3).
    public enum SymbolScale: Int, Sendable {
        case unspecified = 0
        case small = 1
        case medium = 2
        case large = 3
    }
}

#if canImport(Foundation)
/// Internal initializer carrier. A pure-Swift subclass that declares the
/// required NSCoder initializer no longer inherits any other designated
/// initializer, so a second designated storage initializer would also prevent
/// it from inheriting SymbolConfiguration(pointSize:weight:). UIKit imports
/// that entry point as a class-factory convenience initializer. Delegating the
/// convenience initializer through the one required designated coder path
/// preserves downstream source inheritance and dynamic type. Unlike the ObjC
/// factory, however, pure Swift must invoke an external subclass's coder init;
/// the documented bounded contract requires that initializer to accept this
/// keyed seed and return non-nil.
@available(iOS 13.0, *)
private final class _UIImageSymbolConfigurationSeedCoder: NSCoder {
    let pointSize: Double
    let weight: Int
    let scale: Int

    init(pointSize: CGFloat, weight: UIImage.SymbolWeight,
         scale: UIImage.SymbolScale = .unspecified) {
        self.pointSize = Double(pointSize)
        self.weight = weight.rawValue
        self.scale = scale.rawValue
        super.init()
    }

    override var allowsKeyedCoding: Bool { true }

    override func containsValue(forKey key: String) -> Bool {
        key == "OpenUIKit.pointSize" || key == "OpenUIKit.weight"
            || key == "OpenUIKit.scale"
    }

    override func decodeDouble(forKey key: String) -> Double {
        key == "OpenUIKit.pointSize" ? pointSize : 0
    }

    override func decodeInteger(forKey key: String) -> Int {
        if key == "OpenUIKit.weight" { return weight }
        if key == "OpenUIKit.scale" { return scale }
        return 0
    }

    override func decodeBool(forKey key: String) -> Bool {
        _ = key
        return false
    }

    override func decodeFloat(forKey key: String) -> Float {
        _ = key
        return 0
    }

    override func decodeInt32(forKey key: String) -> Int32 {
        _ = key
        return 0
    }

    override func decodeInt64(forKey key: String) -> Int64 {
        _ = key
        return 0
    }

    override func decodeObject(forKey key: String) -> Any? {
        _ = key
        return nil
    }
}

@available(iOS 13.0, *)
open class _UIImageSymbolConfiguration: _UIImageConfiguration, @unchecked Sendable {
    let _pointSize: CGFloat
    let _weight: UIImage.SymbolWeight
    let _scale: UIImage.SymbolScale

    public convenience init(pointSize: CGFloat,
                            weight: UIImage.SymbolWeight) {
        self.init(coder: _UIImageSymbolConfigurationSeedCoder(
            pointSize: pointSize,
            weight: weight
        ))!
    }

    public convenience init(pointSize: CGFloat,
                            weight: UIImage.SymbolWeight,
                            scale: UIImage.SymbolScale) {
        self.init(coder: _UIImageSymbolConfigurationSeedCoder(
            pointSize: pointSize,
            weight: weight,
            scale: scale
        ))!
    }

    open override class var supportsSecureCoding: Bool { true }

    open override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        // NSCoder is the sole required designated path, so constructing
        // through the dynamic metatype keeps copy distinct and preserves an
        // external subclass. See the class note for the bounded coder-routing
        // divergence from Objective-C's class factory.
        return type(of: self).init(coder: _UIImageSymbolConfigurationSeedCoder(
            pointSize: _pointSize,
            weight: _weight,
            scale: _scale
        ))!
    }

    public required init?(coder: NSCoder) {
        let pointSize = CGFloat(coder.decodeDouble(forKey: "OpenUIKit.pointSize"))
        let rawWeight = coder.decodeInteger(forKey: "OpenUIKit.weight")
        guard let weight = UIImage.SymbolWeight(rawValue: rawWeight) else {
            return nil
        }
        let rawScale = coder.decodeInteger(forKey: "OpenUIKit.scale")
        let scale = UIImage.SymbolScale(rawValue: rawScale) ?? .unspecified
        _pointSize = pointSize
        _weight = weight
        _scale = scale
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        coder.encode(Double(_pointSize), forKey: "OpenUIKit.pointSize")
        coder.encode(_weight.rawValue, forKey: "OpenUIKit.weight")
        coder.encode(_scale.rawValue, forKey: "OpenUIKit.scale")
        super.encode(with: coder)
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? _UIImageSymbolConfiguration else {
            return false
        }
        return _pointSize == other._pointSize
            && _weight == other._weight
            && _scale == other._scale
    }

    open override var hash: Int {
        var hasher = Hasher()
        hasher.combine(_pointSize)
        hasher.combine(_weight.rawValue)
        hasher.combine(_scale.rawValue)
        return hasher.finalize()
    }
}
#else
@available(iOS 13.0, *)
open class _UIImageSymbolConfiguration: _UIImageConfiguration, @unchecked Sendable {
    let _pointSize: CGFloat
    let _weight: UIImage.SymbolWeight
    let _scale: UIImage.SymbolScale

    internal init(_systemPointSize pointSize: CGFloat,
                  weight: UIImage.SymbolWeight,
                  scale: UIImage.SymbolScale) {
        _pointSize = pointSize
        _weight = weight
        _scale = scale
        super.init(_systemImageConfiguration: ())
    }

    public convenience init(pointSize: CGFloat,
                            weight: UIImage.SymbolWeight) {
        self.init(_systemPointSize: pointSize, weight: weight,
                  scale: .unspecified)
    }

    public convenience init(pointSize: CGFloat,
                            weight: UIImage.SymbolWeight,
                            scale: UIImage.SymbolScale) {
        self.init(_systemPointSize: pointSize, weight: weight, scale: scale)
    }
}
#endif

@available(iOS 13.0, *)
extension UIImage {
    public typealias SymbolConfiguration = _UIImageSymbolConfiguration

    /// Project-authored procedural image for one of OpenUIKit's supported
    /// semantic symbol names.  Matching is exact and case-sensitive.
    public convenience init?(systemName name: String) {
        guard let rendered = _UISystemImageRenderer.render(name: name,
                                                            configuration: nil)
        else { return nil }
        self.init(bitmap: rendered.bitmap, scale: rendered.scale)
        _markAsSystemSymbol(name)
    }

    /// Configured system image.  The Reminder path exercises a 56-point,
    /// regular-weight plus.circle.fill; other finite, bounded point sizes and
    /// declared weights use the same deterministic procedural geometry.
    public convenience init?(systemName name: String,
                             withConfiguration configuration: UIImage.Configuration?) {
        guard let rendered = _UISystemImageRenderer.render(
            name: name,
            configuration: configuration
        ) else { return nil }
        self.init(bitmap: rendered.bitmap, scale: rendered.scale)
        _markAsSystemSymbol(name)
    }
}

@available(iOS 13.0, *)
private enum _UISystemImageRenderer {
    struct Metrics {
        let oneX: CGSize
        let twoX: CGSize
    }

    // Logical sizes are iOS 26.1 oracle observations.  The half-point 2x
    // values are load-bearing: UIImage.size is pixels / scale.
    static let metrics: [String: Metrics] = [
        "calendar": Metrics(oneX: CGSize(width: 21, height: 18),
                            twoX: CGSize(width: 21, height: 17.5)),
        "clock": Metrics(oneX: CGSize(width: 19, height: 19),
                         twoX: CGSize(width: 20, height: 19)),
        "clock.fill": Metrics(oneX: CGSize(width: 19, height: 19),
                              twoX: CGSize(width: 20, height: 19)),
        "multiply": Metrics(oneX: CGSize(width: 16, height: 14),
                            twoX: CGSize(width: 15.5, height: 13.5)),
        "plus.circle.fill": Metrics(oneX: CGSize(width: 19, height: 19),
                                    twoX: CGSize(width: 20, height: 19)),
        "circlebadge": Metrics(oneX: CGSize(width: 15, height: 15),
                               twoX: CGSize(width: 16, height: 15)),
        "checkmark.circle.fill": Metrics(oneX: CGSize(width: 19, height: 19),
                                         twoX: CGSize(width: 20, height: 19)),
    ]

    static let maximumScale: CGFloat = 4
    static let maximumPointSize: CGFloat = 512
    static let maximumDimension = 4096
    static let maximumPixels = 4_000_000

    static func render(name: String,
                       configuration: UIImage.Configuration?) -> UIImage? {
        let scale = OpenUIKitRuntime.imageScreenScale
        guard scale.isFinite, scale > 0, scale <= maximumScale else { return nil }

        let symbolConfiguration: UIImage.SymbolConfiguration?
        if let configuration {
            guard let concrete = configuration as? UIImage.SymbolConfiguration else {
                return nil
            }
            guard concrete._pointSize.isFinite,
                  concrete._pointSize > 0,
                  concrete._pointSize <= maximumPointSize else { return nil }
            symbolConfiguration = concrete
        } else {
            symbolConfiguration = nil
        }

        // MEASURED symbolinkprobe, SE 2x / iPhone 16 3x / iOS 26.1:
        // harvested label-opaque coverage (Resources/symbol_ink_ios.json
        // / _3x) at the configurations real apps use (default
        // 17|regular|unspecified, tab bar 18|medium|large, bar-button
        // 17|medium|large). Procedural paths missed that ink (Tabs t1000
        // calendar blob 59 at [91.5, 597.5, 22.5, 21]). Catalyst keeps
        // the vectors below. A harvested name at a harvested
        // configuration whose key is missing fails loudly.
        if let stamped = SymbolInkTable.stampTemplate(
            name: name, configuration: symbolConfiguration, scale: scale
        ) {
            return stamped
        }

        guard let symbolMetrics = metrics[name] else { return nil }

        let logicalSize = configuredSize(
            for: name,
            metrics: symbolMetrics,
            configuration: symbolConfiguration,
            scale: scale
        )
        guard let pixelSize = _UIBitmapAllocation.checkedPixelSize(
            for: CGRect(origin: .zero, size: logicalSize),
            scale: scale,
            maximumDimension: CGFloat(maximumDimension),
            maximumPixels: maximumPixels
        ) else {
            return nil
        }

        let bitmap = Bitmap(width: pixelSize.width, height: pixelSize.height)
        let canvas = Canvas(bitmap: bitmap, scale: scale)
        draw(name: name, in: canvas,
             size: CGSize(width: CGFloat(pixelSize.width) / scale,
                          height: CGFloat(pixelSize.height) / scale),
             weight: symbolConfiguration?._weight ?? .regular)
        return UIImage(bitmap: bitmap, scale: scale)
    }

    static func configuredSize(for name: String, metrics: Metrics,
                               configuration: UIImage.SymbolConfiguration?,
                               scale: CGFloat) -> CGSize {
        guard let configuration else {
            // Native 1x and 2x rasterizations have slightly different
            // alignment bounds.  Use the measured 1x box only at 1x; other
            // finite scales use the retina alignment box deterministically.
            return scale == 1 ? metrics.oneX : metrics.twoX
        }

        if name == "plus.circle.fill", configuration._weight == .regular,
           configuration._pointSize == 56 {
            return CGSize(width: 66, height: 64)
        }

        // MEASURED Tabs probe, iPhone SE 2x / iOS 26.1: every tab-bar
        // UIImageView.preferredSymbolConfiguration dumps
        // "pointSize=18, weight=Medium, scale=Large". withConfiguration at
        // that triple: calendar 29×25 (46×42 px), clock / clock.fill /
        // plus.circle.fill 27.5×27.5 (47×47 px). The live selected
        // calendar view is `[33, 7.5, 29, 25]` in the 94×54 button.
        if configuration._pointSize == 18,
           configuration._weight == .medium,
           configuration._scale == .large {
            if name == "calendar" {
                return CGSize(width: 29, height: 25)
            }
            if name == "clock" || name == "clock.fill"
                || name == "plus.circle.fill" {
                return CGSize(width: 27.5, height: 27.5)
            }
        }

        let ratio = configuration._pointSize / 17
        return CGSize(width: metrics.twoX.width * ratio,
                      height: metrics.twoX.height * ratio)
    }

    static func draw(name: String, in canvas: Canvas, size: CGSize,
                     weight: UIImage.SymbolWeight) {
        let bounds = CGRect(origin: .zero, size: size)
        let minSide = Swift.min(size.width, size.height)
        let stroke = minSide * strokeFraction(for: weight)
        let black = CGColor.black

        switch name {
        case "calendar":
            // MEASURED Tabs probe calendar at 18pt medium large, SE 2x:
            // a filled header (~0.26 of the 42 px glyph) continuous with
            // the rounded-rect ring, then a cut-out page with three rows
            // of day-dots. The default outline stand-in (stroke + two
            // rings) did not match that ink. Same silhouette at every
            // size: fill the rounded body, even-odd cut the page below
            // the header, fill the dots into the hole.
            let body = bounds.insetBy(dx: size.width * 0.12,
                                      dy: size.height * 0.12)
            let radius = minSide * 0.12
            var silhouette = Path.roundedRect(body, cornerRadius: radius)
            let headerH = body.height * 0.26
            let ring = Swift.max(stroke, minSide * 0.08)
            let hole = CGRect(x: body.minX + ring,
                              y: body.minY + headerH,
                              width: body.width - 2 * ring,
                              height: Swift.max(0, body.height - headerH - ring))
            silhouette.elements.append(contentsOf: Path.rect(hole).elements)
            let cols = 5
            let rows = 3
            let insetX = hole.width * 0.12
            let insetY = hole.height * 0.14
            let dot = Swift.min(hole.width, hole.height) * 0.10
            let spanX = hole.width - 2 * insetX - dot
            let spanY = hole.height - 2 * insetY - dot
            var r = 0
            while r < rows {
                var c = 0
                let colsThisRow = r == 2 ? 3 : cols
                while c < colsThisRow {
                    let dx = colsThisRow == 1 ? 0
                        : spanX * CGFloat(c) / CGFloat(cols - 1)
                    let dy = spanY * CGFloat(r) / CGFloat(rows - 1)
                    let d = CGRect(x: hole.minX + insetX + dx,
                                   y: hole.minY + insetY + dy,
                                   width: dot, height: dot)
                    silhouette.elements.append(contentsOf:
                        Path.roundedRect(d, cornerRadius: dot / 2).elements)
                    c += 1
                }
                r += 1
            }
            canvas.fill(silhouette, color: black, evenOdd: true)

        case "clock":
            let circle = bounds.insetBy(dx: size.width * 0.10,
                                        dy: size.height * 0.08)
            canvas.stroke(ellipse(in: circle), color: black, lineWidth: stroke,
                          cap: .round, join: .round)
            let center = CGPoint(x: circle.midX, y: circle.midY)
            var hands = Path()
            hands.move(to: center)
            hands.addLine(to: CGPoint(x: center.x,
                                      y: circle.minY + circle.height * 0.25))
            hands.move(to: center)
            hands.addLine(to: CGPoint(x: circle.minX + circle.width * 0.70,
                                      y: circle.minY + circle.height * 0.61))
            canvas.stroke(hands, color: black, lineWidth: stroke,
                          cap: .round, join: .round)

        case "clock.fill":
            // MEASURED Tabs probe clock.fill at 18pt medium large, SE 2x:
            // 27.5×27.5 filled disc with cut-out hands (ink 1696 px vs
            // outline clock's 777). Selected tab items whose name has a
            // `.fill` sibling use it; calendar.fill does not exist.
            let circle = bounds.insetBy(dx: size.width * 0.10,
                                          dy: size.height * 0.08)
            var silhouette = ellipse(in: circle)
            let center = CGPoint(x: circle.midX, y: circle.midY)
            let t = stroke * 1.15
            appendThickSegment(
                to: &silhouette,
                from: center,
                to: CGPoint(x: center.x,
                             y: circle.minY + circle.height * 0.25),
                thickness: t)
            appendThickSegment(
                to: &silhouette,
                from: center,
                to: CGPoint(x: circle.minX + circle.width * 0.70,
                            y: circle.minY + circle.height * 0.61),
                thickness: t)
            canvas.fill(silhouette, color: black, evenOdd: true)

        case "multiply":
            let insetX = size.width * 0.20
            let insetY = size.height * 0.16
            var cross = Path()
            cross.move(to: CGPoint(x: insetX, y: insetY))
            cross.addLine(to: CGPoint(x: size.width - insetX,
                                      y: size.height - insetY))
            cross.move(to: CGPoint(x: size.width - insetX, y: insetY))
            cross.addLine(to: CGPoint(x: insetX, y: size.height - insetY))
            canvas.stroke(cross, color: black, lineWidth: stroke * 1.15,
                          cap: .round, join: .round)

        case "circlebadge":
            let circle = bounds.insetBy(dx: size.width * 0.12,
                                        dy: size.height * 0.10)
            canvas.stroke(ellipse(in: circle), color: black,
                          lineWidth: stroke * 0.90,
                          cap: .round, join: .round)

        case "plus.circle.fill":
            let circle = bounds.insetBy(dx: size.width * 0.06,
                                        dy: size.height * 0.03)
            var silhouette = ellipse(in: circle)
            appendPlusCutout(to: &silhouette, in: circle,
                             thickness: Swift.min(0.23,
                                                  0.12 * weightFactor(for: weight)))
            canvas.fill(silhouette, color: black, evenOdd: true)

        case "checkmark.circle.fill":
            let circle = bounds.insetBy(dx: size.width * 0.06,
                                        dy: size.height * 0.03)
            var silhouette = ellipse(in: circle)
            appendCheckCutout(to: &silhouette, in: circle,
                              thickness: Swift.min(0.075,
                                                   0.043 * weightFactor(for: weight)))
            canvas.fill(silhouette, color: black, evenOdd: true)

        default:
            break
        }
    }

    static func strokeFraction(for weight: UIImage.SymbolWeight) -> CGFloat {
        0.075 * weightFactor(for: weight)
    }

    static func weightFactor(for weight: UIImage.SymbolWeight) -> CGFloat {
        switch weight {
        case .unspecified, .regular: return 1
        case .ultraLight: return 0.56
        case .thin: return 0.68
        case .light: return 0.82
        case .medium: return 1.12
        case .semibold: return 1.24
        case .bold: return 1.38
        case .heavy: return 1.52
        case .black: return 1.66
        }
    }

    static func ellipse(in rect: CGRect) -> Path {
        let k: CGFloat = 0.5522847498307936
        let rx = rect.width / 2
        let ry = rect.height / 2
        let cx = rect.midX
        let cy = rect.midY
        var path = Path()
        path.move(to: CGPoint(x: cx + rx, y: cy))
        path.addCurve(to: CGPoint(x: cx, y: cy + ry),
                      control1: CGPoint(x: cx + rx, y: cy + k * ry),
                      control2: CGPoint(x: cx + k * rx, y: cy + ry))
        path.addCurve(to: CGPoint(x: cx - rx, y: cy),
                      control1: CGPoint(x: cx - k * rx, y: cy + ry),
                      control2: CGPoint(x: cx - rx, y: cy + k * ry))
        path.addCurve(to: CGPoint(x: cx, y: cy - ry),
                      control1: CGPoint(x: cx - rx, y: cy - k * ry),
                      control2: CGPoint(x: cx - k * rx, y: cy - ry))
        path.addCurve(to: CGPoint(x: cx + rx, y: cy),
                      control1: CGPoint(x: cx + k * rx, y: cy - ry),
                      control2: CGPoint(x: cx + rx, y: cy - k * ry))
        path.close()
        return path
    }

    static func point(_ x: CGFloat, _ y: CGFloat, in rect: CGRect) -> CGPoint {
        CGPoint(x: rect.minX + rect.width * x,
                y: rect.minY + rect.height * y)
    }

    static func appendPlusCutout(to path: inout Path, in rect: CGRect,
                                 thickness: CGFloat) {
        let low = 0.5 - thickness / 2
        let high = 0.5 + thickness / 2
        let reach: CGFloat = 0.73
        let near: CGFloat = 1 - reach
        path.move(to: point(low, near, in: rect))
        path.addLine(to: point(high, near, in: rect))
        path.addLine(to: point(high, low, in: rect))
        path.addLine(to: point(reach, low, in: rect))
        path.addLine(to: point(reach, high, in: rect))
        path.addLine(to: point(high, high, in: rect))
        path.addLine(to: point(high, reach, in: rect))
        path.addLine(to: point(low, reach, in: rect))
        path.addLine(to: point(low, high, in: rect))
        path.addLine(to: point(near, high, in: rect))
        path.addLine(to: point(near, low, in: rect))
        path.addLine(to: point(low, low, in: rect))
        path.close()
    }

    static func appendCheckCutout(to path: inout Path, in rect: CGRect,
                                  thickness: CGFloat) {
        let a = point(0.25, 0.52, in: rect)
        let b = point(0.43, 0.68, in: rect)
        let c = point(0.76, 0.32, in: rect)
        let t = Swift.min(rect.width, rect.height) * thickness
        let n1 = unitNormal(from: a, to: b)
        let n2 = unitNormal(from: b, to: c)
        path.move(to: offset(a, by: n1, amount: t))
        path.addLine(to: offset(b, by: n1, amount: t))
        path.addLine(to: offset(b, by: n2, amount: t))
        path.addLine(to: offset(c, by: n2, amount: t))
        path.addLine(to: offset(c, by: n2, amount: -t))
        path.addLine(to: offset(b, by: n2, amount: -t))
        path.addLine(to: offset(b, by: n1, amount: -t))
        path.addLine(to: offset(a, by: n1, amount: -t))
        path.close()
    }

    static func unitNormal(from a: CGPoint, to b: CGPoint) -> CGPoint {
        let dx = b.x - a.x
        let dy = b.y - a.y
        let length = (dx * dx + dy * dy).squareRoot()
        guard length > 0 else { return .zero }
        return CGPoint(x: -dy / length, y: dx / length)
    }

    static func offset(_ point: CGPoint, by normal: CGPoint,
                       amount: CGFloat) -> CGPoint {
        CGPoint(x: point.x + normal.x * amount,
                y: point.y + normal.y * amount)
    }

    static func appendThickSegment(to path: inout Path, from a: CGPoint,
                                   to b: CGPoint, thickness: CGFloat) {
        let n = unitNormal(from: a, to: b)
        let t = thickness / 2
        path.move(to: offset(a, by: n, amount: t))
        path.addLine(to: offset(b, by: n, amount: t))
        path.addLine(to: offset(b, by: n, amount: -t))
        path.addLine(to: offset(a, by: n, amount: -t))
        path.close()
    }
}
