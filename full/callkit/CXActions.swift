import Foundation

open class CXAction: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public let uuid: UUID
    public private(set) var isComplete = false
    public private(set) var timeoutDate: Date
    public private(set) var failed = false
    weak var owningTransaction: CXTransaction?
    weak var owningProvider: CXProvider?

    public override init() {
        self.uuid = UUID()
        self.timeoutDate = Date.distantFuture
        super.init()
    }

    public required init?(coder aDecoder: NSCoder) {
        guard let uuidString = aDecoder.decodeObject(of: NSString.self, forKey: "uuid") as String?,
              let decoded = UUID(uuidString: uuidString)
        else {
            return nil
        }
        self.uuid = decoded
        self.timeoutDate = (aDecoder.decodeObject(of: NSDate.self, forKey: "timeoutDate") as Date?)
            ?? Date.distantFuture
        self.isComplete = aDecoder.decodeBool(forKey: "isComplete")
        super.init()
    }

    open func encode(with coder: NSCoder) {
        coder.encode(uuid.uuidString as NSString, forKey: "uuid")
        coder.encode(timeoutDate as NSDate, forKey: "timeoutDate")
        coder.encode(isComplete, forKey: "isComplete")
    }

    public static var supportsSecureCoding: Bool { true }

    open func copy(with zone: NSZone? = nil) -> Any {
        let copy = CXAction()
        copy.timeoutDate = timeoutDate
        return copy
    }

    open func fulfill() {
        complete(failed: false)
    }

    open func fail() {
        complete(failed: true)
    }

    func complete(failed: Bool) {
        guard !isComplete else { return }
        isComplete = true
        self.failed = failed
        owningTransaction?.actionDidComplete(self)
    }
}

open class CXCallAction: CXAction, @unchecked Sendable {
    public let callUUID: UUID

    public init(callUUID: UUID) {
        self.callUUID = callUUID
        super.init()
    }

    public convenience init(call callUUID: UUID) {
        self.init(callUUID: callUUID)
    }

    public required init?(coder aDecoder: NSCoder) {
        guard let uuidString = aDecoder.decodeObject(of: NSString.self, forKey: "callUUID") as String?,
              let decoded = UUID(uuidString: uuidString)
        else {
            return nil
        }
        self.callUUID = decoded
        super.init(coder: aDecoder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(callUUID.uuidString as NSString, forKey: "callUUID")
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        CXCallAction(callUUID: callUUID)
    }
}

open class CXStartCallAction: CXCallAction, @unchecked Sendable {
    @NSCopying public var handle: CXHandle
    public var contactIdentifier: String?
    public var isVideo = false
    public private(set) var dateStarted: Date?

    public init(callUUID: UUID, handle: CXHandle) {
        self.handle = handle
        super.init(callUUID: callUUID)
    }

    public convenience init(call callUUID: UUID, handle: CXHandle) {
        self.init(callUUID: callUUID, handle: handle)
    }

    public required init?(coder aDecoder: NSCoder) {
        guard let handle = aDecoder.decodeObject(of: CXHandle.self, forKey: "handle") else {
            return nil
        }
        self.handle = handle
        self.contactIdentifier = aDecoder.decodeObject(of: NSString.self, forKey: "contactIdentifier") as String?
        self.isVideo = aDecoder.decodeBool(forKey: "isVideo")
        super.init(coder: aDecoder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(handle, forKey: "handle")
        if let contactIdentifier {
            coder.encode(contactIdentifier as NSString, forKey: "contactIdentifier")
        }
        coder.encode(isVideo, forKey: "isVideo")
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        let copy = CXStartCallAction(callUUID: callUUID, handle: handle)
        copy.contactIdentifier = contactIdentifier
        copy.isVideo = isVideo
        return copy
    }

    public func fulfill(withDateStarted dateStarted: Date) {
        self.dateStarted = dateStarted
        if let provider = owningProvider {
            _ = CallKitRegistry.shared.applyStart(
                uuid: callUUID,
                provider: provider,
                handle: handle,
                video: isVideo
            )
            CallKitRegistry.shared.notifyObservers(callUUID: callUUID)
        }
        complete(failed: false)
    }

    open override func fulfill() {
        fulfill(withDateStarted: Date())
    }

    open override func fail() {
        CallKitRegistry.shared.releaseReservations([callUUID])
        complete(failed: true)
    }
}

open class CXAnswerCallAction: CXCallAction, @unchecked Sendable {
    public private(set) var dateConnected: Date?

