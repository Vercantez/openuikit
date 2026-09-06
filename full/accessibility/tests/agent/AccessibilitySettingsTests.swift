import Foundation
import Accessibility

func testSettingsFailClosedDefaults() {
    _ = AccessibilitySettings()
    precondition(AccessibilitySettings.isAssistiveAccessEnabled == false)
    precondition(AccessibilitySettings.showBordersEnabled == false)
    precondition(AccessibilitySettings.animatedImagesEnabled == false)
    precondition(AccessibilitySettings.prefersHorizontalTextLayout == false)
    precondition(AccessibilitySettings.prefersActionSliderAlternative == false)
    precondition(AccessibilitySettings.prefersNonBlinkingTextInsertionIndicator == false)
    precondition(AXAnimatedImagesEnabled() == false)
    precondition(AXPrefersHorizontalTextLayout() == false)

    precondition(
        AccessibilitySettings.animatedImagesEnabledDidChangeNotification.rawValue
            == "AXAnimatedImagesEnabledDidChangeNotification"
    )
    precondition(
        AccessibilitySettings.prefersHorizontalTextLayoutDidChangeNotification.rawValue
            == "AXPrefersHorizontalTextLayoutDidChangeNotification"
    )
    precondition(
        AccessibilitySettings.prefersActionSliderAlternativeDidChangeNotification.rawValue
            == "AXPrefersActionSliderAlternativeDidChangeNotification"
    )
    precondition(
        AccessibilitySettings.prefersNonBlinkingTextInsertionIndicatorDidChangeNotification.rawValue
            == "AXPrefersNonBlinkingTextInsertionIndicatorDidChangeNotification"
    )
    precondition(
        AccessibilitySettings.showBordersEnabledStatusDidChangeNotification.rawValue
            == "AXShowBordersEnabledStatusDidChangeNotification"
    )
    precondition(
        NSNotification.Name.AXAnimatedImagesEnabledDidChange.rawValue
            == "AXAnimatedImagesEnabledDidChangeNotification"
    )
    precondition(
        NSNotification.Name.AXPrefersHorizontalTextLayoutDidChange.rawValue
            == "AXPrefersHorizontalTextLayoutDidChangeNotification"
    )
}
