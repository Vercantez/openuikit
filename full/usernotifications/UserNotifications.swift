import Foundation

public let UNErrorDomain = "UNErrorDomain"
public let UNNotificationDefaultActionIdentifier =
  "com.apple.UNNotificationDefaultActionIdentifier"
public let UNNotificationDismissActionIdentifier =
  "com.apple.UNNotificationDismissActionIdentifier"

public struct UNError: Error, Equatable, Sendable, CustomStringConvertible {
  public enum Code: Int, Sendable {
    case notificationsNotAllowed = 1
    case attachmentInvalidURL = 100
    case attachmentUnrecognizedType = 101
    case attachmentInvalidFileSize = 102
    case attachmentNotInDataStore = 103
    case attachmentMoveIntoDataStoreFailed = 104
    case attachmentCorrupt = 105
    case notificationInvalidNoDate = 1400
    case notificationInvalidNoContent = 1401
    case contentProvidingObjectNotAllowed = 1500
    case contentProvidingInvalid = 1501
    case badgeInputInvalid = 1600
  }

  public let code: Code

  public init(_ code: Code) {
    self.code = code
  }

  public var description: String {
    switch code {
    case .notificationsNotAllowed:
      "Notifications are unavailable on this host"
    case .badgeInputInvalid:
      "The notification badge value is invalid"
    default:
      "UserNotifications error \(code.rawValue)"
    }
  }
}

public struct UNAuthorizationOptions: OptionSet, Sendable {
  public let rawValue: UInt

  public init(rawValue: UInt) { self.rawValue = rawValue }

  public static let badge = Self(rawValue: 1 << 0)
  public static let sound = Self(rawValue: 1 << 1)
  public static let alert = Self(rawValue: 1 << 2)
  public static let carPlay = Self(rawValue: 1 << 3)
  public static let criticalAlert = Self(rawValue: 1 << 4)
  public static let providesAppNotificationSettings = Self(rawValue: 1 << 5)
  public static let provisional = Self(rawValue: 1 << 6)
  public static let announcement = Self(rawValue: 1 << 7)
  public static let timeSensitive = Self(rawValue: 1 << 8)
}

public struct UNNotificationPresentationOptions: OptionSet, Sendable {
  public let rawValue: UInt

  public init(rawValue: UInt) { self.rawValue = rawValue }

  public static let badge = Self(rawValue: 1 << 0)
  public static let sound = Self(rawValue: 1 << 1)
  public static let alert = Self(rawValue: 1 << 2)
  public static let list = Self(rawValue: 1 << 3)
  public static let banner = Self(rawValue: 1 << 4)
}

public enum UNAuthorizationStatus: Int, Sendable {
  case notDetermined = 0
  case denied = 1
  case authorized = 2
  case provisional = 3
  case ephemeral = 4
}

public enum UNNotificationSetting: Int, Sendable {
  case notSupported = 0
  case disabled = 1
  case enabled = 2
}

public enum UNShowPreviewsSetting: Int, Sendable {
  case always = 0
  case whenAuthenticated = 1
  case never = 2
}

public enum UNAlertStyle: Int, Sendable {
  case none = 0
  case banner = 1
  case alert = 2
}

public enum UNNotificationInterruptionLevel: UInt, Sendable {
  case passive = 0
  case active = 1
  case timeSensitive = 2
  case critical = 3
}

public final class UNNotificationSettings: NSObject {
  public let authorizationStatus: UNAuthorizationStatus
  public let soundSetting: UNNotificationSetting
  public let badgeSetting: UNNotificationSetting
  public let alertSetting: UNNotificationSetting
  public let notificationCenterSetting: UNNotificationSetting
  public let lockScreenSetting: UNNotificationSetting
  public let carPlaySetting: UNNotificationSetting
  public let alertStyle: UNAlertStyle
  public let showPreviewsSetting: UNShowPreviewsSetting
  public let criticalAlertSetting: UNNotificationSetting
  public let providesAppNotificationSettings: Bool
  public let announcementSetting: UNNotificationSetting
  public let timeSensitiveSetting: UNNotificationSetting
  public let scheduledDeliverySetting: UNNotificationSetting
  public let directMessagesSetting: UNNotificationSetting

