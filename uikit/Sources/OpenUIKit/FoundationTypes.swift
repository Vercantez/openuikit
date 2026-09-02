// Foundation types UIKit vends, plus the UIKit-owned conveniences on them.
// Owner: app-compat cluster (M15 — docs/APP_COMPAT.md "Foundation coexistence").
//
// WHAT CHANGED, AND WHY
// ---------------------
// Until M15 OpenUIKit declared its OWN `IndexPath`, `NSRange`,
// `NSRangePointer` and `TimeInterval`, because the library imported no
// Foundation at all. docs/APP_COMPAT.md then measured what that cost: an app
// that imports BOTH OpenUIKit and Foundation — which every real app does,
// because its model layer is Foundation — saw two types of each name and the
// compiler refused to pick one.
//
// The collision was never missing API. It was duplicate NAMES. So the library
// imports Foundation here and re-exports Foundation's own types under the
// names UIKit uses; `Bundle` follows the same rule for UIViewController's nib
// API. A Foundation-free Mach-O build can instead import the open-source
// FoundationEssentials module and share its `IndexPath`; that is the first
// app-facing identity needed before the complete Foundation umbrella exists.
// `typealias` is what makes that work: unqualified lookup
// that finds a typealias AND the type it aliases resolves to ONE declaration,
// so `import Foundation` + `import OpenUIKit` in one file is unambiguous — and
// unlike the old shadowing, an `IndexPath` built by an app's model layer IS
// the one `tableView(_:cellForRowAt:)` receives.
//
// Aliasing rather than `@_exported import Foundation` is deliberate: it puts
// the names in OpenUIKit's namespace, so the other ~100 source files keep
// compiling without a per-file Foundation import, and OpenCoreGraphics'
// `CGAffineTransform` / `CGColor` never have to fight CoreGraphics' for the
// name on Darwin (docs/PORTABILITY.md).
//
// WHAT IS DELIBERATELY *NOT* ALIASED
// ----------------------------------
// Four families keep OpenUIKit's own implementation. Each has a measured
// reason, reproduced in docs/KNOWN_GAPS.md "Foundation coexistence":
//
//   * `CGAffineTransform` — Foundation has none on Linux, so there is no
//     collision to remove, and one shared implementation is what keeps the
//     Linux render byte-identical (its `init(rotationAngle:)` uses the
//     library's own series, not libm).
//   * `NSAttributedString` / `NSMutableAttributedString` — MEASURED: on
//     swift 6.2 Linux, `NSMutableAttributedString.addAttribute` TRAPS the
//     second time a plain Swift value is stored for a key, because run
//     coalescing calls `isEqual` on the boxed value. Every OpenUIKit
//     attribute value (UIFont, UIColor, CGFloat, NSParagraphStyle) is a plain
//     Swift value. Foundation's attributed string cannot hold UIKit's
//     attributes on the target platform.
//   * The Notification family has a capability split rather than one blanket
//     choice. Foundation-visible builds alias `Notification`,
//     `NSNotification`, and `OperationQueue`. When Objective-C is also
//     available, `NotificationCenter` is Foundation's too. Native ELF keeps
//     OpenUIKit's selector-registry center because corelibs Foundation has no
//     selector form and its object-filter behavior differs. A Foundation-
//     hidden Objective-C guest keeps the custom value/center and bridges the
//     value through one NSObject-backed NSNotification carrier.
//   * `Timer` / `RunLoop` — they run on the SCRIPTED host clock
//     (`UIWindow.tick(timestamp:)`), not a wall clock. Foundation's run on
//     `Date`, which would put wall-clock time into the frame loop and end
//     byte-identical rendering. See Timer.swift.

#if canImport(Foundation)
import Foundation

#if canImport(AppKit)
// macOS ONLY, and only because of the oracle/dev platform: AppKit already
// extends Foundation's `IndexPath` with `init(item:section:)`, `.item` and
// `.section` — the same `[section, item]` storage UIKit uses — and XCTest
// drags AppKit into every test target. If OpenUIKit declared those three as
// well, every `indexPath.section` in a test would be ambiguous between two
// identical members. So on macOS we import AppKit's and declare only the
// `row` spelling it lacks; on Linux, where there is no AppKit, OpenUIKit
// declares all of them. Nothing else in the library touches AppKit.
import AppKit
#endif

