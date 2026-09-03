@_spi(OpenUIKitHost) import UserNotifications
import Foundation

/// Schema v2 load-smoke is `UserNotificationsLoadSmoke.swift`. Focused
/// behavioral checks live in `UserNotificationsTests.swift`. This file records
/// the Linux runtime contract: the default center fails closed, and a host
/// may opt into the OpenUIKitHost SPI for a volatile in-process session.
enum UserNotificationsRuntimeContract {
  static let failClosedAuthorization = UNAuthorizationStatus.denied
  static let overlayArchiveVersion: Int32 = 1

  static func sampleContent() -> UNMutableNotificationContent {
    let content = UNMutableNotificationContent()
    content.title = "runtime"
    content.body = "volatile"
    content.sound = .default
    return content
  }
}
