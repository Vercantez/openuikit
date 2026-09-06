import Foundation
import ExposureNotification

/// Isolated-host identity probe. The sealed host gate does not compile this
/// file. The later EC2 integration build imports real Foundation and passes
/// genuine Foundation values through public ExposureNotification APIs.
func exposureNotificationDependencyIdentityProbe() {
    let domain: String = ENErrorDomain
    precondition(domain == "ENErrorDomain")

    let info: [String: Any] = ["foundation": UUID().uuidString]
    let error = ENError(.unsupported, userInfo: info)
    precondition(error.userInfo["sentinel"] == nil)
    precondition(error.userInfo["foundation"] as? String == info["foundation"] as? String)
    let ns = error as NSError
    precondition(ns.domain == ENErrorDomain)
    precondition(ns.code == ENError.Code.unsupported.rawValue)

    let date = Date(timeIntervalSince1970: 1)
    let data = Data([0x01, 0x02, 0x03, 0x04])
    let key = ENTemporaryExposureKey()
    key.keyData = data
    precondition(key.keyData == data)

    let config = ENExposureConfiguration()
    config.metadata = ["uuid": UUID().uuidString]
    precondition(config.metadata?["uuid"] is String)

    let summary = ENExposureDetectionSummary(
        attenuationDurations: [NSNumber(value: 1)],
        daySummaries: [],
        daysSinceLastExposure: 0,
        matchedKeyCount: 0,
        maximumRiskScore: 0,
        maximumRiskScoreFullRange: 0,
        metadata: ["date": date],
        riskScoreSumFullRange: 0
    )
    precondition(summary.metadata?["date"] as? Date == date)

    let url = URL(fileURLWithPath: "/tmp/en-identity")
    let manager = ENManager()
    var called = false
    _ = manager.detectExposures(configuration: config, diagnosisKeyURLs: [url]) { _, error in
        called = true
        precondition(error != nil)
    }
    precondition(called)
}
