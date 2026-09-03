import Foundation

public let UNErrorDomain = "UNErrorDomain"
public let UNNotificationDefaultActionIdentifier =
  "com.apple.UNNotificationDefaultActionIdentifier"
public let UNNotificationDismissActionIdentifier =
  "com.apple.UNNotificationDismissActionIdentifier"

/// Apple documents these as `UNNotificationAttachmentOptions*` string
/// constants. The pinned public inputs do not include the raw bytes; Linux
/// uses the NS_STRING_ENUM constant names, matching the `UNErrorDomain`
/// pattern, until an Apple-oracle observation lands.
public let UNNotificationAttachmentOptionsTypeHintKey =
  "UNNotificationAttachmentOptionsTypeHintKey"
public let UNNotificationAttachmentOptionsThumbnailHiddenKey =
  "UNNotificationAttachmentOptionsThumbnailHiddenKey"
public let UNNotificationAttachmentOptionsThumbnailClippingRectKey =
  "UNNotificationAttachmentOptionsThumbnailClippingRectKey"
public let UNNotificationAttachmentOptionsThumbnailTimeKey =
  "UNNotificationAttachmentOptionsThumbnailTimeKey"

/// Linux overlay keyed-archive identifiers. Apple's NSSecureCoding keys are
/// not in the pinned public inputs and remain an oracle question.
private enum UNPortableArchive {
  static let versionKey = "OpenUIKit.UserNotifications.archiveVersion"
  static let kindKey = "OpenUIKit.UserNotifications.archiveKind"
  static let version: Int32 = 1
}

private func unDecodeObject<T: NSObject & NSCoding>(
  _ type: T.Type, from coder: NSCoder, key: String
) -> T? {
  guard coder.containsValue(forKey: key) else { return nil }
  return coder.decodeObject(of: type, forKey: key)
}

private func unDecodeObject(
  _ types: [AnyClass], from coder: NSCoder, key: String
) -> Any? {
  guard coder.containsValue(forKey: key) else { return nil }
  return coder.decodeObject(of: types, forKey: key)
}

private func unDecodeString(_ coder: NSCoder, _ key: String) -> String? {
  unDecodeObject(NSString.self, from: coder, key: key) as String?
}

