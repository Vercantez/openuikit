import Foundation
import UserNotifications

private final class NativeSurfaceDelegate: NSObject,
  UNUserNotificationCenterDelegate
{
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse
  ) async {
    _ = center
    _ = response.notification.request.content.userInfo
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification
  ) async -> UNNotificationPresentationOptions {
    _ = center
    _ = notification.date
    return [.banner, .sound]
  }
}

private func sharedNativeSurface(
  _ center: UNUserNotificationCenter
) async throws {
  let delegate = NativeSurfaceDelegate()
  center.delegate = delegate
  _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])

  let content = UNMutableNotificationContent()
  content.title = "title"
  content.body = "body"
  content.userInfo = ["key": Data([1])]
  content.sound = .default
  let request = UNNotificationRequest(
    identifier: "oracle",
    content: content,
    trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
  )
  try await center.add(request)
  _ = await center.pendingNotificationRequests()
  _ = await center.deliveredNotifications()
  _ = await center.notificationSettings()
  _ = await center.notificationCategories()
  try await center.setBadgeCount(1)
  center.removePendingNotificationRequests(withIdentifiers: ["oracle"])
  center.removeDeliveredNotifications(withIdentifiers: ["oracle"])
  withExtendedLifetime(delegate) {}
}
