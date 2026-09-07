// UIImage — portable image model. Owner: image module.
//
// A UIImage wraps an RGBA8 Bitmap (the pixel backing store) plus a scale
// factor, mirroring real UIKit: `size` is in POINTS (pixel size / scale).
// Images may be synthesized procedurally (the scene runner does this, see
// docs/SCENE_SPEC.md) or decoded from PNG/JPEG bytes or files — see the
// "Loading" section below.

// M15: a DEFAULT ARGUMENT or an `@inlinable` body may only use members whose
// defining module THIS FILE imports -- `CGRect.zero` and `CGFloat.pi` do not
// ride in on OpenCoreGraphics' typealias the way ordinary uses do. These are
// SCOPED imports on purpose: they satisfy that rule without pulling in
// CoreGraphics' CGColor / CGAffineTransform, which would collide with
// OpenCoreGraphics' own. One knock-on, measured: in a file where the name is
// visible twice, `[CGFloat](repeating:count:)` array sugar stops parsing as a
// type; spell it `Array<CGFloat>(...)`.
#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
// Re-export the SDK's declaration rather than shadowing it. Selective export
// keeps OpenCoreGraphics' CGColor/CGAffineTransform out of the namespace.
@_exported import enum CoreGraphics.CGBlendMode
#elseif canImport(Foundation)
import Foundation
#endif

// UIImageWriteToSavedPhotosAlbum is implemented in this Foundation-free
// target, but its optional selector completion receives an NSError on an
// ordinary Darwin build. Keep that dependency conditional: the cold guest
// builds OpenUIKit before the app-facing Foundation facade exists.
#if canImport(Foundation)
import class Foundation.NSError
import class Foundation.NSObject
#endif
#if canImport(ObjectiveC)
import ObjectiveC
#endif


/// How a UIImage's pixels are used when it is drawn: as-is, or as a
/// silhouette tinted with the destination's tint color.


public enum UIImageRenderingMode: Sendable {
    case automatic, alwaysOriginal, alwaysTemplate
}

/// Core Graphics blend-mode source surface used by `UIImage.draw`.
///
/// On Darwin this is CoreGraphics' own type, just as UIKit exposes it. The
/// alias is important: importing OpenUIKit and CoreGraphics together still
/// yields one declaration rather than two ambiguous `CGBlendMode`s. A
/// Foundation/CoreGraphics-free target gets the portable mirror below.
#if !canImport(CoreGraphics)
public enum CGBlendMode: Int32, Sendable {
    case normal = 0
    case multiply = 1
    case screen = 2
    case overlay = 3
    case darken = 4
    case lighten = 5
    case colorDodge = 6
    case colorBurn = 7
    case softLight = 8
    case hardLight = 9
    case difference = 10
    case exclusion = 11
    case hue = 12
    case saturation = 13
    case color = 14
    case luminosity = 15
    case clear = 16
    case copy = 17
    case sourceIn = 18
    case sourceOut = 19
    case sourceAtop = 20
    case destinationOver = 21
    case destinationIn = 22
    case destinationOut = 23
    case destinationAtop = 24
    case xor = 25
    case plusDarker = 26
    case plusLighter = 27
}
#endif

// MEASURED simplenote-launch-image-oracle, iPhone 16 / iOS 26.1:
// class_getSuperclass(UIImage.self) == NSObject; an @objc UIImage-returning
// factory compiles and responds to its selector. Gridicons c904cb7 has two
// such factories (Gridicons.swift:10,17). This is the class ABI surface,
// not a rendering rule; both font cuts retain their existing pixel model.
public final class UIImage: NSObject {
    /// Pixel backing store (width/height are in PIXELS at `scale`).
    public let bitmap: Bitmap
    /// Pixels-per-point of the backing store (like UIImage.scale).
    public let scale: CGFloat

    /// Logical size in points (pixel size / scale), like UIImage.size.
    public var size: CGSize {
        CGSize(width: CGFloat(bitmap.width) / scale,
               height: CGFloat(bitmap.height) / scale)
    }