  @usableFromInline
  internal init(
    authorizationStatus: UNAuthorizationStatus,
    requestedOptions: UNAuthorizationOptions
  ) {
    self.authorizationStatus = authorizationStatus
    let enabled =
      authorizationStatus == .authorized
      || authorizationStatus == .provisional
      || authorizationStatus == .ephemeral
    func setting(_ option: UNAuthorizationOptions) -> UNNotificationSetting {
      guard requestedOptions.contains(option) else { return .disabled }
      return enabled ? .enabled : .disabled
    }
    soundSetting = setting(.sound)
    badgeSetting = setting(.badge)
    alertSetting = setting(.alert)
    notificationCenterSetting = enabled ? .enabled : .disabled
    lockScreenSetting = enabled ? .enabled : .disabled
    carPlaySetting = setting(.carPlay)
    alertStyle = setting(.alert) == .enabled ? .banner : .none
    showPreviewsSetting = enabled ? .always : .never
    criticalAlertSetting = setting(.criticalAlert)
    providesAppNotificationSettings =
      enabled && requestedOptions.contains(.providesAppNotificationSettings)
    announcementSetting = setting(.announcement)
    timeSensitiveSetting = setting(.timeSensitive)
    scheduledDeliverySetting = .notSupported
    directMessagesSetting = .notSupported
    super.init()
  }
}

public struct UNNotificationSoundName: RawRepresentable, Hashable, Sendable,
  ExpressibleByStringLiteral
{
  public let rawValue: String

  public init(rawValue: String) { self.rawValue = rawValue }
  public init(_ rawValue: String) { self.rawValue = rawValue }
  public init(stringLiteral value: String) { rawValue = value }
}

open class UNNotificationSound: NSObject {
  public enum Kind: Equatable, Sendable {
    case defaultSound
    case named(UNNotificationSoundName)
    case critical(UNNotificationSoundName?, Float)
    case ringtone(UNNotificationSoundName)
  }

  public let portableKind: Kind

  public required init(kind: Kind) {
    portableKind = kind
    super.init()
  }

  public class var `default`: UNNotificationSound {
    UNNotificationSound(kind: .defaultSound)
  }

  public class var defaultCritical: UNNotificationSound {
    UNNotificationSound(kind: .critical(nil, 1))
  }

  public class var defaultRingtone: UNNotificationSound {
    UNNotificationSound(kind: .ringtone("default"))
  }

  public convenience init(named name: UNNotificationSoundName) {
    self.init(kind: .named(name))
  }

  public class func defaultCriticalSound(
    withAudioVolume volume: Float
  ) -> Self {
    self.init(kind: .critical(nil, volume))
  }

  public class func criticalSoundNamed(
    _ name: UNNotificationSoundName
  ) -> Self {
    self.init(kind: .critical(name, 1))
  }

  public class func criticalSoundNamed(
    _ name: UNNotificationSoundName,
    withAudioVolume volume: Float
  ) -> Self {
    self.init(kind: .critical(name, volume))
  }

  public class func ringtoneSoundNamed(
    _ name: UNNotificationSoundName
  ) -> Self {
    self.init(kind: .ringtone(name))
  }
}

public protocol UNNotificationContentProviding: AnyObject {}

internal final class _UNContentStorage {
  var attachments: [UNNotificationAttachment] = []
  var badge: NSNumber?
  var body = ""
  var categoryIdentifier = ""
  var launchImageName = ""
  var sound: UNNotificationSound?
  var subtitle = ""
  var threadIdentifier = ""
  var title = ""
  var userInfo: [AnyHashable: Any] = [:]
  var summaryArgument = ""
  var summaryArgumentCount = 1
  var targetContentIdentifier: String?
  var interruptionLevel: UNNotificationInterruptionLevel = .active
  var relevanceScore = 0.0
  var filterCriteria: String?

  func copied() -> _UNContentStorage {
    let result = _UNContentStorage()
    result.attachments = attachments
    result.badge = badge
    result.body = body
    result.categoryIdentifier = categoryIdentifier
    result.launchImageName = launchImageName
    result.sound = sound
    result.subtitle = subtitle
    result.threadIdentifier = threadIdentifier
    result.title = title
    result.userInfo = userInfo
    result.summaryArgument = summaryArgument
    result.summaryArgumentCount = summaryArgumentCount
    result.targetContentIdentifier = targetContentIdentifier
    result.interruptionLevel = interruptionLevel
    result.relevanceScore = relevanceScore
    result.filterCriteria = filterCriteria
    return result
  }
}

