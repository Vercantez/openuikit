// Open implementation of the first-party Intents module for Mach-O guests.
//
// The core is deliberately operational: interactions can be donated and
// deleted, voice shortcuts have stable identities and a process-wide center,
// and resolution results retain their outcome/value. Services which require
// Siri's proprietary speech or account infrastructure report unavailable
// state instead of manufacturing success.

@_exported import Foundation
#if canImport(OpenUIKit)
@_exported import OpenUIKit
#endif
import Synchronization

#if canImport(ObjectiveC)
import class ObjectiveC.NSObject
#else
import class Foundation.NSObject
#endif

// Corelibs Foundation has no NSUserActivity. The production Mach-O guest uses
// OpenUIKit's class identity. The isolated host gate cannot import OpenUIKit,
// so this lookalike exists only when neither Darwin nor OpenUIKit is present.
#if !canImport(Darwin) && !canImport(OpenUIKit)
open class NSUserActivity: NSObject, @unchecked Sendable {
    public let activityType: String

    public init(activityType: String) {
        self.activityType = activityType
        super.init()
    }
}
#endif

// MARK: - Intent and interaction identity

open class INIntent: NSObject, @unchecked Sendable {
    open var suggestedInvocationPhrase: String?
    open var identifier: String?
    open var intentDescription: String?
    open var donationMetadata: INIntentDonationMetadata?
    open var shortcutAvailability: INShortcutAvailabilityOptions = []

    public override init() {
        super.init()
    }

    public required convenience init?(coder: NSCoder) {
        self.init()
        identifier = inDecodeString(coder, "identifier")
        suggestedInvocationPhrase = inDecodeString(coder, "suggestedInvocationPhrase")
        intentDescription = inDecodeString(coder, "intentDescription")
    }

    open func keyImage() -> INImage? {
        nil
    }
}

open class INIntentResponse: NSObject, @unchecked Sendable {
    open var userActivity: NSUserActivity?

    public override init() {
        super.init()
    }

    public required convenience init?(coder: NSCoder) {
        self.init()
        if let type = inDecodeString(coder, "userActivityType") {
            userActivity = NSUserActivity(activityType: type)
        }
    }
}

open class INExtension: NSObject, INIntentHandlerProviding {
    @_spi(OpenIntentsHost)
    open var hostHandler: Any?

    public override init() {
        super.init()
    }

    open func handler(for intent: INIntent) -> Any? {
        hostHandler ?? self
    }
}

public enum INInteractionDirection: Int, Sendable {
    case unspecified = 0
    case outgoing = 1
    case incoming = 2
}

private struct _InteractionStore: @unchecked Sendable {
    var interactions: [String: INInteraction] = [:]
}

private let _interactionStore = Mutex(_InteractionStore())

open class INInteraction: NSObject, @unchecked Sendable {
    public let intent: INIntent
    public let intentResponse: INIntentResponse?
    open var identifier: String?
    open var direction: INInteractionDirection = .unspecified
    open var dateInterval: DateInterval?
    open var groupIdentifier: String?
    open var intentHandlingStatus: INIntentHandlingStatus = .unspecified

    public init(intent: INIntent, response: INIntentResponse?) {
        self.intent = intent
        self.intentResponse = response
        super.init()
    }

    public required convenience init?(coder: NSCoder) {
        guard let intent = coder.decodeObject(of: INIntent.self, forKey: "intent") else {
            return nil
        }
        let response = coder.decodeObject(of: INIntentResponse.self, forKey: "intentResponse")
        self.init(intent: intent, response: response)
        identifier = inDecodeString(coder, "identifier")
        if coder.containsValue(forKey: "direction") {
            direction = INInteractionDirection(
                rawValue: Int(coder.decodeInt64(forKey: "direction"))
            ) ?? .unspecified
        }
        groupIdentifier = inDecodeString(coder, "groupIdentifier")
        if coder.containsValue(forKey: "dateIntervalStart") {
            let start = coder.decodeObject(of: NSDate.self, forKey: "dateIntervalStart") as Date?
                ?? Date(timeIntervalSince1970: 0)
            let duration = coder.decodeDouble(forKey: "dateIntervalDuration")
            dateInterval = DateInterval(start: start, duration: duration)
        }
    }

    open func donate(completion: ((Error?) -> Void)? = nil) {
        let key = identifier ?? UUID().uuidString
        identifier = key
        _interactionStore.withLock { state in
            state.interactions[key] = self
        }
        completion?(nil)
    }

