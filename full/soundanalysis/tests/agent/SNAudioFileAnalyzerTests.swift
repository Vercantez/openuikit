@_spi(OpenUIKitHost) import SoundAnalysis
import Foundation

private func snExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

private final class RecordingObserver: NSObject, SNResultsObserving {
    var produced: [any SNResult] = []
    var failures: [Error] = []
    var completions = 0

    func request(_ request: any SNRequest, didProduce result: any SNResult) {
        _ = request
        produced.append(result)
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

private func snTemporaryFile() -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("soundanalysis-\(UUID().uuidString).bin")
    try! Data([0x01, 0x02]).write(to: url)
    return url
}

func testAudioFileAnalyzerInitExistingFile() {
    let url = snTemporaryFile()
    defer { try? FileManager.default.removeItem(at: url) }
    let analyzer = try! SNAudioFileAnalyzer(url: url)
    snExpect(analyzer.url == url, "stores the file URL")
}

func testAudioFileAnalyzerInitMissingFile() {
    let url = URL(fileURLWithPath: "/tmp/soundanalysis-missing-\(UUID().uuidString).bin")
    do {
        _ = try SNAudioFileAnalyzer(url: url)
        preconditionFailure("missing file must fail closed")
    } catch let error as SNError {
        snExpect(error.code == .invalidFile, "invalidFile")
    } catch {
        preconditionFailure("expected SNError")
    }
}

func testAudioFileAnalyzerInitURLAlias() {
    let url = snTemporaryFile()
    defer { try? FileManager.default.removeItem(at: url) }
    let analyzer = try! SNAudioFileAnalyzer(URL: url)
    snExpect(analyzer.url == url, "init(URL:) matches init(url:)")
}

func testAudioFileAnalyzerRequestRegistry() {
    let url = snTemporaryFile()
    defer { try? FileManager.default.removeItem(at: url) }
    let analyzer = try! SNAudioFileAnalyzer(url: url)
    let request = try! SNClassifySoundRequest(classifierIdentifier: .version1)
    let observer = RecordingObserver()
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
}

func testAudioFileAnalyzerAnalyzeFailsClosed() {
    let url = snTemporaryFile()
    defer { try? FileManager.default.removeItem(at: url) }
    let analyzer = try! SNAudioFileAnalyzer(url: url)
    let request = try! SNClassifySoundRequest(classifierIdentifier: .version1)
    let observer = RecordingObserver()
    try! analyzer.add(request, withObserver: observer)
    analyzer.analyze()
    snExpect(observer.failures.count == 1, "one fail-closed callback")
    snExpect(observer.produced.isEmpty, "no invented classifications")
    let error = observer.failures[0] as! SNError
    snExpect(error.code == .invalidFile, "invalidFile")
}

func testAudioFileAnalyzerCompletionHandler() {
    let url = snTemporaryFile()
    defer { try? FileManager.default.removeItem(at: url) }
    let analyzer = try! SNAudioFileAnalyzer(url: url)
    let request = try! SNClassifySoundRequest(classifierIdentifier: .version1)
    let observer = RecordingObserver()
    try! analyzer.add(request, withObserver: observer)
    var reachedEnd: Bool? = nil
    analyzer.analyze { reachedEnd = $0 }
    snExpect(reachedEnd == false, "completion reports that EOF was not classified")
    snExpect(observer.failures.count == 1, "failure delivered before completion")
}

func testAudioFileAnalyzerCancel() {
    let url = snTemporaryFile()
    defer { try? FileManager.default.removeItem(at: url) }
    let analyzer = try! SNAudioFileAnalyzer(url: url)
    let request = try! SNClassifySoundRequest(classifierIdentifier: .version1)
    let observer = RecordingObserver()
    try! analyzer.add(request, withObserver: observer)
    analyzer.cancelAnalysis()
    analyzer.analyze()
    let error = observer.failures[0] as! SNError
    snExpect(error.code == .operationFailed, "cancelled analysis")
}
