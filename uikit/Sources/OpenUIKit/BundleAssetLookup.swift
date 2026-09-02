// Bundle resource-root extraction shared by UIImage and UIColor named assets.
//
// Foundation-capable builds use the selected Bundle's own resource path.
// FoundationEssentials-only Mach-O builds use OpenUIKit's portable Bundle.
// Fully Foundation-free renderer builds retain imageSearchPaths as their
// explicit resource-root contract.

#if canImport(Foundation)
import class Foundation.Bundle
#endif

enum BundleAssetLookup {
    /// Validate a bundle-relative logical asset name without over-restricting
    /// legitimate subdirectory names. Resource lookup is not a path traversal
    /// API: absolute paths, empty components, and `.`/`..` components must not
    /// escape the selected bundle root.
    static func relativeResourceName(_ name: String) -> String? {
        guard !name.isEmpty,
              !name.hasPrefix("/"),
              !name.contains("\\"),
              !name.utf8.contains(0) else { return nil }

        let components = name.split(separator: "/", omittingEmptySubsequences: false)
        guard components.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }) else {
            return nil
        }
        return name
    }

    static func resourceRoots(in bundle: Bundle?) -> [String] {
#if canImport(Foundation)
        let selected = bundle ?? Bundle.main
        if let resourcePath = selected.resourcePath, !resourcePath.isEmpty {
            return [resourcePath]
        }

        // Foundation-less/hand-authored flat bundles may not expose a resource
        // path. Only then use the bundle directory itself; a structured bundle
        // must never fall through from Contents/Resources to its package root.
        let bundlePath = selected.bundlePath
        return bundlePath.isEmpty ? [] : [bundlePath]
#elseif canImport(FoundationEssentials)
        let selected = bundle ?? Bundle.main
        if let resourcePath = selected.resourcePath, !resourcePath.isEmpty {
            return [resourcePath]
        }
        return selected.bundlePath.isEmpty ? [] : [selected.bundlePath]
#else
        _ = bundle
        return OpenUIKitRuntime.imageSearchPaths
#endif
    }
}

// MARK: - Materialized source-catalog index

/// A named lookup must distinguish "this valid index does not contain the
/// name" from "the index contains the name but cannot safely resolve it".
/// Only the former may fall through to legacy loose/source-catalog lookup.
enum _AssetCatalogLookup<Value> {
    case absent
    case blocked
    case value(Value)
}

/// Deferred indexed color. Keeping the record rather than eagerly choosing a
/// light/dark value preserves UIColor's dynamic appearance behavior.
struct _AssetCatalogColor {
    fileprivate let record: _AssetCatalogRecord
    fileprivate let idiom: String

    var hasAppearanceVariants: Bool {
        record.variants.contains {
            ($0["appearance"]?.stringValue ?? "any") != "any"
        }
    }

    func resolvedColor(for traits: UITraitCollection) -> CGColor? {
        let appearance = BundleAssetLookup.assetAppearance(for: traits)
        guard let variant = _AssetCatalogStore.resolveVariant(
            record, idiom: idiom, appearance: appearance, scale: nil
        ) else { return nil }
        return _AssetCatalogStore.color(from: variant)
    }
}

extension BundleAssetLookup {
    /// Materialized indexes live under this stable packager-owned path in an
    /// application bundle's resource root.
    fileprivate static let assetIndexRelativePath =
        "OpenUIKit/AssetCatalogs/index.json"

    static func indexedImage(
        named name: String,
        resourceRoots: [String],
        preferredScale: CGFloat,
        traits: UITraitCollection
    ) -> _AssetCatalogLookup<UIImage> {
        guard relativeResourceName(name) != nil else { return .blocked }
        let scale = assetScale(preferredScale)
        let appearance = assetAppearance(for: traits)
        let idiom = assetIdiom()

        switch _AssetCatalogStore.record(named: name, roots: resourceRoots) {
        case .absent:
            return .absent
        case .blocked:
            return .blocked
        case .value(let located):
            let record = located.record
            guard record.type == "imageset",
                  let variant = _AssetCatalogStore.resolveVariant(
                    record, idiom: idiom, appearance: appearance, scale: scale
                  ),
                  _AssetCatalogStore.hasSupportedImageQualifiers(variant),
                  let payload = _AssetCatalogStore.payload(from: variant),
                  payload.ext == ".png" || payload.ext == ".jpg"
                    || payload.ext == ".jpeg" || payload.ext == ".pdf",
                  let bytes = ResourceIO.readFile(
                    located.indexRoot + "/Resources/" + payload.file
                  ),
                  bytes.count == payload.bytes
            else { return .blocked }

            let encodedScale = _AssetCatalogStore.scale(in: variant)
            let imageScale = CGFloat(encodedScale ?? scale)
            let bitmap: Bitmap?
            if payload.ext == ".pdf" {
                bitmap = ImageCodec.decodePDF(bytes, scale: imageScale)
            } else {
                bitmap = ImageCodec.decode(bytes)
            }
            guard let bitmap else { return .blocked }
            var image = UIImage(bitmap: bitmap, scale: imageScale)
            switch record.templateRenderingIntent {
            case "template":
                image = image.withRenderingMode(.alwaysTemplate)
            case "original":
                image = image.withRenderingMode(.alwaysOriginal)
            default:
                break
            }
            return .value(image)
        }
    }