open class UNNotificationContent: NSObject {
  private let storage: _UNContentStorage

  internal init(storage: _UNContentStorage) {
    self.storage = storage
    super.init()
  }

  open var attachments: [UNNotificationAttachment] { storage.attachments }
  open var badge: NSNumber? { storage.badge }
  open var body: String { storage.body }
  open var categoryIdentifier: String { storage.categoryIdentifier }
  open var launchImageName: String { storage.launchImageName }
  open var sound: UNNotificationSound? { storage.sound }
  open var subtitle: String { storage.subtitle }
  open var threadIdentifier: String { storage.threadIdentifier }
  open var title: String { storage.title }
  open var userInfo: [AnyHashable: Any] { storage.userInfo }
  open var summaryArgument: String { storage.summaryArgument }
  open var summaryArgumentCount: Int { storage.summaryArgumentCount }
  open var targetContentIdentifier: String? { storage.targetContentIdentifier }
  open var interruptionLevel: UNNotificationInterruptionLevel {
    storage.interruptionLevel
  }
  open var relevanceScore: Double { storage.relevanceScore }
  open var filterCriteria: String? { storage.filterCriteria }

  internal func portableCopy() -> UNNotificationContent {
    UNNotificationContent(storage: storage.copied())
  }

  public func updating(
    from provider: any UNNotificationContentProviding
  ) throws -> UNNotificationContent {
    _ = provider
    throw UNError(.contentProvidingInvalid)
  }
}

open class UNMutableNotificationContent: UNNotificationContent {
  private let mutableStorage: _UNContentStorage

  public init() {
    let storage = _UNContentStorage()
    mutableStorage = storage
    super.init(storage: storage)
  }

  public override var attachments: [UNNotificationAttachment] {
    get { mutableStorage.attachments }
    set { mutableStorage.attachments = newValue }
  }
  public override var badge: NSNumber? {
    get { mutableStorage.badge }
    set { mutableStorage.badge = newValue }
  }
  public override var body: String {
    get { mutableStorage.body }
    set { mutableStorage.body = newValue }
  }
  public override var categoryIdentifier: String {
    get { mutableStorage.categoryIdentifier }
    set { mutableStorage.categoryIdentifier = newValue }
  }
  public override var launchImageName: String {
    get { mutableStorage.launchImageName }
    set { mutableStorage.launchImageName = newValue }
  }
  public override var sound: UNNotificationSound? {
    get { mutableStorage.sound }
    set { mutableStorage.sound = newValue }
  }
  public override var subtitle: String {
    get { mutableStorage.subtitle }
    set { mutableStorage.subtitle = newValue }
  }
  public override var threadIdentifier: String {
    get { mutableStorage.threadIdentifier }
    set { mutableStorage.threadIdentifier = newValue }
  }
  public override var title: String {
    get { mutableStorage.title }
    set { mutableStorage.title = newValue }
  }
  public override var userInfo: [AnyHashable: Any] {
    get { mutableStorage.userInfo }
    set { mutableStorage.userInfo = newValue }
  }
  public override var summaryArgument: String {
    get { mutableStorage.summaryArgument }
    set { mutableStorage.summaryArgument = newValue }
  }
  public override var summaryArgumentCount: Int {
    get { mutableStorage.summaryArgumentCount }
    set { mutableStorage.summaryArgumentCount = max(1, newValue) }
  }
  public override var targetContentIdentifier: String? {
    get { mutableStorage.targetContentIdentifier }
    set { mutableStorage.targetContentIdentifier = newValue }
  }
  public override var interruptionLevel: UNNotificationInterruptionLevel {
    get { mutableStorage.interruptionLevel }
    set { mutableStorage.interruptionLevel = newValue }
  }
  public override var relevanceScore: Double {
    get { mutableStorage.relevanceScore }
    set { mutableStorage.relevanceScore = min(1, max(0, newValue)) }
  }
  public override var filterCriteria: String? {
    get { mutableStorage.filterCriteria }
    set { mutableStorage.filterCriteria = newValue }
  }
}

public final class UNNotificationAttachment: NSObject {
  public let identifier: String
  public let url: URL
  public let type: String

  public init(
    identifier: String,
    url: URL,
    options: [AnyHashable: Any]? = nil
  ) throws {
    _ = options
    guard url.isFileURL else { throw UNError(.attachmentInvalidURL) }
    self.identifier = identifier
    self.url = url
    type = url.pathExtension
    super.init()
  }
}

