@_spi(OpenUIKitHost) import MetricKit
import Foundation

func mxRequire(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError(message)
    }
}

final class MXDummyCoder: NSCoder {}

final class MXDefaultingSubscriber: NSObject, MXMetricManagerSubscriber {}

final class MXCountingSubscriber: NSObject, MXMetricManagerSubscriber {
    var metricDeliveries = 0
    var diagnosticDeliveries = 0

    func didReceive(_ payloads: [MXMetricPayload]) {
        metricDeliveries += payloads.count
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        diagnosticDeliveries += payloads.count
    }
}

func mxJSONObject(_ data: Data, _ message: String) -> [String: Any] {
    do {
        let object = try JSONSerialization.jsonObject(with: data, options: [])
        guard let dictionary = object as? [String: Any] else {
            fatalError("\(message): JSON is not an object")
        }
        return dictionary
    } catch {
        fatalError("\(message): \(error)")
    }
}

func mxJSONNumber(_ value: Any?, equals expected: Double) -> Bool {
    if let number = value as? NSNumber {
        return number.doubleValue == expected
    }
    if let number = value as? Double {
        return number == expected
    }
    if let number = value as? Int {
        return Double(number) == expected
    }
    return false
}

func mxJSONInt(_ value: Any?, equals expected: Int) -> Bool {
    if let number = value as? NSNumber {
        return number.intValue == expected
    }
    if let number = value as? Int {
        return number == expected
    }
    return false
}

func mxJSONBool(_ value: Any?, equals expected: Bool) -> Bool {
    if let flag = value as? Bool {
        return flag == expected
    }
    if let number = value as? NSNumber {
        return number.boolValue == expected
    }
    return false
}

func mxMeasurementDict(_ value: Any?) -> [String: Any]? {
    value as? [String: Any]
}