    public static func deleteAll(completion: ((Error?) -> Void)? = nil) {
        _interactionStore.withLock { $0.interactions.removeAll(keepingCapacity: false) }
        completion?(nil)
    }

    public static func delete(with identifiers: [String], completion: ((Error?) -> Void)? = nil) {
        _interactionStore.withLock { state in
            for identifier in identifiers {
                state.interactions.removeValue(forKey: identifier)
            }
        }
        completion?(nil)
    }

    public static func delete(with groupIdentifier: String, completion: ((Error?) -> Void)? = nil) {
        _interactionStore.withLock { state in
            let keys = state.interactions.compactMap { key, value in
                value.groupIdentifier == groupIdentifier ? key : nil
            }
            for key in keys {
                state.interactions.removeValue(forKey: key)
            }
        }
        completion?(nil)
    }

    public static func delete(with groupIdentifier: String) async throws {
        delete(with: groupIdentifier, completion: { _ in })
    }

    open func parameterValue(for parameter: INParameter) -> Any? {
        let path = parameter.parameterKeyPath
        if path == "identifier" { return intent.identifier }
        if path == "suggestedInvocationPhrase" { return intent.suggestedInvocationPhrase }
        if path == "intentDescription" { return intent.intentDescription }
        return nil
    }

    @_spi(OpenIntentsHost)
    public static var donatedInteractions: [INInteraction] {
        _interactionStore.withLock { state in
            state.interactions.keys.sorted().compactMap { state.interactions[$0] }
        }
    }
}

// Corelibs Foundation does not currently provide NSUserActivity on the guest
// path; OpenUIKit owns its canonical class identity. Intents owns the Siri
// overlay state, matching the placement of `interaction` in Apple's Intents
// overlay while keeping the Foundation/UIKit dependency graph acyclic.
#if !canImport(Darwin)
public typealias NSUserActivityPersistentIdentifier = String

private struct _UserActivityIntentState: @unchecked Sendable {
    var title: String?
    var userInfo: [AnyHashable: Any]?
    var eligibleForSearch = false
    var eligibleForPrediction = false
    var suggestedInvocationPhrase: String?
    var persistentIdentifier: NSUserActivityPersistentIdentifier?
    var interaction: INInteraction?
}

private let _userActivityStates = Mutex<[ObjectIdentifier: _UserActivityIntentState]>([:])

private func _readActivityState<T>(
    _ activity: NSUserActivity,
    _ body: (_UserActivityIntentState) -> T
) -> T {
    _userActivityStates.withLock { states in
        body(states[ObjectIdentifier(activity)] ?? _UserActivityIntentState())
    }
}

private func _mutateActivityState(
    _ activity: NSUserActivity,
    _ body: (inout _UserActivityIntentState) -> Void
) {
    _userActivityStates.withLock { states in
        let key = ObjectIdentifier(activity)
        var state = states[key] ?? _UserActivityIntentState()
        body(&state)
        states[key] = state
    }
}

public extension NSUserActivity {
    var title: String? {
        get { _readActivityState(self) { $0.title } }
        set { _mutateActivityState(self) { $0.title = newValue } }
    }

    var userInfo: [AnyHashable: Any]? {
        get { _readActivityState(self) { $0.userInfo } }
        set { _mutateActivityState(self) { $0.userInfo = newValue } }
    }

    var isEligibleForSearch: Bool {
        get { _readActivityState(self) { $0.eligibleForSearch } }
        set { _mutateActivityState(self) { $0.eligibleForSearch = newValue } }
    }

    var isEligibleForPrediction: Bool {
        get { _readActivityState(self) { $0.eligibleForPrediction } }
        set { _mutateActivityState(self) { $0.eligibleForPrediction = newValue } }
    }

    var suggestedInvocationPhrase: String? {
        get { _readActivityState(self) { $0.suggestedInvocationPhrase } }
        set { _mutateActivityState(self) { $0.suggestedInvocationPhrase = newValue } }
    }

    var persistentIdentifier: NSUserActivityPersistentIdentifier? {
        get { _readActivityState(self) { $0.persistentIdentifier } }
        set { _mutateActivityState(self) { $0.persistentIdentifier = newValue } }
    }

    var interaction: INInteraction? {
        get { _readActivityState(self) { $0.interaction } }
        set { _mutateActivityState(self) { $0.interaction = newValue } }
    }
}
#endif

// MARK: - Objects and resolution

open class INSpeakableString: NSObject, INSpeakable, @unchecked Sendable {
    public let spokenPhrase: String
    public let pronunciationHint: String?
    public let vocabularyIdentifier: String?
    public var identifier: String? { vocabularyIdentifier }
    open var alternativeSpeakableMatches: [INSpeakable]?

