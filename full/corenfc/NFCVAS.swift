import Foundation

open class NFCVASCommandConfiguration: NSObject {
    public enum Mode: Int, Hashable, Sendable {
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

open class NFCVASResponse: NSObject {
    public enum ErrorCode: Int, Hashable, Sendable {
        case success = 0x9000
        case dataNotFound = 0x6A83
        case dataNotActivated = 0x6287
        case wrongParameters = 0x6B00
        case wrongLCField = 0x6700
        case userIntervention = 0x6984
        case incorrectData = 0x6A80
        case unsupportedApplicationVersion = 0x6A81

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