    /// UIKit's renderingMode. Ordinary raster images in `.automatic` remain
    /// original pixels. Images made by `init(systemName:)` carry an internal
    /// system-symbol marker, so their automatic mode is template-rendered by
    /// UIImageView just like UIKit.
    public private(set) var renderingMode: UIImageRenderingMode = .automatic

    /// System symbols default to template rendering while ordinary decoded,
    /// named, literal, and bitmap-backed images do not. This is metadata, not
    /// a heuristic over pixels or names, and it survives immutable copies.
    private var _isSystemSymbol = false
    /// The `systemName` this image was created with. Tab-bar chrome uses it
    /// to pick the filled sibling (clock → clock.fill) under the iOS cut.
    var _systemSymbolName: String?

    /// Whether this image was created from the supported system-symbol
    /// provider. The flag is semantic metadata and is preserved by UIImage's
    /// immutable rendering-mode and tint copies.
    @available(iOS 13.0, *)
    public var isSymbolImage: Bool { _isSystemSymbol }

    var _usesTemplateTint: Bool {
        renderingMode == .alwaysTemplate
            || (renderingMode == .automatic && _isSystemSymbol)
    }

    func _markAsSystemSymbol(_ name: String) {
        _isSystemSymbol = true
        _systemSymbolName = name
    }

    public init(bitmap: Bitmap, scale: CGFloat = 1) {
        self.bitmap = bitmap
        self.scale = scale > 0 ? scale : 1
    }

    /// UIKit's empty image initializer. The resulting image has zero logical
    /// size and is useful as a sentinel (for example, to suppress navigation
    /// bar background and shadow artwork).
    public override convenience init() {
        self.init(bitmap: Bitmap(width: 0, height: 0), scale: 1)
    }

    private init(bitmap: Bitmap, scale: CGFloat,
                 renderingMode: UIImageRenderingMode,
                 isSystemSymbol: Bool,
                 systemSymbolName: String?) {
        self.bitmap = bitmap
        self.scale = scale > 0 ? scale : 1
        self.renderingMode = renderingMode
        self._isSystemSymbol = isSystemSymbol
        self._systemSymbolName = systemSymbolName
    }

    // MARK: Rendering mode / tinting

    /// A copy of this image with the given rendering mode. Shares the
    /// backing store (UIKit does the same — images are immutable).
    public func withRenderingMode(_ mode: UIImageRenderingMode) -> UIImage {
        UIImage(bitmap: bitmap, scale: scale, renderingMode: mode,
                isSystemSymbol: _isSystemSymbol,
                systemSymbolName: _systemSymbolName)
    }

    /// A copy whose pixels are recolored with `color`, keeping the original
    /// per-pixel alpha (CG `.sourceIn` of a flat color over the silhouette —
    /// what UIKit does for a template image). The result is
    /// the receiver's rendering mode, like UIKit's one-argument
    /// `withTintColor(_:)`. The returned pixels contain the requested color.
    /// A system-symbol copy remains a symbol, so UIImageView's ambient tint
    /// still wins while the public mode is automatic; an ordinary automatic
    /// raster keeps the baked color. Explicit template/original modes likewise
    /// survive the immutable copy. These branches match the native iOS 26.1
    /// metadata and visual oracle.
    public func withTintColor(_ color: UIColor) -> UIImage {
        withTintColor(color, renderingMode: renderingMode)
    }

    public func withTintColor(_ color: UIColor,
                              renderingMode mode: UIImageRenderingMode) -> UIImage {
        _withTintColor(color, renderingMode: mode,
                       traits: UITraitCollection.current)
    }

