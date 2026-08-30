import Foundation
import OpenUIKit

let _: OpenUIKit.NSAttributedString.Type = Foundation.NSAttributedString.self
let _: OpenUIKit.NSMutableAttributedString.Type = Foundation.NSMutableAttributedString.self
let _: OpenUIKit.NSParagraphStyle.Type = Foundation.NSParagraphStyle.self
let _: OpenUIKit.NSMutableParagraphStyle.Type = Foundation.NSMutableParagraphStyle.self
let _: OpenUIKit.NSUnderlineStyle.Type = Foundation.NSUnderlineStyle.self
let _: OpenUIKit.Timer.Type = Foundation.Timer.self
let _: OpenUIKit.RunLoop.Type = Foundation.RunLoop.self
let _: OpenUIKit.NSUserActivity.Type = Foundation.NSUserActivity.self

func acceptsUIKitActivity(_ value: OpenUIKit.NSUserActivity) {}
acceptsUIKitActivity(Foundation.NSUserActivity(activityType: "test.identity"))
