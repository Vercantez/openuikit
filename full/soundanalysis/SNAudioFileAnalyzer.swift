import Foundation

/// File analyzer. Linux can construct an analyzer for an existing regular
/// file but cannot decode Apple audio containers or run a sound classifier.
/// `analyze()` fails closed synchronously with `SNError.invalidFile`.
public final class SNAudioFileAnalyzer: NSObject {
    public let url: URL
    private let table = SNAnalyzerRequestTable()

    @available(*, unavailable)
    public override init() {
        fatalError("SNAudioFileAnalyzer has no public default initializer")
    }

    public init(url: URL) throws {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(
            atPath: url.path,
            isDirectory: &isDirectory
        )
        guard exists, !isDirectory.boolValue else {
            throw snLinuxUnavailable(.invalidFile)
        }
        self.url = url
        super.init()
    }

    public convenience init(URL url: URL) throws {
        try self.init(url: url)
    }

    public func add(_ request: any SNRequest, withObserver observer: any SNResultsObserving) throws {
        try table.add(request, observer: observer)
    }

    public func remove(_ request: any SNRequest) {
        table.remove(request)
    }

    public func removeAllRequests() {
        table.removeAll()
    }

    public func cancelAnalysis() {
        table.cancel()
    }

    public func analyze() {
        failClosed()
    }

    public func analyze(completionHandler: @escaping (Bool) -> Void) {
        failClosed()
        completionHandler(false)
    }

    private func failClosed() {
        let code: SNError.Code = table.cancelled ? .operationFailed : .invalidFile
        table.failAll(snLinuxUnavailable(code))
    }
}
