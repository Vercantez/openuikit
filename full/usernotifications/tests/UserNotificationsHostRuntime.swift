import Foundation
@_spi(OpenUIKitHost) import UserNotifications

private final class Delegate: UNUserNotificationCenterDelegate {
  var presentations: [String] = []
  var responses: [String] = []

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
}

@main
private struct UserNotificationsHostRuntime {
  static func main() async {
    let center = UNUserNotificationCenter.current()
    center._resetPortableState()

    let initialSettings = await center.notificationSettings()
    precondition(initialSettings.authorizationStatus == .notDetermined)
    var callbackCount = 0
    center.requestAuthorization(options: [.alert, .sound, .badge]) {
      granted, error in
      precondition(!granted)
      precondition((error as? UNError)?.code == .notificationsNotAllowed)
      callbackCount += 1
    }
    precondition(callbackCount == 1)
    let deniedSettings = await center.notificationSettings()
    precondition(deniedSettings.authorizationStatus == .denied)

    let deniedContent = UNMutableNotificationContent()
    deniedContent.body = "must not schedule"
    do {
      try await center.add(
        UNNotificationRequest(
          identifier: "denied", content: deniedContent, trigger: nil
        )
      )
      preconditionFailure("unavailable host accepted a notification")
    } catch let error as UNError {
      precondition(error.code == .notificationsNotAllowed)
    } catch {
      preconditionFailure("unexpected scheduling error")
    }

    center._setPortableAuthorizationStatus(
      .authorized,
      options: [.alert, .sound, .badge, .providesAppNotificationSettings]
    )
    let granted = try! await center.requestAuthorization(options: [.alert])
    precondition(granted)
    let settings = await center.notificationSettings()
    precondition(settings.authorizationStatus == .authorized)
    precondition(settings.alertSetting == .enabled)
    precondition(settings.providesAppNotificationSettings)

    let category = UNNotificationCategory(
      identifier: "messages",
      actions: [
        UNNotificationAction(
          identifier: "reply", title: "Reply", options: [.foreground]
        )
      ],
      intentIdentifiers: [],
      options: [.customDismissAction]
    )
    center.setNotificationCategories([category])
    let categories = await center.notificationCategories()
    precondition(categories.first?.identifier == "messages")

    let content = UNMutableNotificationContent()
    content.title = "Portable notification"
    content.body = "Stored without an operating-system daemon"
    content.categoryIdentifier = "messages"
    content.userInfo = ["plaintext": Data([1, 2, 3])]
    content.sound = .default
    let request = UNNotificationRequest(
      identifier: "portable",
      content: content,
      trigger: UNTimeIntervalNotificationTrigger(
        timeInterval: 5, repeats: false
      )
    )
    content.title = "mutated after scheduling"
    try! await center.add(request)
    let pending = await center.pendingNotificationRequests()
    precondition(pending.map(\.identifier) == ["portable"])
    precondition(pending[0].content.title == "Portable notification")

    let delegate = Delegate()
    center.delegate = delegate
    let options = await center._deliverPortableNotification(
      withIdentifier: "portable",
      date: Date(timeIntervalSince1970: 42)
    )
    precondition(options == [.banner, .sound])
    precondition(delegate.presentations == ["portable"])
    let pendingAfterDelivery = await center.pendingNotificationRequests()
    precondition(pendingAfterDelivery.isEmpty)
    let delivered = await center.deliveredNotifications()
    precondition(delivered.count == 1)
    precondition(delivered[0].date == Date(timeIntervalSince1970: 42))
    await center._respondPortable(to: delivered[0], actionIdentifier: "reply")
    precondition(delegate.responses == ["reply"])

    try! await center.setBadgeCount(7)
    precondition(center._portableBadgeCount == 7)
    do {
      try await center.setBadgeCount(-1)
      preconditionFailure("negative badge count was accepted")
    } catch let error as UNError {
      precondition(error.code == .badgeInputInvalid)
    } catch {
      preconditionFailure("unexpected badge error")
    }

    center.removeDeliveredNotifications(withIdentifiers: ["portable"])
    let deliveredAfterRemoval = await center.deliveredNotifications()
    precondition(deliveredAfterRemoval.isEmpty)
    center._resetPortableState()
    print(
      "USERNOTIFICATIONS_HOST_OK authorization=fail-closed "
        + "scheduling=volatile delegate=async response=delivered "
        + "badge=validated"
    )
  }
}
