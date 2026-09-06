import Foundation
import Matter

func testClusterAndAttributePaths() {
    let cluster = MTRClusterPath(endpointID: n(1), clusterID: n(6))
    mtrRequire(cluster.endpoint.uintValue == 1, "ep")
    mtrRequire(cluster.cluster.uintValue == 6, "cl")
    let attr = MTRAttributePath(endpointID: n(1), clusterID: n(6), attributeID: n(0))
    mtrRequire(attr.attribute.uintValue == 0, "attr")
    mtrRequire(attr.isEqual(MTRAttributePath(endpointId: n(1), clusterId: n(6), attributeId: n(0))), "eq")
    mtrRequire(!attr.isEqual(MTRAttributePath(endpointID: n(2), clusterID: n(6), attributeID: n(0))), "neq")
    let event = MTREventPath(endpointID: n(1), clusterID: n(0x28), eventID: n(0))
    mtrRequire(event.event.uintValue == 0, "ev")
    mtrRequire(event.isEqual(MTREventPath(endpointId: n(1), clusterId: n(0x28), eventId: n(0))), "eeq")
    let cmd = MTRCommandPath(endpointID: n(1), clusterID: n(6), commandID: n(1))
    mtrRequire(cmd.command.uintValue == 1, "cmd")
    mtrRequire(cmd.isEqual(MTRCommandPath(endpointId: n(1), clusterId: n(6), commandId: n(1))), "ceq")
    let req = MTRAttributeRequestPath(endpointID: n(1), clusterID: n(6), attributeID: n(0))
    mtrRequire(req.endpoint?.uintValue == 1, "areq")
    let ereq = MTREventRequestPath(endpointID: nil, clusterID: n(0x28), eventID: nil)
    mtrRequire(ereq.endpoint == nil, "wildcard")
    let report = MTRAttributeReport(path: attr, value: true, error: nil)
    mtrRequire(report.path.attribute.uintValue == 0, "rep path")
    let fromDict = try? MTRAttributeReport(responseValue: MTRMakeAttributeResponse(path: attr, data: MTRMakeDataValue(type: MTRBooleanValueType, value: true)))
    mtrRequire(fromDict?.path.attribute.uintValue == 0, "from dict")
    let errReport = try? MTRAttributeReport(responseValue: [
        MTRAttributePathKey: attr,
        MTRErrorKey: MTRError(.notFound)
    ])
    mtrRequire(errReport?.error != nil, "err report")
    let evReport = MTREventReport(
        path: event, eventNumber: n(1), priority: .info, eventTimeType: .systemUpTime,
        systemUpTime: 1.5, timestampDate: nil, value: nil, error: nil
    )
    mtrRequire(evReport.priority == .info, "prio")
    mtrRequire(evReport.eventTimeType == .systemUpTime, "time type")
    mtrRequire(cluster.hash != 0 || cluster.hash == 0, "hash")
}

func testReadSubscribeWriteParams() {
    let read = MTRReadParams()
    mtrRequire(read.shouldAssumeUnknownAttributesReportable, "unknown reportable")
    mtrRequire(read.shouldFilterByFabric, "fabric filter")
    read.minEventNumber = n(3)
    mtrRequire(read.minEventNumber?.intValue == 3, "min event")
    read.fabricFiltered = n(1)
    mtrRequire(read.fabricFiltered?.intValue == 1, "ff")
    let sub = MTRSubscribeParams(minInterval: n(1), maxInterval: n(5))
    mtrRequire(sub.minInterval.intValue == 1, "min")
    mtrRequire(sub.maxInterval.intValue == 5, "max")
    mtrRequire(sub.shouldResubscribeAutomatically, "autoresub")
    mtrRequire(sub.shouldReplaceExistingSubscriptions, "replace")
    mtrRequire(!sub.shouldReportEventsUrgently, "urgent")
    sub.autoResubscribe = n(1)
    sub.keepPreviousSubscriptions = n(0)
    mtrRequire(sub.autoResubscribe?.intValue == 1, "auto")
    mtrRequire(sub.keepPreviousSubscriptions?.intValue == 0, "keep")
    let fresh = MTRSubscribeParams.new()
    mtrRequire(fresh.maxInterval.intValue == 1, "new")
    let write = MTRWriteParams()
    write.dataVersion = n(7)
    write.timedWriteTimeout = n(1000)
    mtrRequire(write.dataVersion?.intValue == 7, "dv")
    mtrRequire(write.timedWriteTimeout?.intValue == 1000, "tto")
}
