import Foundation

/// Base class for user-driven junk/not-junk classification requests.
open class ILClassificationRequest: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init()
        _ = coder
    }

    open func encode(with coder: NSCoder) {
        _ = coder
    }
}

/// Payload of incoming calls the user is classifying.
open class ILCallClassificationRequest: ILClassificationRequest {
    public private(set) var callCommunications: [ILCallCommunication]

    public init(callCommunications: [ILCallCommunication]) {
        self.callCommunications = callCommunications
        super.init()
    }

    public required init?(coder: NSCoder) {
        let count = IdentityLookupLinux.decodeInt(coder, key: "linuxCallCount") ?? 0
        var items: [ILCallCommunication] = []
        items.reserveCapacity(count)
        for index in 0..<count {
            guard let item = coder.decodeObject(
                of: ILCallCommunication.self,
                forKey: "linuxCall[\(index)]"
            ) else {
                return nil
            }
            items.append(item)
        }
        self.callCommunications = items
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        IdentityLookupLinux.encodeInt(callCommunications.count, coder, key: "linuxCallCount")
        for (index, item) in callCommunications.enumerated() {
            coder.encode(item, forKey: "linuxCall[\(index)]")
        }
    }
}

/// Payload of incoming messages the user is classifying.
open class ILMessageClassificationRequest: ILClassificationRequest {
    public private(set) var messageCommunications: [ILMessageCommunication]

    public init(messageCommunications: [ILMessageCommunication]) {
        self.messageCommunications = messageCommunications
        super.init()
    }

    public required init?(coder: NSCoder) {
        let count = IdentityLookupLinux.decodeInt(coder, key: "linuxMessageCount") ?? 0
        var items: [ILMessageCommunication] = []
        items.reserveCapacity(count)
        for index in 0..<count {
            guard let item = coder.decodeObject(
                of: ILMessageCommunication.self,
                forKey: "linuxMessage[\(index)]"
            ) else {
                return nil
            }
            items.append(item)
        }
        self.messageCommunications = items
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        IdentityLookupLinux.encodeInt(messageCommunications.count, coder, key: "linuxMessageCount")
        for (index, item) in messageCommunications.enumerated() {
            coder.encode(item, forKey: "linuxMessage[\(index)]")
        }
    }
}

/// User-selected classification result for a reported communication.
open class ILClassificationResponse: NSObject, NSSecureCoding {
    public private(set) var action: ILClassificationAction
    public var userString: String?
    public var userInfo: [String: Any]?

    public static var supportsSecureCoding: Bool { true }

    public init(action: ILClassificationAction) {
        self.action = action
        super.init()
    }

    public convenience init(classificationAction action: ILClassificationAction) {
        self.init(action: action)
    }

    @available(*, unavailable)
    public override init() {
        fatalError("ILClassificationResponse requires init(action:)")
    }

    public required init?(coder: NSCoder) {
        guard let raw = IdentityLookupLinux.decodeInt(coder, key: "linuxAction"),
              let action = ILClassificationAction(rawValue: raw) else {
            return nil
        }
        self.action = action
        self.userString = IdentityLookupLinux.decodeString(coder, key: "linuxUserString")
        super.init()
    }

    open func encode(with coder: NSCoder) {
        IdentityLookupLinux.encodeInt(action.rawValue, coder, key: "linuxAction")
        IdentityLookupLinux.encodeString(userString, coder, key: "linuxUserString")
    }
}