    public init(
        vocabularyIdentifier: String? = nil,
        spokenPhrase: String,
        pronunciationHint: String? = nil
    ) {
        self.vocabularyIdentifier = vocabularyIdentifier
        self.spokenPhrase = spokenPhrase
        self.pronunciationHint = pronunciationHint
        super.init()
    }

    public convenience init(
        identifier: String,
        spokenPhrase: String,
        pronunciationHint: String?
    ) {
        self.init(
            vocabularyIdentifier: identifier,
            spokenPhrase: spokenPhrase,
            pronunciationHint: pronunciationHint
        )
    }

    public required convenience init?(coder: NSCoder) {
        guard let phrase = inDecodeString(coder, "spokenPhrase") else { return nil }
        self.init(
            vocabularyIdentifier: inDecodeString(coder, "vocabularyIdentifier"),
            spokenPhrase: phrase,
            pronunciationHint: inDecodeString(coder, "pronunciationHint")
        )
    }
}

open class INObject: NSObject, @unchecked Sendable {
    public let identifier: String?
    public let displayString: String
    public let pronunciationHint: String?
    open var alternativeSpeakableMatches: [INSpeakableString]?
    open var subtitleString: String?
    open var displayImage: INImage?

    public init(identifier: String?, display: String) {
        self.identifier = identifier
        self.displayString = display
        self.pronunciationHint = nil
        super.init()
    }

    public init(identifier: String?, display: INSpeakableString) {
        self.identifier = identifier
        self.displayString = display.spokenPhrase
        self.pronunciationHint = display.pronunciationHint
        super.init()
    }

    public init(identifier: String?, display: String, pronunciationHint: String?) {
        self.identifier = identifier
        self.displayString = display
        self.pronunciationHint = pronunciationHint
        super.init()
    }

    public convenience init(identifier: String?, displayString: String) {
        self.init(identifier: identifier, display: displayString, pronunciationHint: nil)
    }

    public convenience init(identifier: String?, displayString: String, pronunciationHint: String?) {
        self.init(identifier: identifier, display: displayString, pronunciationHint: pronunciationHint)
    }

    public convenience init(
        identifier: String?,
        displayString: String,
        subtitleString: String?,
        displayImage: INImage?
    ) {
        self.init(identifier: identifier, display: displayString, pronunciationHint: nil)
        self.subtitleString = subtitleString
        self.displayImage = displayImage
    }

    public convenience init(
        identifier: String?,
        displayString: String,
        pronunciationHint: String?,
        subtitleString: String?,
        displayImage: INImage?
    ) {
        self.init(identifier: identifier, display: displayString, pronunciationHint: pronunciationHint)
        self.subtitleString = subtitleString
        self.displayImage = displayImage
    }

    public required convenience init?(coder: NSCoder) {
        guard let display = inDecodeString(coder, "displayString") else { return nil }
        self.init(
            identifier: inDecodeString(coder, "identifier"),
            displayString: display,
            pronunciationHint: inDecodeString(coder, "pronunciationHint"),
            subtitleString: inDecodeString(coder, "subtitleString"),
            displayImage: coder.containsValue(forKey: "displayImage")
                ? coder.decodeObject(of: INImage.self, forKey: "displayImage")
                : nil
        )
    }
}

public enum INIntentResolutionResultOutcome: Int, Sendable {
    case needsValue
    case notRequired
    case unsupported
    case success
    case disambiguation
    case confirmationRequired
}

open class INIntentResolutionResult: NSObject, @unchecked Sendable {
    public let outcome: INIntentResolutionResultOutcome
    public let resolvedValue: Any?

    public required init(outcome: INIntentResolutionResultOutcome, value: Any?) {
        self.outcome = outcome
        self.resolvedValue = value
        super.init()
    }

    open class func needsValue() -> Self {
        self.init(outcome: .needsValue, value: nil)
    }

    open class func notRequired() -> Self {
        self.init(outcome: .notRequired, value: nil)
    }

    open class func unsupported() -> Self {
        self.init(outcome: .unsupported, value: nil)
    }
}

open class INObjectResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func success(with resolvedObject: INObject) -> Self {
        self.init(outcome: .success, value: resolvedObject)
    }

    open class func disambiguation(with objectsToDisambiguate: [INObject]) -> Self {
        self.init(outcome: .disambiguation, value: objectsToDisambiguate)
    }

    open class func confirmationRequired(with objectToConfirm: INObject?) -> Self {
        self.init(outcome: .confirmationRequired, value: objectToConfirm)
    }
}