    /// Trait-explicit tinting seam used by UIImageView. UIKit resolves a
    /// dynamic tint color in the destination view's trait environment, not
    /// process-global UITraitCollection.current.
    func _withTintColor(_ color: UIColor,
                        renderingMode mode: UIImageRenderingMode,
                        traits: UITraitCollection) -> UIImage {
        let c = color.resolvedCGColor(with: traits)
        let out = Bitmap(width: bitmap.width, height: bitmap.height)
        let r = UInt8(Swift.max(0, Swift.min(255, (c.red * 255).rounded())))
        let g = UInt8(Swift.max(0, Swift.min(255, (c.green * 255).rounded())))
        let b = UInt8(Swift.max(0, Swift.min(255, (c.blue * 255).rounded())))
        bitmap.pixels.withUnsafeBufferPointer { src in
            out.pixels.withUnsafeMutableBufferPointer { dst in
                var i = 0
                while i + 3 < dst.count {
                    dst[i] = r; dst[i + 1] = g; dst[i + 2] = b
                    dst[i + 3] = UInt8(CGFloat(src[i + 3]) * c.alpha)
                    i += 4
                }
            }
        }
        return UIImage(bitmap: out, scale: scale, renderingMode: mode,
                       isSystemSymbol: _isSystemSymbol,
                       systemSymbolName: _systemSymbolName)
    }

    // MARK: Loading (PNG / JPEG plus indexed vector PDF via ImageCodec)

    /// Decode PNG or JPEG bytes. `scale` defaults to 1, like
    /// `UIImage(data:)`.
    public convenience init?(data: [UInt8], scale: CGFloat = 1) {
        guard let bitmap = ImageCodec.decode(data) else { return nil }
        self.init(bitmap: bitmap, scale: scale)
    }

    /// Foundation.Data-compatible spelling without a Foundation dependency.
    /// Keeping this generic in the emitted interface matters for Mach-O guest
    /// builds: OpenUIKit can be compiled while Foundation is invisible, then
    /// a client importing Foundation.Data still satisfies `Sequence<UInt8>`.
    public convenience init?<Bytes: Sequence>(data: Bytes, scale: CGFloat = 1)
    where Bytes.Element == UInt8 {
        self.init(data: Array(data), scale: scale)
    }

    /// Decode an image file. Like UIKit, an `@2x`/`@3x` suffix on the file
    /// name (before the extension) sets the image's scale.
    public convenience init?(contentsOfFile path: String) {
        guard let bytes = ResourceIO.readFile(path),
              let bitmap = ImageCodec.decode(bytes) else { return nil }
        self.init(bitmap: bitmap, scale: UIImage.scaleFromFileName(path))
    }

    /// UIKit's `UIImage(named:)`, resolved against
    /// `OpenUIKitRuntime.imageSearchPaths` (empty by default — the library
    /// hardcodes no host paths). `name` may carry an extension; when it
    /// does not, `png`, `jpg` and `jpeg` are tried in that order. For each
    /// candidate the search first resolves a materialized asset-catalog
    /// index, then (only when the name is absent from every valid index)
    /// prefers the loose `@Nx` variant for
    /// `OpenUIKitRuntime.imageScreenScale`, then lower scales, then the
    /// unsuffixed file. Results are cached by the complete lookup environment
    /// (UIKit caches `named:` lookups too).
    public static func named(_ name: String) -> UIImage? {
        let traits = UITraitCollection.current
        let key = _NamedCacheKey(
            name: name,
            searchPaths: OpenUIKitRuntime.imageSearchPaths,
            scale: BundleAssetLookup.assetScale(
                OpenUIKitRuntime.imageScreenScale
            ),
            appearance: BundleAssetLookup.assetAppearance(for: traits),
            idiom: BundleAssetLookup.assetIdiom()
        )
        if let hit = _namedCache[key] { return hit }
        guard let img = loadNamed(name,
                                  searchPaths: OpenUIKitRuntime.imageSearchPaths,
                                  preferredScale: OpenUIKitRuntime.imageScreenScale,
                                  traits: traits) else {
            return nil
        }
        _namedCache[key] = img
        return img
    }