    static func indexedColor(
        named name: String,
        resourceRoots: [String]
    ) -> _AssetCatalogLookup<_AssetCatalogColor> {
        guard relativeResourceName(name) != nil else { return .blocked }
        switch _AssetCatalogStore.record(named: name, roots: resourceRoots) {
        case .absent:
            return .absent
        case .blocked:
            return .blocked
        case .value(let located):
            guard located.record.type == "colorset" else { return .blocked }
            return .value(_AssetCatalogColor(
                record: located.record, idiom: assetIdiom()
            ))
        }
    }

    static func clearAssetCatalogCache() {
        _AssetCatalogStore.clearCache()
    }

    static func assetScale(_ value: CGFloat) -> Int {
        let bounded = value.isFinite
            ? Swift.max(1, Swift.min(3, value))
            : 1
        return Int(bounded.rounded())
    }

    static func assetAppearance(for traits: UITraitCollection) -> String {
        let style: UIUserInterfaceStyle
        if traits.userInterfaceStyle == .unspecified {
            style = UITraitCollection.current.userInterfaceStyle
        } else {
            style = traits.userInterfaceStyle
        }
        return style == .dark ? "dark" : "light"
    }

    static func assetIdiom() -> String {
        switch OpenUIKitRuntime.assetCatalogIdiom {
        case .phone, .unspecified: return "iphone"
        case .pad: return "ipad"
        case .tv: return "tv"
        case .carPlay: return "car"
        case .mac: return "mac"
        case .vision: return "vision"
        }
    }
}

private struct _AssetCatalogPayload {
    let file: String
    let ext: String
    let bytes: Int
}

fileprivate struct _AssetCatalogRecord {
    let type: String
    let properties: [String: JSONValue]
    let variants: [JSONValue]

    var templateRenderingIntent: String? {
        properties["template-rendering-intent"]?.stringValue
    }
}

private struct _LocatedAssetCatalogRecord {
    let indexRoot: String
    let record: _AssetCatalogRecord
}

private struct _AssetCatalogIndex {
    let indexRoot: String
    let assets: [String: _AssetCatalogRecord]
    let unresolvedNames: Set<String>
}

private enum _AssetCatalogCacheEntry {
    case missing
    case malformed
    case valid(_AssetCatalogIndex)
}

/// Foundation-free parser, schema validator, resolution engine and cache for
/// `OpenUIKit/AssetCatalogs/index.json`. It deliberately validates the whole
/// version-1 index before exposing any record: a corrupt unrelated entry must
/// not turn a packaged build into a partly stale loose-resource lookup.
private enum _AssetCatalogStore {
    private static var cache: [String: _AssetCatalogCacheEntry] = [:]
    private static let maximumIndexBytes = 64 * 1024 * 1024
    private static let knownTypes: Set<String> = [
        "imageset", "colorset", "appiconset", "dataset", "symbolset",
    ]
    private static let knownIdioms: Set<String> = [
        "universal", "iphone", "ipad", "watch", "tv", "mac", "car",
        "vision", "ios-marketing", "watch-marketing",
    ]
    private static let knownAppearances: Set<String> = [
        "any", "light", "dark", "tinted",
    ]
    private static let knownColorSpaces: Set<String> = [
        "srgb", "display-p3", "extended-srgb", "gray-gamma-22",
    ]

    static func clearCache() { cache.removeAll() }

