import Foundation
import SensitiveContentAnalysis

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest-Foundation success.
//
// Expected EC2 steps (no local Docker):
// 1. Build the actual guest Foundation module and `libFoundation.dylib`.
// 2. Build SensitiveContentAnalysis with that Foundation on `-I` / `-L`.
// 3. Link this file as a client that imports SensitiveContentAnalysis and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering both dylibs.
// 5. Confirm `SENSITIVECONTENTANALYSIS_DEPENDENCY_IDENTITY_OK`.

private func assertNotSensitiveContentAnalysisType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("SensitiveContentAnalysis."))
}

/// Pass genuine Foundation values through public SensitiveContentAnalysis APIs.
func sensitiveContentAnalysisDependencyIdentityProbe() {
    let fileURL = URL(fileURLWithPath: "/tmp/sensitivecontentanalysis-identity.bin")
    assertNotSensitiveContentAnalysisType(fileURL)
    precondition(type(of: fileURL) == URL.self)

    let analyzer = SCSensitivityAnalyzer()
    var completionCalls = 0
    analyzer.analyzeImage(at: fileURL) { analysis, error in
        completionCalls += 1
        precondition(analysis == nil)
        let nsError = error as NSError?
        precondition(nsError?.domain == SCLinuxUnavailableErrorDomain)
        precondition(nsError?.code == 1)
    }
    precondition(completionCalls == 1)

    let handler = analyzer.videoAnalysis(forFileAt: fileURL)
    assertNotSensitiveContentAnalysisType(handler.progress)
    precondition(type(of: handler.progress) == Progress.self)
    precondition(handler.progress.totalUnitCount == 1)

    let replacement = Progress(totalUnitCount: 4)
    assertNotSensitiveContentAnalysisType(replacement)
    handler.progress = replacement
    precondition(handler.progress.totalUnitCount == 4)
}

#if SENSITIVECONTENTANALYSIS_IDENTITY_MAIN
sensitiveContentAnalysisDependencyIdentityProbe()
print("SENSITIVECONTENTANALYSIS_DEPENDENCY_IDENTITY_OK")
#endif
