import Dispatch
import Foundation
@_spi(OpenUIKitHost) import UserNotifications

private final class UNLocked<Value>: @unchecked Sendable {
  private let lock = NSLock()
  private var value: Value

  init(_ value: Value) {
    self.value = value
  }

  func load() -> Value {
    lock.lock()
    defer { lock.unlock() }
    return value
  }

  func store(_ value: Value) {
    lock.lock()
    self.value = value
    lock.unlock()
  }
}

private func unAwait<T>(_ body: @escaping () async throws -> T) -> Result<T, Error> {
  let semaphore = DispatchSemaphore(value: 0)
  let box = UNLocked<Result<T, Error>?>(nil)
  Task {
    do {
      box.store(.success(try await body()))
    } catch {
      box.store(.failure(error))
    }
    semaphore.signal()
  }
  semaphore.wait()
  guard let result = box.load() else {
    preconditionFailure("async probe did not complete")
  }
  return result
}

private func unResetCenter() -> UNUserNotificationCenter {
  let center = UNUserNotificationCenter.current()
  center._resetPortableState()
  return center
}

private func unArchiveRoundTrip<T: NSObject & NSSecureCoding>(_ value: T) -> T {
  let data: Data
  do {
    data = try NSKeyedArchiver.archivedData(
      withRootObject: value, requiringSecureCoding: true
    )
  } catch {
    preconditionFailure("archive failed: \(error)")
  }
  do {
    guard let restored = try NSKeyedUnarchiver.unarchivedObject(ofClass: T.self, from: data)
    else {
      preconditionFailure("expected restored \(T.self)")
    }
    return restored
  } catch {
    preconditionFailure("unarchive failed: \(error)")
  }
}

private func unRejectsEmptyCoder<T: NSObject & NSSecureCoding>(_ type: T.Type) {
  do {
    let data = try NSKeyedArchiver.archivedData(
      withRootObject: "un-malformed", requiringSecureCoding: true
    )
    let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
    unarchiver.requiresSecureCoding = true
    precondition(type.init(coder: unarchiver) == nil)
  } catch {
    preconditionFailure("malformed archive setup failed: \(error)")
  }
}

private func unExerciseOptionSet<T: OptionSet>(
  empty: T,
  a: T,
  b: T
) where T.Element == T, T: Equatable {
  precondition(empty.isEmpty)
  precondition(!a.isEmpty)
  precondition(a != empty)
  precondition(T().isEmpty)
  precondition(T(rawValue: a.rawValue) == a)
  var copy = empty
  let inserted = copy.insert(a)
  precondition(inserted.inserted)
  precondition(copy.contains(a))
  precondition(!copy.contains(b) || a == b)
  _ = copy.update(with: a)
  let removed = copy.remove(a)
  precondition(removed != nil)
  copy.formUnion(a)
  copy.formIntersection(a)
  copy.formSymmetricDifference(b)
  copy.subtract(b)
  _ = a.union(b)
  _ = a.intersection(b)
  _ = a.symmetricDifference(b)
  _ = a.subtracting(b)
  _ = a.isSubset(of: a.union(b))
  _ = a.isSuperset(of: a)
  _ = a.isDisjoint(with: empty)
  _ = a.isStrictSubset(of: a.union(b))
  _ = a.isStrictSuperset(of: empty)
  _ = T([a, b])
}

func testUNErrorDomain() {
  precondition(UNErrorDomain == "UNErrorDomain")
  precondition(UNError.errorDomain == "UNErrorDomain")
  precondition(UNError.errorDomain == UNErrorDomain)
  precondition(UNError._nsErrorDomain == UNErrorDomain)
}

func testUNErrorCodes() {
  precondition(UNError.Code.notificationsNotAllowed.rawValue == 1)
  precondition(UNError.Code.attachmentInvalidURL.rawValue == 100)
  precondition(UNError.Code.attachmentUnrecognizedType.rawValue == 101)
  precondition(UNError.Code.attachmentInvalidFileSize.rawValue == 102)
  precondition(UNError.Code.attachmentNotInDataStore.rawValue == 103)
  precondition(UNError.Code.attachmentMoveIntoDataStoreFailed.rawValue == 104)
  precondition(UNError.Code.attachmentCorrupt.rawValue == 105)
  precondition(UNError.Code.notificationInvalidNoDate.rawValue == 1400)
  precondition(UNError.Code.notificationInvalidNoContent.rawValue == 1401)
  precondition(UNError.Code.contentProvidingObjectNotAllowed.rawValue == 1500)
  precondition(UNError.Code.contentProvidingInvalid.rawValue == 1501)
  precondition(UNError.Code.badgeInputInvalid.rawValue == 1600)
  precondition(UNError.Code(rawValue: 1) == .notificationsNotAllowed)
  precondition(UNError.Code(rawValue: 99) == nil)
  precondition(UNError.notificationsNotAllowed == .notificationsNotAllowed)
  precondition(UNError.attachmentInvalidURL == .attachmentInvalidURL)
  precondition(UNError.attachmentUnrecognizedType == .attachmentUnrecognizedType)
  precondition(UNError.attachmentInvalidFileSize == .attachmentInvalidFileSize)
  precondition(UNError.attachmentNotInDataStore == .attachmentNotInDataStore)
  precondition(UNError.attachmentMoveIntoDataStoreFailed == .attachmentMoveIntoDataStoreFailed)
  precondition(UNError.attachmentCorrupt == .attachmentCorrupt)
  precondition(UNError.notificationInvalidNoDate == .notificationInvalidNoDate)
  precondition(UNError.notificationInvalidNoContent == .notificationInvalidNoContent)
  precondition(UNError.contentProvidingObjectNotAllowed == .contentProvidingObjectNotAllowed)
  precondition(UNError.contentProvidingInvalid == .contentProvidingInvalid)
  precondition(UNError.badgeInputInvalid == .badgeInputInvalid)
}

