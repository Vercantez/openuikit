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