    static func record(
        named name: String,
        roots: [String]
    ) -> _AssetCatalogLookup<_LocatedAssetCatalogRecord> {
        for root in roots {
            switch index(for: root) {
            case .missing:
                continue
            case .malformed:
                return .blocked
            case .valid(let index):
                if index.unresolvedNames.contains(name) { return .blocked }
                if let record = index.assets[name] {
                    return .value(_LocatedAssetCatalogRecord(
                        indexRoot: index.indexRoot, record: record
                    ))
                }
            }
        }
        return .absent
    }

    static func resolveVariant(
        _ record: _AssetCatalogRecord,
        idiom: String,
        appearance: String,
        scale requestedScale: Int?
    ) -> JSONValue? {
        var candidates = record.variants

        let exactIdiom = candidates.filter {
            $0["idiom"]?.stringValue == idiom
        }
        let universal = candidates.filter {
            $0["idiom"]?.stringValue == "universal"
        }
        candidates = exactIdiom.isEmpty ? universal : exactIdiom
        guard !candidates.isEmpty else { return nil }

        let exactAppearance = candidates.filter {
            $0["appearance"]?.stringValue == appearance
        }
        let anyAppearance = candidates.filter {
            $0["appearance"]?.stringValue == "any"
        }
        candidates = exactAppearance.isEmpty ? anyAppearance : exactAppearance
        guard !candidates.isEmpty else { return nil }

        // Color entries may be explicitly platform-qualified. This runtime
        // models iOS: within the already selected idiom/appearance an exact
        // `ios` entry beats an unqualified entry; macOS/watchOS never leak
        // into the candidate set. Images have no platform field and therefore
        // pass through the unqualified branch unchanged.
        let iosPlatform = candidates.filter {
            $0["platform"]?.stringValue == "ios"
        }
        let unqualifiedPlatform = candidates.filter {
            guard let value = $0["platform"] else { return true }
            if case .null = value { return true }
            return false
        }
        candidates = iosPlatform.isEmpty ? unqualifiedPlatform : iosPlatform
        guard !candidates.isEmpty else { return nil }

        guard let requestedScale else { return candidates.first }
        if let exact = candidates.first(where: {
            scale(in: $0) == requestedScale
        }) { return exact }

        let explicit = candidates.compactMap { variant -> (Int, JSONValue)? in
            guard let scale = scale(in: variant) else { return nil }
            return (scale, variant)
        }
        if let belowScale = explicit.map(\.0)
            .filter({ $0 < requestedScale }).max(),
           let below = explicit.first(where: { $0.0 == belowScale }) {
            return below.1
        }
        if let aboveScale = explicit.map(\.0)
            .filter({ $0 > requestedScale }).min(),
           let above = explicit.first(where: { $0.0 == aboveScale }) {
            return above.1
        }
        return candidates.first(where: { scale(in: $0) == nil })
    }

    static func scale(in variant: JSONValue) -> Int? {
        guard let value = variant["scale"] else { return nil }
        if case .null = value { return nil }
        guard let number = value.doubleValue,
              number == number.rounded(), number >= 1, number <= 3 else {
            return nil
        }
        return Int(number)
    }

    static func hasSupportedImageQualifiers(_ variant: JSONValue) -> Bool {
        for key in [
            "screen_width", "language_direction", "height_class", "resizing",
        ] {
            guard let value = variant[key] else { continue }
            if case .null = value { continue }
            return false
        }
        return true
    }

    static func payload(from variant: JSONValue) -> _AssetCatalogPayload? {
        guard let payload = variant["payload"] else { return nil }
        return parsePayload(payload)
    }

    static func color(from variant: JSONValue) -> CGColor? {
        if variant["reference"]?.stringValue != nil { return nil }
        guard let space = variant["color_space"]?.stringValue else { return nil }
        switch space {
        case "srgb", "extended-srgb":
            guard let rgba = components(variant["native"], count: 4) else {
                return nil
            }
            return CGColor(red: CGFloat(rgba[0]), green: CGFloat(rgba[1]),
                           blue: CGFloat(rgba[2]), alpha: CGFloat(rgba[3]))
        case "display-p3":
            guard let rgba = components(variant["srgb"], count: 4) else {
                return nil
            }
            return CGColor(red: CGFloat(rgba[0]), green: CGFloat(rgba[1]),
                           blue: CGFloat(rgba[2]), alpha: CGFloat(rgba[3]))
        case "gray-gamma-22":
            guard let values = components(variant["native"], count: 2) else {
                return nil
            }
            let white = CGFloat(values[0])
            return CGColor(red: white, green: white, blue: white,
                           alpha: CGFloat(values[1]))
        default:
            return nil
        }
    }