open class UNNotificationTrigger: NSObject {
  public let repeats: Bool

  internal init(repeats: Bool) {
    self.repeats = repeats
    super.init()
  }

  open func nextTriggerDate() -> Date? { nil }
}

public final class UNTimeIntervalNotificationTrigger: UNNotificationTrigger {
  public let timeInterval: TimeInterval

  public init(timeInterval: TimeInterval, repeats: Bool) {
    self.timeInterval = max(0, timeInterval)
    super.init(repeats: repeats)
  }

  public override func nextTriggerDate() -> Date? {
    Date(timeIntervalSinceNow: timeInterval)
  }
}

public final class UNCalendarNotificationTrigger: UNNotificationTrigger {
  public let dateComponents: DateComponents

  public init(dateMatching dateInfo: DateComponents, repeats: Bool) {
    dateComponents = dateInfo
    super.init(repeats: repeats)
  }

  public override func nextTriggerDate() -> Date? {
    Calendar.current.nextDate(
      after: Date(), matching: dateComponents,
      matchingPolicy: .nextTime
    )
  }
}

public final class UNNotificationRequest: NSObject {
  public let identifier: String
  public let content: UNNotificationContent
  public let trigger: UNNotificationTrigger?

  public init(
    identifier: String,
    content: UNNotificationContent,
    trigger: UNNotificationTrigger?
  ) {
    self.identifier = identifier
    self.content = content.portableCopy()
    self.trigger = trigger
    super.init()
  }
}

open class UNNotification: NSObject {
  public let date: Date
  public let request: UNNotificationRequest

  @_spi(OpenUIKitHost)
  public init(date: Date, request: UNNotificationRequest) {
    self.date = date
    self.request = request
    super.init()
  }
}

open class UNNotificationResponse: NSObject {
  public let notification: UNNotification
  public let actionIdentifier: String

  @_spi(OpenUIKitHost)
  public init(notification: UNNotification, actionIdentifier: String) {
    self.notification = notification
    self.actionIdentifier = actionIdentifier
    super.init()
  }
}

public final class UNTextInputNotificationResponse: UNNotificationResponse {
  public let userText: String

  @_spi(OpenUIKitHost)
  public init(
    notification: UNNotification,
    actionIdentifier: String,
    userText: String
  ) {
    self.userText = userText
    super.init(
      notification: notification,
      actionIdentifier: actionIdentifier
    )
  }
}

public struct UNNotificationActionOptions: OptionSet, Sendable {
  public let rawValue: UInt
  public init(rawValue: UInt) { self.rawValue = rawValue }
  public static let authenticationRequired = Self(rawValue: 1 << 0)
  public static let destructive = Self(rawValue: 1 << 1)
  public static let foreground = Self(rawValue: 1 << 2)
}

open class UNNotificationAction: NSObject {
  public let identifier: String
  public let title: String
  public let options: UNNotificationActionOptions

  public init(
    identifier: String,
    title: String,
    options: UNNotificationActionOptions = []
  ) {
    self.identifier = identifier
    self.title = title
    self.options = options
    super.init()
  }
}

public struct UNNotificationCategoryOptions: OptionSet, Sendable {
  public let rawValue: UInt
  public init(rawValue: UInt) { self.rawValue = rawValue }
  public static let customDismissAction = Self(rawValue: 1 << 0)
  public static let allowInCarPlay = Self(rawValue: 1 << 1)
  public static let hiddenPreviewsShowTitle = Self(rawValue: 1 << 2)
  public static let hiddenPreviewsShowSubtitle = Self(rawValue: 1 << 3)
  public static let allowAnnouncement = Self(rawValue: 1 << 4)
}

public final class UNNotificationCategory: NSObject {
  public let identifier: String
  public let actions: [UNNotificationAction]
  public let intentIdentifiers: [String]
  public let hiddenPreviewsBodyPlaceholder: String
  public let categorySummaryFormat: String
  public let options: UNNotificationCategoryOptions

  public init(
    identifier: String,
    actions: [UNNotificationAction],
    intentIdentifiers: [String],
    hiddenPreviewsBodyPlaceholder: String? = nil,
    categorySummaryFormat: String? = nil,
    options: UNNotificationCategoryOptions = []
  ) {
    self.identifier = identifier
    self.actions = actions
    self.intentIdentifiers = intentIdentifiers
    self.hiddenPreviewsBodyPlaceholder = hiddenPreviewsBodyPlaceholder ?? ""
    self.categorySummaryFormat = categorySummaryFormat ?? ""
    self.options = options
    super.init()
  }
}