func testUNErrorEqualityAndHash() {
  let empty = UNError(.notificationsNotAllowed)
  let other = UNError(.badgeInputInvalid)
  let withInfo = UNError(.notificationsNotAllowed, userInfo: ["sentinel": "value"])
  precondition(empty == UNError(.notificationsNotAllowed))
  precondition(empty != other)
  precondition(empty.code == .notificationsNotAllowed)
  precondition(empty.errorCode == 1)
  precondition(withInfo.userInfo["sentinel"] as? String == "value")
  precondition(withInfo.errorUserInfo["sentinel"] as? String == "value")
  var hasherA = Hasher()
  var hasherB = Hasher()
  empty.hash(into: &hasherA)
  UNError(.notificationsNotAllowed).hash(into: &hasherB)
  precondition(hasherA.finalize() == hasherB.finalize())
  precondition(empty.hashValue == UNError(.notificationsNotAllowed).hashValue)
  precondition(!empty.localizedDescription.isEmpty)
}

func testUNErrorThrowCatch() {
  do {
    throw UNError(.notificationsNotAllowed)
  } catch let error as UNError where error.code == .notificationsNotAllowed {
    precondition(UNError.Code.notificationsNotAllowed ~= error)
    precondition(!(UNError.Code.badgeInputInvalid ~= error))
  } catch {
    preconditionFailure("expected UNError")
  }
}

func testActionIdentifierConstants() {
  precondition(
    UNNotificationDefaultActionIdentifier
      == "com.apple.UNNotificationDefaultActionIdentifier"
  )
  precondition(
    UNNotificationDismissActionIdentifier
      == "com.apple.UNNotificationDismissActionIdentifier"
  )
}

func testAttachmentOptionKeys() {
  precondition(
    UNNotificationAttachmentOptionsTypeHintKey
      == "UNNotificationAttachmentOptionsTypeHintKey"
  )
  precondition(
    UNNotificationAttachmentOptionsThumbnailHiddenKey
      == "UNNotificationAttachmentOptionsThumbnailHiddenKey"
  )
  precondition(
    UNNotificationAttachmentOptionsThumbnailClippingRectKey
      == "UNNotificationAttachmentOptionsThumbnailClippingRectKey"
  )
  precondition(
    UNNotificationAttachmentOptionsThumbnailTimeKey
      == "UNNotificationAttachmentOptionsThumbnailTimeKey"
  )
}

func testLocalizedUserNotificationString() {
  let key = NSString.localizedUserNotificationString(
    forKey: "hello-%d", arguments: nil
  )
  precondition(key == "hello-%d")
  let formatted = NSString.localizedUserNotificationString(
    forKey: "hello-%d", arguments: [7]
  )
  precondition(formatted == "hello-7")
}

