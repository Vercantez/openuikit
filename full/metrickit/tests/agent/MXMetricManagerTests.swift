@_spi(OpenUIKitHost) import MetricKit
import Foundation
import Dispatch

func testSharedManagerAndEmptyPayloads() {
    mxRequire(MXMetricManager.shared === MXMetricManager.shared, "testSharedManagerAndEmptyPayloads: shared")
    mxRequire(MXMetricManager.shared.pastPayloads.isEmpty, "testSharedManagerAndEmptyPayloads: pastPayloads")
    mxRequire(
        MXMetricManager.shared.pastDiagnosticPayloads.isEmpty,
        "testSharedManagerAndEmptyPayloads: pastDiagnosticPayloads"
    )
}

private final class MXDeinitBox: @unchecked Sendable {
    private let lock = NSLock()
    private var _deinited = false

    var deinited: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _deinited
    }

    func mark() {
        lock.lock()
        _deinited = true
        lock.unlock()
    }
}

private final class MXLifetimeSubscriber: NSObject, MXMetricManagerSubscriber {
    let box: MXDeinitBox

    init(box: MXDeinitBox) {
        self.box = box
        super.init()
    }

    deinit {
        box.mark()
    }
}

func testSubscriberAddRemoveRetention() {
    MXMetricManager.shared._portableRemoveAllSubscribers()
    let box = MXDeinitBox()
    weak var weakSubscriber: MXLifetimeSubscriber?
    do {
        let subscriber = MXLifetimeSubscriber(box: box)
        weakSubscriber = subscriber
        MXMetricManager.shared.add(subscriber)
        MXMetricManager.shared.add(subscriber)
    }
    mxRequire(
        MXMetricManager.shared._portableSubscriberCount == 1,
        "testSubscriberAddRemoveRetention: idempotent add"
    )
    mxRequire(weakSubscriber != nil, "testSubscriberAddRemoveRetention: strong retention")
    mxRequire(!box.deinited, "testSubscriberAddRemoveRetention: not deinited while retained")
    mxRequire(
        MXMetricManager.shared._portableContains(weakSubscriber!),
        "testSubscriberAddRemoveRetention: contains"
    )
    let probe = MXCountingSubscriber()
    MXMetricManager.shared.add(probe)
    mxRequire(probe.metricDeliveries == 0, "testSubscriberAddRemoveRetention: no metric telemetry")
    mxRequire(probe.diagnosticDeliveries == 0, "testSubscriberAddRemoveRetention: no diagnostic telemetry")
    mxRequire(
        MXMetricManager.shared._portableSubscriberCount == 2,
        "testSubscriberAddRemoveRetention: two subscribers"
    )
    MXMetricManager.shared.remove(probe)
    MXMetricManager.shared.remove(weakSubscriber!)
    mxRequire(
        MXMetricManager.shared._portableSubscriberCount == 0,
        "testSubscriberAddRemoveRetention: count after remove"
    )
    mxRequire(weakSubscriber == nil, "testSubscriberAddRemoveRetention: released after remove")
    mxRequire(box.deinited, "testSubscriberAddRemoveRetention: deinit after remove")
}

private final class MXSubscriberList: @unchecked Sendable {
    private let lock = NSLock()
    private var items: [MXCountingSubscriber] = []

    func append(_ subscriber: MXCountingSubscriber) {
        lock.lock()
        items.append(subscriber)
        lock.unlock()
    }

    func snapshot() -> [MXCountingSubscriber] {
        lock.lock()
        let copy = items
        lock.unlock()
        return copy
    }
}

func testSubscriberConcurrentAddRemove() {
    MXMetricManager.shared._portableRemoveAllSubscribers()
    let group = DispatchGroup()
    let queue = DispatchQueue(label: "metrickit.subscribers", attributes: .concurrent)
    let live = MXSubscriberList()
    for _ in 0..<64 {
        queue.async(group: group) {
            let subscriber = MXCountingSubscriber()
            MXMetricManager.shared.add(subscriber)
            MXMetricManager.shared.add(subscriber)
            live.append(subscriber)
        }
    }
    group.wait()
    let items = live.snapshot()
    mxRequire(items.count == 64, "testSubscriberConcurrentAddRemove: live count")
    mxRequire(
        MXMetricManager.shared._portableSubscriberCount == 64,
        "testSubscriberConcurrentAddRemove: unique adds"
    )
    for subscriber in items {
        queue.async(group: group) {
            MXMetricManager.shared.remove(subscriber)
            MXMetricManager.shared.remove(subscriber)
        }
    }
    group.wait()
    mxRequire(
        MXMetricManager.shared._portableSubscriberCount == 0,
        "testSubscriberConcurrentAddRemove: released"
    )
}