    public func fulfill(withDateConnected dateConnected: Date) {
        self.dateConnected = dateConnected
        _ = CallKitRegistry.shared.applyAnswer(uuid: callUUID, connectedAt: dateConnected)
        CallKitRegistry.shared.notifyObservers(callUUID: callUUID)
        complete(failed: false)
    }

    open override func fulfill() {
        fulfill(withDateConnected: Date())
    }
}

open class CXEndCallAction: CXCallAction, @unchecked Sendable {
    public private(set) var dateEnded: Date?

    public func fulfill(withDateEnded dateEnded: Date) {
        self.dateEnded = dateEnded
        _ = CallKitRegistry.shared.applyEnd(uuid: callUUID, endedAt: dateEnded)
        CallKitRegistry.shared.notifyObservers(callUUID: callUUID)
        complete(failed: false)
    }

    open override func fulfill() {
        fulfill(withDateEnded: Date())
    }
}

open class CXSetHeldCallAction: CXCallAction, @unchecked Sendable {
    public var isOnHold: Bool

    public init(callUUID: UUID, onHold: Bool) {
        self.isOnHold = onHold
        super.init(callUUID: callUUID)
    }

    public convenience init(call callUUID: UUID, onHold: Bool) {
        self.init(callUUID: callUUID, onHold: onHold)
    }

    public required init?(coder aDecoder: NSCoder) {
        self.isOnHold = aDecoder.decodeBool(forKey: "onHold")
        super.init(coder: aDecoder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(isOnHold, forKey: "onHold")
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        CXSetHeldCallAction(callUUID: callUUID, onHold: isOnHold)
    }

    open override func fulfill() {
        _ = CallKitRegistry.shared.applyHold(uuid: callUUID, onHold: isOnHold)
        CallKitRegistry.shared.notifyObservers(callUUID: callUUID)
        complete(failed: false)
    }
}

open class CXSetMutedCallAction: CXCallAction, @unchecked Sendable {
    public var isMuted: Bool

    public init(callUUID: UUID, muted: Bool) {
        self.isMuted = muted
        super.init(callUUID: callUUID)
    }

    public convenience init(call callUUID: UUID, muted: Bool) {
        self.init(callUUID: callUUID, muted: muted)
    }

    public required init?(coder aDecoder: NSCoder) {
        self.isMuted = aDecoder.decodeBool(forKey: "muted")
        super.init(coder: aDecoder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(isMuted, forKey: "muted")
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        CXSetMutedCallAction(callUUID: callUUID, muted: isMuted)
    }

    open override func fulfill() {
        _ = CallKitRegistry.shared.applyMute(uuid: callUUID, muted: isMuted)
        CallKitRegistry.shared.notifyObservers(callUUID: callUUID)
        complete(failed: false)
    }
}

open class CXSetGroupCallAction: CXCallAction, @unchecked Sendable {
    public var callUUIDToGroupWith: UUID?

    public init(callUUID: UUID, callUUIDToGroupWith: UUID?) {
        self.callUUIDToGroupWith = callUUIDToGroupWith
        super.init(callUUID: callUUID)
    }

    public convenience init(call callUUID: UUID, callUUIDToGroupWith: UUID?) {
        self.init(callUUID: callUUID, callUUIDToGroupWith: callUUIDToGroupWith)
    }

    public required init?(coder aDecoder: NSCoder) {
        if let grouped = aDecoder.decodeObject(of: NSString.self, forKey: "grouped") as String? {
            self.callUUIDToGroupWith = UUID(uuidString: grouped)
        }
        super.init(coder: aDecoder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        if let grouped = callUUIDToGroupWith {
            coder.encode(grouped.uuidString as NSString, forKey: "grouped")
        }
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        CXSetGroupCallAction(callUUID: callUUID, callUUIDToGroupWith: callUUIDToGroupWith)
    }

    open override func fulfill() {
        _ = CallKitRegistry.shared.applyGroup(uuid: callUUID, with: callUUIDToGroupWith)
        CallKitRegistry.shared.notifyObservers(callUUID: callUUID)
        complete(failed: false)
    }
}

open class CXPlayDTMFCallAction: CXCallAction, @unchecked Sendable {
    public enum ActionType: Int, Hashable, Sendable {
        case singleTone = 1
        case softPause = 2
        case hardPause = 3
    }

    public var digits: String
    public var type: ActionType

    public init(callUUID: UUID, digits: String, type: ActionType) {
        self.digits = digits
        self.type = type
        super.init(callUUID: callUUID)
    }

    public convenience init(call callUUID: UUID, digits: String, type: ActionType) {
        self.init(callUUID: callUUID, digits: digits, type: type)
    }

