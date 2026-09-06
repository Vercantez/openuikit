import Foundation
@_spi(OpenUIKitHost) import FinanceKitUI

private struct SampleConnectionExtension: FinancialConnectionUIExtension {
    var body: FinancialConnectionUIExtensionAuthorizationScene<EmptyView> {
        FinancialConnectionUIExtensionAuthorizationScene(content: { EmptyView() })
    }

    func authorize(_ request: FinancialConnectionExtensionAuthorizationRequest) {
        request.complete(
            error: FinanceKitUIUnavailable.linuxHost(operation: "authorize")
        )
    }
}

func testFinancialConnectionUIExtensionProtocol() {
    let ext = SampleConnectionExtension()
    let asProviding: any FinancialConnectionUIExtensionProviding = ext
    let asExtension: any AppExtension = ext
    _ = asProviding
    _ = asExtension
    precondition(type(of: ext.body) == FinancialConnectionUIExtensionAuthorizationScene<EmptyView>.self)
}

func testFinancialConnectionUIExtensionBodyAssociatedType() {
    precondition(
        SampleConnectionExtension.Body.self
            == FinancialConnectionUIExtensionAuthorizationScene<EmptyView>.self
    )
}

func testFinancialConnectionUIExtensionBody() {
    let ext = SampleConnectionExtension()
    let body = ext.body
    let asScene: any FinancialConnectionUIExtensionScene = body
    _ = asScene
    precondition(type(of: body) == FinancialConnectionUIExtensionAuthorizationScene<EmptyView>.self)
}

func testFinancialConnectionUIExtensionConfiguration() {
    let ext = SampleConnectionExtension()
    let configuration = ext.configuration
    precondition(type(of: configuration) == AppExtensionSceneConfiguration.self)
    precondition(!configuration.hostSceneTypeName.isEmpty)
}

func testFinancialConnectionUIExtensionSceneProtocol() {
    let scene = FinanceKitUIHostExtensionScene()
    let asScene: any FinancialConnectionUIExtensionScene = scene
    let asApp: any AppExtensionScene = scene
    _ = asScene
    _ = asApp
    precondition(FinanceKitUIHostExtensionScene.Body.self == Never.self)
}

func testFinancialConnectionUIExtensionProvidingProtocol() {
    FinanceKitUIHostControl.reset()
    var delivered: Result<FinancialConnectionExtensionAuthorizationResult, any Error>?
    let request = FinancialConnectionExtensionAuthorizationRequest(
        params: ["client": "linux"],
        completion: { delivered = $0 }
    )
    let ext = SampleConnectionExtension()
    ext.authorize(request)
    switch delivered {
    case .failure(let error as FinanceKitUIUnavailable):
        precondition(error == .linuxHost(operation: "authorize"))
    default:
        precondition(false, "authorize must fail closed on Linux")
    }
    precondition(request.hostCompleted)
}

func testFinancialConnectionUIExtensionProvidingAuthorize() {
    FinanceKitUIHostControl.reset()
    var calls = 0
    let request = FinancialConnectionExtensionAuthorizationRequest(
        params: [:],
        completion: { _ in calls += 1 }
    )
    SampleConnectionExtension().authorize(request)
    precondition(calls == 1)
    precondition(FinanceKitUIHostControl.lastAuthorizationCompleted())
}

func testFinancialConnectionExtensionAuthorizationParams() {
    let params: FinancialConnectionExtensionAuthorizationParams = ["k": "v", "empty": ""]
    precondition(params["k"] == "v")
    precondition(params["empty"] == "")
    precondition(FinancialConnectionExtensionAuthorizationParams.self == [String: String].self)
}

func testFinancialConnectionExtensionAuthorizationResultStruct() {
    let result = FinancialConnectionExtensionAuthorizationResult(params: ["a": "1"])
    precondition(result.params["a"] == "1")
    let copy = FinancialConnectionExtensionAuthorizationResult(params: ["a": "1"])
    precondition(result == copy)
}

func testFinancialConnectionExtensionAuthorizationResultInitFrom() {
    let original = FinancialConnectionExtensionAuthorizationResult(
        params: ["institution": "bank", "token": "abc"]
    )
    do {
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(
            FinancialConnectionExtensionAuthorizationResult.self,
            from: data
        )
        precondition(decoded == original)
        precondition(decoded.params["institution"] == "bank")
    } catch {
        precondition(false, "Codable round-trip failed: \(error)")
    }
}

func testFinancialConnectionExtensionAuthorizationResultEncode() {
    let result = FinancialConnectionExtensionAuthorizationResult(params: ["x": "y"])
    do {
        let data = try JSONEncoder().encode(result)
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let params = object?["params"] as? [String: String]
        precondition(params?["x"] == "y")
    } catch {
        precondition(false, "encode failed: \(error)")
    }
}

func testFinancialConnectionExtensionAuthorizationResultInitParams() {
    let result = FinancialConnectionExtensionAuthorizationResult(params: [:])
    precondition(result.params.isEmpty)
    let filled = FinancialConnectionExtensionAuthorizationResult(params: ["id": "42"])
    precondition(filled.params["id"] == "42")
}

