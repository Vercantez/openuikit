import Foundation
import ImagePlayground

/// Table-driven enum cases. Darwin `Int` payloads are unobserved; Linux-host
/// mapping is automatic=0, enabled=1, disabled=2.
func testPersonalizationPolicyCases() {
    let cases: [ImagePlaygroundPersonalizationPolicy] = [
        .automatic, .enabled, .disabled,
    ]
    precondition(cases[0] == .automatic)
    precondition(cases[1] == .enabled)
    precondition(cases[2] == .disabled)
    precondition(Set(cases).count == 3)
    // Documented default: automatic chooses the most appropriate behavior and
    // equals enabled for UI purposes; the enum cases remain distinct values.
    precondition(ImagePlaygroundPersonalizationPolicy.automatic != .enabled)
    precondition(ImagePlaygroundPersonalizationPolicy.automatic != .disabled)
    precondition(ImagePlaygroundPersonalizationPolicy.enabled != .disabled)
}

func testPersonalizationPolicyRawValues() {
    typealias Raw = ImagePlaygroundPersonalizationPolicy.RawValue
    precondition(Raw.self == Int.self)
    let rows: [(ImagePlaygroundPersonalizationPolicy, Int)] = [
        (.automatic, 0),
        (.enabled, 1),
        (.disabled, 2),
    ]
    for (policy, raw) in rows {
        precondition(policy.rawValue == raw)
        precondition(ImagePlaygroundPersonalizationPolicy(rawValue: raw) == policy)
    }
    precondition(ImagePlaygroundPersonalizationPolicy(rawValue: -1) == nil)
    precondition(ImagePlaygroundPersonalizationPolicy(rawValue: 3) == nil)
    precondition(ImagePlaygroundPersonalizationPolicy(rawValue: 99) == nil)
}

func testPersonalizationPolicyHashable() {
    precondition(ImagePlaygroundPersonalizationPolicy.automatic != .enabled)
    precondition(!(ImagePlaygroundPersonalizationPolicy.disabled != .disabled))
    var hasherA = Hasher()
    var hasherB = Hasher()
    ImagePlaygroundPersonalizationPolicy.enabled.hash(into: &hasherA)
    ImagePlaygroundPersonalizationPolicy.enabled.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(
        ImagePlaygroundPersonalizationPolicy.enabled.hashValue
            == ImagePlaygroundPersonalizationPolicy.enabled.hashValue
    )
    precondition(
        ImagePlaygroundPersonalizationPolicy.automatic.hashValue
            != ImagePlaygroundPersonalizationPolicy.disabled.hashValue
    )
}