open class INEnumResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    public class func __success(withResolvedValue value: Int) -> Self {
        self.init(outcome: .success, value: value)
    }

    public class func __confirmationRequiredWithValue(toConfirm value: Int) -> Self {
        self.init(outcome: .confirmationRequired, value: value)
    }
}

open class INStringResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func success(with resolvedString: String) -> Self {
        self.init(outcome: .success, value: resolvedString)
    }

    open class func disambiguation(with stringsToDisambiguate: [String]) -> Self {
        self.init(outcome: .disambiguation, value: stringsToDisambiguate)
    }

    open class func confirmationRequired(with stringToConfirm: String?) -> Self {
        self.init(outcome: .confirmationRequired, value: stringToConfirm)
    }
}

open class INBooleanResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func success(with resolvedValue: Bool) -> Self {
        self.init(outcome: .success, value: resolvedValue)
    }

    open class func confirmationRequired(with valueToConfirm: NSNumber?) -> Self {
        self.init(outcome: .confirmationRequired, value: valueToConfirm)
    }

    @nonobjc
    open class func confirmationRequired(with valueToConfirm: Bool?) -> Self {
        self.init(outcome: .confirmationRequired, value: valueToConfirm)
    }
}

open class INIntegerResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func success(with resolvedValue: Int) -> Self {
        self.init(outcome: .success, value: resolvedValue)
    }

    open class func confirmationRequired(with valueToConfirm: NSNumber?) -> Self {
        self.init(outcome: .confirmationRequired, value: valueToConfirm)
    }

    @nonobjc
    open class func confirmationRequired(with valueToConfirm: Int?) -> Self {
        self.init(outcome: .confirmationRequired, value: valueToConfirm)
    }
}

open class INDoubleResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func success(with resolvedValue: Double) -> Self {
        self.init(outcome: .success, value: resolvedValue)
    }

    open class func confirmationRequired(with valueToConfirm: NSNumber?) -> Self {
        self.init(outcome: .confirmationRequired, value: valueToConfirm)
    }
}

open class INObjectCollection<Element>: NSObject, @unchecked Sendable {
    public let items: [Element]
    public let sections: [INObjectSection<Element>]

    public init(items: [Element]) {
        self.items = items
        self.sections = []
        super.init()
    }

    public init(sections: [INObjectSection<Element>]) {
        self.sections = sections
        self.items = sections.flatMap(\.items)
        super.init()
    }

    public required convenience init?(coder: NSCoder) {
        self.init(items: [])
    }
}

open class INObjectSection<Element>: NSObject, @unchecked Sendable {
    public let title: String?
    public let items: [Element]

    public init(title: String?, items: [Element]) {
        self.title = title
        self.items = items
        super.init()
    }

    public required convenience init?(coder: NSCoder) {
        self.init(title: inDecodeString(coder, "title"), items: [])
    }
}

// MARK: - Shortcuts

open class INShortcut: NSObject, @unchecked Sendable {
    public let intent: INIntent?
    public let userActivity: NSUserActivity?

    public init(intent: INIntent) {
        self.intent = intent
        self.userActivity = nil
        super.init()
    }

    public init(userActivity: NSUserActivity) {
        self.intent = nil
        self.userActivity = userActivity
        super.init()
    }

    public required convenience init?(coder: NSCoder) {
        if let intent = coder.decodeObject(of: INIntent.self, forKey: "intent") {
            self.init(intent: intent)
            return
        }
        return nil
    }
}

open class INVoiceShortcut: NSObject, @unchecked Sendable {
    public let identifier: UUID
    public let invocationPhrase: String
    public let shortcut: INShortcut

    public init(identifier: UUID = UUID(), invocationPhrase: String, shortcut: INShortcut) {
        self.identifier = identifier
        self.invocationPhrase = invocationPhrase
        self.shortcut = shortcut
        super.init()
    }

    public required convenience init?(coder: NSCoder) {
        guard let phrase = inDecodeString(coder, "invocationPhrase"),
              let shortcut = coder.decodeObject(of: INShortcut.self, forKey: "shortcut") else {
            return nil
        }
        let identifier = inDecodeString(coder, "identifier").flatMap(UUID.init(uuidString:)) ?? UUID()
        self.init(identifier: identifier, invocationPhrase: phrase, shortcut: shortcut)
    }
}

private struct _VoiceShortcutState: @unchecked Sendable {
    var values: [UUID: INVoiceShortcut] = [:]
    var suggestions: [INShortcut] = []
}

