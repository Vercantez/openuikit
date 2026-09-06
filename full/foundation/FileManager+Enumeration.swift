// File-system resource metadata and recursive directory enumeration for
// Linux-hosted Mach-O guests.
//
// FoundationEssentials deliberately leaves URLResourceKey empty when it is
// built outside Apple's Foundation framework, and its FileManager currently
// exposes only the primitive path operations.  The app-facing Foundation
// umbrella owns the missing value type and composes those primitives into the
// public Foundation behavior here.  Traversal is lazy and never follows
// symbolic links, so a hostile directory tree cannot create a recursion loop
// or force the enumerator to retain the whole tree.

#if FOUNDATION_GUEST_SERVICES_HOST
import Foundation
#else
import FoundationEssentials
#endif

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

#if FOUNDATION_GUEST_SERVICES_HOST
public struct URLResourceKey: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let nameKey = Self("NSURLNameKey")
    public static let isRegularFileKey = Self("NSURLIsRegularFileKey")
    public static let isDirectoryKey = Self("NSURLIsDirectoryKey")
    public static let isSymbolicLinkKey = Self("NSURLIsSymbolicLinkKey")
    public static let isPackageKey = Self("NSURLIsPackageKey")
    public static let isHiddenKey = Self("NSURLIsHiddenKey")
    public static let fileSizeKey = Self("NSURLFileSizeKey")
    public static let fileAllocatedSizeKey = Self("NSURLFileAllocatedSizeKey")
    public static let totalFileSizeKey = Self("NSURLTotalFileSizeKey")
    public static let totalFileAllocatedSizeKey =
        Self("NSURLTotalFileAllocatedSizeKey")
}
#else
public extension URLResourceKey {
    init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }

    static let nameKey = Self("NSURLNameKey")
    static let isRegularFileKey = Self("NSURLIsRegularFileKey")
    static let isDirectoryKey = Self("NSURLIsDirectoryKey")
    static let isSymbolicLinkKey = Self("NSURLIsSymbolicLinkKey")
    static let isPackageKey = Self("NSURLIsPackageKey")
    static let isHiddenKey = Self("NSURLIsHiddenKey")
    static let fileSizeKey = Self("NSURLFileSizeKey")
    static let fileAllocatedSizeKey = Self("NSURLFileAllocatedSizeKey")
    static let totalFileSizeKey = Self("NSURLTotalFileSizeKey")
    static let totalFileAllocatedSizeKey =
        Self("NSURLTotalFileAllocatedSizeKey")
}
#endif

public struct URLResourceValues: Sendable {
    public internal(set) var name: String?
    public internal(set) var isRegularFile: Bool?
    public internal(set) var isDirectory: Bool?
    public internal(set) var isSymbolicLink: Bool?
    public internal(set) var isPackage: Bool?
    public internal(set) var isHidden: Bool?
    public internal(set) var fileSize: Int?
    public internal(set) var fileAllocatedSize: Int?
    public internal(set) var totalFileSize: Int?
    public internal(set) var totalFileAllocatedSize: Int?

    public var allValues: [URLResourceKey: Any] {
        var result: [URLResourceKey: Any] = [:]
        if let name { result[.nameKey] = name }
        if let isRegularFile { result[.isRegularFileKey] = isRegularFile }
        if let isDirectory { result[.isDirectoryKey] = isDirectory }
        if let isSymbolicLink { result[.isSymbolicLinkKey] = isSymbolicLink }
        if let isPackage { result[.isPackageKey] = isPackage }
        if let isHidden { result[.isHiddenKey] = isHidden }
        if let fileSize { result[.fileSizeKey] = fileSize }
        if let fileAllocatedSize { result[.fileAllocatedSizeKey] = fileAllocatedSize }
        if let totalFileSize { result[.totalFileSizeKey] = totalFileSize }
        if let totalFileAllocatedSize { result[.totalFileAllocatedSizeKey] = totalFileAllocatedSize }
        return result
    }

    public init() {}
}

private let _foundationPackageExtensions: Set<String> = [
    "app", "appex", "bundle", "framework", "kext", "mdimporter", "pkg",
    "plugin", "prefpane", "qlgenerator", "rtfd", "wdgt", "xcodeproj",
    "xcworkspace",
]

private func _foundationIsPackage(_ url: URL, isDirectory: Bool) -> Bool {
    guard isDirectory else { return false }
    return _foundationPackageExtensions.contains(url.pathExtension.lowercased())
}

private func _foundationIntegerAttribute(_ value: Any?) -> Int? {
    switch value {
    case let value as Int: return value
    case let value as UInt: return Int(clamping: value)
    case let value as Int64: return Int(clamping: value)
    case let value as UInt64: return Int(clamping: value)
    case let value as Int32: return Int(value)
    case let value as UInt32: return Int(value)
    default: return nil
    }
}

private func _foundationAllocatedSize(atPath path: String) -> Int? {
#if canImport(Darwin)
    var metadata = Darwin.stat()
    let result = path.withCString { Darwin.lstat($0, &metadata) }
#elseif canImport(Glibc)
    var metadata = Glibc.stat()
    let result = path.withCString { Glibc.lstat($0, &metadata) }
#else
    return nil
#endif
    guard result == 0, metadata.st_blocks >= 0 else { return nil }
    let blocks = Int64(metadata.st_blocks)
    let (bytes, overflow) = blocks.multipliedReportingOverflow(by: 512)
    guard !overflow else { return Int.max }
    return Int(clamping: bytes)
}

