@_spi(OpenUIKitHost) import SensitiveContentAnalysis
import Foundation

private func scExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testAnalyzerType() {
    let analyzer = SCSensitivityAnalyzer()
    scExpect((analyzer as Any) is NSObject, "SCSensitivityAnalyzer subclasses NSObject")
    scExpect(type(of: analyzer) == SCSensitivityAnalyzer.self, "dynamic type")
}

func testAnalyzerInit() {
    let first = SCSensitivityAnalyzer()
    let second = SCSensitivityAnalyzer()
    scExpect(first !== second, "each init() yields a distinct instance")
}

func testAnalysisPolicyDisabled() {
    let analyzer = SCSensitivityAnalyzer()
    scExpect(analyzer.analysisPolicy == .disabled, "Linux policy is disabled")
    scExpect(analyzer.analysisPolicy.rawValue == 0, "disabled raw value 0")
}

func testAnalyzeImageAtFailsClosed() {
    let analyzer = SCSensitivityAnalyzer()
    let url = URL(fileURLWithPath: "/tmp/sensitivecontentanalysis-missing.png")
    var calls = 0
    var analysis: SCSensitivityAnalysis?
    var error: (any Error)?
    analyzer.analyzeImage(at: url) { receivedAnalysis, receivedError in
        calls += 1
        analysis = receivedAnalysis
        error = receivedError
    }
    scExpect(calls == 1, "completion handler runs once, synchronously")
    scExpect(analysis == nil, "never invents an analysis result")
    let linux = error as? SCLinuxUnavailableError
    scExpect(linux != nil, "Linux unavailable error")
    let nsError = error as NSError?
    scExpect(nsError?.domain == SCLinuxUnavailableErrorDomain, "error domain")
    scExpect(nsError?.code == 1, "error code 1")
    scExpect(SCLinuxUnavailableError.errorDomain == SCLinuxUnavailableErrorDomain, "CustomNSError.domain")
}