/// Foundation's `IndexPath`. Real UIKit does not declare its own either — it
/// adds the two-component conveniences below to Foundation's type, which is
/// exactly what this extension does.
public typealias IndexPath = Foundation.IndexPath

#elseif canImport(FoundationEssentials)

import FoundationEssentials

#if os(macOS)
@_silgen_name("_NSGetExecutablePath")
private func _openUIKitExecutablePath(
    _ buffer: UnsafeMutablePointer<CChar>?,
    _ size: UnsafeMutablePointer<UInt32>
) -> Int32
#endif

@_silgen_name("swift_getTypeContextDescriptor")
private func _openUIKitTypeContextDescriptor(of type: AnyClass) -> UnsafeRawPointer

private struct _OpenUIKitDlInfo {
    var imagePath: UnsafePointer<CChar>?
    var imageBase: UnsafeMutableRawPointer?
    var symbolName: UnsafePointer<CChar>?
    var symbolAddress: UnsafeMutableRawPointer?
}

@_silgen_name("dladdr")
private func _openUIKitDladdr(
    _ address: UnsafeRawPointer?,
    _ info: UnsafeMutablePointer<_OpenUIKitDlInfo>
) -> Int32

#if os(macOS)
@_silgen_name("_dyld_image_count")
private func _openUIKitDyldImageCount() -> UInt32

@_silgen_name("_dyld_get_image_header")
private func _openUIKitDyldImageHeader(_ index: UInt32) -> UnsafeRawPointer?

@_silgen_name("_dyld_get_image_name")
private func _openUIKitDyldImageName(_ index: UInt32) -> UnsafePointer<CChar>?
#endif

/// FoundationEssentials' canonical `IndexPath`. This branch is used by the
/// Linux-built Mach-O framework before a complete `Foundation` umbrella is
/// available. App code that imports FoundationEssentials and OpenUIKit now
/// sees one identity rather than two lookalike values.
public typealias IndexPath = FoundationEssentials.IndexPath

#endif

// MARK: - IndexPath

#if canImport(Foundation) || canImport(FoundationEssentials)

extension IndexPath {
    /// Table-view index path, stored `[section, row]` like UIKit's.
    public init(row: Int, section: Int) { self.init(indexes: [section, row]) }
    /// The row component of a table-view index path — the same slot as
    /// `item`, exactly like UIKit.
    public var row: Int { count > 1 ? self[1] : 0 }

#if !canImport(AppKit)
    /// Collection-view index path, stored `[section, item]`.
    public init(item: Int, section: Int) { self.init(indexes: [section, item]) }

    /// The section component. UIKit traps on an index path too short to have
    /// one; reporting 0 keeps a malformed path from taking down a layout
    /// pass, and nothing in OpenUIKit produces one.
    public var section: Int { count > 0 ? self[0] : 0 }
    /// The item component of a collection-view index path.
    public var item: Int { count > 1 ? self[1] : 0 }
#endif
}

#endif

#if canImport(Foundation)

public typealias IndexSet = Foundation.IndexSet

// MARK: - Ranges and time

/// Foundation's `NSRange`: `location`/`length` in UTF-16 code units, with
/// `upperBound`, `lowerBound` and `contains(_:)` already on it.
public typealias NSRange = Foundation.NSRange
public typealias NSRangePointer = Foundation.NSRangePointer

/// Foundation's `TimeInterval` (`Double`, seconds). OpenUIKit's clock is the
/// host tick timestamp, not a wall clock — the UNIT is all that is shared.
public typealias TimeInterval = Foundation.TimeInterval

/// Foundation's keyed-archive decoder base class.  UIKit's view initializer
/// names this exact type; keeping the alias in OpenUIKit's namespace lets an
/// app import Foundation and OpenUIKit together without creating a second
/// initializer signature.
public typealias NSCoder = Foundation.NSCoder

// MARK: - Bundle

/// Foundation's resource bundle type. UIViewController's nib initializer
/// exposes it even when the controller is otherwise entirely programmatic.
public typealias Bundle = Foundation.Bundle

#else

/// Foundation-free identity used by UIKit's required coder initializers.
/// The Mach-O app-path Foundation shim aliases its `NSCoder` spelling back to
/// this class so framework and application declarations keep one signature.
/// No archive decoding is implemented by this compatibility type.
open class NSCoder {
    public init() {}
}