func testEnumRawValues() {
  precondition(UNAlertStyle.none.rawValue == 0)
  precondition(UNAlertStyle.banner.rawValue == 1)
  precondition(UNAlertStyle.alert.rawValue == 2)
  precondition(UNAlertStyle(rawValue: 1) == .banner)
  precondition(UNAlertStyle.none != .alert)
  precondition(UNAlertStyle.banner.hashValue == UNAlertStyle.banner.hashValue)
  var hasher = Hasher()
  UNAlertStyle.alert.hash(into: &hasher)
  _ = hasher.finalize()

  precondition(UNAuthorizationStatus.notDetermined.rawValue == 0)
  precondition(UNAuthorizationStatus.denied.rawValue == 1)
  precondition(UNAuthorizationStatus.authorized.rawValue == 2)
  precondition(UNAuthorizationStatus.provisional.rawValue == 3)
  precondition(UNAuthorizationStatus.ephemeral.rawValue == 4)
  precondition(UNAuthorizationStatus(rawValue: 2) == .authorized)
  precondition(UNAuthorizationStatus.denied != .authorized)
  precondition(
    UNAuthorizationStatus.authorized.hashValue
      == UNAuthorizationStatus.authorized.hashValue
  )
  var statusHasher = Hasher()
  UNAuthorizationStatus.provisional.hash(into: &statusHasher)
  _ = statusHasher.finalize()

  precondition(UNNotificationSetting.notSupported.rawValue == 0)
  precondition(UNNotificationSetting.disabled.rawValue == 1)
  precondition(UNNotificationSetting.enabled.rawValue == 2)
  precondition(UNNotificationSetting(rawValue: 1) == .disabled)
  precondition(UNNotificationSetting.enabled != .disabled)
  var settingHasher = Hasher()
  UNNotificationSetting.enabled.hash(into: &settingHasher)
  precondition(
    UNNotificationSetting.enabled.hashValue
      == UNNotificationSetting.enabled.hashValue
  )
  _ = settingHasher.finalize()

  precondition(UNShowPreviewsSetting.always.rawValue == 0)
  precondition(UNShowPreviewsSetting.whenAuthenticated.rawValue == 1)
  precondition(UNShowPreviewsSetting.never.rawValue == 2)
  precondition(UNShowPreviewsSetting(rawValue: 2) == .never)
  precondition(UNShowPreviewsSetting.always != .never)
  var previewHasher = Hasher()
  UNShowPreviewsSetting.never.hash(into: &previewHasher)
  precondition(
    UNShowPreviewsSetting.always.hashValue
      == UNShowPreviewsSetting.always.hashValue
  )
  _ = previewHasher.finalize()

  precondition(UNNotificationInterruptionLevel.passive.rawValue == 0)
  precondition(UNNotificationInterruptionLevel.active.rawValue == 1)
  precondition(UNNotificationInterruptionLevel.timeSensitive.rawValue == 2)
  precondition(UNNotificationInterruptionLevel.critical.rawValue == 3)
  precondition(UNNotificationInterruptionLevel(rawValue: 2) == .timeSensitive)
  precondition(UNNotificationInterruptionLevel.active != .critical)
  var levelHasher = Hasher()
  UNNotificationInterruptionLevel.critical.hash(into: &levelHasher)
  precondition(
    UNNotificationInterruptionLevel.active.hashValue
      == UNNotificationInterruptionLevel.active.hashValue
  )
  _ = levelHasher.finalize()

  var codeHasher = Hasher()
  UNError.Code.badgeInputInvalid.hash(into: &codeHasher)
  precondition(
    UNError.Code.notificationsNotAllowed.hashValue
      == UNError.Code.notificationsNotAllowed.hashValue
  )
  _ = codeHasher.finalize()
}

func testAuthorizationOptionsOptionSet() {
  unExerciseOptionSet(
    empty: UNAuthorizationOptions(),
    a: .alert,
    b: .sound
  )
  let options: UNAuthorizationOptions = [.alert, .sound, .badge]
  precondition(options.contains(.alert))
  precondition(options.contains(.sound))
  precondition(options.contains(.badge))
  precondition(!options.contains(.carPlay))
  _ = UNAuthorizationOptions.criticalAlert
  _ = UNAuthorizationOptions.providesAppNotificationSettings
  _ = UNAuthorizationOptions.provisional
  _ = UNAuthorizationOptions.announcement
  _ = UNAuthorizationOptions.timeSensitive
}

func testActionOptionsOptionSet() {
  unExerciseOptionSet(
    empty: UNNotificationActionOptions(),
    a: .foreground,
    b: .destructive
  )
  let options: UNNotificationActionOptions = [
    .authenticationRequired, .destructive, .foreground,
  ]
  precondition(options.contains(.authenticationRequired))
}

func testCategoryOptionsOptionSet() {
  unExerciseOptionSet(
    empty: UNNotificationCategoryOptions(),
    a: .customDismissAction,
    b: .allowInCarPlay
  )
  let options: UNNotificationCategoryOptions = [
    .customDismissAction, .allowInCarPlay, .hiddenPreviewsShowTitle,
    .hiddenPreviewsShowSubtitle, .allowAnnouncement,
  ]
  precondition(options.contains(.hiddenPreviewsShowTitle))
}

func testPresentationOptionsOptionSet() {
  unExerciseOptionSet(
    empty: UNNotificationPresentationOptions(),
    a: .banner,
    b: .sound
  )
  let options: UNNotificationPresentationOptions = [
    .badge, .sound, .alert, .list, .banner,
  ]
  precondition(options.contains(.list))
}

func testNotificationSoundName() {
  let named = UNNotificationSoundName(rawValue: "ping")
  let aliased = UNNotificationSoundName("ping")
  precondition(named == aliased)
  precondition(named != UNNotificationSoundName("other"))
  precondition(named.hashValue == aliased.hashValue)
  var hasher = Hasher()
  named.hash(into: &hasher)
  _ = hasher.finalize()
  let literal: UNNotificationSoundName = "ping"
  precondition(literal.rawValue == "ping")
}

