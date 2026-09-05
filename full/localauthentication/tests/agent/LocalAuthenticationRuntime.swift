import LocalAuthentication

/// Focused `test*` functions live in `LocalAuthenticationTests.swift` so the
/// sealed host runner (which compiles only `*Tests.swift`) can invoke them.
/// This file is a human-facing pointer, not behavioral evidence.
func localAuthenticationRuntimeProbeNote() -> String {
    "LOCALAUTHENTICATION_TESTS_ARE_IN_LocalAuthenticationTests"
}
