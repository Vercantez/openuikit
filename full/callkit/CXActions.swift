import Foundation

open class CXAction: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    public let uuid: UUID
    public private(set) var isComplete: Bool
    public let timeoutDate: Date

    private let stateLock = NSLock()
    weak var portableProvider: CXProvider?
    private var portableSucceeded: Bool?

    @_spi(OpenUIKitHost)
    public var _portableDidFulfill: Bool? { portableSucceeded }

    public override init() {
        self.uuid = UUID()
        self.isComplete = false
        self.timeoutDate = Date.distantFuture
        super.init()
    }

    public init(uuid: UUID, timeoutDate: Date = .distantFuture) {
        self.uuid = uuid
        self.isComplete = false
        self.timeoutDate = timeoutDate
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard
            let uuidString = coder.decodeObject(of: NSString.self, forKey: "uuid") as String?
                ?? coder.decodeObject(forKey: "uuid") as? String,
            let uuid = UUID(uuidString: uuidString)
        else {
            return nil
        }
        self.uuid = uuid
        self.isComplete = coder.decodeBool(forKey: "complete")
        self.timeoutDate =
            (coder.decodeObject(of: NSDate.self, forKey: "timeoutDate") as Date?)
            ?? Date.distantFuture
        super.init()
    }

    open func encode(with coder: NSCoder) {
        coder.encode(uuid.uuidString as NSString, forKey: "uuid")
        coder.encode(isComplete, forKey: "complete")
        coder.encode(timeoutDate as NSDate, forKey: "timeoutDate")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = CXAction(uuid: uuid, timeoutDate: timeoutDate)
        copy.isComplete = isComplete
        return copy
    }

    open func fulfill() {
        complete(success: true)
    }

    open func fail() {
        complete(success: false)
    }

    func portableReject() {
        complete(success: false, notify: false)
    }

    private func complete(success: Bool, notify: Bool = true) {
        stateLock.lock()
        if isComplete {
            stateLock.unlock()
            return
        }
        isComplete = true
        portableSucceeded = success
        let provider = portableProvider
        stateLock.unlock()
        if notify {
            provider?.portableActionDidComplete(self, success: success)
        }
    }
}

open class CXCallAction: CXAction, @unchecked Sendable {
    public let callUUID: UUID

    public init(call callUUID: UUID) {
        self.callUUID = callUUID
        super.init()
    }

    public convenience init(callUUID: UUID) {
        self.init(call: callUUID)
    }

    public required init?(coder: NSCoder) {
        guard
            let uuidString = coder.decodeObject(of: NSString.self, forKey: "callUUID") as String?
                ?? coder.decodeObject(forKey: "callUUID") as? String,
            let callUUID = UUID(uuidString: uuidString)
        else {
            return nil
        }
        self.callUUID = callUUID
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(callUUID.uuidString as NSString, forKey: "callUUID")
    }

    public override func copy(with zone: NSZone? = nil) -> Any {
        CXCallAction(call: callUUID)
    }
}

open class CXAnswerCallAction: CXCallAction, @unchecked Sendable {
    public private(set) var dateConnected: Date?

    public override init(call callUUID: UUID) {
        super.init(call: callUUID)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    open func fulfill(withDateConnected dateConnected: Date) {
        self.dateConnected = dateConnected
        fulfill()
    }
}

open class CXEndCallAction: CXCallAction, @unchecked Sendable {
    public private(set) var dateEnded: Date?

    public override init(call callUUID: UUID) {
        super.init(call: callUUID)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    open func fulfill(withDateEnded dateEnded: Date) {
        self.dateEnded = dateEnded
        fulfill()
    }
}

open class CXStartCallAction: CXCallAction, @unchecked Sendable {
    public var handle: CXHandle {
        didSet { handle = (handle.copy() as? CXHandle) ?? handle }
    }
    public var contactIdentifier: String?
    public var isVideo: Bool

    public init(call callUUID: UUID, handle: CXHandle) {
        self.handle = (handle.copy() as? CXHandle) ?? handle
        self.contactIdentifier = nil
        self.isVideo = false
        super.init(call: callUUID)
    }

    public convenience init(callUUID: UUID, handle: CXHandle) {
        self.init(call: callUUID, handle: handle)
    }

    public required init?(coder: NSCoder) {
        guard let handle = coder.decodeObject(of: CXHandle.self, forKey: "handle") else {
            return nil
        }
        self.handle = handle
        self.contactIdentifier =
            coder.decodeObject(of: NSString.self, forKey: "contactIdentifier") as String?
            ?? coder.decodeObject(forKey: "contactIdentifier") as? String
        self.isVideo = coder.decodeBool(forKey: "video")
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(handle, forKey: "handle")
        if let contactIdentifier {
            coder.encode(contactIdentifier as NSString, forKey: "contactIdentifier")
        }
        coder.encode(isVideo, forKey: "video")
    }

    open func fulfill(withDateStarted dateStarted: Date) {
        _ = dateStarted
        fulfill()
    }
}

open class CXSetHeldCallAction: CXCallAction, @unchecked Sendable {
    public var isOnHold: Bool

    public init(call callUUID: UUID, onHold: Bool) {
        self.isOnHold = onHold
        super.init(call: callUUID)
    }

    public convenience init(callUUID: UUID, onHold: Bool) {
        self.init(call: callUUID, onHold: onHold)
    }

    public required init?(coder: NSCoder) {
        self.isOnHold = coder.decodeBool(forKey: "onHold")
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(isOnHold, forKey: "onHold")
    }
}

open class CXSetMutedCallAction: CXCallAction, @unchecked Sendable {
    public var isMuted: Bool