func testNotificationSoundFactories() {
  precondition(UNNotificationSound.default.portableKind == .defaultSound)
  precondition(UNNotificationSound.defaultCritical.portableKind == .critical(nil, 1))
  precondition(UNNotificationSound.defaultRingtone.portableKind == .ringtone("default"))
  let named = UNNotificationSound(named: "custom")
  precondition(named.portableKind == .named("custom"))
  let critical = UNNotificationSound.criticalSoundNamed("crit")
  precondition(critical.portableKind == .critical("crit", 1))
  let criticalVolume = UNNotificationSound.criticalSoundNamed(
    "crit", withAudioVolume: 0.5
  )
  precondition(criticalVolume.portableKind == .critical("crit", 0.5))
  let defaultCriticalVolume = UNNotificationSound.defaultCriticalSound(
    withAudioVolume: 0.25
  )
  precondition(defaultCriticalVolume.portableKind == .critical(nil, 0.25))
  let ringtone = UNNotificationSound.ringtoneSoundNamed("tone")
  precondition(ringtone.portableKind == .ringtone("tone"))
}

func testMutableContentRoundTrip() {
  let content = UNMutableNotificationContent()
  content.title = "Title"
  content.subtitle = "Sub"
  content.body = "Body"
  content.badge = 3
  content.categoryIdentifier = "cat"
  content.launchImageName = "launch"
  content.sound = .default
  content.threadIdentifier = "thread"
  content.userInfo = ["k": "v"]
  content.summaryArgument = "arg"
  content.summaryArgumentCount = 4
  content.targetContentIdentifier = "target"
  content.interruptionLevel = .timeSensitive
  content.relevanceScore = 0.75
  content.filterCriteria = "filter"
  let url = URL(fileURLWithPath: "/tmp/un-content.png")
  content.attachments = [
    try! UNNotificationAttachment(identifier: "a", url: url)
  ]
  precondition(content.title == "Title")
  precondition(content.subtitle == "Sub")
  precondition(content.body == "Body")
  precondition(content.badge == 3)
  precondition(content.categoryIdentifier == "cat")
  precondition(content.launchImageName == "launch")
  precondition(content.sound?.portableKind == .defaultSound)
  precondition(content.threadIdentifier == "thread")
  precondition(content.userInfo["k"] as? String == "v")
  precondition(content.summaryArgument == "arg")
  precondition(content.summaryArgumentCount == 4)
  precondition(content.targetContentIdentifier == "target")
  precondition(content.interruptionLevel == .timeSensitive)
  precondition(content.relevanceScore == 0.75)
  precondition(content.filterCriteria == "filter")
  precondition(content.attachments.count == 1)
  content.summaryArgumentCount = 0
  precondition(content.summaryArgumentCount == 1)
  content.relevanceScore = 2
  precondition(content.relevanceScore == 1)
  content.relevanceScore = -1
  precondition(content.relevanceScore == 0)
}

func testContentUpdatingFailsClosed() {
  let provider = UNNotificationAttributedMessageContext()
  do {
    _ = try UNMutableNotificationContent().updating(from: provider)
    preconditionFailure("provider update must fail closed")
  } catch let error as UNError {
    precondition(error.code == .contentProvidingObjectNotAllowed)
  } catch {
    preconditionFailure("unexpected error")
  }
}

func testAttachmentFileURLValidation() {
  do {
    _ = try UNNotificationAttachment(
      identifier: "bad",
      url: URL(string: "https://example.invalid/a.png")!
    )
    preconditionFailure("non-file URL must fail")
  } catch let error as UNError {
    precondition(error.code == .attachmentInvalidURL)
  } catch {
    preconditionFailure("unexpected error")
  }
  let file = URL(fileURLWithPath: "/tmp/un-attach.jpg")
  let attachment = try! UNNotificationAttachment(
    identifier: "ok",
    url: file,
    options: [UNNotificationAttachmentOptionsTypeHintKey: "public.jpeg"]
  )
  precondition(attachment.identifier == "ok")
  precondition(attachment.url == file)
  precondition(attachment.type == "jpg")
  let aliased = try! UNNotificationAttachment(
    identifier: "alias",
    URL: file
  )
  precondition(aliased.identifier == "alias")
}

func testTimeIntervalTrigger() {
  let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: true)
  precondition(trigger.timeInterval == 5)
  precondition(trigger.repeats)
  precondition(trigger.nextTriggerDate() != nil)
  let clamped = UNTimeIntervalNotificationTrigger(timeInterval: -1, repeats: false)
  precondition(clamped.timeInterval == 0)
}

func testCalendarTrigger() {
  var components = DateComponents()
  components.hour = 8
  components.minute = 30
  let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
  precondition(trigger.dateComponents.hour == 8)
  precondition(trigger.repeats)
  let aliased = UNCalendarNotificationTrigger(
    dateMatchingComponents: components, repeats: false
  )
  precondition(aliased.dateComponents.minute == 30)
  _ = trigger.nextTriggerDate()
}