open class INVoiceShortcutCenter: NSObject, @unchecked Sendable {
    public static let shared = INVoiceShortcutCenter()
    private let state = Mutex(_VoiceShortcutState())

    private override init() {
        super.init()
    }

    open func getAllVoiceShortcuts(
        completion: @escaping ([INVoiceShortcut]?, Error?) -> Void
    ) {
        // Linux has no Siri/Shortcuts daemon. A fresh process is empty; the
        // in-process store is only the host SPI install path (IntentsUI).
        let values = state.withLock { state in
            state.values.values.sorted { $0.identifier.uuidString < $1.identifier.uuidString }
        }
        completion(values, nil)
    }

    open func getVoiceShortcut(
        with identifier: UUID,
        completion: @escaping (INVoiceShortcut?, Error?) -> Void
    ) {
        if let value = state.withLock({ $0.values[identifier] }) {
            completion(value, nil)
        } else {
            completion(nil, INIntentError(.voiceShortcutGetFailed))
        }
    }

    open func getVoiceShortcut(with identifier: UUID) async throws -> INVoiceShortcut {
        try await withCheckedThrowingContinuation { continuation in
            getVoiceShortcut(with: identifier, completion: { value, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let value {
                    continuation.resume(returning: value)
                } else {
                    continuation.resume(throwing: INIntentError(.voiceShortcutGetFailed))
                }
            })
        }
    }

    open func setShortcutSuggestions(_ suggestions: [INShortcut]) {
        state.withLock { $0.suggestions = suggestions }
    }

    @_spi(OpenIntentsHost)
    public var shortcutSuggestions: [INShortcut] {
        state.withLock { $0.suggestions }
    }

    @_spi(OpenIntentsHost)
    @discardableResult
    public func install(
        _ shortcut: INShortcut,
        invocationPhrase: String,
        identifier: UUID = UUID()
    ) -> INVoiceShortcut {
        let voiceShortcut = INVoiceShortcut(
            identifier: identifier,
            invocationPhrase: invocationPhrase,
            shortcut: shortcut
        )
        state.withLock { $0.values[identifier] = voiceShortcut }
        return voiceShortcut
    }

    @_spi(OpenIntentsHost)
    public func update(_ voiceShortcut: INVoiceShortcut, invocationPhrase: String) -> INVoiceShortcut {
        install(
            voiceShortcut.shortcut,
            invocationPhrase: invocationPhrase,
            identifier: voiceShortcut.identifier
        )
    }

    @_spi(OpenIntentsHost)
    @discardableResult
    public func remove(identifier: UUID) -> Bool {
        state.withLock { $0.values.removeValue(forKey: identifier) != nil }
    }

    @_spi(OpenIntentsHost)
    public func removeAll() {
        state.withLock {
            $0.values.removeAll(keepingCapacity: false)
            $0.suggestions.removeAll(keepingCapacity: false)
        }
    }
}

extension INVoiceShortcutCenter {
    /// Swift overlay of `getAllVoiceShortcuts(completion:)`.
    /// public-surface.tsv names this `allVoiceShortcuts() async throws`.
    /// Linux returns the in-process store (empty until host SPI `install`).
    public func allVoiceShortcuts() async throws -> [INVoiceShortcut] {
        try await withCheckedThrowingContinuation { continuation in
            getAllVoiceShortcuts { values, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: values ?? [])
                }
            }
        }
    }
}

// MARK: - Common media and person values

open class INImage: NSObject, @unchecked Sendable {
    public let imageData: Data?
    public let namedImage: String?
    public let imageURL: URL?
    public let imageWidth: Double?
    public let imageHeight: Double?

    public init(imageData: Data) {
        self.imageData = imageData
        self.namedImage = nil
        self.imageURL = nil
        self.imageWidth = nil
        self.imageHeight = nil
        super.init()
    }

    public required init(named name: String) {
        self.imageData = nil
        self.namedImage = name
        self.imageURL = nil
        self.imageWidth = nil
        self.imageHeight = nil
        super.init()
    }

    public convenience init?(url URL: URL) {
        self.init(url: URL, width: 0, height: 0)
    }

    public convenience init?(URL: URL) {
        self.init(url: URL, width: 0, height: 0)
    }

    public init?(url URL: URL, width: Double, height: Double) {
        self.imageData = nil
        self.namedImage = nil
        self.imageURL = URL
        self.imageWidth = width
        self.imageHeight = height
        super.init()
    }

    public convenience init?(URL: URL, width: Double, height: Double) {
        self.init(url: URL, width: width, height: height)
    }