    /// Decode a loose PNG/JPEG resource from one of `searchPaths`.
    ///
    /// Materialized indexes may point at PNG, JPEG, or supported vector PDF
    /// image-set members. Loose fallback remains raster-only so a malformed or
    /// unsupported indexed vector cannot be bypassed by a stale source file.
    private static func loadNamed(_ name: String,
                                  searchPaths: [String],
                                  preferredScale: CGFloat,
                                  traits: UITraitCollection) -> UIImage? {
        guard let name = BundleAssetLookup.relativeResourceName(name) else {
            return nil
        }
        switch BundleAssetLookup.indexedImage(
            named: name,
            resourceRoots: searchPaths,
            preferredScale: preferredScale,
            traits: traits
        ) {
        case .value(let image):
            return image
        case .blocked:
            return nil
        case .absent:
            break
        }

        let (base, ext) = splitExtension(name)
        let exts = ext.map { [$0] } ?? ["png", "jpg", "jpeg"]
        var scales: [Int] = []
        // Converting NaN, infinity, or an out-of-range CGFloat directly to Int
        // traps. Bound finite values before conversion and give non-finite
        // caller input a deterministic 1x fallback.
        let boundedScale = preferredScale.isFinite
            ? Swift.max(1, Swift.min(3, preferredScale))
            : 1
        let want = Int(boundedScale.rounded())
        for s in stride(from: Swift.max(1, Swift.min(3, want)), through: 1, by: -1) {
            scales.append(s)
        }
        for dir in searchPaths {
            let prefix = dir.isEmpty || dir.hasSuffix("/") ? dir : dir + "/"
            for e in exts {
                for s in scales {
                    let suffix = s > 1 ? "@\(s)x" : ""
                    let path = prefix + base + suffix + "." + e
                    if let bytes = ResourceIO.readFile(path),
                       let bitmap = ImageCodec.decode(bytes) {
                        return UIImage(bitmap: bitmap, scale: CGFloat(s))
                    }
                }
            }
        }
        return nil
    }

    /// UIKit spells this as an initializer; the failable convenience init
    /// simply forwards to `named(_:)`.
    public convenience init?(named name: String) {
        guard let img = UIImage.named(name) else { return nil }
        self.init(bitmap: img.bitmap, scale: img.scale,
                  renderingMode: img.renderingMode,
                  isSystemSymbol: img._isSystemSymbol,
                  systemSymbolName: img._systemSymbolName)
    }

    /// UIKit's bundle-selecting named-image initializer.
    ///
    /// Materialized asset-catalog raster variants are resolved using idiom,
    /// appearance and display scale before the loose PNG/JPEG fallback.
    /// Apple's compiled `Assets.car` and SVGs are not decoded. Supported PDF
    /// vectors are rasterized at the selected trait/display scale.
    ///
    /// In a Foundation-hidden guest build Bundle has no filesystem metadata,
    /// so the host-configured `OpenUIKitRuntime.imageSearchPaths` are used.
    public convenience init?(named name: String,
                             in bundle: Bundle?,
                             compatibleWith traitCollection: UITraitCollection?) {
        let preferredScale = traitCollection?.displayScale
            ?? OpenUIKitRuntime.imageScreenScale
        let traits = traitCollection ?? UITraitCollection.current
        guard let img = UIImage.loadNamed(
            name,
            searchPaths: BundleAssetLookup.resourceRoots(in: bundle),
            preferredScale: preferredScale,
            traits: traits
        ) else { return nil }
        self.init(bitmap: img.bitmap, scale: img.scale,
                  renderingMode: img.renderingMode,
                  isSystemSymbol: img._isSystemSymbol,
                  systemSymbolName: img._systemSymbolName)
    }

    /// Drop every cached `named:` lookup (hosts call this after changing
    /// `imageSearchPaths`).
    public static func clearNamedCache() {
        _namedCache.removeAll()
        BundleAssetLookup.clearAssetCatalogCache()
    }

    private struct _NamedCacheKey: Hashable {
        let name: String
        let searchPaths: [String]
        let scale: Int
        let appearance: String
        let idiom: String
    }
    private static var _namedCache: [_NamedCacheKey: UIImage] = [:]

