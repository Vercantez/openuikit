@_spi(OpenUIKitHost) import SensitiveContentAnalysis

private func scExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testPolicyRawValues() {
    let rows: [(SCSensitivityAnalysisPolicy, Int)] = [
        (.disabled, 0),
        (.simpleInterventions, 1),
        (.descriptiveInterventions, 2),
    ]
    scExpect(rows.count == 3, "policy has three documented cases")
    for (policy, raw) in rows {
        scExpect(policy.rawValue == raw, "raw value \(raw)")
        scExpect(SCSensitivityAnalysisPolicy(rawValue: raw) == policy, "init(rawValue:) \(raw)")
    }
    scExpect(SCSensitivityAnalysisPolicy(rawValue: 3) == nil, "unknown raw 3 is nil")
    scExpect(SCSensitivityAnalysisPolicy(rawValue: -1) == nil, "unknown raw -1 is nil")
}

func testPolicyInequality() {
    scExpect(SCSensitivityAnalysisPolicy.disabled != .simpleInterventions, "disabled != simple")
    scExpect(SCSensitivityAnalysisPolicy.simpleInterventions != .descriptiveInterventions, "simple != descriptive")
    scExpect(!(SCSensitivityAnalysisPolicy.disabled != .disabled), "disabled == disabled")
}

func testPolicyHashValue() {
    scExpect(
        SCSensitivityAnalysisPolicy.disabled.hashValue == SCSensitivityAnalysisPolicy.disabled.hashValue,
        "same case hashes equal"
    )
    scExpect(
        SCSensitivityAnalysisPolicy.disabled.hashValue != SCSensitivityAnalysisPolicy.descriptiveInterventions.hashValue,
        "distinct cases hash distinctly"
    )
}

func testPolicyHashInto() {
    var hasher = Hasher()
    SCSensitivityAnalysisPolicy.simpleInterventions.hash(into: &hasher)
    _ = hasher.finalize()
    var left = Hasher()
    var right = Hasher()
    SCSensitivityAnalysisPolicy.disabled.hash(into: &left)
    SCSensitivityAnalysisPolicy.disabled.hash(into: &right)
    scExpect(left.finalize() == right.finalize(), "hash(into:) is stable for the same case")
}