    private static func index(for rawRoot: String) -> _AssetCatalogCacheEntry {
        let root = normalizedRoot(rawRoot)
        if let cached = cache[root] { return cached }
        let prefix = root.isEmpty ? "" : root + "/"
        let indexPath = prefix + BundleAssetLookup.assetIndexRelativePath
        guard let bytes = ResourceIO.readFile(indexPath) else {
            cache[root] = .missing
            return .missing
        }
        guard bytes.count <= maximumIndexBytes,
              let parsed = JSONValue.parse(bytes),
              let index = parseIndex(parsed, indexRoot:
                prefix + "OpenUIKit/AssetCatalogs") else {
            cache[root] = .malformed
            return .malformed
        }
        cache[root] = .valid(index)
        return .valid(index)
    }

    private static func normalizedRoot(_ root: String) -> String {
        var result = root
        while result.count > 1 && result.hasSuffix("/") {
            result.removeLast()
        }
        return result
    }

    private static func parseIndex(
        _ value: JSONValue,
        indexRoot: String
    ) -> _AssetCatalogIndex? {
        guard let object = value.objectValue,
              object["format"]?.stringValue == "openuikit-xcassets-index",
              object["version"]?.doubleValue == 1,
              let app = object["app"]?.stringValue, !app.isEmpty,
              object["resources_dir"]?.stringValue == "Resources",
              let catalogValues = object["catalogs"]?.arrayValue,
              catalogValues.allSatisfy({ value in
                guard let path = value.stringValue else { return false }
                return BundleAssetLookup.relativeResourceName(path) != nil
              }),
              let assetValues = object["assets"]?.objectValue,
              let unresolvedValues = object["unresolved"]?.objectValue,
              let collisionValues = object["collisions"]?.objectValue,
              let orphanValues = object["folder_orphans"]?.arrayValue,
              let stats = object["stats"]?.objectValue,
              stats.values.allSatisfy({ value in
                  guard let number = value.doubleValue else { return false }
                  return number.isFinite && number >= 0
                    && number == number.rounded()
              }) else { return nil }

        var assets: [String: _AssetCatalogRecord] = [:]
        for (name, encoded) in assetValues {
            guard BundleAssetLookup.relativeResourceName(name) != nil,
                  let record = parseRecord(encoded) else { return nil }
            assets[name] = record
        }

        var unresolved = Set<String>()
        for (name, encoded) in unresolvedValues {
            guard BundleAssetLookup.relativeResourceName(name) != nil,
                  let record = encoded.objectValue,
                  let type = record["type"]?.stringValue, !type.isEmpty,
                  let reason = record["reason"]?.stringValue, !reason.isEmpty,
                  let files = record["files"]?.arrayValue,
                  files.allSatisfy({ parsePayload($0) != nil }) else { return nil }
            if let nestedValue = record["nested_asset_dirs"] {
                guard let nested = nestedValue.objectValue,
                      nested.allSatisfy({ key, value in
                          guard !key.isEmpty,
                                let count = value.doubleValue else { return false }
                          return count.isFinite && count >= 0
                            && count == count.rounded()
                      }) else { return nil }
            }
            unresolved.insert(name)
        }
        guard Set(assets.keys).isDisjoint(with: unresolved) else { return nil }

        // Collisions are audit records. `assets` already contains the
        // packager's ordered first-catalog winner, which is the runtime value.
        // Still validate their shape and paths so malformed metadata cannot
        // bless the rest of an index.
        for (name, encoded) in collisionValues {
            guard BundleAssetLookup.relativeResourceName(name) != nil,
                  assets[name] != nil else { return nil }
            guard let collisions = encoded.arrayValue,
                  !collisions.isEmpty else { return nil }
            for collision in collisions {
                guard let item = collision.objectValue,
                      let contents = item["contents"]?.stringValue,
                      BundleAssetLookup.relativeResourceName(contents) != nil,
                      let collisionRecord = item["record"],
                      parseRecord(collisionRecord) != nil else { return nil }
            }
        }
        guard orphanValues.allSatisfy({ parsePayload($0) != nil }) else {
            return nil
        }
        return _AssetCatalogIndex(
            indexRoot: indexRoot, assets: assets,
            unresolvedNames: unresolved
        )
    }