    /// Compiler entry point used by `#imageLiteral(resourceName:)` in
    /// unchanged UIKit application sources. Image literals follow the same
    /// loose-resource lookup policy as `UIImage(named:)`; a missing literal is
    /// a packaging error and therefore fails loudly instead of inventing a
    /// transparent placeholder.
    public convenience init(imageLiteralResourceName name: String) {
        guard let image = UIImage.named(name) else {
            preconditionFailure("UIImage image literal resource not found: \(name)")
        }
        self.init(bitmap: image.bitmap, scale: image.scale,
                  renderingMode: image.renderingMode,
                  isSystemSymbol: image._isSystemSymbol,
                  systemSymbolName: image._systemSymbolName)
    }

    /// "…@2x.png" → 2, "…@3x" → 3, anything else → 1.
    static func scaleFromFileName(_ path: String) -> CGFloat {
        let (base, _) = splitExtension(path)
        if base.hasSuffix("@2x") { return 2 }
        if base.hasSuffix("@3x") { return 3 }
        return 1
    }

    /// Split a path into (everything before the last dot of the last path
    /// component, extension) — nil extension when there is none.
    static func splitExtension(_ path: String) -> (String, String?) {
        var lastDot: String.Index? = nil
        var i = path.startIndex
        while i < path.endIndex {
            let c = path[i]
            if c == "." { lastDot = i }
            if c == "/" { lastDot = nil }
            i = path.index(after: i)
        }
        guard let dot = lastDot, path.index(after: dot) < path.endIndex else {
            return (path, nil)
        }
        return (String(path[path.startIndex..<dot]),
                String(path[path.index(after: dot)...]))
    }

    // MARK: Encoding

    /// PNG representation of the backing store (straight alpha, RGBA8).
    public func pngData() -> [UInt8]? { ImageCodec.encodePNG(bitmap) }

    /// JPEG representation. `compressionQuality` is UIKit's 0...1.
    public func jpegData(compressionQuality: CGFloat) -> [UInt8]? {
        ImageCodec.encodeJPEG(bitmap, quality: compressionQuality)
    }

    // MARK: CG-compatible resampling
    //
    // Real CG (oracle: layer.render into a CGContext, default interpolation)
    // does NOT use plain bilinear filtering when scaling image contents.
    // Probing the oracle with magnified step edges (see ImageViewTests and
    // module notes) shows a separable resampler that:
    //   1. samples at s = (d + 0.5) * srcSize / dstSize - 0.5 (standard
    //      center-aligned mapping, edge-clamped),
    //   2. quantizes the fractional part t to eighths: k = round(8t),
    //   3. uses a WARPED weight from a fixed table instead of t itself:
    //        W = [0, 1/16, 1/8, 1/4, 1/2, 3/4, 7/8, 15/16, 1]
    // which yields the dyadic staircase edge profiles real CG produces
    // (255, 239, 223, 191, 128, 64, 32, 16, 0 across a magnified
    // black/white edge). Verified exactly against oracle renders at scales
    // 1.5x, 2.5x and 20x; plain bilinear is off by up to 44/255 at seams.
    static let resampleWeights: [CGFloat] = [
        0, 1.0 / 16, 1.0 / 8, 1.0 / 4, 1.0 / 2, 3.0 / 4, 7.0 / 8, 15.0 / 16, 1,
    ]