public extension URL {
    func resourceValues(
        forKeys keys: Set<URLResourceKey>
    ) throws -> URLResourceValues {
        guard isFileURL else {
            throw CocoaError(.fileReadUnsupportedScheme)
        }

        let attributes = try FileManager.default.attributesOfItem(atPath: path)
        let fileType = attributes[.type] as? FileAttributeType
        let isRegular = fileType == .typeRegular
        let isDirectory = fileType == .typeDirectory
        let isSymbolicLink = fileType == .typeSymbolicLink
        let logicalSize = _foundationIntegerAttribute(attributes[.size])
        let allocatedSize = _foundationAllocatedSize(atPath: path) ?? logicalSize
        var values = URLResourceValues()

        if keys.contains(.nameKey) {
            values.name = lastPathComponent
        }
        if keys.contains(.isRegularFileKey) {
            values.isRegularFile = isRegular
        }
        if keys.contains(.isDirectoryKey) {
            values.isDirectory = isDirectory
        }
        if keys.contains(.isSymbolicLinkKey) {
            values.isSymbolicLink = isSymbolicLink
        }
        if keys.contains(.isPackageKey) {
            values.isPackage = _foundationIsPackage(self, isDirectory: isDirectory)
        }
        if keys.contains(.isHiddenKey) {
            values.isHidden = lastPathComponent.hasPrefix(".")
        }
        if keys.contains(.fileSizeKey) {
            values.fileSize = logicalSize
        }
        if keys.contains(.fileAllocatedSizeKey) {
            values.fileAllocatedSize = allocatedSize
        }
        if keys.contains(.totalFileSizeKey) {
            values.totalFileSize = logicalSize
        }
        if keys.contains(.totalFileAllocatedSizeKey) {
            values.totalFileAllocatedSize = allocatedSize
        }
        return values
    }
}

public extension FileManager {
    final class DirectoryEnumerator: Sequence, IteratorProtocol {
        public typealias Element = Any

        private enum Pending {
            case visit(URL, level: Int)
            case emit(URL, level: Int)

            var level: Int {
                switch self {
                case .visit(_, let level), .emit(_, let level): return level
                }
            }
        }

        private let manager: FileManager
        private let options: FileManager.DirectoryEnumerationOptions
        private let errorHandler: ((URL, Error) -> Bool)?
        private var pending: [Pending] = []
        private var stopped = false
        private var currentLevel = 0

        fileprivate init(
            root: URL,
            manager: FileManager,
            options: FileManager.DirectoryEnumerationOptions,
            errorHandler: ((URL, Error) -> Bool)?
        ) {
            self.manager = manager
            self.options = options
            self.errorHandler = errorHandler
            _appendChildren(of: root, level: 1)
        }

        public var level: Int { currentLevel }

        public func makeIterator() -> DirectoryEnumerator { self }

        public func skipDescendants() {
            while let last = pending.last, last.level > currentLevel {
                pending.removeLast()
            }
        }

        public func next() -> Any? {
            guard !stopped else { return nil }

            while let item = pending.popLast() {
                let url: URL
                let level: Int
                switch item {
                case .emit(let value, let valueLevel):
                    currentLevel = valueLevel
                    return value
                case .visit(let value, let valueLevel):
                    url = value
                    level = valueLevel
                }

                let hidden = url.lastPathComponent.hasPrefix(".")
                if hidden, options.contains(.skipsHiddenFiles) {
                    continue
                }

                let attributes: [FileAttributeKey: Any]
                do {
                    attributes = try manager.attributesOfItem(atPath: url.path)
                } catch {
                    guard errorHandler?(url, error) != false else {
                        stopped = true
                        pending.removeAll(keepingCapacity: false)
                        return nil
                    }
                    continue
                }

                let fileType = attributes[.type] as? FileAttributeType
                let isDirectory = fileType == .typeDirectory
                let isPackage = _foundationIsPackage(
                    url,
                    isDirectory: isDirectory
                )
                let mayDescend = isDirectory &&
                    !options.contains(.skipsSubdirectoryDescendants) &&
                    !(isPackage && options.contains(.skipsPackageDescendants))

                if options.contains(.includesDirectoriesPostOrder), isDirectory {
                    pending.append(.emit(url, level: level))
                    if mayDescend {
                        _appendChildren(of: url, level: level + 1)
                    }
                    continue
                }

                if mayDescend {
                    _appendChildren(of: url, level: level + 1)
                }
                currentLevel = level
                return url
            }
            return nil
        }

        private func _appendChildren(of directory: URL, level: Int) {
            do {
                // FileManager does not promise filesystem enumeration order.
                // Sorting makes the portable implementation reproducible.
                let names = try manager.contentsOfDirectory(atPath: directory.path)
                    .sorted()
                for name in names.reversed() {
                    pending.append(.visit(
                        directory.appendingPathComponent(name),
                        level: level
                    ))
                }
            } catch {
                if errorHandler?(directory, error) == false {
                    stopped = true
                    pending.removeAll(keepingCapacity: false)
                }
            }
        }
    }

    func enumerator(
        at url: URL,
        includingPropertiesForKeys keys: [URLResourceKey]?,
        options mask: DirectoryEnumerationOptions = [],
        errorHandler handler: ((URL, Error) -> Bool)? = nil
    ) -> DirectoryEnumerator? {
        guard url.isFileURL else { return nil }
        var isDirectory = false
        guard fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory else {
            return nil
        }
        _ = keys // The value URL API resolves metadata on demand.
        return DirectoryEnumerator(
            root: url,
            manager: self,
            options: mask,
            errorHandler: handler
        )
    }
}
