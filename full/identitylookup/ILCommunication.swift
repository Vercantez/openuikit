import Foundation

/// Base class for an incoming call or SMS/MMS that Identity Lookup can
/// classify. Linux stores sender and timestamp; there is no telephony
/// daemon.
open class ILCommunication: NSObject, NSSecureCoding {
    public private(set) var sender: String?
    public private(set) var dateReceived: Date

    public static var supportsSecureCoding: Bool { true }

    public init(sender: String?, dateReceived: Date) {
        self.sender = sender
        self.dateReceived = dateReceived
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.sender = IdentityLookupLinux.decodeString(coder, key: "linuxSender")
        guard let date = IdentityLookupLinux.decodeDate(coder, key: "linuxDateReceived") else {
            return nil
        }
        self.dateReceived = date
        super.init()
    }

    open func encode(with coder: NSCoder) {
        IdentityLookupLinux.encodeString(sender, coder, key: "linuxSender")
        IdentityLookupLinux.encodeDate(dateReceived, coder, key: "linuxDateReceived")
    }
}

/// An incoming call offered to a Call Classification extension.
open class ILCallCommunication: ILCommunication {
    public override init(sender: String?, dateReceived: Date) {
        super.init(sender: sender, dateReceived: dateReceived)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

/// An incoming SMS/MMS offered to a Message Classification extension.
open class ILMessageCommunication: ILCommunication {
    public private(set) var messageBody: String?

    public init(sender: String?, dateReceived: Date, messageBody: String?) {
        self.messageBody = messageBody
        super.init(sender: sender, dateReceived: dateReceived)
    }

    public required init?(coder: NSCoder) {
        self.messageBody = IdentityLookupLinux.decodeString(coder, key: "linuxMessageBody")
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        IdentityLookupLinux.encodeString(messageBody, coder, key: "linuxMessageBody")
    }
}