    /// Resample the backing bitmap to an exact pixel size using the
    /// CG-compatible warped-weight filter (premultiplied-alpha sampling).
    /// Returns the original bitmap when the size already matches.
    func resampledBitmap(width dw: Int, height dh: Int) -> Bitmap {
        let sw = bitmap.width, sh = bitmap.height
        if dw == sw && dh == sh { return bitmap }
        let out = Bitmap(width: dw, height: dh)
        guard dw > 0, dh > 0, sw > 0, sh > 0 else { return out }
        let W = UIImage.resampleWeights

        // Per-axis source index pairs + warped weights.
        func axis(_ dst: Int, _ src: Int) -> ([Int], [Int], [CGFloat]) {
            var i0 = [Int](), i1 = [Int](), w = Array<CGFloat>()
            i0.reserveCapacity(dst); i1.reserveCapacity(dst); w.reserveCapacity(dst)
            for d in 0..<dst {
                let s = (CGFloat(d) + 0.5) * CGFloat(src) / CGFloat(dst) - 0.5
                let f = s.rounded(.down)
                let t = s - f
                let k = Int((8 * t).rounded())
                let a = Int(f)
                i0.append(Swift.min(Swift.max(a, 0), src - 1))
                i1.append(Swift.min(Swift.max(a + 1, 0), src - 1))
                w.append(W[k])
            }
            return (i0, i1, w)
        }
        let (xi0, xi1, xw) = axis(dw, sw)
        let (yi0, yi1, yw) = axis(dh, sh)

        bitmap.pixels.withUnsafeBufferPointer { src in
            out.pixels.withUnsafeMutableBufferPointer { dst in
                @inline(__always) func premul(_ x: Int, _ y: Int) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
                    let o = (y * sw + x) * 4
                    let a = CGFloat(src[o + 3])
                    return (CGFloat(src[o]) * a, CGFloat(src[o + 1]) * a,
                            CGFloat(src[o + 2]) * a, a * 255)
                }
                @inline(__always) func b8(_ v: CGFloat) -> UInt8 {
                    UInt8(Swift.max(0, Swift.min(255, v.rounded())))
                }
                for y in 0..<dh {
                    let wy = yw[y], y0 = yi0[y], y1 = yi1[y]
                    for x in 0..<dw {
                        let wx = xw[x], x0 = xi0[x], x1 = xi1[x]
                        let s00 = premul(x0, y0), s10 = premul(x1, y0)
                        let s01 = premul(x0, y1), s11 = premul(x1, y1)
                        let w00 = (1 - wx) * (1 - wy), w10 = wx * (1 - wy)
                        let w01 = (1 - wx) * wy, w11 = wx * wy
                        let pr = s00.0 * w00 + s10.0 * w10 + s01.0 * w01 + s11.0 * w11
                        let pg = s00.1 * w00 + s10.1 * w10 + s01.1 * w01 + s11.1 * w11
                        let pb = s00.2 * w00 + s10.2 * w10 + s01.2 * w01 + s11.2 * w11
                        let pa = s00.3 * w00 + s10.3 * w10 + s01.3 * w01 + s11.3 * w11
                        let o = (y * dw + x) * 4
                        if pa <= 0 {
                            dst[o] = 0; dst[o + 1] = 0; dst[o + 2] = 0; dst[o + 3] = 0
                        } else {
                            let inv = 255 / pa
                            dst[o] = b8(pr * inv); dst[o + 1] = b8(pg * inv)
                            dst[o + 2] = b8(pb * inv); dst[o + 3] = b8(pa / 255)
                        }
                    }
                }
            }
        }
        return out
    }
}

extension UIImage: _ExpressibleByImageLiteral {}

/// Swift's image-literal default type, matching UIKit's module-level alias.
public typealias _ImageLiteralType = UIImage

// MARK: - Saved photo album host boundary

/// A portable failure reported by a host implementing saved-photo storage.
///
/// UIKit's C function reports failure only through an optional NSError sent
/// to the completion selector. OpenUIKit additionally publishes this small
/// value to its host hook so a Linux compositor, desktop shell, or test host
/// can describe the result without importing Foundation or Photos.
public struct UIImagePhotoLibrarySaveError: Error, Hashable, Sendable,
                                            CustomStringConvertible {
    public enum Code: Int, Hashable, Sendable {
        /// No host installed a photo-library writer.
        case unavailable = 1
        /// The user or host denied add access.
        case permissionDenied = 2
        /// A configured host attempted the write and it failed.
        case writeFailed = 3
    }

    /// NSError domain used for Objective-C selector completions on builds
    /// where Foundation is visible.
    public static let errorDomain = "OpenUIKit.PhotoLibrary"

    public let code: Code
    public let description: String

    public init(code: Code, description: String) {
        self.code = code
        self.description = description
    }

    public static let unavailable = UIImagePhotoLibrarySaveError(
        code: .unavailable,
        description: "No host photo-library save handler is installed"
    )
}

