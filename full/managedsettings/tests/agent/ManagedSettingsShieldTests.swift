import Foundation
import ManagedSettings

private func linuxToken<T>(_ uuid: String) -> Token<T> {
    let json = Data("{\"linuxOpaqueID\":\"\(uuid)\"}".utf8)
    do {
        return try JSONDecoder().decode(Token<T>.self, from: json)
    } catch {
        preconditionFailure("linux token decode failed: \(error)")
    }
}

func testShieldActionDelegateInit() {
    let delegate = ShieldActionDelegate()
    let asObject: NSObject = delegate
    precondition(asObject === delegate)
}

func testHandleApplicationFailClosed() {
    let delegate = ShieldActionDelegate()
    let token: ApplicationToken = linuxToken("F1F1F1F1-F1F1-41F1-81F1-F1F1F1F1F1F1")
    var responses: [ShieldActionResponse] = []
    delegate.handle(action: .primaryButtonPressed, for: token) { response in
        responses.append(response)
    }
    precondition(responses == [ShieldActionResponse.none])
}

func testHandleCategoryFailClosed() {
    let delegate = ShieldActionDelegate()
    let token: ActivityCategoryToken = linuxToken("F2F2F2F2-F2F2-42F2-82F2-F2F2F2F2F2F2")
    var responses: [ShieldActionResponse] = []
    delegate.handle(action: .secondaryButtonPressed, for: token) { response in
        responses.append(response)
    }
    precondition(responses == [ShieldActionResponse.none])
}

func testHandleWebDomainFailClosed() {
    let delegate = ShieldActionDelegate()
    let token: WebDomainToken = linuxToken("F3F3F3F3-F3F3-43F3-83F3-F3F3F3F3F3F3")
    var responses: [ShieldActionResponse] = []
    delegate.handle(action: .primaryButtonPressed, for: token) { response in
        responses.append(response)
    }
    precondition(responses == [ShieldActionResponse.none])
}

private final class RecordingShieldDelegate: ShieldActionDelegate {
    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        _ = action
        _ = application
        completionHandler(.close)
    }
}

func testShieldActionDelegateSubclassOverride() {
    let delegate = RecordingShieldDelegate()
    let token: ApplicationToken = linuxToken("F4F4F4F4-F4F4-44F4-84F4-F4F4F4F4F4F4")
    var responses: [ShieldActionResponse] = []
    delegate.handle(action: .primaryButtonPressed, for: token) { response in
        responses.append(response)
    }
    precondition(responses == [.close])
}
