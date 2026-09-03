import Foundation
import UserNotifications

/// Isolated-host identity probe. The sealed cloud gate does not compile this
/// file. The later EC2 integration build imports the real Foundation module
/// and passes genuine Foundation values through public UserNotifications APIs.
func userNotificationsDependencyIdentityProbe() {
  let url = URL(fileURLWithPath: "/tmp/usernotifications-identity.png")
  let attachment = try! UNNotificationAttachment(
    identifier: "identity-attachment",
    url: url
  )
  precondition(attachment.url == url)
  precondition(attachment.identifier == "identity-attachment")

  var components = DateComponents()
  components.hour = 9
  let calendarTrigger = UNCalendarNotificationTrigger(
    dateMatching: components, repeats: false
  )
  precondition(calendarTrigger.dateComponents.hour == 9)

  let interval = TimeInterval(3)
  let timeTrigger = UNTimeIntervalNotificationTrigger(
    timeInterval: interval, repeats: false
  )
  precondition(timeTrigger.timeInterval == interval)

  let badge: NSNumber = 4
  let content = UNMutableNotificationContent()
  content.badge = badge
  content.userInfo = ["sent": Date(timeIntervalSince1970: 1)]
  precondition(content.badge == badge)

  let request = UNNotificationRequest(
    identifier: "identity",
    content: content,
    trigger: timeTrigger
  )
  precondition(request.identifier == "identity")
  _ = UNUserNotificationCenter.current()
  _ = UNErrorDomain
  _ = NSString.localizedUserNotificationString(forKey: "identity", arguments: nil)
}