/// Completion result used by ``OpenUIKitRuntime/photoLibrarySaveHandler``.
public enum UIImagePhotoLibrarySaveResult: Hashable, Sendable {
    case success
    case failure(UIImagePhotoLibrarySaveError)
}

/// Host implementation of saved-photo storage.
///
/// The host receives the immutable UIImage and calls `completion` exactly
/// once when its write has actually completed. The completion may be retained
/// for an asynchronous OS service. OpenUIKit never chooses a filesystem path,
/// silently exports a PNG, or reports success without this handler.
public typealias UIImagePhotoLibrarySaveHandler = (
    _ image: UIImage,
    _ completion: @escaping (UIImagePhotoLibrarySaveResult) -> Void
) -> Void

extension OpenUIKitRuntime {
    /// HOST HOOK for ``UIImageWriteToSavedPhotosAlbum(_:_:_:_:)``.
    ///
    /// Install this during host startup to route the UIKit API to the host's
    /// real photo library. Nil is the safe default: no bytes leave the
    /// process, and a supplied completion selector receives `.unavailable`.
    /// Hosts must configure this startup seam before concurrent application
    /// work begins, just like the other OpenUIKitRuntime backend selections.
    nonisolated(unsafe) public static var photoLibrarySaveHandler:
        UIImagePhotoLibrarySaveHandler?
}

/// Portable fallback for a three-argument Objective-C completion selector.
///
/// Mach-O builds use the genuine Objective-C runtime and unchanged `@objc`
/// methods. A host without Objective-C cannot compile `#selector`; it can use
/// `Selector.named(...)` and adopt this SPI to preserve the same selector
/// name, image, failure, and context-pointer delivery without changing the
/// public UIKit function.
@_spi(OpenUIKitHost)
public protocol UIImagePhotoLibrarySaveCompletionDispatching: AnyObject {
    @discardableResult
    func _openUIKitPerformPhotoLibrarySaveCompletion(
        _ selectorName: String,
        image: UIImage,
        error: UIImagePhotoLibrarySaveError?,
        contextInfo: UnsafeMutableRawPointer?
    ) -> Bool
}

#if canImport(ObjectiveC)
private typealias _UIImagePhotoLibraryCompletionIMP = @convention(c) (
    AnyObject, Selector, AnyObject, AnyObject?, UnsafeMutableRawPointer?
) -> Void
#endif

#if canImport(ObjectiveC) && !canImport(Foundation)
/// Objective-C `id` fallback used only while Foundation is hidden from the
/// cold guest OpenUIKit build. The final app-facing platform normally has a
/// host handler and therefore supplies its own result; this box still makes
/// the default failure non-nil and inspectable instead of claiming success.
private final class _UIImagePhotoLibrarySaveErrorBox: NSObject {
    let failure: UIImagePhotoLibrarySaveError

    init(_ failure: UIImagePhotoLibrarySaveError) {
        self.failure = failure
        super.init()
    }
}
#endif

private final class _UIImagePhotoLibrarySaveCompletion {
    private let image: UIImage
    private let target: Any?
    private let selector: Selector?
    private let contextInfo: UnsafeMutableRawPointer?
    private var hasDelivered = false

    init(image: UIImage, target: Any?, selector: Selector?,
         contextInfo: UnsafeMutableRawPointer?) {
        self.image = image
        self.target = target
        self.selector = selector
        self.contextInfo = contextInfo
    }

