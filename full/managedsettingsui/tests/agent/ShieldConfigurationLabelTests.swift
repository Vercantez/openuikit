import Foundation
@_spi(OpenUIKitHost) import ManagedSettingsUI

func testShieldConfigurationLabelStruct() {
    let color = UIColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 1)
    let label: ShieldConfiguration.Label = ShieldConfiguration.Label(text: "Title", color: color)
    precondition(type(of: label) == ShieldConfiguration.Label.self)
    precondition(label.text == "Title")
    precondition(label.color === color)
}

func testShieldConfigurationLabelInit() {
    let first = UIColor.red
    let second = UIColor.blue
    let label = ShieldConfiguration.Label(text: "Ask for more time", color: first)
    precondition(label.text == "Ask for more time")
    precondition(label.color === first)
    precondition(label.color !== second)

    let empty = ShieldConfiguration.Label(text: "", color: second)
    precondition(empty.text.isEmpty)
    precondition(empty.color === second)
}

func testShieldConfigurationLabelText() {
    let color = UIColor.white
    let label = ShieldConfiguration.Label(text: "This app is restricted", color: color)
    let text: String = label.text
    precondition(text == "This app is restricted")
    precondition(text.count == 22)

    let unicode = ShieldConfiguration.Label(text: "制限されています", color: color)
    precondition(unicode.text == "制限されています")
}

func testShieldConfigurationLabelColor() {
    let red = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
    let label = ShieldConfiguration.Label(text: "OK", color: red)
    let color: UIColor = label.color
    precondition(color === red)
    precondition(color.isEqual(UIColor.red))
    precondition(!color.isEqual(UIColor.blue))
}
