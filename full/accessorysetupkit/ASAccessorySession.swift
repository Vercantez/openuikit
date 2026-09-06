import Foundation

/// Accessory setup session. Local activate/invalidate is a process-local
/// state machine. Linux has no picker UI, pairing daemon, or entitlement:
/// picker and authorization APIs fail closed with documented `ASError` codes
/// and never invent accessories.
open class ASAccessorySession: NSObject {
    private enum Phase {
        case idle
        case activated
        case invalidated
    }

    private var phase: Phase = .idle
    private var eventHandler: ((ASAccessoryEvent) -> Void)?
    private var storedPickerDisplaySettings: ASPickerDisplaySettings?

    public override init() {
        super.init()
    }

    open var accessories: [ASAccessory] { [] }

    open var pickerDisplaySettings: ASPickerDisplaySettings? {
        get { storedPickerDisplaySettings }
        set { storedPickerDisplaySettings = newValue }
    }

    /// Records the handler and delivers `.activated` synchronously. Queue
    /// hops are unobserved (the sealed runner has no run loop).
    open func activate(
        on queue: dispatch_queue_t,
        eventHandler: @escaping (ASAccessoryEvent) -> Void
    ) {
        _ = queue
        guard phase != .invalidated else {
            eventHandler(
                ASAccessoryEvent(
                    hostEventType: .invalidated,
                    hostError: ASError(.invalidated)
                )
            )
            return
        }
        self.eventHandler = eventHandler
        phase = .activated
        eventHandler(ASAccessoryEvent(hostEventType: .activated))
    }

    open func invalidate() {
        guard phase != .invalidated else { return }
        phase = .invalidated
        let handler = eventHandler
        eventHandler = nil
        handler?(ASAccessoryEvent(hostEventType: .invalidated))
    }

    open func showPicker(completionHandler: @escaping ((any Error)?) -> Void) {
        completionHandler(failClosedPicker())
    }

    open func showPicker(for displayItems: [ASPickerDisplayItem]) async throws {
        _ = displayItems
        throw failClosedPicker()
    }

    open func showPicker(
        for displayItems: [ASPickerDisplayItem],
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = displayItems
        completionHandler(failClosedPicker())
    }

    open func finishAuthorization(
        for accessory: ASAccessory,
        settings: ASAccessorySettings
    ) async throws {
        _ = accessory
        _ = settings
        throw failClosedRequest()
    }

    open func finishAuthorization(
        for accessory: ASAccessory,
        settings: ASAccessorySettings,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = accessory
        _ = settings
        completionHandler(failClosedRequest())
    }

    open func removeAccessory(_ accessory: ASAccessory) async throws {
        _ = accessory
        throw failClosedRequest()
    }

    open func removeAccessory(
        _ accessory: ASAccessory,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = accessory
        completionHandler(failClosedRequest())
    }

    open func renameAccessory(
        _ accessory: ASAccessory,
        options renameOptions: ASAccessory.RenameOptions = []
    ) async throws {
        _ = accessory
        _ = renameOptions
        throw failClosedRequest()
    }

    open func renameAccessory(
        _ accessory: ASAccessory,
        options renameOptions: ASAccessory.RenameOptions = [],
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = accessory
        _ = renameOptions
        completionHandler(failClosedRequest())
    }

    open func failAuthorization(for accessory: ASAccessory) async throws {
        _ = accessory
        throw failClosedRequest()
    }

    open func failAuthorization(
        for accessory: ASAccessory,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = accessory
        completionHandler(failClosedRequest())
    }

    open func updateAuthorization(
        for accessory: ASAccessory,
        descriptor: ASDiscoveryDescriptor
    ) async throws {
        _ = accessory
        _ = descriptor
        throw failClosedRequest()
    }

    open func updateAuthorization(
        for accessory: ASAccessory,
        descriptor: ASDiscoveryDescriptor,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = accessory
        _ = descriptor
        completionHandler(failClosedRequest())
    }

    open func updatePicker(showing displayItems: [ASDiscoveredDisplayItem]) async throws {
        _ = displayItems
        throw failClosedPicker()
    }

    open func updatePicker(
        showing displayItems: [ASDiscoveredDisplayItem],
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = displayItems
        completionHandler(failClosedPicker())
    }

    open func finishPickerDiscovery(completionHandler: @escaping ((any Error)?) -> Void) {
        completionHandler(failClosedPicker())
    }

    private func failClosedPicker() -> ASError {
        switch phase {
        case .idle, .invalidated:
            return ASError(.invalidated)
        case .activated:
            return ASError(.pickerRestricted)
        }
    }

    private func failClosedRequest() -> ASError {
        switch phase {
        case .idle, .invalidated:
            return ASError(.invalidated)
        case .activated:
            return ASError(.invalidRequest)
        }
    }
}