    func deliver(_ result: UIImagePhotoLibrarySaveResult) {
        // A misbehaving host must not invoke an application callback twice.
        guard !hasDelivered else { return }
        hasDelivered = true

        guard let target, let selector, selector.actionArity == 3 else { return }
        let failure: UIImagePhotoLibrarySaveError?
        switch result {
        case .success:
            failure = nil
        case .failure(let error):
            failure = error
        }

#if canImport(ObjectiveC)
        // NSObject.perform exposes only zero, one, and two argument forms.
        // The documented UIKit callback has three arguments, so resolve the
        // genuine method IMP and invoke its exact Objective-C ABI directly.
        if let object = target as? NSObject,
           object.responds(to: selector) {
            let implementation = object.method(for: selector)
            let call = unsafeBitCast(
                implementation,
                to: _UIImagePhotoLibraryCompletionIMP.self
            )
            call(object, selector, image, errorObject(for: failure), contextInfo)
            return
        }
#endif

        if let portable = target as?
            any UIImagePhotoLibrarySaveCompletionDispatching {
            _ = portable._openUIKitPerformPhotoLibrarySaveCompletion(
                selector.actionName,
                image: image,
                error: failure,
                contextInfo: contextInfo
            )
        }
    }

#if canImport(ObjectiveC)
    private func errorObject(
        for failure: UIImagePhotoLibrarySaveError?
    ) -> AnyObject? {
        guard let failure else { return nil }
#if canImport(Foundation)
        return NSError(
            domain: UIImagePhotoLibrarySaveError.errorDomain,
            code: failure.code.rawValue,
            userInfo: nil
        )
#else
        return _UIImagePhotoLibrarySaveErrorBox(failure)
#endif
    }
#endif
}

/// Adds `image` to the host's saved-photos album.
///
/// This is the exact source shape of UIKit's C entry point. A host-installed
/// ``OpenUIKitRuntime/photoLibrarySaveHandler`` owns the actual persistence
/// operation. Its result is forwarded once to the optional selector using
/// the documented `image:didFinishSavingWithError:contextInfo:` ABI. With no
/// handler the operation fails closed and delivers a non-nil unavailable
/// error when the caller supplied a valid completion target and selector.
public func UIImageWriteToSavedPhotosAlbum(
    _ image: UIImage,
    _ completionTarget: Any?,
    _ completionSelector: Selector?,
    _ contextInfo: UnsafeMutableRawPointer?
) {
    let completion = _UIImagePhotoLibrarySaveCompletion(
        image: image,
        target: completionTarget,
        selector: completionSelector,
        contextInfo: contextInfo
    )
    guard let handler = OpenUIKitRuntime.photoLibrarySaveHandler else {
        completion.deliver(.failure(.unavailable))
        return
    }
    handler(image) { result in
        completion.deliver(result)
    }
}

// MARK: - Drawing (M14, real-app harness)
//
// `UIImage.draw(in:)` / `draw(at:)` are how app code composites an image into
// the current graphics context (a `UIGraphicsImageRenderer` block, or
// `UIView.draw(_:)`). Missing entirely before M14 — found by compiling a real
// app's image helpers (docs/REAL_APP_TEST.md).
extension UIImage {
    /// Draw the image scaled into `rect` in the CURRENT context.
    public func draw(in rect: CGRect) {
        UIGraphicsGetCurrentContext()?.draw(bitmap, in: rect)
    }

    /// Draw at natural size with its top-left at `point`.
    public func draw(at point: CGPoint) {
        draw(in: CGRect(origin: point, size: size))
    }


    /// Draw at natural size with an explicit blend mode and global alpha.
    /// `.normal` uses a transparency layer so alpha is applied once to the
    /// whole image, matching CGContext/UIImage semantics even for
    /// translucent source pixels. Unsupported blend modes currently use the
    /// same source-over path; see `CGBlendMode`'s declaration.
    public func draw(at point: CGPoint, blendMode: CGBlendMode, alpha: CGFloat) {
        guard let canvas = UIGraphicsGetCurrentContext() else { return }
        let rect = CGRect(origin: point, size: size)
        let opacity = Swift.min(Swift.max(alpha, 0), 1)
        guard opacity > 0 else { return }

        // Keep the mode switch explicit: this is an honest compatibility
        // fallback, not an accidental claim that Canvas implements all 28
        // Core Graphics equations.
        switch blendMode {
        case .normal:
            break
        default:
            break
        }

        if opacity >= 1 {
            canvas.draw(bitmap, in: rect)
        } else {
            canvas.beginTransparencyLayer(alpha: opacity)
            canvas.draw(bitmap, in: rect)
            canvas.endTransparencyLayer()
        }
    }
}