/// Bridged UserNotifications error.
///
/// The pinned API digester records a stored `_nsError: NSError` overlay.
/// Linux Foundation exposes `Foundation._BridgedStoredNSError` and
/// `Foundation._ErrorCodeProtocol`. Foundation's protocol-default
/// `hash(into:)` / `hashValue` witnesses trap (`__HALT`) on this toolchain,
/// so those two Hashable members are provided here.
@frozen
public struct UNError: Foundation._BridgedStoredNSError, @unchecked Sendable,
  CustomStringConvertible
{
  public enum Code: Int, Foundation._ErrorCodeProtocol, Sendable {
    public typealias _ErrorType = UNError

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

  public let _nsError: NSError

  public init(_nsError: NSError) {
    self._nsError = _nsError
  }

  public static var _nsErrorDomain: String { UNErrorDomain }

  public static var notificationsNotAllowed: Code { .notificationsNotAllowed }
  public static var attachmentInvalidURL: Code { .attachmentInvalidURL }
  public static var attachmentUnrecognizedType: Code { .attachmentUnrecognizedType }
  public static var attachmentInvalidFileSize: Code { .attachmentInvalidFileSize }
  public static var attachmentNotInDataStore: Code { .attachmentNotInDataStore }
  public static var attachmentMoveIntoDataStoreFailed: Code {
    .attachmentMoveIntoDataStoreFailed
  }
  public static var attachmentCorrupt: Code { .attachmentCorrupt }
  public static var notificationInvalidNoDate: Code { .notificationInvalidNoDate }
  public static var notificationInvalidNoContent: Code { .notificationInvalidNoContent }
  public static var contentProvidingObjectNotAllowed: Code {
    .contentProvidingObjectNotAllowed
  }
  public static var contentProvidingInvalid: Code { .contentProvidingInvalid }
  public static var badgeInputInvalid: Code { .badgeInputInvalid }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(_nsError.domain)
    hasher.combine(_nsError.code)
  }

  public var hashValue: Int {
    var hasher = Hasher()
    hash(into: &hasher)
    return hasher.finalize()
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

public enum UNAuthorizationStatus: Int, Hashable, Sendable {
  case notDetermined = 0
  case denied = 1
  case authorized = 2
  case provisional = 3
  case ephemeral = 4
}

public enum UNNotificationSetting: Int, Hashable, Sendable {
  case notSupported = 0
  case disabled = 1
  case enabled = 2
}

public enum UNShowPreviewsSetting: Int, Hashable, Sendable {
  case always = 0
  case whenAuthenticated = 1
  case never = 2
}

public enum UNAlertStyle: Int, Hashable, Sendable {
  case none = 0
  case banner = 1
  case alert = 2
}

public enum UNNotificationInterruptionLevel: UInt, Hashable, Sendable {
  case passive = 0
  case active = 1
  case timeSensitive = 2
  case critical = 3
}

public final class UNNotificationSettings: NSObject, NSCopying, NSSecureCoding {
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
    soundSetting: UNNotificationSetting,
    badgeSetting: UNNotificationSetting,
    alertSetting: UNNotificationSetting,
    notificationCenterSetting: UNNotificationSetting,
    lockScreenSetting: UNNotificationSetting,
    carPlaySetting: UNNotificationSetting,
    alertStyle: UNAlertStyle,
    showPreviewsSetting: UNShowPreviewsSetting,
    criticalAlertSetting: UNNotificationSetting,
    providesAppNotificationSettings: Bool,
    announcementSetting: UNNotificationSetting,
    timeSensitiveSetting: UNNotificationSetting,
    scheduledDeliverySetting: UNNotificationSetting,
    directMessagesSetting: UNNotificationSetting
  ) {
    self.authorizationStatus = authorizationStatus
    self.soundSetting = soundSetting
    self.badgeSetting = badgeSetting
    self.alertSetting = alertSetting
    self.notificationCenterSetting = notificationCenterSetting
    self.lockScreenSetting = lockScreenSetting
    self.carPlaySetting = carPlaySetting
    self.alertStyle = alertStyle
    self.showPreviewsSetting = showPreviewsSetting
    self.criticalAlertSetting = criticalAlertSetting
    self.providesAppNotificationSettings = providesAppNotificationSettings
    self.announcementSetting = announcementSetting
    self.timeSensitiveSetting = timeSensitiveSetting
    self.scheduledDeliverySetting = scheduledDeliverySetting
    self.directMessagesSetting = directMessagesSetting
    super.init()
  }

  @usableFromInline
  internal convenience init(
    authorizationStatus: UNAuthorizationStatus,
    requestedOptions: UNAuthorizationOptions
  ) {
    let enabled =
      authorizationStatus == .authorized
      || authorizationStatus == .provisional
      || authorizationStatus == .ephemeral
    func setting(_ option: UNAuthorizationOptions) -> UNNotificationSetting {
      guard requestedOptions.contains(option) else { return .disabled }
      return enabled ? .enabled : .disabled
    }
    self.init(
      authorizationStatus: authorizationStatus,
      soundSetting: setting(.sound),
      badgeSetting: setting(.badge),
      alertSetting: setting(.alert),
      notificationCenterSetting: enabled ? .enabled : .disabled,
      lockScreenSetting: enabled ? .enabled : .disabled,
      carPlaySetting: setting(.carPlay),
      alertStyle: setting(.alert) == .enabled ? .banner : .none,
      showPreviewsSetting: enabled ? .always : .never,
      criticalAlertSetting: setting(.criticalAlert),
      providesAppNotificationSettings:
        enabled && requestedOptions.contains(.providesAppNotificationSettings),
      announcementSetting: setting(.announcement),
      timeSensitiveSetting: setting(.timeSensitive),
      scheduledDeliverySetting: .notSupported,
      directMessagesSetting: .notSupported
    )
  }

  public static var supportsSecureCoding: Bool { true }

  public required init?(coder: NSCoder) {
    guard coder.containsValue(forKey: UNPortableArchive.versionKey) else { return nil }
    let version = coder.decodeInt32(forKey: UNPortableArchive.versionKey)
    guard version == UNPortableArchive.version else { return nil }
    guard
      let authorizationStatus = UNAuthorizationStatus(
        rawValue: Int(coder.decodeInt64(forKey: "authorizationStatus"))
      ),
      let soundSetting = UNNotificationSetting(
        rawValue: Int(coder.decodeInt64(forKey: "soundSetting"))
      ),
      let badgeSetting = UNNotificationSetting(
        rawValue: Int(coder.decodeInt64(forKey: "badgeSetting"))
      ),
      let alertSetting = UNNotificationSetting(
        rawValue: Int(coder.decodeInt64(forKey: "alertSetting"))
      ),
      let notificationCenterSetting = UNNotificationSetting(
        rawValue: Int(coder.decodeInt64(forKey: "notificationCenterSetting"))
      ),
      let lockScreenSetting = UNNotificationSetting(
        rawValue: Int(coder.decodeInt64(forKey: "lockScreenSetting"))
      ),
      let carPlaySetting = UNNotificationSetting(
        rawValue: Int(coder.decodeInt64(forKey: "carPlaySetting"))
      ),
      let alertStyle = UNAlertStyle(
        rawValue: Int(coder.decodeInt64(forKey: "alertStyle"))
      ),
      let showPreviewsSetting = UNShowPreviewsSetting(
        rawValue: Int(coder.decodeInt64(forKey: "showPreviewsSetting"))
      ),
      let criticalAlertSetting = UNNotificationSetting(
        rawValue: Int(coder.decodeInt64(forKey: "criticalAlertSetting"))
      ),
      let announcementSetting = UNNotificationSetting(
        rawValue: Int(coder.decodeInt64(forKey: "announcementSetting"))
      ),
      let timeSensitiveSetting = UNNotificationSetting(
        rawValue: Int(coder.decodeInt64(forKey: "timeSensitiveSetting"))
      ),
      let scheduledDeliverySetting = UNNotificationSetting(
        rawValue: Int(coder.decodeInt64(forKey: "scheduledDeliverySetting"))
      ),
      let directMessagesSetting = UNNotificationSetting(
        rawValue: Int(coder.decodeInt64(forKey: "directMessagesSetting"))
      )
    else {
      return nil
    }
    self.authorizationStatus = authorizationStatus
    self.soundSetting = soundSetting
    self.badgeSetting = badgeSetting
    self.alertSetting = alertSetting
    self.notificationCenterSetting = notificationCenterSetting
    self.lockScreenSetting = lockScreenSetting
    self.carPlaySetting = carPlaySetting
    self.alertStyle = alertStyle
    self.showPreviewsSetting = showPreviewsSetting
    self.criticalAlertSetting = criticalAlertSetting
    self.providesAppNotificationSettings =
      coder.decodeBool(forKey: "providesAppNotificationSettings")
    self.announcementSetting = announcementSetting
    self.timeSensitiveSetting = timeSensitiveSetting
    self.scheduledDeliverySetting = scheduledDeliverySetting
    self.directMessagesSetting = directMessagesSetting
    super.init()
  }

  public func encode(with coder: NSCoder) {
    coder.encode(UNPortableArchive.version, forKey: UNPortableArchive.versionKey)
    coder.encode(Int64(authorizationStatus.rawValue), forKey: "authorizationStatus")
    coder.encode(Int64(soundSetting.rawValue), forKey: "soundSetting")
    coder.encode(Int64(badgeSetting.rawValue), forKey: "badgeSetting")
    coder.encode(Int64(alertSetting.rawValue), forKey: "alertSetting")
    coder.encode(
      Int64(notificationCenterSetting.rawValue), forKey: "notificationCenterSetting"
    )
    coder.encode(Int64(lockScreenSetting.rawValue), forKey: "lockScreenSetting")
    coder.encode(Int64(carPlaySetting.rawValue), forKey: "carPlaySetting")
    coder.encode(Int64(alertStyle.rawValue), forKey: "alertStyle")
    coder.encode(Int64(showPreviewsSetting.rawValue), forKey: "showPreviewsSetting")
    coder.encode(Int64(criticalAlertSetting.rawValue), forKey: "criticalAlertSetting")
    coder.encode(
      providesAppNotificationSettings, forKey: "providesAppNotificationSettings"
    )
    coder.encode(Int64(announcementSetting.rawValue), forKey: "announcementSetting")
    coder.encode(Int64(timeSensitiveSetting.rawValue), forKey: "timeSensitiveSetting")
    coder.encode(
      Int64(scheduledDeliverySetting.rawValue), forKey: "scheduledDeliverySetting"
    )
    coder.encode(Int64(directMessagesSetting.rawValue), forKey: "directMessagesSetting")
  }

  public func copy(with zone: NSZone? = nil) -> Any {
    _ = zone
    return UNNotificationSettings(
      authorizationStatus: authorizationStatus,
      soundSetting: soundSetting,
      badgeSetting: badgeSetting,
      alertSetting: alertSetting,
      notificationCenterSetting: notificationCenterSetting,
      lockScreenSetting: lockScreenSetting,
      carPlaySetting: carPlaySetting,
      alertStyle: alertStyle,
      showPreviewsSetting: showPreviewsSetting,
      criticalAlertSetting: criticalAlertSetting,
      providesAppNotificationSettings: providesAppNotificationSettings,
      announcementSetting: announcementSetting,
      timeSensitiveSetting: timeSensitiveSetting,
      scheduledDeliverySetting: scheduledDeliverySetting,
      directMessagesSetting: directMessagesSetting
    )
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

open class UNNotificationSound: NSObject, NSCopying, NSSecureCoding {
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

  public static var supportsSecureCoding: Bool { true }

  public required init?(coder: NSCoder) {
    guard coder.containsValue(forKey: UNPortableArchive.versionKey) else { return nil }
    let version = coder.decodeInt32(forKey: UNPortableArchive.versionKey)
    guard version == UNPortableArchive.version else { return nil }
    let kindTag = coder.decodeInt64(forKey: "kind")
    let name = unDecodeString(coder, "name")
    let volume = Float(coder.decodeDouble(forKey: "volume"))
    switch kindTag {
    case 0:
      portableKind = .defaultSound
    case 1:
      guard let name else { return nil }
      portableKind = .named(UNNotificationSoundName(name))
    case 2:
      portableKind = .critical(name.map(UNNotificationSoundName.init(_:)), volume)
    case 3:
      guard let name else { return nil }
      portableKind = .ringtone(UNNotificationSoundName(name))
    default:
      return nil
    }
    super.init()
  }

  public func encode(with coder: NSCoder) {
    coder.encode(UNPortableArchive.version, forKey: UNPortableArchive.versionKey)
    switch portableKind {
    case .defaultSound:
      coder.encode(Int64(0), forKey: "kind")
    case .named(let name):
      coder.encode(Int64(1), forKey: "kind")
      coder.encode(name.rawValue as NSString, forKey: "name")
    case .critical(let name, let volume):
      coder.encode(Int64(2), forKey: "kind")
      if let name {
        coder.encode(name.rawValue as NSString, forKey: "name")
      }
      coder.encode(Double(volume), forKey: "volume")
    case .ringtone(let name):
      coder.encode(Int64(3), forKey: "kind")
      coder.encode(name.rawValue as NSString, forKey: "name")
    }
  }

  public func copy(with zone: NSZone? = nil) -> Any {
    _ = zone
    return UNNotificationSound(kind: portableKind)
  }
}

public protocol UNNotificationContentProviding: NSObjectProtocol {}

internal final class _UNContentStorage: NSObject {
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

  func encodeFields(with coder: NSCoder) {
    coder.encode(attachments as NSArray, forKey: "attachments")
    coder.encode(badge, forKey: "badge")
    coder.encode(body as NSString, forKey: "body")
    coder.encode(categoryIdentifier as NSString, forKey: "categoryIdentifier")
    coder.encode(launchImageName as NSString, forKey: "launchImageName")
    coder.encode(sound, forKey: "sound")
    coder.encode(subtitle as NSString, forKey: "subtitle")
    coder.encode(threadIdentifier as NSString, forKey: "threadIdentifier")
    coder.encode(title as NSString, forKey: "title")
    coder.encode(userInfo as NSDictionary, forKey: "userInfo")
    coder.encode(summaryArgument as NSString, forKey: "summaryArgument")
    coder.encode(Int64(summaryArgumentCount), forKey: "summaryArgumentCount")
    if let targetContentIdentifier {
      coder.encode(targetContentIdentifier as NSString, forKey: "targetContentIdentifier")
    }
    coder.encode(Int64(interruptionLevel.rawValue), forKey: "interruptionLevel")
    coder.encode(relevanceScore, forKey: "relevanceScore")
    if let filterCriteria {
      coder.encode(filterCriteria as NSString, forKey: "filterCriteria")
    }
  }

  static func decodeFields(from coder: NSCoder) -> _UNContentStorage? {
    let result = _UNContentStorage()
    if let attachments = unDecodeObject(
      [NSArray.self, UNNotificationAttachment.self],
      from: coder,
      key: "attachments"
    ) as? [UNNotificationAttachment] {
      result.attachments = attachments
    }
    result.badge = unDecodeObject(NSNumber.self, from: coder, key: "badge")
    result.body = unDecodeString(coder, "body") ?? ""
    result.categoryIdentifier = unDecodeString(coder, "categoryIdentifier") ?? ""
    result.launchImageName = unDecodeString(coder, "launchImageName") ?? ""
    result.sound = unDecodeObject(UNNotificationSound.self, from: coder, key: "sound")
    result.subtitle = unDecodeString(coder, "subtitle") ?? ""
    result.threadIdentifier = unDecodeString(coder, "threadIdentifier") ?? ""
    result.title = unDecodeString(coder, "title") ?? ""
    if let dictionary = unDecodeObject(NSDictionary.self, from: coder, key: "userInfo") {
      var restored: [AnyHashable: Any] = [:]
      dictionary.enumerateKeysAndObjects { key, value, _ in
        restored[key as! AnyHashable] = value
      }
      result.userInfo = restored
    }
    result.summaryArgument = unDecodeString(coder, "summaryArgument") ?? ""
    let count = Int(coder.decodeInt64(forKey: "summaryArgumentCount"))
    result.summaryArgumentCount = count > 0 ? count : 1
    result.targetContentIdentifier = unDecodeString(coder, "targetContentIdentifier")
    guard
      let interruptionLevel = UNNotificationInterruptionLevel(
        rawValue: UInt(truncatingIfNeeded: UInt64(bitPattern: coder.decodeInt64(forKey: "interruptionLevel")))
      )
    else {
      return nil
    }
    result.interruptionLevel = interruptionLevel
    result.relevanceScore = coder.decodeDouble(forKey: "relevanceScore")
    result.filterCriteria = unDecodeString(coder, "filterCriteria")
    return result
  }
}

open class UNNotificationContent: NSObject, NSCopying, NSSecureCoding {
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
    throw UNError(.contentProvidingObjectNotAllowed)
  }

  public static var supportsSecureCoding: Bool { true }

  public required init?(coder: NSCoder) {
    guard coder.containsValue(forKey: UNPortableArchive.versionKey) else { return nil }
    let version = coder.decodeInt32(forKey: UNPortableArchive.versionKey)
    guard version == UNPortableArchive.version else { return nil }
    guard let storage = _UNContentStorage.decodeFields(from: coder) else { return nil }
    self.storage = storage
    super.init()
  }

  public func encode(with coder: NSCoder) {
    coder.encode(UNPortableArchive.version, forKey: UNPortableArchive.versionKey)
    storage.encodeFields(with: coder)
  }

  public func copy(with zone: NSZone? = nil) -> Any {
    _ = zone
    return portableCopy()
  }
}

open class UNMutableNotificationContent: UNNotificationContent {
  private let mutableStorage: _UNContentStorage

  public init() {
    let storage = _UNContentStorage()
    mutableStorage = storage
    super.init(storage: storage)
  }

  public required init?(coder: NSCoder) {
    guard coder.containsValue(forKey: UNPortableArchive.versionKey) else { return nil }
    let version = coder.decodeInt32(forKey: UNPortableArchive.versionKey)
    guard version == UNPortableArchive.version else { return nil }
    guard let storage = _UNContentStorage.decodeFields(from: coder) else { return nil }
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

public final class UNNotificationAttachment: NSObject, NSCopying, NSSecureCoding {
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

  public convenience init(
    identifier: String,
    URL: URL,
    options: [AnyHashable: Any]? = nil
  ) throws {
    try self.init(identifier: identifier, url: URL, options: options)
  }

  public static var supportsSecureCoding: Bool { true }

  public required init?(coder: NSCoder) {
    guard coder.containsValue(forKey: UNPortableArchive.versionKey) else { return nil }
    let version = coder.decodeInt32(forKey: UNPortableArchive.versionKey)
    guard version == UNPortableArchive.version else { return nil }
    guard
      let identifier = unDecodeString(coder, "identifier"),
      let url = unDecodeObject(NSURL.self, from: coder, key: "url") as URL?,
      let type = unDecodeString(coder, "type")
    else {
      return nil
    }
    guard url.isFileURL else { return nil }
    self.identifier = identifier
    self.url = url
    self.type = type
    super.init()
  }

  public func encode(with coder: NSCoder) {
    coder.encode(UNPortableArchive.version, forKey: UNPortableArchive.versionKey)
    coder.encode(identifier as NSString, forKey: "identifier")
    coder.encode(url as NSURL, forKey: "url")
    coder.encode(type as NSString, forKey: "type")
  }

  public func copy(with zone: NSZone? = nil) -> Any {
    _ = zone
    return (try? UNNotificationAttachment(identifier: identifier, url: url)) ?? self
  }
}

open class UNNotificationTrigger: NSObject, NSCopying, NSSecureCoding {
  public let repeats: Bool

  internal init(repeats: Bool) {
    self.repeats = repeats
    super.init()
  }

  open func nextTriggerDate() -> Date? { nil }

  public static var supportsSecureCoding: Bool { true }

  public required init?(coder: NSCoder) {
    guard coder.containsValue(forKey: UNPortableArchive.versionKey) else { return nil }
    let version = coder.decodeInt32(forKey: UNPortableArchive.versionKey)
    guard version == UNPortableArchive.version else { return nil }
    repeats = coder.decodeBool(forKey: "repeats")
    super.init()
  }

  public func encode(with coder: NSCoder) {
    coder.encode(UNPortableArchive.version, forKey: UNPortableArchive.versionKey)
    coder.encode(repeats, forKey: "repeats")
  }

  public func copy(with zone: NSZone? = nil) -> Any {
    _ = zone
    return UNNotificationTrigger(repeats: repeats)
  }
}

public final class UNTimeIntervalNotificationTrigger: UNNotificationTrigger {
  public let timeInterval: TimeInterval

  public init(timeInterval: TimeInterval, repeats: Bool) {
    self.timeInterval = max(0, timeInterval)
    super.init(repeats: repeats)
  }

  public required init?(coder: NSCoder) {
    timeInterval = coder.decodeDouble(forKey: "timeInterval")
    super.init(coder: coder)
  }

  public override func encode(with coder: NSCoder) {
    super.encode(with: coder)
    coder.encode(timeInterval, forKey: "timeInterval")
    coder.encode("timeInterval" as NSString, forKey: UNPortableArchive.kindKey)
  }

  public override func nextTriggerDate() -> Date? {
    Date(timeIntervalSinceNow: timeInterval)
  }

  public override func copy(with zone: NSZone? = nil) -> Any {
    _ = zone
    return UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: repeats)
  }
}

public final class UNCalendarNotificationTrigger: UNNotificationTrigger {
  public let dateComponents: DateComponents

  public init(dateMatching dateInfo: DateComponents, repeats: Bool) {
    dateComponents = dateInfo
    super.init(repeats: repeats)
  }

  public convenience init(dateMatchingComponents dateComponents: DateComponents, repeats: Bool) {
    self.init(dateMatching: dateComponents, repeats: repeats)
  }

  public required init?(coder: NSCoder) {
    guard
      let dateComponents = unDecodeObject(
        NSDateComponents.self, from: coder, key: "dateComponents"
      ) as DateComponents?
    else {
      dateComponents = DateComponents()
      super.init(coder: coder)
      return nil
    }
    self.dateComponents = dateComponents
    super.init(coder: coder)
  }

  public override func encode(with coder: NSCoder) {
    super.encode(with: coder)
    coder.encode(dateComponents as NSDateComponents, forKey: "dateComponents")
    coder.encode("calendar" as NSString, forKey: UNPortableArchive.kindKey)
  }

  public override func nextTriggerDate() -> Date? {
    Calendar.current.nextDate(
      after: Date(), matching: dateComponents,
      matchingPolicy: .nextTime
    )
  }

  public override func copy(with zone: NSZone? = nil) -> Any {
    _ = zone
    return UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: repeats)
  }
}

/// System-created remote-notification trigger. Linux has no APNs daemon, so
/// there is no public initializer; the OpenUIKitHost SPI can construct a
/// volatile stand-in for in-process tests.
public final class UNPushNotificationTrigger: UNNotificationTrigger {
  @_spi(OpenUIKitHost)
  public override init(repeats: Bool = false) {
    super.init(repeats: repeats)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  public override func encode(with coder: NSCoder) {
    super.encode(with: coder)
    coder.encode("push" as NSString, forKey: UNPortableArchive.kindKey)
  }

  public override func copy(with zone: NSZone? = nil) -> Any {
    _ = zone
    return UNPushNotificationTrigger(repeats: repeats)
  }
}

/// Location-boundary trigger. `CLRegion` is owned by CoreLocation, which is
/// not a declared dependency of this seed, so the region API is omitted
/// rather than replaced with a module-local lookalike.
public final class UNLocationNotificationTrigger: UNNotificationTrigger {
  @_spi(OpenUIKitHost)
  public override init(repeats: Bool = false) {
    super.init(repeats: repeats)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  public override func encode(with coder: NSCoder) {
    super.encode(with: coder)
    coder.encode("location" as NSString, forKey: UNPortableArchive.kindKey)
  }

  public override func copy(with zone: NSZone? = nil) -> Any {
    _ = zone
    return UNLocationNotificationTrigger(repeats: repeats)
  }
}

public final class UNNotificationRequest: NSObject, NSCopying, NSSecureCoding {
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

  public static var supportsSecureCoding: Bool { true }

  public required init?(coder: NSCoder) {
    guard coder.containsValue(forKey: UNPortableArchive.versionKey) else { return nil }
    let version = coder.decodeInt32(forKey: UNPortableArchive.versionKey)
    guard version == UNPortableArchive.version else { return nil }
    guard
      let identifier = unDecodeString(coder, "identifier"),
      let content = unDecodeObject(
        [UNNotificationContent.self, UNMutableNotificationContent.self],
        from: coder,
        key: "content"
      ) as? UNNotificationContent
    else {
      return nil
    }
    self.identifier = identifier
    self.content = content
    self.trigger = unDecodeObject(
      [
        UNNotificationTrigger.self,
        UNTimeIntervalNotificationTrigger.self,
        UNCalendarNotificationTrigger.self,
        UNPushNotificationTrigger.self,
        UNLocationNotificationTrigger.self,
      ],
      from: coder,
      key: "trigger"
    ) as? UNNotificationTrigger
    super.init()
  }

  public func encode(with coder: NSCoder) {
    coder.encode(UNPortableArchive.version, forKey: UNPortableArchive.versionKey)
    coder.encode(identifier as NSString, forKey: "identifier")
    coder.encode(content, forKey: "content")
    coder.encode(trigger, forKey: "trigger")
  }

  public func copy(with zone: NSZone? = nil) -> Any {
    _ = zone
    return UNNotificationRequest(
      identifier: identifier, content: content, trigger: trigger
    )
  }
}

open class UNNotification: NSObject, NSCopying, NSSecureCoding {
  public let date: Date
  public let request: UNNotificationRequest

  @_spi(OpenUIKitHost)
  public init(date: Date, request: UNNotificationRequest) {
    self.date = date
    self.request = request
    super.init()
  }

  public static var supportsSecureCoding: Bool { true }

  public required init?(coder: NSCoder) {
    guard coder.containsValue(forKey: UNPortableArchive.versionKey) else { return nil }
    let version = coder.decodeInt32(forKey: UNPortableArchive.versionKey)
    guard version == UNPortableArchive.version else { return nil }
    guard
      let date = unDecodeObject(NSDate.self, from: coder, key: "date") as Date?,
      let request = unDecodeObject(UNNotificationRequest.self, from: coder, key: "request")
    else {
      return nil
    }
    self.date = date
    self.request = request
    super.init()
  }

  public func encode(with coder: NSCoder) {
    coder.encode(UNPortableArchive.version, forKey: UNPortableArchive.versionKey)
    coder.encode(date as NSDate, forKey: "date")
    coder.encode(request, forKey: "request")
  }

  public func copy(with zone: NSZone? = nil) -> Any {
    _ = zone
    return UNNotification(date: date, request: request)
  }
}

open class UNNotificationResponse: NSObject, NSCopying, NSSecureCoding {
  public let notification: UNNotification
  public let actionIdentifier: String

  @_spi(OpenUIKitHost)
  public init(notification: UNNotification, actionIdentifier: String) {
    self.notification = notification
    self.actionIdentifier = actionIdentifier
    super.init()
  }

  public static var supportsSecureCoding: Bool { true }

  public required init?(coder: NSCoder) {
    guard coder.containsValue(forKey: UNPortableArchive.versionKey) else { return nil }
    let version = coder.decodeInt32(forKey: UNPortableArchive.versionKey)
    guard version == UNPortableArchive.version else { return nil }
    guard
      let notification = unDecodeObject(
        UNNotification.self, from: coder, key: "notification"
      ),
      let actionIdentifier = unDecodeString(coder, "actionIdentifier")
    else {
      return nil
    }
    self.notification = notification
    self.actionIdentifier = actionIdentifier
    super.init()
  }

  public func encode(with coder: NSCoder) {
    coder.encode(UNPortableArchive.version, forKey: UNPortableArchive.versionKey)
    coder.encode(notification, forKey: "notification")
    coder.encode(actionIdentifier as NSString, forKey: "actionIdentifier")
  }

  public func copy(with zone: NSZone? = nil) -> Any {
    _ = zone
    return UNNotificationResponse(
      notification: notification, actionIdentifier: actionIdentifier
    )
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

  public required init?(coder: NSCoder) {
    userText = unDecodeString(coder, "userText") ?? ""
    super.init(coder: coder)
  }

  public override func encode(with coder: NSCoder) {
    super.encode(with: coder)
    coder.encode(userText as NSString, forKey: "userText")
  }
}

public struct UNNotificationActionOptions: OptionSet, Sendable {
  public let rawValue: UInt
  public init(rawValue: UInt) { self.rawValue = rawValue }
  public static let authenticationRequired = Self(rawValue: 1 << 0)
  public static let destructive = Self(rawValue: 1 << 1)
  public static let foreground = Self(rawValue: 1 << 2)
}

public final class UNNotificationActionIcon: NSObject, NSCopying, NSSecureCoding {
  public let systemImageName: String?
  public let templateImageName: String?

  public init(systemImageName: String) {
    self.systemImageName = systemImageName
    self.templateImageName = nil
    super.init()
  }

  public init(templateImageName: String) {
    self.systemImageName = nil
    self.templateImageName = templateImageName
    super.init()
  }

  public static var supportsSecureCoding: Bool { true }

  public required init?(coder: NSCoder) {
    guard coder.containsValue(forKey: UNPortableArchive.versionKey) else { return nil }
    let version = coder.decodeInt32(forKey: UNPortableArchive.versionKey)
    guard version == UNPortableArchive.version else { return nil }
    systemImageName = unDecodeString(coder, "systemImageName")
    templateImageName = unDecodeString(coder, "templateImageName")
    super.init()
  }

  public func encode(with coder: NSCoder) {
    coder.encode(UNPortableArchive.version, forKey: UNPortableArchive.versionKey)
    if let systemImageName {
      coder.encode(systemImageName as NSString, forKey: "systemImageName")
    }
    if let templateImageName {
      coder.encode(templateImageName as NSString, forKey: "templateImageName")
    }
  }

  public func copy(with zone: NSZone? = nil) -> Any {
    _ = zone
    if let systemImageName {
      return UNNotificationActionIcon(systemImageName: systemImageName)
    }
    return UNNotificationActionIcon(templateImageName: templateImageName ?? "")
  }
}

open class UNNotificationAction: NSObject, NSCopying, NSSecureCoding {
  public let identifier: String
  public let title: String
  public let options: UNNotificationActionOptions
  public let icon: UNNotificationActionIcon?

  public init(
    identifier: String,
    title: String,
    options: UNNotificationActionOptions = [],
    icon: UNNotificationActionIcon? = nil
  ) {
    self.identifier = identifier
    self.title = title
    self.options = options
    self.icon = icon
    super.init()
  }

  public static var supportsSecureCoding: Bool { true }

  public required init?(coder: NSCoder) {
    guard coder.containsValue(forKey: UNPortableArchive.versionKey) else { return nil }
    let version = coder.decodeInt32(forKey: UNPortableArchive.versionKey)
    guard version == UNPortableArchive.version else { return nil }
    guard
      let identifier = unDecodeString(coder, "identifier"),
      let title = unDecodeString(coder, "title")
    else {
      return nil
    }
    self.identifier = identifier
    self.title = title
    options = UNNotificationActionOptions(
      rawValue: UInt(truncatingIfNeeded: UInt64(bitPattern: coder.decodeInt64(forKey: "options")))
    )
    icon = unDecodeObject(UNNotificationActionIcon.self, from: coder, key: "icon")
    super.init()
  }

  public func encode(with coder: NSCoder) {
    coder.encode(UNPortableArchive.version, forKey: UNPortableArchive.versionKey)
    coder.encode(identifier as NSString, forKey: "identifier")
    coder.encode(title as NSString, forKey: "title")
    coder.encode(Int64(bitPattern: UInt64(options.rawValue)), forKey: "options")
    coder.encode(icon, forKey: "icon")
  }

  public func copy(with zone: NSZone? = nil) -> Any {
    _ = zone
    return UNNotificationAction(
      identifier: identifier, title: title, options: options, icon: icon
    )
  }
}

public final class UNTextInputNotificationAction: UNNotificationAction {
  public let textInputButtonTitle: String
  public let textInputPlaceholder: String

  public init(
    identifier: String,
    title: String,
    options: UNNotificationActionOptions = [],
    icon: UNNotificationActionIcon? = nil,
    textInputButtonTitle: String,
    textInputPlaceholder: String
  ) {
    self.textInputButtonTitle = textInputButtonTitle
    self.textInputPlaceholder = textInputPlaceholder
    super.init(identifier: identifier, title: title, options: options, icon: icon)
  }

  public convenience init(
    identifier: String,
    title: String,
    options: UNNotificationActionOptions = [],
    textInputButtonTitle: String,
    textInputPlaceholder: String
  ) {
    self.init(
      identifier: identifier,
      title: title,
      options: options,
      icon: nil,
      textInputButtonTitle: textInputButtonTitle,
      textInputPlaceholder: textInputPlaceholder
    )
  }

  public required init?(coder: NSCoder) {
    textInputButtonTitle = unDecodeString(coder, "textInputButtonTitle") ?? ""
    textInputPlaceholder = unDecodeString(coder, "textInputPlaceholder") ?? ""
    super.init(coder: coder)
  }

  public override func encode(with coder: NSCoder) {
    super.encode(with: coder)
    coder.encode(textInputButtonTitle as NSString, forKey: "textInputButtonTitle")
    coder.encode(textInputPlaceholder as NSString, forKey: "textInputPlaceholder")
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

public final class UNNotificationCategory: NSObject, NSCopying, NSSecureCoding {
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

  public convenience init(
    identifier: String,
    actions: [UNNotificationAction],
    intentIdentifiers: [String],
    hiddenPreviewsBodyPlaceholder: String,
    options: UNNotificationCategoryOptions = []
  ) {
    self.init(
      identifier: identifier,
      actions: actions,
      intentIdentifiers: intentIdentifiers,
      hiddenPreviewsBodyPlaceholder: hiddenPreviewsBodyPlaceholder,
      categorySummaryFormat: nil,
      options: options
    )
  }

  public convenience init(
    identifier: String,
    actions: [UNNotificationAction],
    intentIdentifiers: [String],
    options: UNNotificationCategoryOptions = []
  ) {
    self.init(
      identifier: identifier,
      actions: actions,
      intentIdentifiers: intentIdentifiers,
      hiddenPreviewsBodyPlaceholder: nil,
      categorySummaryFormat: nil,
      options: options
    )
  }

  public static var supportsSecureCoding: Bool { true }

  public required init?(coder: NSCoder) {
    guard coder.containsValue(forKey: UNPortableArchive.versionKey) else { return nil }
    let version = coder.decodeInt32(forKey: UNPortableArchive.versionKey)
    guard version == UNPortableArchive.version else { return nil }
    guard
      let identifier = unDecodeString(coder, "identifier")
    else {
      return nil
    }
    self.identifier = identifier
    actions =
      (unDecodeObject(
        [NSArray.self, UNNotificationAction.self, UNTextInputNotificationAction.self],
        from: coder,
        key: "actions"
      ) as? [UNNotificationAction]) ?? []
    intentIdentifiers =
      (unDecodeObject(
        [NSArray.self, NSString.self], from: coder, key: "intentIdentifiers"
      ) as? [String]) ?? []
    hiddenPreviewsBodyPlaceholder =
      unDecodeString(coder, "hiddenPreviewsBodyPlaceholder") ?? ""
    categorySummaryFormat = unDecodeString(coder, "categorySummaryFormat") ?? ""
    options = UNNotificationCategoryOptions(
      rawValue: UInt(truncatingIfNeeded: UInt64(bitPattern: coder.decodeInt64(forKey: "options")))
    )
    super.init()
  }

  public func encode(with coder: NSCoder) {
    coder.encode(UNPortableArchive.version, forKey: UNPortableArchive.versionKey)
    coder.encode(identifier as NSString, forKey: "identifier")
    coder.encode(actions as NSArray, forKey: "actions")
    coder.encode(intentIdentifiers as NSArray, forKey: "intentIdentifiers")
    coder.encode(
      hiddenPreviewsBodyPlaceholder as NSString, forKey: "hiddenPreviewsBodyPlaceholder"
    )
    coder.encode(categorySummaryFormat as NSString, forKey: "categorySummaryFormat")
    coder.encode(Int64(bitPattern: UInt64(options.rawValue)), forKey: "options")
  }

  public func copy(with zone: NSZone? = nil) -> Any {
    _ = zone
    return UNNotificationCategory(
      identifier: identifier,
      actions: actions,
      intentIdentifiers: intentIdentifiers,
      hiddenPreviewsBodyPlaceholder: hiddenPreviewsBodyPlaceholder,
      categorySummaryFormat: categorySummaryFormat,
      options: options
    )
  }
}

/// `INSendMessageIntent` is owned by Intents, which is not a declared
/// dependency. The attributed-message initializer is omitted rather than
/// replaced with a module-local lookalike. The class still exists so
/// `UNNotificationContentProviding` type checks compile.
public final class UNNotificationAttributedMessageContext: NSObject,
  UNNotificationContentProviding
{
}

open class UNNotificationServiceExtension: NSObject {
  public override init() {
    super.init()
  }

  /// Base implementation fail-closes by delivering the original request
  /// content. Subclasses that mutate payloads must still call the handler;
  /// Linux has no Notification Service Extension host to enforce the
  /// expiration window.
  open func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    contentHandler(request.content)
  }

  open func serviceExtensionTimeWillExpire() {}
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

extension NSString {
  /// Linux has no UserNotifications strings table. Missing keys return the
  /// key itself; non-empty `arguments` are formatted with `String(format:)`.
  public class func localizedUserNotificationString(
    forKey key: String,
    arguments: [Any]?
  ) -> String {
    let localized = Bundle.main.localizedString(forKey: key, value: key, table: nil)
    guard let arguments, !arguments.isEmpty else { return localized }
    let vars: [CVarArg] = arguments.map { value -> CVarArg in
      if let int = value as? Int { return int }
      if let number = value as? NSNumber { return number.intValue }
      if let string = value as? String { return string }
      if let string = value as? NSString { return string as String }
      return String(describing: value)
    }
    return String(format: localized, arguments: vars)
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