/// Foundation-free renderer builds still compile the complete OpenUIKit
/// module. They cannot load resources or nibs, but they need the identity and
/// `main` spelling carried by UIViewController's public initializer surface.
/// Foundation-visible package builds use the aliases above; a
/// Foundation-hidden guest app uses these fallback identities at the shared
/// framework/application boundary.
public final class Bundle: @unchecked Sendable {
#if canImport(FoundationEssentials)
    /// The bundle containing the guest executable.
    ///
    /// The first-party guest runtime supplies `_NSGetExecutablePath`, so this
    /// resolves the Mach-O guest image rather than the Linux loader process.
    public static let main = Bundle(uncheckedDirectoryURL: mainBundleURL())

    public let bundleURL: FoundationEssentials.URL

    public var bundlePath: String { bundleURL.path }

    public var resourcePath: String? { resourceURL?.path }

    /// The optional root used by named-resource lookup. macOS-style bundles
    /// use `Contents/Resources`, frameworks use `Resources`, and flat SwiftPM
    /// or iOS bundles use the bundle directory itself.
    public var resourceURL: FoundationEssentials.URL? {
        let contents = bundleURL.appendingPathComponent("Contents", isDirectory: true)
        var isDirectory = false
        if FoundationEssentials.FileManager.default.fileExists(
            atPath: contents.path,
            isDirectory: &isDirectory
        ), isDirectory {
            return contents.appendingPathComponent("Resources", isDirectory: true)
        }

        if bundleURL.pathExtension == "framework" {
            let resources = bundleURL.appendingPathComponent("Resources", isDirectory: true)
            if FoundationEssentials.FileManager.default.fileExists(
                atPath: resources.path,
                isDirectory: &isDirectory
            ), isDirectory {
                return resources
            }
        }
        return bundleURL
    }

    /// Return an existing named item beneath this bundle's resource root.
    ///
    /// This is deliberately smaller than Foundation's complete Bundle API.
    /// It matches the measured Apple behavior needed by unchanged Focus: nil
    /// and empty extensions are equivalent, a leading dot is accepted, an
    /// extension is appended even when `name` already has a suffix, and a
    /// slash-delimited name may address a nested resource. Nil or empty names
    /// fail closed because Foundation treats some of those calls as resource
    /// enumeration, which this bounded implementation does not claim. Every
    /// descendant component must also be an ordinary node: symlinks are
    /// rejected even when their destination stays inside the resource root.
    public func url(
        forResource name: String?,
        withExtension extensionName: String?
    ) -> FoundationEssentials.URL? {
        guard let name, !name.isEmpty, let resourceURL else { return nil }

        var candidate = resourceURL.appendingPathComponent(name)
        if var extensionName, !extensionName.isEmpty {
            if extensionName.first == "." {
                extensionName.removeFirst()
            }
            if !extensionName.isEmpty {
                candidate.appendPathExtension(extensionName)
            }
        }
        candidate = candidate.standardized

        let root = resourceURL.standardized
        guard Bundle.hasNoSymlinkComponents(candidate, beneath: root) else { return nil }
        guard FoundationEssentials.FileManager.default.fileExists(atPath: candidate.path) else {
            return nil
        }
        return candidate
    }

    /// Inspect every descendant with `readlink` through FileManager. EINVAL is
    /// the one expected failure for an ordinary node. A successful readlink,
    /// missing/inaccessible node, or any other error fails closed.
    private static func hasNoSymlinkComponents(
        _ candidate: FoundationEssentials.URL,
        beneath root: FoundationEssentials.URL
    ) -> Bool {
        // `standardized` is lexical. Do not use `standardizedFileURL`: the
        // latter consults the filesystem and reaches unsupported getattrlist
        // in the current Foundation-hidden target15 runtime.
        let root = root.standardized
        let candidate = candidate.standardized
        let rootPath = root.path
        let candidatePath = candidate.path

        // The filesystem root already ends in `/`; all other standardized
        // directory roots need one separator. This produces `/child`, never
        // `//child`, while still preventing `/root-other` prefix confusion.
        let descendantPrefix = rootPath == "/" ? "/" : rootPath + "/"
        guard candidatePath.hasPrefix(descendantPrefix) else { return false }
        let suffix = candidatePath.dropFirst(descendantPrefix.count)
        guard !suffix.isEmpty else { return false }

        var current = root
        for component in suffix.split(separator: "/") {
            current.appendPathComponent(String(component))
            do {
                _ = try FoundationEssentials.FileManager.default
                    .destinationOfSymbolicLink(atPath: current.path)
                return false
            } catch let error as FoundationEssentials.CocoaError {
                guard let posix = error.underlying as? FoundationEssentials.POSIXError,
                      posix.code == .EINVAL else {
                    return false
                }
            } catch {
                return false
            }
        }
        return true
    }