func testPushAndLocationTriggerTypes() {
  let push = UNPushNotificationTrigger(repeats: false)
  precondition(!push.repeats)
  precondition(push.nextTriggerDate() == nil)
  let location = UNLocationNotificationTrigger(repeats: true)
  precondition(location.repeats)
  let asTrigger: UNNotificationTrigger = location
  precondition(type(of: asTrigger) == UNLocationNotificationTrigger.self)
}

func testNotificationRequestSnapshotsContent() {
  let content = UNMutableNotificationContent()
  content.title = "original"
  let request = UNNotificationRequest(
    identifier: "snap",
    content: content,
    trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
  )
  content.title = "mutated"
  precondition(request.identifier == "snap")
  precondition(request.content.title == "original")
  precondition(request.trigger is UNTimeIntervalNotificationTrigger)
}

func testNotificationActionAndIcon() {
  let icon = UNNotificationActionIcon(systemImageName: "star")
  precondition(icon.systemImageName == "star")
  let template = UNNotificationActionIcon(templateImageName: "tmpl")
  precondition(template.templateImageName == "tmpl")
  let action = UNNotificationAction(
    identifier: "act",
    title: "Act",
    options: [.foreground],
    icon: icon
  )
  precondition(action.identifier == "act")
  precondition(action.title == "Act")
  precondition(action.options.contains(.foreground))
  precondition(action.icon === icon)
  let withoutIcon = UNNotificationAction(identifier: "plain", title: "Plain")
  precondition(withoutIcon.icon == nil)
}

func testTextInputNotificationAction() {
  let action = UNTextInputNotificationAction(
    identifier: "reply",
    title: "Reply",
    options: [.authenticationRequired],
    textInputButtonTitle: "Send",
    textInputPlaceholder: "Message"
  )
  precondition(action.textInputButtonTitle == "Send")
  precondition(action.textInputPlaceholder == "Message")
  let withIcon = UNTextInputNotificationAction(
    identifier: "reply2",
    title: "Reply",
    options: [],
    icon: UNNotificationActionIcon(systemImageName: "pencil"),
    textInputButtonTitle: "OK",
    textInputPlaceholder: "…"
  )
  precondition(withIcon.icon?.systemImageName == "pencil")
}

func testNotificationCategoryInits() {
  let action = UNNotificationAction(identifier: "a", title: "A")
  let full = UNNotificationCategory(
    identifier: "full",
    actions: [action],
    intentIdentifiers: ["intent"],
    hiddenPreviewsBodyPlaceholder: "hidden",
    categorySummaryFormat: "%u messages",
    options: [.customDismissAction]
  )
  precondition(full.identifier == "full")
  precondition(full.actions.count == 1)
  precondition(full.intentIdentifiers == ["intent"])
  precondition(full.hiddenPreviewsBodyPlaceholder == "hidden")
  precondition(full.categorySummaryFormat == "%u messages")
  precondition(full.options.contains(.customDismissAction))
  let mid = UNNotificationCategory(
    identifier: "mid",
    actions: [],
    intentIdentifiers: [],
    hiddenPreviewsBodyPlaceholder: "ph",
    options: []
  )
  precondition(mid.hiddenPreviewsBodyPlaceholder == "ph")
  precondition(mid.categorySummaryFormat.isEmpty)
  let short = UNNotificationCategory(
    identifier: "short",
    actions: [],
    intentIdentifiers: [],
    options: [.allowAnnouncement]
  )
  precondition(short.options.contains(.allowAnnouncement))
}

func testServiceExtensionPassThrough() {
  let content = UNMutableNotificationContent()
  content.body = "ext"
  let request = UNNotificationRequest(
    identifier: "ext", content: content, trigger: nil
  )
  let extensionObject = UNNotificationServiceExtension()
  var delivered: String?
  extensionObject.didReceive(request) { updated in
    delivered = updated.body
  }
  precondition(delivered == "ext")
  extensionObject.serviceExtensionTimeWillExpire()
}

func testAttributedMessageContextType() {
  let context = UNNotificationAttributedMessageContext()
  let asProvider: any UNNotificationContentProviding = context
  _ = asProvider
}

func testCenterFailClosedAuthorization() {
  let center = unResetCenter()
  precondition(center.supportsContentExtensions == false)
  precondition(UNUserNotificationCenter.current() === center)
  let settings = unAwait { await center.notificationSettings() }
  guard case .success(let initial) = settings else {
    preconditionFailure("settings failed")
  }
  precondition(initial.authorizationStatus == .notDetermined)
  var callbackCount = 0
  center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
    precondition(!granted)
    precondition((error as? UNError)?.code == .notificationsNotAllowed)
    callbackCount += 1
  }
  precondition(callbackCount == 1)
  let denied = unAwait { await center.notificationSettings() }
  guard case .success(let deniedSettings) = denied else {
    preconditionFailure("denied settings failed")
  }
  precondition(deniedSettings.authorizationStatus == .denied)
  let asyncDenied = unAwait {
    try await center.requestAuthorization(options: [.alert])
  }
  guard case .failure(let error as UNError) = asyncDenied else {
    preconditionFailure("async authorization must fail closed")
  }
  precondition(error.code == .notificationsNotAllowed)
}

