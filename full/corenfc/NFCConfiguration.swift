import Foundation

open class NFCTagCommandConfiguration: NSObject {
    public var maximumRetries: Int
    public var retryInterval: TimeInterval

    public override init() {
        self.maximumRetries = 0
        self.retryInterval = 0
        super.init()
    }

    public init(maximumRetries: Int, retryInterval: TimeInterval) {
        self.maximumRetries = maximumRetries
        self.retryInterval = retryInterval
        super.init()
    }
}

public class NFCISO15693CustomCommandConfiguration: NFCTagCommandConfiguration {
    public var manufacturerCode: Int
    public var customCommandCode: Int
    public var requestParameters: Data

    public init(manufacturerCode: Int, customCommandCode: Int, requestParameters: Data?) {
        self.manufacturerCode = manufacturerCode
        self.customCommandCode = customCommandCode
        self.requestParameters = requestParameters ?? Data()
        super.init()
    }

    public init(
        manufacturerCode: Int,
        customCommandCode: Int,
        requestParameters: Data?,
        maximumRetries: Int,
        retryInterval: TimeInterval
    ) {
        self.manufacturerCode = manufacturerCode
        self.customCommandCode = customCommandCode
        self.requestParameters = requestParameters ?? Data()
        super.init(maximumRetries: maximumRetries, retryInterval: retryInterval)
    }
}

public class NFCISO15693ReadMultipleBlocksConfiguration: NFCTagCommandConfiguration {
    public var range: NSRange
    public var chunkSize: Int

    public init(range: NSRange, chunkSize: Int) {
        self.range = range
        self.chunkSize = chunkSize
        super.init()
    }

    public init(range: NSRange, chunkSize: Int, maximumRetries: Int, retryInterval: TimeInterval) {
        self.range = range
        self.chunkSize = chunkSize
        super.init(maximumRetries: maximumRetries, retryInterval: retryInterval)
    }
}

public class NFCVASCommandConfiguration: NSObject {
    public enum Mode: Int, Sendable, Hashable {
        case urlOnly = 0
        case normal = 1

        public static var VASModeURLOnly: Mode { .urlOnly }
        public static var VASModeNormal: Mode { .normal }
    }

    public var mode: Mode
    public var passTypeIdentifier: String
    public var url: URL?

    public init(vasMode mode: Mode, passTypeIdentifier: String, url: URL?) {
        self.mode = mode
        self.passTypeIdentifier = passTypeIdentifier
        self.url = url
        super.init()
    }

    public init(VASMode mode: Mode, passTypeIdentifier: String, url: URL?) {
        self.mode = mode
        self.passTypeIdentifier = passTypeIdentifier
        self.url = url
        super.init()
    }
}

public class NFCVASResponse: NSObject {
    /// ISO 7816-4 status words recorded in the pinned macios bindings
    /// (success = 0x9000, etc.). Not measured on Apple VAS hardware.
    public enum ErrorCode: Int, Sendable, Hashable {
        case success = 36864
        case dataNotFound = 27267
        case dataNotActivated = 25223
        case wrongParameters = 27392
        case wrongLCField = 26368
        case userIntervention = 27012
        case incorrectData = 27264
        case unsupportedApplicationVersion = 25408

        public static var VASErrorCodeSuccess: ErrorCode { .success }
        public static var VASErrorCodeDataNotFound: ErrorCode { .dataNotFound }
        public static var VASErrorCodeDataNotActivated: ErrorCode { .dataNotActivated }
        public static var VASErrorCodeWrongParameters: ErrorCode { .wrongParameters }
        public static var VASErrorCodeWrongLCField: ErrorCode { .wrongLCField }
        public static var VASErrorCodeUserIntervention: ErrorCode { .userIntervention }
        public static var VASErrorCodeIncorrectData: ErrorCode { .incorrectData }
        public static var VASErrorCodeUnsupportedApplicationVersion: ErrorCode {
            .unsupportedApplicationVersion
        }
    }

    public let status: ErrorCode
    public let vasData: Data
    public let mobileToken: Data

    public init(status: ErrorCode, vasData: Data, mobileToken: Data) {
        self.status = status
        self.vasData = vasData
        self.mobileToken = mobileToken
        super.init()
    }
}
