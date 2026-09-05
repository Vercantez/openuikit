@_spi(OpenUIKitHost) import SoundAnalysis
import Foundation

private func snExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

private final class ProduceOnlyObserver: NSObject, SNResultsObserving {
    var produced = 0

    func request(_ request: any SNRequest, didProduce result: any SNResult) {
        _ = request
        _ = result
        produced += 1
    }
}

private final class FullObserver: NSObject, SNResultsObserving {
    var produced = 0
    var failures = 0
    var completions = 0

    func request(_ request: any SNRequest, didProduce result: any SNResult) {
        _ = request
        _ = result
        produced += 1
    }

    func request(_ request: any SNRequest, didFailWithError error: any Error) {
        _ = request
        _ = error
        failures += 1
    }

    func requestDidComplete(_ request: any SNRequest) {
        _ = request
        completions += 1
    }
}

func testRequestResultProtocols() {
    let request: any SNRequest = try! SNClassifySoundRequest(classifierIdentifier: .version1)
    let result: any SNResult = SNClassificationResult(
        hostClassifications: [],
        timeRange: .invalid
    )
    snExpect(request is SNClassifySoundRequest, "SNRequest")
    snExpect(result is SNClassificationResult, "SNResult")
}

func testResultsObservingOptionalDefaults() {
    let observer = ProduceOnlyObserver()
    let request = try! SNClassifySoundRequest(classifierIdentifier: .version1)
    observer.request(request, didFailWithError: SNError(.unknownError))
    observer.requestDidComplete(request)
    snExpect(observer.produced == 0, "optional defaults are no-ops")
}

func testResultsObservingDidProduce() {
    let observer = FullObserver()
    let request = try! SNClassifySoundRequest(classifierIdentifier: .version1)
    let result = SNClassificationResult(
        hostClassifications: [
            SNClassification(hostIdentifier: "speech", confidence: 0.5)
        ],
        timeRange: .zero
    )
    observer.request(request, didProduce: result)
    snExpect(observer.produced == 1, "didProduce")
    observer.request(request, didFailWithError: SNError(.invalidFormat))
    observer.requestDidComplete(request)
    snExpect(observer.failures == 1, "didFailWithError")
    snExpect(observer.completions == 1, "requestDidComplete")
}
