#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Foundation

extension BADownload {
    /// Pinned `dotnet/macios` `BADownloadState`: `Failed = -1`, `Created = 0`,
    /// then `Waiting`, `Downloading`, `Finished`.
    public enum State: Int, Hashable, Sendable {
        case failed = -1
        case created = 0
        case waiting = 1
        case downloading = 2
        case finished = 3
    }

    /// Typed integer priority. Exact Darwin `BADownloaderPriorityMin` /
    /// `Default` / `Max` integers are not in the pinned corpus; Linux uses the
    /// conventional 0 / 5 / 10 ordering until an Apple-oracle observation lands.
    public struct Priority: RawRepresentable, Hashable, Sendable {
        public var rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public init(_ rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let min = Priority(rawValue: 0)
        public static let `default` = Priority(rawValue: 5)
        public static let max = Priority(rawValue: 10)
    }
}

/// A scheduled or in-flight background download. Linux never starts Apple's
/// download daemon; instances are local values.
open class BADownload: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    public fileprivate(set) var identifier: String
    public fileprivate(set) var uniqueIdentifier: String
    public fileprivate(set) var priority: Priority
    public fileprivate(set) var isEssential: Bool
    public fileprivate(set) var state: State

    public fileprivate(set) var applicationGroupIdentifier: String
    public fileprivate(set) var fileSize: Int
    public fileprivate(set) var request: URLRequest?

    init(
        identifier: String,
        uniqueIdentifier: String,
        priority: Priority,
        isEssential: Bool,
        state: State,
        applicationGroupIdentifier: String,
        fileSize: Int,
        request: URLRequest?
    ) {
        self.identifier = identifier
        self.uniqueIdentifier = uniqueIdentifier
        self.priority = priority
        self.isEssential = isEssential
        self.state = state
        self.applicationGroupIdentifier = applicationGroupIdentifier
        self.fileSize = fileSize
        self.request = request
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard let identifier = coder.decodeObject(of: NSString.self, forKey: "identifier") as String?,
              let uniqueIdentifier = coder.decodeObject(of: NSString.self, forKey: "uniqueIdentifier") as String?,
              let group = coder.decodeObject(of: NSString.self, forKey: "applicationGroupIdentifier") as String?
        else {
            return nil
        }
        let priorityValue = coder.decodeInteger(forKey: "priority")
        let stateValue = coder.decodeInteger(forKey: "state")
        guard let state = State(rawValue: stateValue) else {
            return nil
        }
        self.identifier = identifier
        self.uniqueIdentifier = uniqueIdentifier
        self.priority = Priority(rawValue: priorityValue)
        self.isEssential = coder.decodeBool(forKey: "isEssential")
        self.state = state
        self.applicationGroupIdentifier = group
        self.fileSize = coder.decodeInteger(forKey: "fileSize")
        if let urlString = coder.decodeObject(of: NSString.self, forKey: "url") as String?,
           let url = URL(string: urlString)
        {
            self.request = URLRequest(url: url)
        } else {
            self.request = nil
        }
        super.init()
    }

    open func encode(with coder: NSCoder) {
        coder.encode(identifier as NSString, forKey: "identifier")
        coder.encode(uniqueIdentifier as NSString, forKey: "uniqueIdentifier")
        coder.encode(priority.rawValue, forKey: "priority")
        coder.encode(isEssential, forKey: "isEssential")
        coder.encode(state.rawValue, forKey: "state")
        coder.encode(applicationGroupIdentifier as NSString, forKey: "applicationGroupIdentifier")
        coder.encode(fileSize, forKey: "fileSize")
        if let url = request?.url?.absoluteString {
            coder.encode(url as NSString, forKey: "url")
        }
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return BADownload(
            identifier: identifier,
            uniqueIdentifier: uniqueIdentifier,
            priority: priority,
            isEssential: isEssential,
            state: state,
            applicationGroupIdentifier: applicationGroupIdentifier,
            fileSize: fileSize,
            request: request
        )
    }

    open func removingEssential() -> Self {
        let copy = BADownload(
            identifier: identifier,
            uniqueIdentifier: UUID().uuidString,
            priority: priority,
            isEssential: false,
            state: state,
            applicationGroupIdentifier: applicationGroupIdentifier,
            fileSize: fileSize,
            request: request
        )
        guard let typed = copy as? Self else {
            fatalError("BADownload.removingEssential produced a different type")
        }
        return typed
    }
}

