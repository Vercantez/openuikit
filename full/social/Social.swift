@_exported import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Service type constants
//
// Payloads below are the commonly documented `com.apple.social.*` identifiers.
// They are **not** Apple-oracle observations on this host. Coverage lists them
// as `declared` until a central probe confirms the exact exported bytes.

public let SLServiceTypeTwitter = "com.apple.social.twitter"
public let SLServiceTypeFacebook = "com.apple.social.facebook"
public let SLServiceTypeSinaWeibo = "com.apple.social.sinaweibo"
public let SLServiceTypeTencentWeibo = "com.apple.social.tencentweibo"
public let SLServiceTypeLinkedIn = "com.apple.social.linkedin"

// MARK: - Public typealiases

public typealias SLComposeSheetConfigurationItemTapHandler = () -> Void
public typealias SLComposeViewControllerCompletionHandler = (SLComposeViewControllerResult) -> Void
public typealias SLRequestHandler = (Data?, HTTPURLResponse?, (any Error)?) -> Void

// MARK: - Enumerations
//
// Raw values follow NS_ENUM declaration order in the pinned overlay
// (`GET, POST, DELETE, PUT` and `cancelled, done`). Exact Darwin numeric
// ABI is still an oracle question.

public enum SLRequestMethod: Int, Sendable, Hashable {
    case GET = 0
    case POST = 1
    case DELETE = 2
    case PUT = 3
}

public enum SLComposeViewControllerResult: Int, Sendable, Hashable {
    case cancelled = 0
    case done = 1
}

// MARK: - Linux fail-closed error
//
// Not an Apple Social error domain. Public `perform` delivers this as
// Foundation `NSError`. The typed surface lives under `@_spi(OpenUIKitHost)`.

public let SocialLinuxErrorDomain = "Social.linux.fail-closed"

@_spi(OpenUIKitHost)
public enum SocialServiceError: Error, Hashable, Sendable {
    case appleServiceUnavailable
    case accountRequiresOAuth
    case invalidMultipartMetadata
    case missingURL
    case unsupportedParameterValue

    public var nsError: NSError {
        let code: Int
        let description: String
        switch self {
        case .appleServiceUnavailable:
            code = 1
            description = "Linux Social has no Apple social-network host"
        case .accountRequiresOAuth:
            code = 2
            description = "SLRequest.account is set but Linux has no OAuth signer"
        case .invalidMultipartMetadata:
            code = 3
            description = "multipart field metadata contains CR, LF, or quote"
        case .missingURL:
            code = 4
            description = "SLRequest.url is nil"
        case .unsupportedParameterValue:
            code = 5
            description = "parameter values must be String or NSNumber"
        }
        return NSError(
            domain: SocialLinuxErrorDomain,
            code: code,
            userInfo: [NSLocalizedDescriptionKey: description]
        )
    }
}

func socialFailClosedError(_ error: SocialServiceError) -> NSError {
    error.nsError
}

let socialPerformQueue = DispatchQueue(
    label: "Social.SLRequest.perform",
    qos: .utility
)

private struct SocialUncheckedWork: @unchecked Sendable {
    let body: () -> Void
}

func socialDeliverPerform(_ body: @escaping () -> Void) {
    let work = SocialUncheckedWork(body: body)
    socialPerformQueue.async {
        work.body()
    }
}

// MARK: - Multipart helpers (non-Apple; SPI)

@_spi(OpenUIKitHost)
public struct MultipartPart: Equatable {
    public var data: Data
    public var name: String
    public var type: String
    public var filename: String?

    public init(data: Data, name: String, type: String, filename: String?) {
        self.data = data
        self.name = name
        self.type = type
        self.filename = filename
    }
}

func socialMultipartMetadataIsSafe(_ value: String) -> Bool {
    for scalar in value.unicodeScalars {
        if scalar == "\r" || scalar == "\n" || scalar == "\"" {
            return false
        }
    }
    return true
}

func socialBoundaryCollides(_ boundary: String, corpus: [Data]) -> Bool {
    guard let needle = boundary.data(using: .utf8), !needle.isEmpty else {
        return true
    }
    for blob in corpus {
        if blob.range(of: needle) != nil {
            return true
        }
    }
    return false
}

func socialMultipartCorpus(
    parameters: [AnyHashable: Any],
    parts: [MultipartPart]
) -> [Data] {
    var corpus: [Data] = []
    for (key, value) in parameters {
        corpus.append(Data(String(describing: key).utf8))
        corpus.append(Data(String(describing: value).utf8))
    }
    for part in parts {
        corpus.append(Data(part.name.utf8))
        corpus.append(Data(part.type.utf8))
        if let filename = part.filename {
            corpus.append(Data(filename.utf8))
        }
        corpus.append(part.data)
    }
    return corpus
}

func socialMakeCollisionCheckedBoundary(corpus: [Data]) -> String {
    while true {
        let candidate = SocialHostControl.nextBoundaryCandidate()
        if !socialBoundaryCollides(candidate, corpus: corpus) {
            return candidate
        }
    }
}

// MARK: - Isolated-host control
//
// Not part of Apple's public Social module. Ordinary `import Social` clients
// do not see these names.

@_spi(OpenUIKitHost)
public enum SocialHostControl {
    private static let lock = NSLock()
    private static var candidateSource: () -> String = SocialHostControl.defaultBoundaryCandidate

    public static func defaultBoundaryCandidate() -> String {
        UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }

    public static func nextBoundaryCandidate() -> String {
        lock.lock()
        let source = candidateSource
        lock.unlock()
        return source()
    }

    public static func setBoundaryCandidateSource(_ source: @escaping () -> String) {
        lock.lock()
        candidateSource = source
        lock.unlock()
    }

    public static func resetBoundaryCandidateSource() {
        setBoundaryCandidateSource(defaultBoundaryCandidate)
    }

    public static func enqueuePerformProbe(_ body: @escaping () -> Void) {
        socialDeliverPerform(body)
    }

    @MainActor
    public static func makeComposeViewController(serviceType: String) -> SLComposeViewController {
        SLComposeViewController(isolatedHostServiceType: serviceType)
    }

    @MainActor
    public static func invokeCompletion(
        _ controller: SLComposeViewController,
        result: SLComposeViewControllerResult
    ) {
        controller.invokeCompletionHandlerForIsolatedHost(result)
    }

    public static func makeAccountFixture() -> ACAccount {
        #if canImport(Accounts)
        // Canonical Accounts.ACAccount has no zero-argument initializer.
        // Isolated host compiles the fallback ACAccount in SocialHostTypes.
        fatalError("Accounts.ACAccount fixture construction is an integration concern")
        #else
        ACAccount()
        #endif
    }

    public static var isStandaloneUnitFixture: Bool {
        #if canImport(UIKit) && canImport(Accounts)
        return false
        #else
        return true
        #endif
    }
}