    public required convenience init?(coder: NSCoder) {
        if let data = inDecodeData(coder, "imageData") {
            self.init(imageData: data)
            return
        }
        if let name = inDecodeString(coder, "namedImage") {
            self.init(named: name)
            return
        }
        if let urlString = inDecodeString(coder, "imageURL"), let url = URL(string: urlString) {
            self.init(url: url)
            return
        }
        return nil
    }

    open class func systemImageNamed(_ systemImageName: String) -> Self {
        self.init(named: systemImageName)
    }
}

public enum INPersonHandleType: Int, Sendable {
    case unknown = 0
    case emailAddress = 1
    case phoneNumber = 2
}

public struct INPersonHandleLabel: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public static let home = Self(rawValue: "home")
    public static let work = Self(rawValue: "work")
    public static let mobile = Self(rawValue: "mobile")
    public static let iPhone = Self(rawValue: "iPhone")
    public static let main = Self(rawValue: "main")
    public static let homeFax = Self(rawValue: "homeFax")
    public static let workFax = Self(rawValue: "workFax")
    public static let pager = Self(rawValue: "pager")
    public static let school = Self(rawValue: "school")
    public static let other = Self(rawValue: "other")
}

open class INPersonHandle: NSObject, @unchecked Sendable {
    public let value: String?
    public let type: INPersonHandleType
    public let label: INPersonHandleLabel?

    public init(value: String?, type: INPersonHandleType) {
        self.value = value
        self.type = type
        self.label = nil
        super.init()
    }

    public init(value: String?, type: INPersonHandleType, label: INPersonHandleLabel?) {
        self.value = value
        self.type = type
        self.label = label
        super.init()
    }

    public required convenience init?(coder: NSCoder) {
        let rawType = Int(coder.decodeInt64(forKey: "type"))
        let type = INPersonHandleType(rawValue: rawType) ?? .unknown
        let labelRaw = inDecodeString(coder, "label")
        self.init(
            value: inDecodeString(coder, "value"),
            type: type,
            label: labelRaw.map { INPersonHandleLabel(rawValue: $0) }
        )
    }
}

public enum INPersonSuggestionType: Int, Sendable {
    case none = 0
    case socialProfile = 1
    case instantMessageAddress = 2
}

open class INPerson: NSObject, @unchecked Sendable {
    public let personHandle: INPersonHandle?
    public let nameComponents: PersonNameComponents?
    public let displayName: String
    public let image: INImage?
    public let contactIdentifier: String?
    public let customIdentifier: String?
    public let aliases: [INPersonHandle]?
    public let suggestionType: INPersonSuggestionType
    public let isMe: Bool
    public let isContactSuggestion: Bool
    public let relationship: INPersonRelationship?
    public var siriMatches: [INPerson]?
    public var handle: String? { personHandle?.value }

    public init(
        personHandle: INPersonHandle?,
        nameComponents: PersonNameComponents?,
        displayName: String?,
        image: INImage?,
        contactIdentifier: String?,
        customIdentifier: String?,
        aliases: [INPersonHandle]? = nil,
        suggestionType: INPersonSuggestionType = .none,
        isMe: Bool = false,
        isContactSuggestion: Bool = false,
        relationship: INPersonRelationship? = nil
    ) {
        self.personHandle = personHandle
        self.nameComponents = nameComponents
        self.displayName = displayName ?? personHandle?.value ?? ""
        self.image = image
        self.contactIdentifier = contactIdentifier
        self.customIdentifier = customIdentifier
        self.aliases = aliases
        self.suggestionType = suggestionType
        self.isMe = isMe
        self.isContactSuggestion = isContactSuggestion
        self.relationship = relationship
        super.init()
    }

    public convenience init(
        personHandle: INPersonHandle,
        nameComponents: PersonNameComponents?,
        displayName: String?,
        image: INImage?,
        contactIdentifier: String?,
        customIdentifier: String?
    ) {
        self.init(
            personHandle: Optional(personHandle),
            nameComponents: nameComponents,
            displayName: displayName,
            image: image,
            contactIdentifier: contactIdentifier,
            customIdentifier: customIdentifier
        )
    }

    public convenience init(
        handle: String,
        displayName: String?,
        contactIdentifier: String?
    ) {
        self.init(
            personHandle: INPersonHandle(value: handle, type: .unknown),
            nameComponents: nil,
            displayName: displayName,
            image: nil,
            contactIdentifier: contactIdentifier,
            customIdentifier: nil
        )
    }

