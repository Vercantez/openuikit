// Focus DesignSystem colours from BlockzillaPackage Colors.xcassets
// at a2832521. Components copied from each colorset Contents.json
// (light + dark appearances). Not a parameter search.
// Lives in the DesignSystem module so Focus `import DesignSystem`
// and Hackers feed share one product.

import UIKit
import SwiftUI

public extension UIColor {
    // Above.colorset
    static let above = UIColor(dynamicProvider: { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.180392, green: 0.145098, blue: 0.364706, alpha: 1)
            : UIColor(red: 0.984314, green: 0.984314, blue: 0.996078, alpha: 1)
    })
    // Accent.colorset
    static let accent = UIColor(dynamicProvider: { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 1, green: 0.29, blue: 0.635, alpha: 1)
            : UIColor(red: 0.776471, green: 0, blue: 0.517647, alpha: 1)
    })
    // DefaultFont.colorset (universal)
    static let defaultFont = UIColor(red: 0.882353, green: 0.898039, blue: 0.917647, alpha: 1)
    // FirstRunTitle.colorset (universal)
    static let firstRunTitle = UIColor(red: 0.129412, green: 0.129412, blue: 0.129412, alpha: 1)
    // Foundation.colorset
    static let foundation = UIColor(dynamicProvider: { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.153, green: 0.098, blue: 0.282, alpha: 1)
            : UIColor(red: 0.835294, green: 0.843137, blue: 0.980392, alpha: 1)
    })
    // GradientBackground.colorset (universal)
    static let gradientBackground = UIColor(red: 0.211765, green: 0.231373, blue: 0.25098, alpha: 1)
    // GradientFirst.colorset (universal)
    static let gradientFirst = UIColor(red: 0.564706, green: 0.34902, blue: 1, alpha: 1)
    // GradientSecond.colorset (universal)
    static let gradientSecond = UIColor(red: 1, green: 0.290196, blue: 0.635294, alpha: 1)
    // GradientThird.colorset (universal)
    static let gradientThird = UIColor(red: 1, green: 0.741176, blue: 0.309804, alpha: 1)
    // Grey10.colorset (universal)
    static let grey10 = UIColor(red: 0.976471, green: 0.976471, blue: 0.980392, alpha: 1)
    // Grey30.colorset (universal)
    static let grey30 = UIColor(red: 0.843137, green: 0.843137, blue: 0.858824, alpha: 1)
    // Grey50.colorset (universal)
    static let grey50 = UIColor(red: 0.45098, green: 0.45098, blue: 0.45098, alpha: 1)
    // Grey70.colorset (universal)
    static let grey70 = UIColor(red: 0.219608, green: 0.219608, blue: 0.239216, alpha: 1)
    // Grey90.colorset (universal)
    static let grey90 = UIColor(red: 0.0470588, green: 0.0470588, blue: 0.0509804, alpha: 1)
    // Ink90.colorset (universal)
    static let ink90 = UIColor(red: 0.0588235, green: 0.0666667, blue: 0.14902, alpha: 1)
    // InputPlaceholder.colorset (universal)
    static let inputPlaceholder = UIColor(red: 0.698039, green: 0.698039, blue: 0.698039, alpha: 1)
    // LaunchScreenBackground.colorset
    static let launchScreenBackground = UIColor(dynamicProvider: { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.0588235, green: 0.0627451, blue: 0.145098, alpha: 1)
            : UIColor(red: 0.905882, green: 0.87451, blue: 1, alpha: 1)
    })
    // LocationBar.colorset
    static let locationBar = UIColor(dynamicProvider: { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.224, green: 0.204, blue: 0.451, alpha: 1)
            : UIColor(red: 0.984314, green: 0.984314, blue: 0.996078, alpha: 1)
    })
    // Magenta40.colorset (universal)
    static let magenta40 = UIColor(red: 0.894118, green: 0.321569, blue: 0.72549, alpha: 1)
    // Magenta70.colorset (universal)
    static let magenta70 = UIColor(red: 0.709804, green: 0, blue: 0.498039, alpha: 1)
    // PrimaryDark.colorset (universal)
    static let primaryDark = UIColor(red: 0.470588, green: 0.470588, blue: 0.501961, alpha: 1)
    // PrimaryText.colorset
    static let primaryText = UIColor(dynamicProvider: { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.984, green: 0.984, blue: 0.996, alpha: 1)
            : UIColor(red: 0.160784, green: 0.113725, blue: 0.309804, alpha: 1)
    })
    // Purple30.colorset (universal)
    static let purple30 = UIColor(red: 0.671, green: 0.443, blue: 1, alpha: 1)
    // Purple50.colorset (universal)
    static let purple50 = UIColor(red: 0.580392, green: 0, blue: 1, alpha: 1)
    // Purple70.colorset (universal)
    static let purple70 = UIColor(red: 0.349, green: 0.165, blue: 0.796, alpha: 1)
    // Purple80.colorset (universal)
    static let purple80 = UIColor(red: 0.266667, green: 0, blue: 0.443137, alpha: 1)
    // Red60.colorset (universal)
    static let red60 = UIColor(red: 0.843137, green: 0, blue: 0.133333, alpha: 1)
    // Scrim.colorset (universal)
    static let scrim = UIColor(red: 0.113725, green: 0.0666667, blue: 0.2, alpha: 1)
    // SearchGradientFirst.colorset
    static let searchGradientFirst = UIColor(dynamicProvider: { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.168627, green: 0.129412, blue: 0.329412, alpha: 1)
            : UIColor(red: 0.827451, green: 0.835294, blue: 0.984314, alpha: 1)
    })
    // SearchGradientSecond.colorset
    static let searchGradientSecond = UIColor(dynamicProvider: { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.156863, green: 0.117647, blue: 0.301961, alpha: 1)
            : UIColor(red: 0.827451, green: 0.839216, blue: 0.988235, alpha: 1)
    })
    // SearchGradientThird.colorset
    static let searchGradientThird = UIColor(dynamicProvider: { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.157, green: 0.114, blue: 0.298, alpha: 1)
            : UIColor(red: 0.823529, green: 0.839216, blue: 0.988235, alpha: 1)
    })
    // SearchGradientFourth.colorset
    static let searchGradientFourth = UIColor(dynamicProvider: { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.164706, green: 0.12549, blue: 0.317647, alpha: 1)
            : UIColor(red: 0.835294, green: 0.843137, blue: 0.980392, alpha: 1)
    })
    // SecondaryText.colorset
    static let secondaryText = UIColor(dynamicProvider: { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.749, green: 0.749, blue: 0.788, alpha: 1)
            : UIColor(red: 0.356863, green: 0.356863, blue: 0.4, alpha: 1)
    })
    // SecondaryButton.colorset (universal)
    static let secondaryButton = UIColor(red: 0.113725, green: 0.0666667, blue: 0.2, alpha: 1)
    // PrimaryButton.colorset
    static let primaryButton = UIColor(dynamicProvider: { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.564706, green: 0.34902, blue: 1, alpha: 1)
            : UIColor(red: 0.113725, green: 0.0666667, blue: 0.2, alpha: 1)
    })
    // SearchSuggestionButtonHighlight.colorset
    static let searchSuggestionButtonHighlight = UIColor(dynamicProvider: { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.204, green: 0.184, blue: 0.427, alpha: 1)
            : UIColor(red: 0.905882, green: 0.87451, blue: 1, alpha: 1)
    })
    // ExtensionNotEnabled.colorset
    static let extensionNotEnabled = UIColor(dynamicProvider: { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 1, green: 0.603922, blue: 0.635294, alpha: 1)
            : UIColor(red: 0.773, green: 0, blue: 0.259, alpha: 1)
    })
    // ActionButton.colorset
    static let actionButton = UIColor(dynamicProvider: { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0, green: 0.866667, blue: 1, alpha: 1)
            : UIColor(red: 0, green: 0.376471, blue: 0.87451, alpha: 1)
    })

    convenience init(rgb: Int, alpha: Float = 1) {
        self.init(
            red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat((rgb & 0x0000FF) >> 0) / 255.0,
            alpha: CGFloat(alpha))
    }
}

public extension Color {
    static let accent = Color(uiColor: .accent)
}