    public required init?(coder aDecoder: NSCoder) {
        self.digits = (aDecoder.decodeObject(of: NSString.self, forKey: "digits") as String?) ?? ""
        self.type = ActionType(rawValue: aDecoder.decodeInteger(forKey: "type")) ?? .singleTone
        super.init(coder: aDecoder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(digits as NSString, forKey: "digits")
        coder.encode(type.rawValue, forKey: "type")
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        CXPlayDTMFCallAction(callUUID: callUUID, digits: digits, type: type)
    }

    open override func fulfill() {
        complete(failed: false)
    }
}

open class CXSetTranslatingCallAction: CXCallAction, @unchecked Sendable {
    public let isTranslating: Bool
    public let localLanguage: String
    public let remoteLanguage: String
    public private(set) var translationEngine: CXTranslationEngine?

    public init(
        callUUID uuid: UUID,
        isTranslating: Bool,
        localLanguage: String,
        remoteLanguage: String
    ) {
        self.isTranslating = isTranslating
        self.localLanguage = localLanguage
        self.remoteLanguage = remoteLanguage
        super.init(callUUID: uuid)
    }

    public convenience init(
        call uuid: UUID,
        isTranslating: Bool,
        localLanguage: String,
        remoteLanguage: String
    ) {
        self.init(
            callUUID: uuid,
            isTranslating: isTranslating,
            localLanguage: localLanguage,
            remoteLanguage: remoteLanguage
        )
    }

    public required init?(coder aDecoder: NSCoder) {
        self.isTranslating = aDecoder.decodeBool(forKey: "isTranslating")
        self.localLanguage = (aDecoder.decodeObject(of: NSString.self, forKey: "localLanguage") as String?) ?? ""
        self.remoteLanguage = (aDecoder.decodeObject(of: NSString.self, forKey: "remoteLanguage") as String?) ?? ""
        super.init(coder: aDecoder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(isTranslating, forKey: "isTranslating")
        coder.encode(localLanguage as NSString, forKey: "localLanguage")
        coder.encode(remoteLanguage as NSString, forKey: "remoteLanguage")
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        CXSetTranslatingCallAction(
            callUUID: callUUID,
            isTranslating: isTranslating,
            localLanguage: localLanguage,
            remoteLanguage: remoteLanguage
        )
    }

    public func fulfill(using translationEngine: CXTranslationEngine) {
        self.translationEngine = translationEngine
        _ = CallKitRegistry.shared.applyTranslation(uuid: callUUID, engine: translationEngine)
        complete(failed: false)
    }

    open override func fulfill() {
        fulfill(using: .default)
    }
}

open class CXTransaction: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public let uuid: UUID
    private var storedActions: [CXAction]
    private let lock = NSLock()

    public var actions: [CXAction] {
        lock.lock()
        defer { lock.unlock() }
        return storedActions
    }

    public var isComplete: Bool {
        lock.lock()
        defer { lock.unlock() }
        return !storedActions.isEmpty && storedActions.allSatisfy(\.isComplete)
    }

    public init(actions: [CXAction]) {
        self.uuid = UUID()
        self.storedActions = actions
        super.init()
        for action in actions {
            action.owningTransaction = self
        }
    }

    public convenience init(action: CXAction) {
        self.init(actions: [action])
    }

    public required init?(coder: NSCoder) {
        guard let uuidString = coder.decodeObject(of: NSString.self, forKey: "uuid") as String?,
              let decoded = UUID(uuidString: uuidString)
        else {
            return nil
        }
        self.uuid = decoded
        self.storedActions = []
        super.init()
    }

    open func encode(with coder: NSCoder) {
        coder.encode(uuid.uuidString as NSString, forKey: "uuid")
    }

    public static var supportsSecureCoding: Bool { true }

    open func copy(with zone: NSZone? = nil) -> Any {
        CXTransaction(actions: actions)
    }

    public func addAction(_ action: CXAction) {
        lock.lock()
        storedActions.append(action)
        action.owningTransaction = self
        lock.unlock()
    }

    func actionDidComplete(_ action: CXAction) {
        _ = action
        if isComplete {
            CallKitRegistry.shared.finishPending(transactionUUID: uuid, error: nil)
        } else if actions.contains(where: { $0.isComplete && $0.failed }) {
            let failed = actions.contains(where: { $0.failed })
            if failed && actions.allSatisfy(\.isComplete) {
                CallKitRegistry.shared.finishPending(
                    transactionUUID: uuid,
                    error: CXErrorCodeRequestTransactionError(.invalidAction)
                )
            }
        }
    }
}
