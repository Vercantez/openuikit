#if canImport(UIKit)
import UIKit
#endif

/// An object that defines the appearance of a shield to display over an
/// application or website.
///
/// The system provides a default appearance for any properties you set to
/// `nil`. Linux stores the eight fields and never renders a shield.
///
/// https://developer.apple.com/documentation/managedsettingsui/shieldconfiguration
public struct ShieldConfiguration {
    /// The appearance of text labels within a shield.
    public struct Label {
        /// The text of the label on a shield.
        public let text: String

        /// The color of the text on a shield.
        public let color: UIColor

        /// Creates a shield label with the provided text and color.
        public init(text: String, color: UIColor) {
            self.text = text
            self.color = color
        }
    }

    /// A blur style to apply to the background of the shield.
    public let backgroundBlurStyle: UIBlurEffect.Style?

    /// A color for a shield to use in the background blur effect.
    public let backgroundColor: UIColor?

    /// An icon to display in the center of the shield.
    public let icon: UIImage?

    /// The title of the shield to display below the icon.
    public let title: ShieldConfiguration.Label?

    /// The subtitle for a shield to display below the title.
    public let subtitle: ShieldConfiguration.Label?

    /// The label of the topmost rounded rectangle button.
    public let primaryButtonLabel: ShieldConfiguration.Label?

    /// The color to fill the contents of the rounded rectangle primary button.
    public let primaryButtonBackgroundColor: UIColor?

    /// The label of the optional secondary button.
    ///
    /// If this is `nil`, then the shield doesn't have a secondary button.
    /// Linux stores `nil` and never draws a button.
    public let secondaryButtonLabel: ShieldConfiguration.Label?

    /// Creates a shield configuration with the specified values.
    ///
    /// The system provides a default for any options that you don't specify.
    /// Linux stores the arguments; every omitted argument is `nil`.
    public init(
        backgroundBlurStyle: UIBlurEffect.Style? = nil,
        backgroundColor: UIColor? = nil,
        icon: UIImage? = nil,
        title: ShieldConfiguration.Label? = nil,
        subtitle: ShieldConfiguration.Label? = nil,
        primaryButtonLabel: ShieldConfiguration.Label? = nil,
        primaryButtonBackgroundColor: UIColor? = nil,
        secondaryButtonLabel: ShieldConfiguration.Label? = nil
    ) {
        self.backgroundBlurStyle = backgroundBlurStyle
        self.backgroundColor = backgroundColor
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.primaryButtonLabel = primaryButtonLabel
        self.primaryButtonBackgroundColor = primaryButtonBackgroundColor
        self.secondaryButtonLabel = secondaryButtonLabel
    }
}