    private static func parseRecord(_ value: JSONValue) -> _AssetCatalogRecord? {
        guard let object = value.objectValue,
              let type = object["type"]?.stringValue,
              knownTypes.contains(type),
              let properties = object["properties"]?.objectValue,
              let variants = object["variants"]?.arrayValue else { return nil }

        if let intent = properties["template-rendering-intent"] {
            guard let name = intent.stringValue,
                  name == "template" || name == "original" else { return nil }
        }
        if let orphanValue = object["orphan_files"] {
            guard let orphans = orphanValue.arrayValue,
                  orphans.allSatisfy({ parsePayload($0) != nil }) else {
                return nil
            }
        }

        for variant in variants {
            guard let entry = variant.objectValue,
                  let idiom = entry["idiom"]?.stringValue,
                  knownIdioms.contains(idiom),
                  let appearance = entry["appearance"]?.stringValue,
                  knownAppearances.contains(appearance) else { return nil }

            if type == "colorset" {
                if let platform = entry["platform"] {
                    if case .null = platform {
                        // Unqualified iOS-compatible entry.
                    } else {
                        guard let name = platform.stringValue,
                              name == "ios" || name == "osx"
                                || name == "watchos" else { return nil }
                    }
                }
                if let reference = entry["reference"]?.stringValue {
                    guard !reference.isEmpty,
                          entry["srgb"].map(isNull) == true else { return nil }
                } else {
                    guard let space = entry["color_space"]?.stringValue,
                          knownColorSpaces.contains(space),
                          components(entry["srgb"], count: 4) != nil else {
                        return nil
                    }
                    let nativeCount = space == "gray-gamma-22" ? 2 : 4
                    guard components(entry["native"], count: nativeCount) != nil else {
                        return nil
                    }
                }
            } else {
                guard let payload = entry["payload"],
                      parsePayload(payload) != nil else { return nil }
                if type == "imageset" || type == "appiconset" {
                    guard entry["scale"] != nil,
                          isValidScale(entry["scale"]!) else { return nil }
                }
            }
        }
        return _AssetCatalogRecord(
            type: type, properties: properties, variants: variants
        )
    }

    private static func parsePayload(_ value: JSONValue) -> _AssetCatalogPayload? {
        guard let object = value.objectValue,
              let sha = object["sha256"]?.stringValue,
              sha.count == 64,
              sha.utf8.allSatisfy({
                ($0 >= UInt8(ascii: "0") && $0 <= UInt8(ascii: "9"))
                    || ($0 >= UInt8(ascii: "a") && $0 <= UInt8(ascii: "f"))
              }),
              let byteCount = object["bytes"]?.doubleValue,
              byteCount.isFinite, byteCount >= 0,
              byteCount == byteCount.rounded(), byteCount <= Double(Int.max),
              let ext = object["ext"]?.stringValue,
              isSafeExtension(ext),
              let filename = object["filename"]?.stringValue,
              !filename.isEmpty, !filename.contains("/"),
              !filename.contains("\\"), !filename.utf8.contains(0),
              let file = object["file"]?.stringValue,
              BundleAssetLookup.relativeResourceName(file) != nil,
              file == String(sha.prefix(2)) + "/" + sha + ext else {
            return nil
        }
        return _AssetCatalogPayload(file: file, ext: ext, bytes: Int(byteCount))
    }

    private static func isSafeExtension(_ ext: String) -> Bool {
        guard ext.isEmpty || ext.first == "." else { return false }
        return ext.dropFirst().utf8.allSatisfy {
            ($0 >= UInt8(ascii: "0") && $0 <= UInt8(ascii: "9"))
                || ($0 >= UInt8(ascii: "a") && $0 <= UInt8(ascii: "z"))
        }
    }

    private static func isValidScale(_ value: JSONValue) -> Bool {
        if case .null = value { return true }
        guard let number = value.doubleValue else { return false }
        return number == number.rounded() && number >= 1 && number <= 3
    }

    private static func components(_ value: JSONValue?, count: Int) -> [Double]? {
        guard let values = value?.arrayValue, values.count == count else {
            return nil
        }
        var result: [Double] = []
        result.reserveCapacity(count)
        for value in values {
            guard let number = value.doubleValue, number.isFinite else {
                return nil
            }
            result.append(number)
        }
        return result
    }

    private static func isNull(_ value: JSONValue) -> Bool {
        if case .null = value { return true }
        return false
    }
}
