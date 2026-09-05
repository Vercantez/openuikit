@_spi(OpenUIKitHost) import WiFiAware
import Foundation

private func waExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testParametersPresets() {
    waExpect(WAParameters.defaults.performanceMode == .bulk, "defaults are bulk")
    waExpect(WAParameters.realtime.performanceMode == .realtime, "realtime preset")
    var parameters = WAParameters()
    waExpect(parameters.performanceMode == .bulk, "init default is bulk")
    parameters = WAParameters(performanceMode: .realtime)
    waExpect(parameters.performanceMode == .realtime, "init(performanceMode:)")
    parameters.performanceMode = .bulk
    waExpect(parameters.performanceMode == .bulk, "performanceMode is settable")
    let _: WAParameters = parameters
}

func testPerformanceModeCases() {
    let cases = WAPerformanceMode.allCases
    waExpect(cases == [.bulk, .realtime], "performance allCases")
    let _: WAPerformanceMode.AllCases = cases
    waExpect(WAPerformanceMode.bulk == .bulk, "bulk ==")
    waExpect(WAPerformanceMode.bulk != .realtime, "bulk !=")
    var hasher = Hasher()
    WAPerformanceMode.realtime.hash(into: &hasher)
    _ = hasher.finalize()
    waExpect(
        WAPerformanceMode.bulk.hashValue != WAPerformanceMode.realtime.hashValue
            || WAPerformanceMode.bulk.hashValue == WAPerformanceMode.realtime.hashValue,
        "hashValue reachable"
    )
    for mode in cases {
        let data = try! JSONEncoder().encode(mode)
        let decoded = try! JSONDecoder().decode(WAPerformanceMode.self, from: data)
        waExpect(decoded == mode, "performance Codable \(mode)")
    }
}

func testAccessCategoryCases() {
    let cases = WAAccessCategory.allCases
    waExpect(
        cases == [.bestEffort, .background, .interactiveVideo, .interactiveVoice],
        "access allCases"
    )
    let _: WAAccessCategory.AllCases = cases
    waExpect(WAAccessCategory.bestEffort == .bestEffort, "bestEffort ==")
    waExpect(WAAccessCategory.bestEffort != .interactiveVoice, "access !=")
    var hasher = Hasher()
    WAAccessCategory.background.hash(into: &hasher)
    _ = hasher.finalize()
    _ = WAAccessCategory.interactiveVideo.hashValue
    for category in cases {
        let data = try! JSONEncoder().encode(category)
        let decoded = try! JSONDecoder().decode(WAAccessCategory.self, from: data)
        waExpect(decoded == category, "access Codable \(category)")
    }
}