func testCenterFailClosedSchedulingAndBadge() {
  let center = unResetCenter()
  let content = UNMutableNotificationContent()
  content.body = "nope"
  let request = UNNotificationRequest(
    identifier: "denied", content: content, trigger: nil
  )
  let addResult = unAwait { try await center.add(request) }
  guard case .failure(let error as UNError) = addResult else {
    preconditionFailure("unauthorized add must fail")
  }
  precondition(error.code == .notificationsNotAllowed)
  let badgeResult = unAwait { try await center.setBadgeCount(1) }
  guard case .failure(let badgeError as UNError) = badgeResult else {
    preconditionFailure("unauthorized badge must fail")
  }
  precondition(badgeError.code == .notificationsNotAllowed)
}

func testCenterVolatileSession() {
  let center = unResetCenter()
  center._setPortableAuthorizationStatus(
    .authorized,
    options: [.alert, .sound, .badge, .providesAppNotificationSettings]
  )
  let granted = unAwait { try await center.requestAuthorization(options: [.alert]) }
  guard case .success(true) = granted else {
    preconditionFailure("already-authorized request should succeed")
  }
  let settings = unAwait { await center.notificationSettings() }
  guard case .success(let snapshot) = settings else {
    preconditionFailure("settings failed")
  }
  precondition(snapshot.authorizationStatus == .authorized)
  precondition(snapshot.alertSetting == .enabled)
  precondition(snapshot.soundSetting == .enabled)
  precondition(snapshot.badgeSetting == .enabled)
  precondition(snapshot.notificationCenterSetting == .enabled)
  precondition(snapshot.lockScreenSetting == .enabled)
  precondition(snapshot.providesAppNotificationSettings)
  precondition(snapshot.alertStyle == .banner)
  precondition(snapshot.showPreviewsSetting == .always)
  precondition(snapshot.carPlaySetting == .disabled)
  precondition(snapshot.criticalAlertSetting == .disabled)
  precondition(snapshot.announcementSetting == .disabled)
  precondition(snapshot.timeSensitiveSetting == .disabled)
  precondition(snapshot.scheduledDeliverySetting == .notSupported)
  precondition(snapshot.directMessagesSetting == .notSupported)

  var completionSettings: UNNotificationSettings?
  center.getNotificationSettings { completionSettings = $0 }
  precondition(completionSettings?.authorizationStatus == .authorized)

  let content = UNMutableNotificationContent()
  content.title = "Portable"
  content.body = "Stored"
  content.userInfo = ["k": "v"]
  let request = UNNotificationRequest(
    identifier: "portable",
    content: content,
    trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
  )
  content.title = "mutated"
  let added = unAwait { try await center.add(request) }
  guard case .success = added else {
    preconditionFailure("authorized add failed")
  }
  var pendingCallback: [UNNotificationRequest]?
  center.getPendingNotificationRequests { pendingCallback = $0 }
  precondition(pendingCallback?.map(\.identifier) == ["portable"])
  let pending = unAwait { await center.pendingNotificationRequests() }
  guard case .success(let pendingRequests) = pending else {
    preconditionFailure("pending fetch failed")
  }
  precondition(pendingRequests.map(\.identifier) == ["portable"])
  precondition(pendingRequests[0].content.title == "Portable")

  let badge = unAwait { try await center.setBadgeCount(7) }
  guard case .success = badge else {
    preconditionFailure("badge set failed")
  }
  precondition(center._portableBadgeCount == 7)
  var badgeError: Error?
  center.setBadgeCount(-1) { badgeError = $0 }
  precondition((badgeError as? UNError)?.code == .badgeInputInvalid)

  let deliveredImmediate = UNMutableNotificationContent()
  deliveredImmediate.body = "now"
  let immediate = unAwait {
    try await center.add(
      UNNotificationRequest(
        identifier: "now", content: deliveredImmediate, trigger: nil
      )
    )
  }
  guard case .success = immediate else {
    preconditionFailure("nil-trigger add failed")
  }
  var deliveredCallback: [UNNotification]?
  center.getDeliveredNotifications { deliveredCallback = $0 }
  precondition(deliveredCallback?.contains { $0.request.identifier == "now" } == true)
}