public protocol UNUserNotificationCenterDelegate: AnyObject {
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification
  ) async -> UNNotificationPresentationOptions

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse
  ) async

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    openSettingsFor notification: UNNotification?
  )
}

extension UNUserNotificationCenterDelegate {
  public func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification
  ) async -> UNNotificationPresentationOptions {
    _ = center
    _ = notification
    return []
  }

  public func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse
  ) async {
    _ = center
    _ = response
  }

  public func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    openSettingsFor notification: UNNotification?
  ) {
    _ = center
    _ = notification
  }
}

private final class _UNCenterState {
  let lock = NSLock()
  var authorizationStatus: UNAuthorizationStatus = .notDetermined
  var requestedOptions: UNAuthorizationOptions = []
  var categories: [String: UNNotificationCategory] = [:]
  var pending: [String: UNNotificationRequest] = [:]
  var delivered: [String: UNNotification] = [:]
  var badgeCount = 0

  func withLock<Result>(_ body: () throws -> Result) rethrows -> Result {
    lock.lock()
    defer { lock.unlock() }
    return try body()
  }
}

public final class UNUserNotificationCenter: NSObject {
  private static let shared = UNUserNotificationCenter()
  private let state = _UNCenterState()

  public weak var delegate: (any UNUserNotificationCenterDelegate)?
  public let supportsContentExtensions = false

  private override init() { super.init() }

  public class func current() -> UNUserNotificationCenter { shared }

  public func requestAuthorization(
    options: UNAuthorizationOptions = [],
    completionHandler: @escaping (Bool, Error?) -> Void
  ) {
    let granted: Bool = state.withLock {
      state.requestedOptions.formUnion(options)
      switch state.authorizationStatus {
      case .authorized, .provisional, .ephemeral:
        return true
      case .notDetermined:
        state.authorizationStatus = .denied
        return false
      case .denied:
        return false
      }
    }
    completionHandler(
      granted,
      granted ? nil : UNError(.notificationsNotAllowed)
    )
  }

  public func requestAuthorization(
    options: UNAuthorizationOptions = []
  ) async throws -> Bool {
    let granted: Bool = state.withLock {
      state.requestedOptions.formUnion(options)
      switch state.authorizationStatus {
      case .authorized, .provisional, .ephemeral:
        return true
      case .notDetermined:
        state.authorizationStatus = .denied
        return false
      case .denied:
        return false
      }
    }
    guard granted else { throw UNError(.notificationsNotAllowed) }
    return true
  }

  public func setNotificationCategories(
    _ categories: Set<UNNotificationCategory>
  ) {
    state.withLock {
      state.categories = Dictionary(
        uniqueKeysWithValues: categories.map { ($0.identifier, $0) }
      )
    }
  }

  public func getNotificationCategories(
    completionHandler: @escaping (Set<UNNotificationCategory>) -> Void
  ) {
    completionHandler(state.withLock { Set(state.categories.values) })
  }

  public func notificationCategories() async -> Set<UNNotificationCategory> {
    state.withLock { Set(state.categories.values) }
  }

  public func getNotificationSettings(
    completionHandler: @escaping (UNNotificationSettings) -> Void
  ) {
    completionHandler(settingsSnapshot())
  }

  public func notificationSettings() async -> UNNotificationSettings {
    settingsSnapshot()
  }

  private func settingsSnapshot() -> UNNotificationSettings {
    state.withLock {
      UNNotificationSettings(
        authorizationStatus: state.authorizationStatus,
        requestedOptions: state.requestedOptions
      )
    }
  }

  public func add(
    _ request: UNNotificationRequest,
    withCompletionHandler completionHandler: ((Error?) -> Void)? = nil
  ) {
    do {
      try addSynchronously(request)
      completionHandler?(nil)
    } catch {
      completionHandler?(error)
    }
  }

  public func add(_ request: UNNotificationRequest) async throws {
    try addSynchronously(request)
  }

