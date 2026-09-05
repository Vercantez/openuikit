@_spi(OpenUIKitHost) import SoundAnalysis
import Foundation

private func snExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

private final class StreamObserver: NSObject, SNResultsObserving {
    var failures: [Error] = []
    var completions = 0

    func request(_ request: any SNRequest, didProduce result: any SNResult) {
        _ = request
        _ = result
    }

    func request(_ request: any SNRequest, didFailWithError error: any Error) {
        _ = request
        failures.append(error)
    }

    func requestDidComplete(_ request: any SNRequest) {
        _ = request
        completions += 1
    }
}

func testAudioStreamAnalyzerHostRegistry() {
    let analyzer = SNAudioStreamAnalyzer(hostPlaceholder: ())
    let request = try! SNClassifySoundRequest(classifierIdentifier: .version1)
    let observer = StreamObserver()
    try! analyzer.add(request, withObserver: observer)
    do {
        try analyzer.add(request, withObserver: observer)
        preconditionFailure("duplicate add must fail")
    } catch let error as SNError {
        snExpect(error.code == .operationFailed, "duplicate add")
    } catch {
        preconditionFailure("expected SNError")
    }
    analyzer.remove(request)
    try! analyzer.add(request, withObserver: observer)
    analyzer.removeAllRequests()
    try! analyzer.add(request, withObserver: observer)
    analyzer.removeAllRequests()
    snExpect(observer.failures.isEmpty, "registry mutations do not classify")
}

func testAudioStreamAnalyzerCompleteAnalysis() {
    let analyzer = SNAudioStreamAnalyzer(hostPlaceholder: ())
    let request = try! SNClassifySoundRequest(classifierIdentifier: .version1)
    let observer = StreamObserver()
    try! analyzer.add(request, withObserver: observer)
    analyzer.completeAnalysis()
    snExpect(observer.completions == 1, "completeAnalysis notifies observers")
    snExpect(observer.failures.isEmpty, "completion is not a fabricated classification")
}
