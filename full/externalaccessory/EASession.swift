import Foundation

/// Session used to exchange bytes with a connected accessory.
///
/// Apple's `-init` is unsupported. `init(accessory:forProtocol:)` returns
/// `nil` on Linux: there is no MFi protocol transport and this port does
/// not invent input/output streams. Host tests may construct a session
/// with nil streams through `@_spi(OpenUIKitHost)` to exercise getters.
open class EASession: NSObject {
    private var _accessory: EAAccessory?
    private var _protocolString: String?
    private var _inputStream: InputStream?
    private var _outputStream: OutputStream?

    public var accessory: EAAccessory? { _accessory }
    public var protocolString: String? { _protocolString }
    public var inputStream: InputStream? { _inputStream }
    public var outputStream: OutputStream? { _outputStream }

    @available(*, unavailable, message: "Use init(accessory:forProtocol:)")
    public override init() {
        fatalError("EASession.init is unsupported")
    }

    /// Always `nil` on Linux. A connected MFi accessory and protocol
    /// transport are required on Apple; this environment has neither.
    public init?(accessory: EAAccessory, forProtocol protocolString: String) {
        _ = accessory
        _ = protocolString
        return nil
    }

    @_spi(OpenUIKitHost)
    public init(hostAccessory accessory: EAAccessory, protocolString: String) {
        _accessory = accessory
        _protocolString = protocolString
        _inputStream = nil
        _outputStream = nil
        super.init()
    }
}