    /// Match Foundation's important failure behavior: missing paths and files
    /// are not bundles. SwiftPM's accessor relies on this to fall through from
    /// its preferred installed path to its build path.
    public convenience init?(path: String) {
        let candidate = FoundationEssentials.URL(
            fileURLWithPath: path,
            isDirectory: true
        ).standardized
        var isDirectory = false
        guard !path.isEmpty,
              FoundationEssentials.FileManager.default.fileExists(
                  atPath: candidate.path,
                  isDirectory: &isDirectory
              ),
              isDirectory else { return nil }
        self.init(uncheckedDirectoryURL: candidate)
    }

    public convenience init?(url: FoundationEssentials.URL) {
        guard url.isFileURL else { return nil }
        self.init(path: url.path)
    }

    /// Resolve a class's defining image. `dladdr` supplies the image base, and
    /// the dyld table supplies its resolved path when the install name is an
    /// unresolved `@rpath` spelling under machorun.
    public convenience init(for aClass: AnyClass) {
        let descriptor = _openUIKitTypeContextDescriptor(of: aClass)
        var info = _OpenUIKitDlInfo(
            imagePath: nil,
            imageBase: nil,
            symbolName: nil,
            symbolAddress: nil
        )
        if _openUIKitDladdr(descriptor, &info) != 0 {
#if os(macOS)
            if let imageBase = info.imageBase {
                for index in 0..<_openUIKitDyldImageCount() {
                    if _openUIKitDyldImageHeader(index) == UnsafeRawPointer(imageBase),
                       let imagePath = _openUIKitDyldImageName(index) {
                        self.init(uncheckedDirectoryURL: Bundle.bundleRoot(
                            forImagePath: String(cString: imagePath)
                        ))
                        return
                    }
                }
            }
#else
            if let imagePath = info.imagePath {
                self.init(uncheckedDirectoryURL: Bundle.bundleRoot(
                    forImagePath: String(cString: imagePath)
                ))
                return
            }
#endif
        }
        self.init(uncheckedDirectoryURL: Bundle.main.bundleURL)
    }

    private init(uncheckedDirectoryURL: FoundationEssentials.URL) {
        bundleURL = uncheckedDirectoryURL
    }

    private static func mainBundleURL() -> FoundationEssentials.URL {
#if os(macOS)
        var capacity: UInt32 = 0
        if _openUIKitExecutablePath(nil, &capacity) == -1, capacity > 0 {
            var bytes = [CChar](repeating: 0, count: Int(capacity))
            if _openUIKitExecutablePath(&bytes, &capacity) == 0 {
                return bundleRoot(forImagePath: String(cString: bytes))
            }
        }
#else
        if let argument = CommandLine.arguments.first, !argument.isEmpty {
            let executable = FoundationEssentials.URL(
                fileURLWithPath: argument,
                isDirectory: false
            ).standardized
            return bundleRoot(forImagePath: executable.path)
        }
#endif
        return FoundationEssentials.URL(
            fileURLWithPath: FoundationEssentials.FileManager.default.currentDirectoryPath,
            isDirectory: true
        )
    }

    private static func bundleRoot(
        forImagePath imagePath: String
    ) -> FoundationEssentials.URL {
        let imageURL = FoundationEssentials.URL(
            fileURLWithPath: imagePath,
            isDirectory: false
        ).standardized
        let components = imageURL.path.split(separator: "/").map(String.init)
        // An app may contain a framework or resource bundle. The class lives
        // in the innermost image bundle, not the first outer `.app` component.
        for index in components.indices.reversed() {
            let component = components[index]
            if component.hasSuffix(".app") || component.hasSuffix(".framework") ||
                component.hasSuffix(".bundle") {
                let root = "/" + components[...index].joined(separator: "/")
                return FoundationEssentials.URL(
                    fileURLWithPath: root,
                    isDirectory: true
                )
            }
        }
        return imageURL.deletingLastPathComponent()
    }
#else
    public static let main = Bundle()
    private init() {}
#endif
}

#endif
