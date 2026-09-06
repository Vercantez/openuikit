import Foundation
@_spi(OpenUIKitHost) import BusinessChat

private final class PortableCoder: NSCoder {}

func testChatButtonClass() {
    let button = BCChatButton(style: .light)
    let asObject: NSObject = button
    precondition(asObject === button)
    precondition(type(of: button) == BCChatButton.self)
    precondition(BusinessChatHostControl.style(of: button) == .light)
}

func testChatButtonInitStyle() {
    let light = BCChatButton(style: .light)
    precondition(BusinessChatHostControl.style(of: light) == .light)
    let dark = BCChatButton(style: .dark)
    precondition(BusinessChatHostControl.style(of: dark) == .dark)
    precondition(light !== dark)
}

func testChatButtonInitCoderFailsClosed() {
    let decoded = BCChatButton(coder: PortableCoder())
    precondition(decoded == nil)

    let archiver = NSKeyedArchiver(requiringSecureCoding: false)
    let fromArchiver = BCChatButton(coder: archiver)
    precondition(fromArchiver == nil)
}
