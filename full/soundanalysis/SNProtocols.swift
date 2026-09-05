import Foundation

public protocol SNRequest: NSObjectProtocol {}

public protocol SNResult: NSObjectProtocol {}

public protocol SNResultsObserving: NSObjectProtocol {
    func request(_ request: any SNRequest, didProduce result: any SNResult)
    func request(_ request: any SNRequest, didFailWithError error: any Error)
    func requestDidComplete(_ request: any SNRequest)
}

extension SNResultsObserving {
    public func request(_ request: any SNRequest, didFailWithError error: any Error) {
        _ = request
        _ = error
    }

    public func requestDidComplete(_ request: any SNRequest) {
        _ = request
    }
}