    public init(call callUUID: UUID, muted: Bool) {
        self.isMuted = muted
        super.init(call: callUUID)
    }

    public convenience init(callUUID: UUID, muted: Bool) {
        self.init(call: callUUID, muted: muted)
    }

    public required init?(coder: NSCoder) {
        self.isMuted = coder.decodeBool(forKey: "muted")
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(isMuted, forKey: "muted")
    }
}

open class CXSetGroupCallAction: CXCallAction, @unchecked Sendable {
    public var callUUIDToGroupWith: UUID?

    public init(call callUUID: UUID, callUUIDToGroupWith: UUID?) {
        self.callUUIDToGroupWith = callUUIDToGroupWith
        super.init(call: callUUID)
    }

    public convenience init(callUUID: UUID, callUUIDToGroupWith: UUID?) {
        self.init(call: callUUID, callUUIDToGroupWith: callUUIDToGroupWith)
    }

    public required init?(coder: NSCoder) {
        if let grouped = coder.decodeObject(of: NSString.self, forKey: "groupUUID") as String?
            ?? coder.decodeObject(forKey: "groupUUID") as? String
        {
            self.callUUIDToGroupWith = UUID(uuidString: grouped)
        } else {
            self.callUUIDToGroupWith = nil
        }
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        if let callUUIDToGroupWith {
            coder.encode(callUUIDToGroupWith.uuidString as NSString, forKey: "groupUUID")
        }
    }
}

open class CXPlayDTMFCallAction: CXCallAction, @unchecked Sendable {
    public enum ActionType: Int, Equatable, Hashable, Sendable {
        case singleTone = 1
        case softPause = 2
        case hardPause = 3
    }

    public var digits: String
    public var type: ActionType

    public init(call callUUID: UUID, digits: String, type: ActionType) {
        self.digits = digits
        self.type = type
        super.init(call: callUUID)
    }

    public convenience init(callUUID: UUID, digits: String, type: ActionType) {
        self.init(call: callUUID, digits: digits, type: type)
    }

    public required init?(coder: NSCoder) {
        self.digits =
            coder.decodeObject(of: NSString.self, forKey: "digits") as String?
            ?? coder.decodeObject(forKey: "digits") as? String
            ?? ""
        self.type = ActionType(rawValue: coder.decodeInteger(forKey: "type")) ?? .singleTone
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(digits as NSString, forKey: "digits")
        coder.encode(type.rawValue, forKey: "type")
    }
}

open class CXSetTranslatingCallAction: CXCallAction, @unchecked Sendable {
    public let isTranslating: Bool
    public let localLanguage: String
    public let remoteLanguage: String
    public private(set) var translationEngine: CXTranslationEngine?

    public init(
        call uuid: UUID,
        isTranslating: Bool,
        localLanguage: String,
        remoteLanguage: String
    ) {
        self.isTranslating = isTranslating
        self.localLanguage = localLanguage
        self.remoteLanguage = remoteLanguage
        super.init(call: uuid)
    }

    public convenience init(
        callUUID uuid: UUID,
        isTranslating: Bool,
        localLanguage: String,
        remoteLanguage: String
    ) {
        self.init(
            call: uuid,
            isTranslating: isTranslating,
            localLanguage: localLanguage,
            remoteLanguage: remoteLanguage
        )
    }

    public required init?(coder: NSCoder) {
        self.isTranslating = coder.decodeBool(forKey: "isTranslating")
        self.localLanguage =
            coder.decodeObject(of: NSString.self, forKey: "localLanguage") as String?
            ?? coder.decodeObject(forKey: "localLanguage") as? String
            ?? ""
        self.remoteLanguage =
            coder.decodeObject(of: NSString.self, forKey: "remoteLanguage") as String?
            ?? coder.decodeObject(forKey: "remoteLanguage") as? String
            ?? ""
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(isTranslating, forKey: "isTranslating")
        coder.encode(localLanguage as NSString, forKey: "localLanguage")
        coder.encode(remoteLanguage as NSString, forKey: "remoteLanguage")
    }

    open func fulfill(using translationEngine: CXTranslationEngine) {
        self.translationEngine = translationEngine
        fulfill()
    }
}

open class CXTransaction: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    public let uuid: UUID
    private var storedActions: [CXAction]

    public var actions: [CXAction] { storedActions }

    public var isComplete: Bool {
        storedActions.allSatisfy(\.isComplete)
    }

    public override init() {
        self.uuid = UUID()
        self.storedActions = []
        super.init()
    }

    public init(actions: [CXAction]) {
        self.uuid = UUID()
        self.storedActions = actions
        super.init()
    }

    public convenience init(action: CXAction) {
        self.init(actions: [action])
    }

    public required init?(coder: NSCoder) {
        guard
            let uuidString = coder.decodeObject(of: NSString.self, forKey: "uuid") as String?
                ?? coder.decodeObject(forKey: "uuid") as? String,
            let uuid = UUID(uuidString: uuidString)
        else {
            return nil
        }
        self.uuid = uuid
        self.storedActions =
            (coder.decodeObject(of: [NSArray.self, CXAction.self], forKey: "actions") as? [CXAction])
            ?? []
        super.init()
    }

    open func encode(with coder: NSCoder) {
        coder.encode(uuid.uuidString as NSString, forKey: "uuid")
        coder.encode(storedActions as NSArray, forKey: "actions")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        CXTransaction(actions: storedActions)
    }

    open func addAction(_ action: CXAction) {
        storedActions.append(action)
    }
}
