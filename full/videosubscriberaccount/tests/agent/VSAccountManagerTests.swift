import Foundation
import VideoSubscriberAccount

final class RecordingAccountManagerDelegate: NSObject, VSAccountManagerDelegate {
    var lastIdentifier: String?
    var returnValue = false

    func accountManager(
        _ accountManager: VSAccountManager,
        shouldAuthenticateAccountProviderWithIdentifier accountProviderIdentifier: String
    ) -> Bool {
        _ = accountManager
        lastIdentifier = accountProviderIdentifier
        return returnValue
    }
}

final class DefaultAccountManagerDelegate: NSObject, VSAccountManagerDelegate {}

func testAccountManagerDelegateStorage() {
    let manager = VSAccountManager()
    precondition(manager.delegate == nil)
    let delegate = RecordingAccountManagerDelegate()
    manager.delegate = delegate
    precondition(manager.delegate === delegate)
    manager.delegate = nil
    precondition(manager.delegate == nil)
}

func testAccountManagerEnqueueFailClosed() {
    let manager = VSAccountManager()
    let request = VSAccountMetadataRequest()
    request.channelIdentifier = "com.example.channel"
    var receivedMetadata: VSAccountMetadata? = VSAccountMetadata()
    var receivedError: (any Error)?
    let result = manager.enqueue(request) { metadata, error in
        receivedMetadata = metadata
        receivedError = error
    }
    precondition(receivedMetadata == nil)
    let vsError = receivedError as? VSError
    precondition(vsError?.code == .unsupported)
    precondition(VSError.Code.unsupported ~= vsError!)
    result.cancel()
    precondition(result.isCancelled)
}

func testAccountManagerResultCancel() {
    let result = VSAccountManagerResult()
    precondition(!result.isCancelled)
    result.cancel()
    precondition(result.isCancelled)
    result.cancel()
    precondition(result.isCancelled)
}

func testAccountManagerDelegateShouldAuthenticateDefault() {
    let manager = VSAccountManager()
    let delegate = DefaultAccountManagerDelegate()
    let allowed = delegate.accountManager(
        manager,
        shouldAuthenticateAccountProviderWithIdentifier: "com.example.tv"
    )
    precondition(allowed == false)
}

func testAccountManagerDelegateShouldAuthenticateOverride() {
    let manager = VSAccountManager()
    let delegate = RecordingAccountManagerDelegate()
    delegate.returnValue = true
    let allowed = delegate.accountManager(
        manager,
        shouldAuthenticateAccountProviderWithIdentifier: "com.example.tv"
    )
    precondition(allowed)
    precondition(delegate.lastIdentifier == "com.example.tv")
}

func testAccountManagerCheckAccessStatusCompletionFailClosed() {
    let manager = VSAccountManager()
    var status: VSAccountAccessStatus?
    var receivedError: (any Error)?
    manager.checkAccessStatus(options: [.prompt: true]) { accessStatus, error in
        status = accessStatus
        receivedError = error
    }
    precondition(status == .notDetermined)
    precondition((receivedError as? VSError)?.code == .unsupported)
}