  private func addSynchronously(_ request: UNNotificationRequest) throws {
    try state.withLock {
      guard
        state.authorizationStatus == .authorized
          || state.authorizationStatus == .provisional
          || state.authorizationStatus == .ephemeral
      else {
        throw UNError(.notificationsNotAllowed)
      }
      if request.trigger == nil {
        state.delivered[request.identifier] = UNNotification(
          date: Date(), request: request
        )
        state.pending.removeValue(forKey: request.identifier)
      } else {
        state.pending[request.identifier] = request
      }
    }
  }

  public func getPendingNotificationRequests(
    completionHandler: @escaping ([UNNotificationRequest]) -> Void
  ) {
    completionHandler(pendingSnapshot())
  }

  public func pendingNotificationRequests() async -> [UNNotificationRequest] {
    pendingSnapshot()
  }

  private func pendingSnapshot() -> [UNNotificationRequest] {
    state.withLock { state.pending.values.sorted { $0.identifier < $1.identifier } }
  }

  public func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
    state.withLock {
      for identifier in identifiers { state.pending.removeValue(forKey: identifier) }
    }
  }

  public func removeAllPendingNotificationRequests() {
    state.withLock { state.pending.removeAll() }
  }

  public func getDeliveredNotifications(
    completionHandler: @escaping ([UNNotification]) -> Void
  ) {
    completionHandler(deliveredSnapshot())
  }

  public func deliveredNotifications() async -> [UNNotification] {
    deliveredSnapshot()
  }

  private func deliveredSnapshot() -> [UNNotification] {
    state.withLock {
      state.delivered.values.sorted {
        if $0.date != $1.date { return $0.date < $1.date }
        return $0.request.identifier < $1.request.identifier
      }
    }
  }

  public func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
    state.withLock {
      for identifier in identifiers { state.delivered.removeValue(forKey: identifier) }
    }
  }

  public func removeAllDeliveredNotifications() {
    state.withLock { state.delivered.removeAll() }
  }

  public func setBadgeCount(
    _ newBadgeCount: Int,
    withCompletionHandler completionHandler: ((Error?) -> Void)? = nil
  ) {
    do {
      try setBadgeCountSynchronously(newBadgeCount)
      completionHandler?(nil)
    } catch {
      completionHandler?(error)
    }
  }

  public func setBadgeCount(_ newBadgeCount: Int) async throws {
    try setBadgeCountSynchronously(newBadgeCount)
  }

  private func setBadgeCountSynchronously(_ newBadgeCount: Int) throws {
    try state.withLock {
      guard newBadgeCount >= 0 else { throw UNError(.badgeInputInvalid) }
      guard
        state.authorizationStatus == .authorized
          || state.authorizationStatus == .provisional
          || state.authorizationStatus == .ephemeral
      else {
        throw UNError(.notificationsNotAllowed)
      }
      state.badgeCount = newBadgeCount
    }
  }

  @_spi(OpenUIKitHost)
  public func _setPortableAuthorizationStatus(
    _ status: UNAuthorizationStatus,
    options: UNAuthorizationOptions = [.alert, .sound, .badge]
  ) {
    state.withLock {
      state.authorizationStatus = status
      state.requestedOptions = options
    }
  }

  @_spi(OpenUIKitHost)
  public var _portableBadgeCount: Int {
    state.withLock { state.badgeCount }
  }

  @_spi(OpenUIKitHost)
  public func _deliverPortableNotification(
    withIdentifier identifier: String,
    date: Date = Date()
  ) async -> UNNotificationPresentationOptions? {
    let notification: UNNotification? = state.withLock {
      guard let request = state.pending.removeValue(forKey: identifier) else {
        return nil
      }
      let notification = UNNotification(date: date, request: request)
      state.delivered[identifier] = notification
      return notification
    }
    guard let notification else { return nil }
    return await delegate?.userNotificationCenter(
      self, willPresent: notification
    ) ?? []
  }

  @_spi(OpenUIKitHost)
  public func _respondPortable(
    to notification: UNNotification,
    actionIdentifier: String = UNNotificationDefaultActionIdentifier
  ) async {
    let response = UNNotificationResponse(
      notification: notification,
      actionIdentifier: actionIdentifier
    )
    await delegate?.userNotificationCenter(self, didReceive: response)
  }

  @_spi(OpenUIKitHost)
  public func _resetPortableState() {
    state.withLock {
      state.authorizationStatus = .notDetermined
      state.requestedOptions = []
      state.categories.removeAll()
      state.pending.removeAll()
      state.delivered.removeAll()
      state.badgeCount = 0
    }
    delegate = nil
  }
}
