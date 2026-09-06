import Foundation
@_spi(OpenUIKitHost) import LockedCameraCapture

func testNSUserActivityTypeLockedCameraCapture() {
    precondition(NSUserActivityTypeLockedCameraCapture == "NSUserActivityTypeLockedCameraCapture")
    precondition(!NSUserActivityTypeLockedCameraCapture.isEmpty)
    let again = NSUserActivityTypeLockedCameraCapture
    precondition(again == NSUserActivityTypeLockedCameraCapture)
    let activity = NSUserActivity(activityType: NSUserActivityTypeLockedCameraCapture)
    precondition(activity.activityType == NSUserActivityTypeLockedCameraCapture)
}