    public convenience init(
        handle: String,
        nameComponents: PersonNameComponents,
        contactIdentifier: String?
    ) {
        self.init(
            personHandle: INPersonHandle(value: handle, type: .unknown),
            nameComponents: nameComponents,
            displayName: nil,
            image: nil,
            contactIdentifier: contactIdentifier,
            customIdentifier: nil
        )
    }

    public convenience init(
        handle: String,
        nameComponents: PersonNameComponents?,
        displayName: String?,
        image: INImage?,
        contactIdentifier: String?
    ) {
        self.init(
            personHandle: INPersonHandle(value: handle, type: .unknown),
            nameComponents: nameComponents,
            displayName: displayName,
            image: image,
            contactIdentifier: contactIdentifier,
            customIdentifier: nil
        )
    }

    public convenience init(
        personHandle: INPersonHandle,
        nameComponents: PersonNameComponents?,
        displayName: String?,
        image: INImage?,
        contactIdentifier: String?,
        customIdentifier: String?,
        aliases: [INPersonHandle]?,
        suggestionType: INPersonSuggestionType
    ) {
        self.init(
            personHandle: Optional(personHandle),
            nameComponents: nameComponents,
            displayName: displayName,
            image: image,
            contactIdentifier: contactIdentifier,
            customIdentifier: customIdentifier,
            aliases: aliases,
            suggestionType: suggestionType
        )
    }

    public convenience init(
        personHandle: INPersonHandle,
        nameComponents: PersonNameComponents?,
        displayName: String?,
        image: INImage?,
        contactIdentifier: String?,
        customIdentifier: String?,
        isContactSuggestion: Bool,
        suggestionType: INPersonSuggestionType
    ) {
        self.init(
            personHandle: Optional(personHandle),
            nameComponents: nameComponents,
            displayName: displayName,
            image: image,
            contactIdentifier: contactIdentifier,
            customIdentifier: customIdentifier,
            suggestionType: suggestionType,
            isContactSuggestion: isContactSuggestion
        )
    }

    public convenience init(
        personHandle: INPersonHandle,
        nameComponents: PersonNameComponents?,
        displayName: String?,
        image: INImage?,
        contactIdentifier: String?,
        customIdentifier: String?,
        isMe: Bool
    ) {
        self.init(
            personHandle: Optional(personHandle),
            nameComponents: nameComponents,
            displayName: displayName,
            image: image,
            contactIdentifier: contactIdentifier,
            customIdentifier: customIdentifier,
            isMe: isMe
        )
    }

    public convenience init(
        personHandle: INPersonHandle,
        nameComponents: PersonNameComponents?,
        displayName: String?,
        image: INImage?,
        contactIdentifier: String?,
        customIdentifier: String?,
        isMe: Bool,
        suggestionType: INPersonSuggestionType
    ) {
        self.init(
            personHandle: Optional(personHandle),
            nameComponents: nameComponents,
            displayName: displayName,
            image: image,
            contactIdentifier: contactIdentifier,
            customIdentifier: customIdentifier,
            suggestionType: suggestionType,
            isMe: isMe
        )
    }

    public convenience init(
        personHandle: INPersonHandle,
        nameComponents: PersonNameComponents?,
        displayName: String?,
        image: INImage?,
        contactIdentifier: String?,
        customIdentifier: String?,
        relationship: INPersonRelationship?
    ) {
        self.init(
            personHandle: Optional(personHandle),
            nameComponents: nameComponents,
            displayName: displayName,
            image: image,
            contactIdentifier: contactIdentifier,
            customIdentifier: customIdentifier,
            relationship: relationship
        )
    }

    public required convenience init?(coder: NSCoder) {
        let handle = coder.decodeObject(of: INPersonHandle.self, forKey: "personHandle")
        self.init(
            personHandle: handle,
            nameComponents: nil,
            displayName: inDecodeString(coder, "displayName"),
            image: coder.decodeObject(of: INImage.self, forKey: "image"),
            contactIdentifier: inDecodeString(coder, "contactIdentifier"),
            customIdentifier: inDecodeString(coder, "customIdentifier")
        )
    }
}

open class INPersonResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func success(with resolvedPerson: INPerson) -> Self {
        self.init(outcome: .success, value: resolvedPerson)
    }

    open class func disambiguation(with peopleToDisambiguate: [INPerson]) -> Self {
        self.init(outcome: .disambiguation, value: peopleToDisambiguate)
    }

    open class func confirmationRequired(with personToConfirm: INPerson?) -> Self {
        self.init(outcome: .confirmationRequired, value: personToConfirm)
    }
}

