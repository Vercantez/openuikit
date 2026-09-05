import Foundation
import FoundationModels

/// Schema-v2 sealed acceptance compiles `tests/agent/*Tests.swift` and the
/// generated load-smoke runner. This file records the portable runtime
/// contract those tests exercise: generated-content round trips, fail-closed
/// SystemLanguageModel availability unless the Linux stand-in is installed,
/// and LanguageModelSession inference. It does not print; the sealed runner
/// emits the marker.
func foundationModelsRuntimeProbe() {
    precondition(SystemLanguageModel.default.isAvailable == false)
    precondition(
        SystemLanguageModel.default.availability
            == .unavailable(.deviceNotEligible)
    )
    _ = GeneratedContent(kind: .null).jsonString
    _ = LanguageModelSession().isResponding
}
