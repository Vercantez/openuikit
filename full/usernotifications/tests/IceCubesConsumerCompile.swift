import Foundation
import UserNotifications

// The untouched IceCubes consumer declares these conformances in its Env
// target. Keeping the same declarations here catches accidental Sendable or
// actor-isolation drift in the portable module before the full package graph.
extension UNNotification: @unchecked @retroactive Sendable {}
extension UNNotificationResponse: @unchecked @retroactive Sendable {}
extension UNUserNotificationCenter: @unchecked @retroactive Sendable {}

final class IceCubesNotificationDelegate: NSObject,
  UNUserNotificationCenterDelegate
{
  override init() {
    super.init()
    UNUserNotificationCenter.current().delegate = self
  }

  func request() {
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .sound, .badge]
    ) { @Sendable _, _ in }
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse
  ) async {
    _ = center
    _ = response
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification
  ) async -> UNNotificationPresentationOptions {
    _ = center
    _ = notification
    return [.banner, .sound]
  }
}