func testCenterCategoriesAndRemoval() {
  let center = unResetCenter()
  center._setPortableAuthorizationStatus(.authorized)
  let category = UNNotificationCategory(
    identifier: "messages",
    actions: [UNNotificationAction(identifier: "reply", title: "Reply")],
    intentIdentifiers: [],
    options: [.customDismissAction]
  )
  center.setNotificationCategories([category])
  var categoriesCallback: Set<UNNotificationCategory>?
  center.getNotificationCategories { categoriesCallback = $0 }
  precondition(categoriesCallback?.contains { $0.identifier == "messages" } == true)
  let categories = unAwait { await center.notificationCategories() }
  guard case .success(let set) = categories else {
    preconditionFailure("categories failed")
  }
  precondition(set.contains { $0.identifier == "messages" })

  let content = UNMutableNotificationContent()
  content.body = "q"
  let pendingAdd = unAwait {
    try await center.add(
      UNNotificationRequest(
        identifier: "p1",
        content: content,
        trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
      )
    )
  }
  guard case .success = pendingAdd else { preconditionFailure("pending add failed") }
  center.removePendingNotificationRequests(withIdentifiers: ["p1"])
  let pending = unAwait { await center.pendingNotificationRequests() }
  guard case .success(let pendingRequests) = pending else {
    preconditionFailure("pending fetch failed")
  }
  precondition(pendingRequests.isEmpty)

  let deliveredAdd = unAwait {
    try await center.add(
      UNNotificationRequest(identifier: "d1", content: content, trigger: nil)
    )
  }
  guard case .success = deliveredAdd else { preconditionFailure("delivered add failed") }
  center.removeDeliveredNotifications(withIdentifiers: ["d1"])
  let delivered = unAwait { await center.deliveredNotifications() }
  guard case .success(let deliveredNotes) = delivered else {
    preconditionFailure("delivered fetch failed")
  }
  precondition(deliveredNotes.isEmpty)

  _ = unAwait {
    try await center.add(
      UNNotificationRequest(
        identifier: "p2",
        content: content,
        trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
      )
    )
  }
  _ = unAwait {
    try await center.add(
      UNNotificationRequest(identifier: "d2", content: content, trigger: nil)
    )
  }
  center.removeAllPendingNotificationRequests()
  center.removeAllDeliveredNotifications()
  let pendingAfter = unAwait { await center.pendingNotificationRequests() }
  let deliveredAfter = unAwait { await center.deliveredNotifications() }
  guard case .success(let p) = pendingAfter, case .success(let d) = deliveredAfter else {
    preconditionFailure("queue fetch failed")
  }
  precondition(p.isEmpty)
  precondition(d.isEmpty)
}

private final class UNTestDelegate: UNUserNotificationCenterDelegate {
  var presentations: [String] = []
  var responses: [String] = []
  var opened: Int = 0

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification
  ) async -> UNNotificationPresentationOptions {
    _ = center
    presentations.append(notification.request.identifier)
    return [.banner, .sound]
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse
  ) async {
    _ = center
    responses.append(response.actionIdentifier)
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    openSettingsFor notification: UNNotification?
  ) {
    _ = center
    _ = notification
    opened += 1
  }
}

func testCenterDelegateDelivery() {
  let center = unResetCenter()
  center._setPortableAuthorizationStatus(.authorized)
  let content = UNMutableNotificationContent()
  content.title = "d"
  let add = unAwait {
    try await center.add(
      UNNotificationRequest(
        identifier: "portable",
        content: content,
        trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
      )
    )
  }
  guard case .success = add else { preconditionFailure("add failed") }
  let delegate = UNTestDelegate()
  center.delegate = delegate
  let options = unAwait {
    await center._deliverPortableNotification(
      withIdentifier: "portable",
      date: Date(timeIntervalSince1970: 42)
    )
  }
  guard case .success(let presentation) = options else {
    preconditionFailure("deliver failed")
  }
  precondition(presentation == [.banner, .sound])
  precondition(delegate.presentations == ["portable"])
  let delivered = unAwait { await center.deliveredNotifications() }
  guard case .success(let notes) = delivered else {
    preconditionFailure("delivered fetch failed")
  }
  precondition(notes.count == 1)
  precondition(notes[0].date == Date(timeIntervalSince1970: 42))
  precondition(notes[0].request.identifier == "portable")
  _ = unAwait {
    await center._respondPortable(to: notes[0], actionIdentifier: "reply")
  }
  precondition(delegate.responses == ["reply"])
  delegate.userNotificationCenter(center, openSettingsFor: notes[0])
  precondition(delegate.opened == 1)
  let response = UNNotificationResponse(
    notification: notes[0],
    actionIdentifier: UNNotificationDefaultActionIdentifier
  )
  precondition(response.notification === notes[0] || response.notification.request.identifier == "portable")
  precondition(response.actionIdentifier == UNNotificationDefaultActionIdentifier)
  let text = UNTextInputNotificationResponse(
    notification: notes[0],
    actionIdentifier: "reply",
    userText: "hi"
  )
  precondition(text.userText == "hi")
}

func testSoundSecureCoding() {
  let named = UNNotificationSound(named: "bell")
  let restored = unArchiveRoundTrip(named)
  precondition(restored.portableKind == .named("bell"))
  unRejectsEmptyCoder(UNNotificationSound.self)
  precondition(UNNotificationSound.supportsSecureCoding)
}

func testActionIconSecureCoding() {
  let icon = UNNotificationActionIcon(systemImageName: "bell")
  let restored = unArchiveRoundTrip(icon)
  precondition(restored.systemImageName == "bell")
  unRejectsEmptyCoder(UNNotificationActionIcon.self)
}