func testFinancialConnectionExtensionAuthorizationResultParams() {
    let params: FinancialConnectionExtensionAuthorizationParams = ["one": "1", "two": "2"]
    let result = FinancialConnectionExtensionAuthorizationResult(params: params)
    precondition(result.params == params)
    precondition(result.params.count == 2)
}

func testFinancialConnectionExtensionAuthorizationRequestStruct() {
    let request = FinancialConnectionExtensionAuthorizationRequest(params: ["n": "1"])
    precondition(request.params["n"] == "1")
    precondition(request.hostCompleted == false)
    precondition(request.hostDuplicateCompletes == 0)
}

func testFinancialConnectionExtensionAuthorizationRequestCompletionHandler() {
    var stored: FinancialConnectionExtensionAuthorizationRequest.CompletionHandler?
    var seen = 0
    let handler: FinancialConnectionExtensionAuthorizationRequest.CompletionHandler = { _ in
        seen += 1
    }
    stored = handler
    stored?(.failure(FinanceKitUIUnavailable.linuxHost(operation: "handler")))
    precondition(seen == 1)
}

func testFinancialConnectionExtensionAuthorizationRequestCompletionHandlerResult() {
    let success: FinancialConnectionExtensionAuthorizationRequest.CompletionHandlerResult =
        .success(FinancialConnectionExtensionAuthorizationResult(params: [:]))
    let failure: FinancialConnectionExtensionAuthorizationRequest.CompletionHandlerResult =
        .failure(FinanceKitUIUnavailable.linuxHost(operation: "result"))
    switch success {
    case .success(let value):
        precondition(value.params.isEmpty)
    case .failure:
        precondition(false)
    }
    switch failure {
    case .failure(let error as FinanceKitUIUnavailable):
        precondition(error == .linuxHost(operation: "result"))
    default:
        precondition(false)
    }
}

func testFinancialConnectionExtensionAuthorizationRequestParams() {
    var request = FinancialConnectionExtensionAuthorizationRequest(params: ["before": "1"])
    precondition(request.params["before"] == "1")
    request.params["after"] = "2"
    precondition(request.params["after"] == "2")
    request.params["before"] = "changed"
    precondition(request.params["before"] == "changed")
}

func testFinancialConnectionExtensionAuthorizationRequestCompleteResult() {
    FinanceKitUIHostControl.reset()
    var delivered: FinancialConnectionExtensionAuthorizationRequest.CompletionHandlerResult?
    let request = FinancialConnectionExtensionAuthorizationRequest(
        params: ["ok": "true"],
        completion: { delivered = $0 }
    )
    let payload = FinancialConnectionExtensionAuthorizationResult(params: ["ok": "true"])
    request.complete(authorizationResult: payload)
    switch delivered {
    case .success(let value):
        precondition(value == payload)
    default:
        precondition(false)
    }
    precondition(request.hostCompleted)
    precondition(request.hostDuplicateCompletes == 0)
    request.complete(authorizationResult: payload)
    precondition(request.hostDuplicateCompletes == 1)
    precondition(FinanceKitUIHostControl.lastAuthorizationDuplicateCompletes() == 1)
}

func testFinancialConnectionExtensionAuthorizationRequestCompleteError() {
    FinanceKitUIHostControl.reset()
    var delivered: FinancialConnectionExtensionAuthorizationRequest.CompletionHandlerResult?
    let request = FinancialConnectionExtensionAuthorizationRequest(
        params: [:],
        completion: { delivered = $0 }
    )
    request.complete(error: FinanceKitUIUnavailable.linuxHost(operation: "complete(error:)"))
    switch delivered {
    case .failure(let error as FinanceKitUIUnavailable):
        precondition(error == .linuxHost(operation: "complete(error:)"))
    default:
        precondition(false)
    }
    request.complete(error: FinanceKitUIUnavailable.linuxHost(operation: "second"))
    precondition(request.hostDuplicateCompletes == 1)
}

func testFinancialConnectionUIExtensionAuthorizationSceneStruct() {
    let scene = FinancialConnectionUIExtensionAuthorizationScene(content: { EmptyView() })
    let asScene: any FinancialConnectionUIExtensionScene = scene
    _ = asScene
    precondition(type(of: scene.hostRenderContent()) == EmptyView.self)
}

func testFinancialConnectionUIExtensionAuthorizationSceneBodyTypealias() {
    precondition(
        FinancialConnectionUIExtensionAuthorizationScene<EmptyView>.Body.self
            == FinanceKitUIHostExtensionScene.self
    )
}

func testFinancialConnectionUIExtensionAuthorizationSceneBody() {
    let scene = FinancialConnectionUIExtensionAuthorizationScene(content: { EmptyView() })
    let body = scene.body
    precondition(type(of: body) == FinanceKitUIHostExtensionScene.self)
}

func testFinancialConnectionUIExtensionAuthorizationSceneInit() {
    var constructed = false
    let scene = FinancialConnectionUIExtensionAuthorizationScene {
        constructed = true
        return EmptyView()
    }
    precondition(constructed == false)
    _ = scene.hostRenderContent()
    precondition(constructed)
}
