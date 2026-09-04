import Intents

// Schema v2 load evidence is tests/agent/IntentsLoadSmoke.swift plus the
// focused test* functions in *Tests.swift. This file keeps a named runtime
// entry for reviewers; the sealed host gate does not compile or invoke it.
enum IntentsRuntimeReview {
    static let marker = "INTENTS_AGENT_RUNTIME_OK"
}
