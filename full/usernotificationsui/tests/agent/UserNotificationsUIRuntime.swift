import Foundation
import UserNotificationsUI

private final class AsyncBox<Value>: @unchecked Sendable {
    var value: Value?
}

private final class Unchecked<Value>: @unchecked Sendable {
    let value: Value
    init(_ value: Value) {
        self.value = value
    }
}

private func awaitBlocking<Value>(_ operation: @escaping @Sendable () async -> Value) -> Value {
    let box = AsyncBox<Value>()
    let semaphore = DispatchSemaphore(value: 0)
    Task {
        box.value = await operation()
        semaphore.signal()
    }
    semaphore.wait()
    guard let value = box.value else {
        fatalError("async operation produced no value")
    }
    return value
}

private func assertEnums() {
    let none = UNNotificationContentExtensionMediaPlayPauseButtonType.none
    let buttonDefault = UNNotificationContentExtensionMediaPlayPauseButtonType.default
    let overlay = UNNotificationContentExtensionMediaPlayPauseButtonType.overlay
    let buttonCases = [none, buttonDefault, overlay]
    precondition(buttonCases.map(\.rawValue) == [0, 1, 2])
    precondition(UNNotificationContentExtensionMediaPlayPauseButtonType(rawValue: 0) == none)
    precondition(UNNotificationContentExtensionMediaPlayPauseButtonType(rawValue: 1) == buttonDefault)
    precondition(UNNotificationContentExtensionMediaPlayPauseButtonType(rawValue: 2) == overlay)
    precondition(UNNotificationContentExtensionMediaPlayPauseButtonType(rawValue: 3) == nil)
    precondition(none != buttonDefault)
    precondition(buttonDefault != overlay)
    precondition(overlay != none)
    precondition(none == none)

    var buttonHasher = Hasher()
    for item in buttonCases {
        item.hash(into: &buttonHasher)
        _ = item.hashValue
    }
    _ = buttonHasher.finalize()
    precondition(none.hashValue == none.hashValue)
    precondition(none.hashValue != overlay.hashValue)

    let doNotDismiss = UNNotificationContentExtensionResponseOption.doNotDismiss
    let dismiss = UNNotificationContentExtensionResponseOption.dismiss
    let dismissAndForward = UNNotificationContentExtensionResponseOption.dismissAndForwardAction
    let responseCases = [doNotDismiss, dismiss, dismissAndForward]
    precondition(responseCases.map(\.rawValue) == [0, 1, 2])
    precondition(UNNotificationContentExtensionResponseOption(rawValue: 0) == doNotDismiss)
    precondition(UNNotificationContentExtensionResponseOption(rawValue: 1) == dismiss)
    precondition(UNNotificationContentExtensionResponseOption(rawValue: 2) == dismissAndForward)
    precondition(UNNotificationContentExtensionResponseOption(rawValue: 99) == nil)
    precondition(doNotDismiss != dismiss)
    precondition(dismiss != dismissAndForward)
    precondition(dismissAndForward != doNotDismiss)
    precondition(dismiss == dismiss)

    var responseHasher = Hasher()
    for item in responseCases {
        item.hash(into: &responseHasher)
        _ = item.hashValue
    }
    _ = responseHasher.finalize()
    precondition(dismiss.hashValue == dismiss.hashValue)
    precondition(doNotDismiss.hashValue != dismiss.hashValue)
}

private final class DefaultingContentExtension: NSObject, UNNotificationContentExtension {
    var receivedCount = 0
    var lastNotification: UNNotification?

    func didReceive(_ notification: UNNotification) {
        receivedCount += 1
        lastNotification = notification
    }
}

private final class OverridingContentExtension: NSObject, UNNotificationContentExtension {
    var receivedCount = 0
    var completionCount = 0
    var mediaPlayCount = 0
    var mediaPauseCount = 0
    var lastNotification: UNNotification?
    var lastResponse: UNNotificationResponse?
    let tint = UIColor()
    let frame = CGRect(x: 4, y: 8, width: 16, height: 32)

    func didReceive(_ notification: UNNotification) {
        receivedCount += 1
        lastNotification = notification
    }

    func didReceive(
        _ response: UNNotificationResponse,
        completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void
    ) {
        completionCount += 1
        lastResponse = response
        completion(.dismiss)
    }

    func didReceive(
        _ response: UNNotificationResponse
    ) async -> UNNotificationContentExtensionResponseOption {
        lastResponse = response
        return .dismissAndForwardAction
    }

    func mediaPlay() {
        mediaPlayCount += 1
    }

    func mediaPause() {
        mediaPauseCount += 1
    }

    var mediaPlayPauseButtonType: UNNotificationContentExtensionMediaPlayPauseButtonType {
        .overlay
    }

    var mediaPlayPauseButtonFrame: CGRect {
        frame
    }

    var mediaPlayPauseButtonTintColor: UIColor {
        tint
    }
}

private func assertDefaultExistential() {
    let concrete = DefaultingContentExtension()
    let existential: any UNNotificationContentExtension = concrete
    let notification = UNNotification()

    existential.didReceive(notification)
    precondition(concrete.receivedCount == 1)
    precondition(concrete.lastNotification === notification)

    let response = UNNotificationResponse(
        notification: notification,
        actionIdentifier: "com.example.action"
    )
    var completionOption: UNNotificationContentExtensionResponseOption?
    existential.didReceive(response) { option in
        completionOption = option
    }
    precondition(completionOption == .doNotDismiss)

    let held = Unchecked(existential)
    let heldResponse = Unchecked(response)
    let asyncOption = awaitBlocking {
        await held.value.didReceive(heldResponse.value)
    }
    precondition(asyncOption == .doNotDismiss)

    existential.mediaPlay()
    existential.mediaPause()
    precondition(existential.mediaPlayPauseButtonType == .none)
    precondition(existential.mediaPlayPauseButtonFrame == .zero)
    _ = existential.mediaPlayPauseButtonTintColor
}

private func assertOverrideExistential() {
    let concrete = OverridingContentExtension()
    let existential: any UNNotificationContentExtension = concrete
    let notification = UNNotification()
    let response = UNNotificationResponse(
        notification: notification,
        actionIdentifier: "com.example.override"
    )

    existential.didReceive(notification)
    precondition(concrete.receivedCount == 1)
    precondition(concrete.lastNotification === notification)

    var completionOption: UNNotificationContentExtensionResponseOption?
    existential.didReceive(response) { option in
        completionOption = option
    }
    precondition(concrete.completionCount == 1)
    precondition(completionOption == .dismiss)
    precondition(concrete.lastResponse === response)

    let held = Unchecked(existential)
    let heldResponse = Unchecked(response)
    let asyncOption = awaitBlocking {
        await held.value.didReceive(heldResponse.value)
    }
    precondition(asyncOption == .dismissAndForwardAction)

    existential.mediaPlay()
    existential.mediaPlay()
    existential.mediaPause()
    precondition(concrete.mediaPlayCount == 2)
    precondition(concrete.mediaPauseCount == 1)
    precondition(existential.mediaPlayPauseButtonType == .overlay)
    precondition(existential.mediaPlayPauseButtonFrame == concrete.frame)
    precondition(existential.mediaPlayPauseButtonTintColor === concrete.tint)

    let defaulting: any UNNotificationContentExtension = DefaultingContentExtension()
    precondition(existential.mediaPlayPauseButtonTintColor
        !== defaulting.mediaPlayPauseButtonTintColor)
}

assertEnums()
assertDefaultExistential()
assertOverrideExistential()
print("USERNOTIFICATIONSUI_AGENT_RUNTIME_OK")