func testActionSecureCoding() {
  let action = UNNotificationAction(
    identifier: "a", title: "A", options: [.destructive]
  )
  let restored = unArchiveRoundTrip(action)
  precondition(restored.identifier == "a")
  precondition(restored.title == "A")
  precondition(restored.options.contains(.destructive))
  unRejectsEmptyCoder(UNNotificationAction.self)
}

func testAttachmentSecureCoding() {
  let url = URL(fileURLWithPath: "/tmp/un-archive.png")
  let attachment = try! UNNotificationAttachment(identifier: "att", url: url)
  let restored = unArchiveRoundTrip(attachment)
  precondition(restored.identifier == "att")
  precondition(restored.url == url)
  precondition(restored.type == "png")
  unRejectsEmptyCoder(UNNotificationAttachment.self)
}

func testCategorySecureCoding() {
  let category = UNNotificationCategory(
    identifier: "cat",
    actions: [UNNotificationAction(identifier: "a", title: "A")],
    intentIdentifiers: ["i"],
    hiddenPreviewsBodyPlaceholder: "h",
    categorySummaryFormat: "s",
    options: [.allowInCarPlay]
  )
  let restored = unArchiveRoundTrip(category)
  precondition(restored.identifier == "cat")
  precondition(restored.actions.first?.identifier == "a")
  precondition(restored.intentIdentifiers == ["i"])
  unRejectsEmptyCoder(UNNotificationCategory.self)
}

func testContentSecureCoding() {
  let content = UNMutableNotificationContent()
  content.title = "t"
  content.body = "b"
  content.userInfo = ["n": 1]
  let restored = unArchiveRoundTrip(content)
  precondition(restored.title == "t")
  precondition(restored.body == "b")
  unRejectsEmptyCoder(UNNotificationContent.self)
}

func testTriggerSecureCoding() {
  let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 9, repeats: true)
  let restored = unArchiveRoundTrip(trigger)
  precondition(restored.timeInterval == 9)
  precondition(restored.repeats)
  var components = DateComponents()
  components.hour = 4
  let calendar = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
  let restoredCalendar = unArchiveRoundTrip(calendar)
  precondition(restoredCalendar.dateComponents.hour == 4)
  unRejectsEmptyCoder(UNNotificationTrigger.self)
}

func testRequestSecureCoding() {
  let content = UNMutableNotificationContent()
  content.title = "req"
  let request = UNNotificationRequest(
    identifier: "r",
    content: content,
    trigger: UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
  )
  let restored = unArchiveRoundTrip(request)
  precondition(restored.identifier == "r")
  precondition(restored.content.title == "req")
  precondition(
    (restored.trigger as? UNTimeIntervalNotificationTrigger)?.timeInterval == 2
  )
  unRejectsEmptyCoder(UNNotificationRequest.self)
}

func testNotificationAndResponseSecureCoding() {
  let content = UNMutableNotificationContent()
  content.body = "n"
  let request = UNNotificationRequest(identifier: "n", content: content, trigger: nil)
  let notification = UNNotification(
    date: Date(timeIntervalSince1970: 10), request: request
  )
  let restored = unArchiveRoundTrip(notification)
  precondition(restored.date == Date(timeIntervalSince1970: 10))
  precondition(restored.request.identifier == "n")
  let response = UNNotificationResponse(
    notification: notification, actionIdentifier: "act"
  )
  let restoredResponse = unArchiveRoundTrip(response)
  precondition(restoredResponse.actionIdentifier == "act")
  unRejectsEmptyCoder(UNNotification.self)
  unRejectsEmptyCoder(UNNotificationResponse.self)
}

func testSettingsSecureCoding() {
  let center = unResetCenter()
  center._setPortableAuthorizationStatus(.authorized, options: [.alert, .sound])
  let settings = unAwait { await center.notificationSettings() }
  guard case .success(let snapshot) = settings else {
    preconditionFailure("settings failed")
  }
  let restored = unArchiveRoundTrip(snapshot)
  precondition(restored.authorizationStatus == .authorized)
  precondition(restored.alertSetting == .enabled)
  precondition(restored.carPlaySetting == .disabled)
  precondition(restored.criticalAlertSetting == .disabled)
  precondition(restored.announcementSetting == .disabled)
  precondition(restored.timeSensitiveSetting == .disabled)
  unRejectsEmptyCoder(UNNotificationSettings.self)
}

func testUNErrorNSErrorRoundTrip() {
  let typed = UNError(.attachmentCorrupt, userInfo: ["path": "/tmp/x"])
  precondition(typed._nsError.domain == UNErrorDomain)
  precondition(typed._nsError.code == 105)
  let asError: any Error = typed
  guard let again = asError as? UNError else {
    preconditionFailure("typed UNError must round-trip")
  }
  precondition(again.code == .attachmentCorrupt)
}
