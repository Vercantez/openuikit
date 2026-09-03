// Type existence probe for real UIKit.UIEdgeInsets and UIKit.UIVibrancyEffect.
// Compile this against an actual staged guest UIKit module. Never compile it
// with a test-owned module named UIKit.
import UIKit

@inline(never)
func requireUIKitCanonicalTypes() {
    let insetsType: UIKit.UIEdgeInsets.Type = UIEdgeInsets.self
    let effectType: UIKit.UIVibrancyEffect.Type = UIVibrancyEffect.self
    let styleType: UIKit.UIVibrancyEffectStyle.Type = UIVibrancyEffectStyle.self
    _ = (insetsType, effectType, styleType)
}

requireUIKitCanonicalTypes()
