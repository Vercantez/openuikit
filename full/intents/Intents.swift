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

    open func keyImage() -> INImage? {
        nil
    }
}

open class INIntentResponse: NSObject, @unchecked Sendable {
    open var userActivity: NSUserActivity?

    public override init() {
        super.init()
    }
}

open class INExtension: NSObject {
    public override init() {
        super.init()
    }

    open func handler(for intent: INIntent) -> Any {
        self
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

    public init(intent: INIntent, response: INIntentResponse?) {
        self.intent = intent
        self.intentResponse = response
        super.init()
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

open class INSpeakableString: NSObject, @unchecked Sendable {
    public let spokenPhrase: String
    public let pronunciationHint: String?
    public let vocabularyIdentifier: String?

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
}

open class INObject: NSObject, @unchecked Sendable {
    public let identifier: String?
    public let displayString: String
    public let pronunciationHint: String?
    open var alternativeSpeakableMatches: [INSpeakableString]?

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
}

open class INIntegerResolutionResult: INIntentResolutionResult, @unchecked Sendable {
    open class func success(with resolvedValue: Int) -> Self {
        self.init(outcome: .success, value: resolvedValue)
    }

    open class func confirmationRequired(with valueToConfirm: NSNumber?) -> Self {
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
}

open class INObjectSection<Element>: NSObject, @unchecked Sendable {
    public let title: String?
    public let items: [Element]

    public init(title: String?, items: [Element]) {
        self.title = title
        self.items = items
        super.init()
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
        let values = state.withLock { state in
            state.values.values.sorted { $0.identifier.uuidString < $1.identifier.uuidString }
        }
        completion(values, nil)
    }

    open func getVoiceShortcut(
        with identifier: UUID,
        completion: @escaping (INVoiceShortcut?, Error?) -> Void
    ) {
        completion(state.withLock { $0.values[identifier] }, nil)
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
    public static let home = Self(rawValue: "home")
    public static let work = Self(rawValue: "work")
    public static let mobile = Self(rawValue: "mobile")
    public static let iPhone = Self(rawValue: "iPhone")
    public static let main = Self(rawValue: "main")
    public static let homeFax = Self(rawValue: "homeFax")
    public static let workFax = Self(rawValue: "workFax")
    public static let pager = Self(rawValue: "pager")
    public static let other = Self(rawValue: "other")
}

open class INPersonHandle: NSObject, @unchecked Sendable {
    public let value: String
    public let type: INPersonHandleType
    public let label: INPersonHandleLabel?

    public init(value: String, type: INPersonHandleType) {
        self.value = value
        self.type = type
        self.label = nil
        super.init()
    }

    public init(value: String, type: INPersonHandleType, label: INPersonHandleLabel?) {
        self.value = value
        self.type = type
        self.label = label
        super.init()
    }
}

public enum INPersonSuggestionType: Int, Sendable {
    case none = 0
    case socialProfile = 1
    case instantMessageAddress = 2
}

open class INPerson: NSObject, @unchecked Sendable {
    public let personHandle: INPersonHandle?
    public let nameComponents: Any?
    public let displayName: String?
    public let image: INImage?
    public let contactIdentifier: String?
    public let customIdentifier: String?
    open var aliases: [INSpeakableString]?
    open var suggestionType: INPersonSuggestionType = .none

    public init(
        personHandle: INPersonHandle?,
        nameComponents: Any?,
        displayName: String?,
        image: INImage?,
        contactIdentifier: String?,
        customIdentifier: String?
    ) {
        self.personHandle = personHandle
        self.nameComponents = nameComponents
        self.displayName = displayName
        self.image = image
        self.contactIdentifier = contactIdentifier
        self.customIdentifier = customIdentifier
        super.init()
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

public enum INMediaItemType: Int, Sendable {
    case unknown = 0
    case song
    case album
    case artist
    case genre
    case playlist
    case podcastShow
    case podcastEpisode
    case podcastPlaylist
    case musicStation
    case audioBook
    case movie
    case tvShow
    case tvShowEpisode
    case musicVideo
    case podcastStation
    case radioStation
    case station
}

open class INMediaItem: NSObject, @unchecked Sendable {
    public let identifier: String?
    public let title: String?
    public let type: INMediaItemType
    public let artwork: INImage?

    public init(identifier: String?, title: String?, type: INMediaItemType, artwork: INImage?) {
        self.identifier = identifier
        self.title = title
        self.type = type
        self.artwork = artwork
        super.init()
    }
}

open class INMediaSearch: NSObject, @unchecked Sendable {
    open var mediaName: String?
    open var artistName: String?
    open var albumName: String?

    public override init() {
        super.init()
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