public enum INMediaItemType: Int, Hashable, Sendable {
    case unknown = 0
    case song = 1
    case album = 2
    case artist = 3
    case genre = 4
    case playlist = 5
    case podcastShow = 6
    case podcastEpisode = 7
    case podcastPlaylist = 8
    case musicStation = 9
    case audioBook = 10
    case movie = 11
    case tvShow = 12
    case tvShowEpisode = 13
    case musicVideo = 14
    case podcastStation = 15
    case radioStation = 16
    case station = 17
    case music = 18
    case algorithmicRadioStation = 19
    case news = 20
}

open class INMediaItem: NSObject, @unchecked Sendable {
    public let identifier: String?
    public let title: String?
    public let type: INMediaItemType
    public let artwork: INImage?
    public let artist: String?

    public init(identifier: String?, title: String?, type: INMediaItemType, artwork: INImage?) {
        self.identifier = identifier
        self.title = title
        self.type = type
        self.artwork = artwork
        self.artist = nil
        super.init()
    }

    public init(
        identifier: String?,
        title: String?,
        type: INMediaItemType,
        artwork: INImage?,
        artist: String?
    ) {
        self.identifier = identifier
        self.title = title
        self.type = type
        self.artwork = artwork
        self.artist = artist
        super.init()
    }

    public required convenience init?(coder: NSCoder) {
        let rawType = Int(coder.decodeInt64(forKey: "type"))
        self.init(
            identifier: inDecodeString(coder, "identifier"),
            title: inDecodeString(coder, "title"),
            type: INMediaItemType(rawValue: rawType) ?? .unknown,
            artwork: coder.decodeObject(of: INImage.self, forKey: "artwork"),
            artist: inDecodeString(coder, "artist")
        )
    }
}

open class INMediaSearch: NSObject, @unchecked Sendable {
    open var mediaName: String?
    open var artistName: String?
    open var albumName: String?
    open var mediaType: INMediaItemType = .unknown
    open var sortOrder: INMediaSortOrder = .unknown
    open var genreNames: [String]?
    open var moodNames: [String]?
    open var activityNames: [String]?
    open var releaseDate: INDateComponentsRange?
    open var reference: INMediaReference = .unknown
    open var mediaIdentifier: String?

    public override init() {
        super.init()
    }

    public convenience init(
        mediaType: INMediaItemType = .unknown,
        sortOrder: INMediaSortOrder = .unknown,
        mediaName: String? = nil,
        artistName: String? = nil,
        albumName: String? = nil,
        genreNames: [String]? = nil,
        moodNames: [String]? = nil,
        releaseDate: INDateComponentsRange? = nil,
        reference: INMediaReference = .unknown,
        mediaIdentifier: String? = nil
    ) {
        self.init()
        self.mediaType = mediaType
        self.sortOrder = sortOrder
        self.mediaName = mediaName
        self.artistName = artistName
        self.albumName = albumName
        self.genreNames = genreNames
        self.moodNames = moodNames
        self.releaseDate = releaseDate
        self.reference = reference
        self.mediaIdentifier = mediaIdentifier
    }

    public required convenience init?(coder: NSCoder) {
        self.init()
        mediaName = inDecodeString(coder, "mediaName")
        artistName = inDecodeString(coder, "artistName")
        albumName = inDecodeString(coder, "albumName")
        mediaIdentifier = inDecodeString(coder, "mediaIdentifier")
    }
}

// MARK: - Honest service availability

public enum INFocusStatusAuthorizationStatus: Int, Sendable {
    case notDetermined = 0
    case restricted
    case denied
    case authorized
}

open class INFocusStatus: NSObject, @unchecked Sendable {
    public let isFocused: Bool?
    public init(isFocused: Bool?) {
        self.isFocused = isFocused
        super.init()
    }

    public required convenience init?(coder: NSCoder) {
        if coder.containsValue(forKey: "isFocused") {
            self.init(isFocused: coder.decodeBool(forKey: "isFocused"))
        } else {
            self.init(isFocused: nil)
        }
    }
}

open class INFocusStatusCenter: NSObject, @unchecked Sendable {
    public static let `default` = INFocusStatusCenter()
    public let authorizationStatus: INFocusStatusAuthorizationStatus = .restricted
    public let focusStatus = INFocusStatus(isFocused: nil)

    private override init() {
        super.init()
    }

    open func requestAuthorization(completionHandler: @escaping (INFocusStatusAuthorizationStatus) -> Void) {
        completionHandler(.restricted)
    }
}