/// URL-backed download. Construction stores the request; scheduling still
/// fails closed because Linux has no Background Assets daemon.
open class BAURLDownload: BADownload, @unchecked Sendable {
    public convenience init(
        identifier: String,
        request: URLRequest,
        applicationGroupIdentifier: String
    ) {
        self.init(
            identifier: identifier,
            request: request,
            essential: false,
            fileSize: 0,
            applicationGroupIdentifier: applicationGroupIdentifier,
            priority: .default
        )
    }

    public convenience init(
        identifier: String,
        request: URLRequest,
        applicationGroupIdentifier: String,
        priority: BADownload.Priority
    ) {
        self.init(
            identifier: identifier,
            request: request,
            essential: false,
            fileSize: 0,
            applicationGroupIdentifier: applicationGroupIdentifier,
            priority: priority
        )
    }

    public convenience init(
        identifier: String,
        request: URLRequest,
        fileSize: Int,
        applicationGroupIdentifier: String
    ) {
        self.init(
            identifier: identifier,
            request: request,
            essential: false,
            fileSize: fileSize,
            applicationGroupIdentifier: applicationGroupIdentifier,
            priority: .default
        )
    }

    public init(
        identifier: String,
        request: URLRequest,
        essential: Bool,
        fileSize: Int,
        applicationGroupIdentifier: String,
        priority: BADownload.Priority
    ) {
        super.init(
            identifier: identifier,
            uniqueIdentifier: UUID().uuidString,
            priority: priority,
            isEssential: essential,
            state: .created,
            applicationGroupIdentifier: applicationGroupIdentifier,
            fileSize: fileSize,
            request: request
        )
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    open override func removingEssential() -> Self {
        guard let request else {
            return super.removingEssential()
        }
        let copy = BAURLDownload(
            identifier: identifier,
            request: request,
            essential: false,
            fileSize: fileSize,
            applicationGroupIdentifier: applicationGroupIdentifier,
            priority: priority
        )
        copy.state = state
        guard let typed = copy as? Self else {
            fatalError("BAURLDownload.removingEssential produced a different type")
        }
        return typed
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        guard let request else {
            return BAURLDownload(
                identifier: identifier,
                request: URLRequest(url: URL(string: "https://invalid.invalid/")!),
                essential: isEssential,
                fileSize: fileSize,
                applicationGroupIdentifier: applicationGroupIdentifier,
                priority: priority
            )
        }
        let copy = BAURLDownload(
            identifier: identifier,
            request: request,
            essential: isEssential,
            fileSize: fileSize,
            applicationGroupIdentifier: applicationGroupIdentifier,
            priority: priority
        )
        copy.uniqueIdentifier = uniqueIdentifier
        copy.state = state
        return copy
    }
}

/// Extension-host info. Linux has no BA extension process; remaining
/// allowances are `nil` (unrestricted / unknown) unless a host injects them.
open class BAAppExtensionInfo: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    public private(set) var restrictedDownloadSizeRemaining: Int?
    public private(set) var restrictedEssentialDownloadSizeRemaining: Int?

    @_spi(OpenUIKitHost)
    public init(
        restrictedDownloadSizeRemaining: Int? = nil,
        restrictedEssentialDownloadSizeRemaining: Int? = nil
    ) {
        self.restrictedDownloadSizeRemaining = restrictedDownloadSizeRemaining
        self.restrictedEssentialDownloadSizeRemaining = restrictedEssentialDownloadSizeRemaining
        super.init()
    }

    public required init?(coder: NSCoder) {
        if coder.containsValue(forKey: "restrictedDownloadSizeRemaining") {
            restrictedDownloadSizeRemaining = coder.decodeInteger(forKey: "restrictedDownloadSizeRemaining")
        } else {
            restrictedDownloadSizeRemaining = nil
        }
        if coder.containsValue(forKey: "restrictedEssentialDownloadSizeRemaining") {
            restrictedEssentialDownloadSizeRemaining = coder.decodeInteger(forKey: "restrictedEssentialDownloadSizeRemaining")
        } else {
            restrictedEssentialDownloadSizeRemaining = nil
        }
        super.init()
    }

    open func encode(with coder: NSCoder) {
        if let remaining = restrictedDownloadSizeRemaining {
            coder.encode(remaining, forKey: "restrictedDownloadSizeRemaining")
        }
        if let remaining = restrictedEssentialDownloadSizeRemaining {
            coder.encode(remaining, forKey: "restrictedEssentialDownloadSizeRemaining")
        }
    }
}
