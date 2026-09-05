@_spi(OpenUIKitHost) import MetricKit
import Foundation

func testSubscriberDidReceiveMetricPayloads() {
    MXMetricManager.shared._portableRemoveAllSubscribers()
    let defaults = MXDefaultingSubscriber()
    defaults.didReceive([MXMetricPayload]())
    defaults.didReceive([MXMetricPayload(latestApplicationVersion: "1")])

    let counting = MXCountingSubscriber()
    MXMetricManager.shared.add(counting)
    mxRequire(counting.metricDeliveries == 0, "testSubscriberDidReceiveMetricPayloads: manager silent")
    counting.didReceive([MXMetricPayload(), MXMetricPayload()])
    mxRequire(counting.metricDeliveries == 2, "testSubscriberDidReceiveMetricPayloads: direct call")
    mxRequire(counting.diagnosticDeliveries == 0, "testSubscriberDidReceiveMetricPayloads: no diagnostic mix")
    MXMetricManager.shared.remove(counting)
}

func testSubscriberDidReceiveDiagnosticPayloads() {
    MXMetricManager.shared._portableRemoveAllSubscribers()
    let defaults = MXDefaultingSubscriber()
    defaults.didReceive([MXDiagnosticPayload]())
    defaults.didReceive([MXDiagnosticPayload()])

    let counting = MXCountingSubscriber()
    MXMetricManager.shared.add(counting)
    mxRequire(
        counting.diagnosticDeliveries == 0,
        "testSubscriberDidReceiveDiagnosticPayloads: manager silent"
    )
    counting.didReceive([MXDiagnosticPayload()])
    mxRequire(counting.diagnosticDeliveries == 1, "testSubscriberDidReceiveDiagnosticPayloads: direct call")
    mxRequire(counting.metricDeliveries == 0, "testSubscriberDidReceiveDiagnosticPayloads: no metric mix")
    MXMetricManager.shared.remove(counting)
}
