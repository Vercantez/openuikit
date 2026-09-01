// Compile-only OpenUIKit boundary for Foundation guest service tests.
//
// The production module owns these identities while Foundation is hidden from
// its compilation.  Keeping the boundary fixture deliberately small lets the
// host-side test type-check the facade without accidentally importing Darwin
// Foundation and accepting a second, incompatible declaration.

import FoundationEssentials

public final class Bundle: @unchecked Sendable {
    public static let main = Bundle(uncheckedURL: URL(fileURLWithPath: "/"))

    public let bundleURL: URL

    public convenience init(for subject: AnyClass) {
        _ = subject
        self.init(uncheckedURL: Bundle.main.bundleURL)
    }

    public convenience init?(url: URL) {
        guard url.isFileURL else { return nil }
        self.init(path: url.path)
    }

    public init?(path: String) {
        var isDirectory = false
        guard !path.isEmpty,
              FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory),
              isDirectory else { return nil }
        bundleURL = URL(fileURLWithPath: path, isDirectory: true).standardized
    }

    private init(uncheckedURL: URL) {
        bundleURL = uncheckedURL
    }

    public var resourceURL: URL? {
        let contents = bundleURL.appendingPathComponent("Contents", isDirectory: true)
        var isDirectory = false
        if FileManager.default.fileExists(atPath: contents.path, isDirectory: &isDirectory),
           isDirectory {
            return contents.appendingPathComponent("Resources", isDirectory: true)
        }
        return bundleURL
    }
    public var resourcePath: String? { resourceURL?.path }

    public func url(forResource name: String?, withExtension extensionName: String?) -> URL? {
        guard let name, !name.isEmpty else { return nil }
        var candidate = resourceURL!.appendingPathComponent(name)
        if var extensionName, !extensionName.isEmpty {
            if extensionName.first == "." { extensionName.removeFirst() }
            if !extensionName.isEmpty { candidate.appendPathExtension(extensionName) }
        }
        return FileManager.default.fileExists(atPath: candidate.path) ? candidate : nil
    }
}

/// The production OpenUIKit module owns these identities. UserDefaults now
/// posts its Darwin-measured mutation notification through that boundary, so
/// the Foundation-hidden service fixture must expose the same minimal shape
/// instead of accidentally resolving Darwin Foundation's declarations.
public struct Notification {
    public struct Name: Hashable, Sendable {
        public let rawValue: String

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
    }
}

public final class NotificationCenter: @unchecked Sendable {
    public static let `default` = NotificationCenter()

    public func post(name: Notification.Name, object: Any?) {
        _ = name
        _ = object
    }
}

open class NSAttributedString {}
open class NSMutableAttributedString: NSAttributedString {}
open class NSParagraphStyle {}
open class NSMutableParagraphStyle: NSParagraphStyle {}
public struct NSUnderlineStyle: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
}

public final class Timer {}
public final class RunLoop {}

open class NSUserActivity {
    public init(activityType: String) {}
}
public typealias NSUserActivityPersistentIdentifier = String

public struct NSRange: Equatable, Hashable, Sendable {
    public var location: Int
    public var length: Int
    public init(location: Int, length: Int) {
        self.location = location
        self.length = length
    }
}
public typealias NSRangePointer = UnsafeMutablePointer<NSRange>
