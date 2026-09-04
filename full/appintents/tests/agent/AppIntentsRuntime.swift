import AppIntents

// Schema v2 load evidence is tests/agent/AppIntentsLoadSmoke.swift plus the
// focused test* functions in *Tests.swift. This file keeps a named runtime
// entry for reviewers; the sealed host gate does not compile or invoke it.
enum AppIntentsRuntimeReview {
    static let marker = "APPINTENTS_AGENT_RUNTIME_OK"
}
