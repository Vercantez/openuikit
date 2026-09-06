import Foundation
@_spi(OpenUIKitHost) import ManagedSettingsUI

func testShieldConfigurationStruct() {
    let configuration = ShieldConfiguration()
    precondition(type(of: configuration) == ShieldConfiguration.self)
    precondition(ManagedSettingsUIHostControl.isSystemDefaultAppearance(configuration))
    precondition(configuration.backgroundBlurStyle == nil)
    precondition(configuration.backgroundColor == nil)
    precondition(configuration.icon == nil)
    precondition(configuration.title == nil)
    precondition(configuration.subtitle == nil)
    precondition(configuration.primaryButtonLabel == nil)
    precondition(configuration.primaryButtonBackgroundColor == nil)
    precondition(configuration.secondaryButtonLabel == nil)
}

func testShieldConfigurationInit() {
    let blur: UIBlurEffect.Style = .dark
    let background = UIColor.black
    let icon = UIImage()
    let title = ShieldConfiguration.Label(text: "Restricted", color: .white)
    let subtitle = ShieldConfiguration.Label(text: "Ask a parent", color: .white)
    let primary = ShieldConfiguration.Label(text: "Ask for more time", color: .black)
    let primaryBackground = UIColor.white
    let secondary = ShieldConfiguration.Label(text: "Close", color: .white)

    let filled = ShieldConfiguration(
        backgroundBlurStyle: blur,
        backgroundColor: background,
        icon: icon,
        title: title,
        subtitle: subtitle,
        primaryButtonLabel: primary,
        primaryButtonBackgroundColor: primaryBackground,
        secondaryButtonLabel: secondary
    )
    precondition(filled.backgroundBlurStyle == blur)
    precondition(filled.backgroundColor === background)
    precondition(filled.icon === icon)
    precondition(filled.title?.text == "Restricted")
    precondition(filled.title?.color === title.color)
    precondition(filled.subtitle?.text == "Ask a parent")
    precondition(filled.primaryButtonLabel?.text == "Ask for more time")
    precondition(filled.primaryButtonBackgroundColor === primaryBackground)
    precondition(filled.secondaryButtonLabel?.text == "Close")
    precondition(!ManagedSettingsUIHostControl.isSystemDefaultAppearance(filled))

    let partial = ShieldConfiguration(title: title)
    precondition(partial.title?.text == "Restricted")
    precondition(partial.backgroundBlurStyle == nil)
    precondition(partial.secondaryButtonLabel == nil)
}

func testShieldConfigurationBackgroundBlurStyle() {
    precondition(UIBlurEffect.Style.extraLight.rawValue == 0)
    precondition(UIBlurEffect.Style.light.rawValue == 1)
    precondition(UIBlurEffect.Style.dark.rawValue == 2)
    precondition(UIBlurEffect.Style.regular.rawValue == 4)
    precondition(UIBlurEffect.Style.prominent.rawValue == 5)

    let unset = ShieldConfiguration()
    precondition(unset.backgroundBlurStyle == nil)

    let dark = ShieldConfiguration(backgroundBlurStyle: .dark)
    precondition(dark.backgroundBlurStyle == .dark)
    precondition(dark.backgroundBlurStyle?.rawValue == 2)
    precondition(dark.backgroundColor == nil)

    let regular = ShieldConfiguration(backgroundBlurStyle: .regular)
    precondition(regular.backgroundBlurStyle == .regular)
    precondition(regular.backgroundBlurStyle != .dark)
}

func testShieldConfigurationBackgroundColor() {
    let unset = ShieldConfiguration()
    precondition(unset.backgroundColor == nil)

    let color = UIColor(red: 0.2, green: 0.3, blue: 0.4, alpha: 0.5)
    let configuration = ShieldConfiguration(backgroundColor: color)
    precondition(configuration.backgroundColor === color)
    precondition(configuration.backgroundBlurStyle == nil)
    precondition(!(configuration.backgroundColor?.isEqual(UIColor.black) ?? true))
}

func testShieldConfigurationIcon() {
    let unset = ShieldConfiguration()
    precondition(unset.icon == nil)

    let icon = UIImage()
    let other = UIImage()
    let configuration = ShieldConfiguration(icon: icon)
    precondition(configuration.icon === icon)
    precondition(configuration.icon !== other)
    precondition(configuration.title == nil)
}

func testShieldConfigurationTitle() {
    let unset = ShieldConfiguration()
    precondition(unset.title == nil)

    let color = UIColor.white
    let title = ShieldConfiguration.Label(text: "Time Limit", color: color)
    let configuration = ShieldConfiguration(title: title)
    precondition(configuration.title?.text == "Time Limit")
    precondition(configuration.title?.color === color)
    precondition(configuration.subtitle == nil)
}

func testShieldConfigurationSubtitle() {
    let unset = ShieldConfiguration()
    precondition(unset.subtitle == nil)

    let color = UIColor.white
    let subtitle = ShieldConfiguration.Label(
        text: "You have reached the limit for this app.",
        color: color
    )
    let configuration = ShieldConfiguration(subtitle: subtitle)
    precondition(configuration.subtitle?.text == "You have reached the limit for this app.")
    precondition(configuration.subtitle?.color === color)
    precondition(configuration.title == nil)
}

func testShieldConfigurationPrimaryButtonLabel() {
    let unset = ShieldConfiguration()
    precondition(unset.primaryButtonLabel == nil)

    let color = UIColor.black
    let primary = ShieldConfiguration.Label(text: "Ask for More Time", color: color)
    let configuration = ShieldConfiguration(primaryButtonLabel: primary)
    precondition(configuration.primaryButtonLabel?.text == "Ask for More Time")
    precondition(configuration.primaryButtonLabel?.color === color)
    precondition(configuration.primaryButtonBackgroundColor == nil)
}

func testShieldConfigurationPrimaryButtonBackgroundColor() {
    let unset = ShieldConfiguration()
    precondition(unset.primaryButtonBackgroundColor == nil)

    let color = UIColor.white
    let configuration = ShieldConfiguration(primaryButtonBackgroundColor: color)
    precondition(configuration.primaryButtonBackgroundColor === color)
    precondition(configuration.primaryButtonLabel == nil)
}

func testShieldConfigurationSecondaryButtonLabel() {
    let unset = ShieldConfiguration()
    precondition(unset.secondaryButtonLabel == nil)

    let color = UIColor.white
    let secondary = ShieldConfiguration.Label(text: "Close", color: color)
    let configuration = ShieldConfiguration(secondaryButtonLabel: secondary)
    precondition(configuration.secondaryButtonLabel?.text == "Close")
    precondition(configuration.secondaryButtonLabel?.color === color)
    precondition(configuration.primaryButtonLabel == nil)
}
