import Foundation
import MediaAccessibility

func testCaptionAppearanceForegroundColorAndBehavior() {
    MAResetProcessLocalStateForTesting()
    var behavior = MACaptionAppearanceBehavior.useContentIfAvailable
    let color = MACaptionAppearanceCopyForegroundColor(.user, &behavior).takeRetainedValue()
    precondition(behavior == .useValue)
#if !canImport(CoreGraphics)
    precondition(color.red == 1)
    precondition(color.green == 1)
    precondition(color.blue == 1)
    precondition(color.alpha == 1)
#else
    _ = color
#endif
}

func testCaptionAppearanceBackgroundColor() {
    MAResetProcessLocalStateForTesting()
    var behavior = MACaptionAppearanceBehavior.useContentIfAvailable
    let color = MACaptionAppearanceCopyBackgroundColor(.default, &behavior).takeRetainedValue()
    precondition(behavior == .useValue)
#if !canImport(CoreGraphics)
    precondition(color.red == 0)
    precondition(color.green == 0)
    precondition(color.blue == 0)
    precondition(color.alpha == 1)
#else
    _ = color
#endif
}

func testCaptionAppearanceWindowColor() {
    MAResetProcessLocalStateForTesting()
    let color = MACaptionAppearanceCopyWindowColor(.user, nil).takeRetainedValue()
#if !canImport(CoreGraphics)
    precondition(color.red == 0)
    precondition(color.green == 0)
    precondition(color.blue == 0)
#else
    _ = color
#endif
}

func testCaptionAppearanceForegroundOpacity() {
    MAResetProcessLocalStateForTesting()
    var behavior = MACaptionAppearanceBehavior.useContentIfAvailable
    let opacity = MACaptionAppearanceGetForegroundOpacity(.user, &behavior)
    precondition(behavior == .useValue)
    precondition(opacity == 1)
}

func testCaptionAppearanceBackgroundOpacity() {
    MAResetProcessLocalStateForTesting()
    var behavior = MACaptionAppearanceBehavior.useContentIfAvailable
    let opacity = MACaptionAppearanceGetBackgroundOpacity(.user, &behavior)
    precondition(behavior == .useValue)
    precondition(opacity == 0)
}

func testCaptionAppearanceWindowOpacity() {
    MAResetProcessLocalStateForTesting()
    var behavior = MACaptionAppearanceBehavior.useContentIfAvailable
    let opacity = MACaptionAppearanceGetWindowOpacity(.user, &behavior)
    precondition(behavior == .useValue)
    precondition(opacity == 0)
}

func testCaptionAppearanceWindowRoundedCornerRadius() {
    MAResetProcessLocalStateForTesting()
    var behavior = MACaptionAppearanceBehavior.useContentIfAvailable
    let radius = MACaptionAppearanceGetWindowRoundedCornerRadius(.user, &behavior)
    precondition(behavior == .useValue)
    precondition(radius == 0)
}

func testCaptionAppearanceRelativeCharacterSize() {
    MAResetProcessLocalStateForTesting()
    var behavior = MACaptionAppearanceBehavior.useContentIfAvailable
    let size = MACaptionAppearanceGetRelativeCharacterSize(.user, &behavior)
    precondition(behavior == .useValue)
    precondition(size == 1)
}

func testCaptionAppearanceTextEdgeStyleGetter() {
    MAResetProcessLocalStateForTesting()
    var behavior = MACaptionAppearanceBehavior.useContentIfAvailable
    let style = MACaptionAppearanceGetTextEdgeStyle(.user, &behavior)
    precondition(behavior == .useValue)
    precondition(style == .undefined)
}

func testCaptionAppearanceFontDescriptorForStyle() {
    MAResetProcessLocalStateForTesting()
    var behavior = MACaptionAppearanceBehavior.useContentIfAvailable
    let descriptor = MACaptionAppearanceCopyFontDescriptorForStyle(
        .user,
        &behavior,
        .casual
    ).takeRetainedValue()
    precondition(behavior == .useValue)
#if !canImport(CoreText)
    precondition(descriptor.fontStyle == .casual)
#else
    _ = descriptor
#endif
}
