import ExternalAccessory
import Foundation

func testEAWiFiUnconfiguredAccessoryBrowserStateRawValues() {
    let cases: [(EAWiFiUnconfiguredAccessoryBrowserState, Int)] = [
        (.wiFiUnavailable, 0),
        (.stopped, 1),
        (.searching, 2),
        (.configuring, 3),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(EAWiFiUnconfiguredAccessoryBrowserState(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(EAWiFiUnconfiguredAccessoryBrowserState(rawValue: 99) == nil)
    precondition(EAWiFiUnconfiguredAccessoryBrowserState.stopped != .searching)
}

func testEAWiFiUnconfiguredAccessoryConfigurationStatusRawValues() {
    let cases: [(EAWiFiUnconfiguredAccessoryConfigurationStatus, Int)] = [
        (.success, 0),
        (.userCancelledConfiguration, 1),
        (.failed, 2),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(EAWiFiUnconfiguredAccessoryConfigurationStatus(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(EAWiFiUnconfiguredAccessoryConfigurationStatus(rawValue: 99) == nil)
    precondition(
        EAWiFiUnconfiguredAccessoryConfigurationStatus.success != .failed
    )
}

func testEAWiFiUnconfiguredAccessoryPropertiesMembers() {
    let members: [(EAWiFiUnconfiguredAccessoryProperties, UInt)] = [
        (.propertySupportsAirPlay, 1 << 0),
        (.propertySupportsAirPrint, 1 << 1),
        (.propertySupportsHomeKit, 1 << 2),
    ]
    for (member, raw) in members {
        precondition(member.rawValue == raw)
        precondition(EAWiFiUnconfiguredAccessoryProperties(rawValue: raw) == member)
    }
    precondition(
        EAWiFiUnconfiguredAccessoryProperties.propertySupportsAirPlay
            != .propertySupportsAirPrint
    )
}

func testEAWiFiUnconfiguredAccessoryPropertiesAlgebra() {
    var properties: EAWiFiUnconfiguredAccessoryProperties = [
        .propertySupportsAirPlay, .propertySupportsHomeKit
    ]
    precondition(properties.contains(.propertySupportsAirPlay))
    properties.insert(.propertySupportsAirPrint)
    _ = properties.remove(.propertySupportsHomeKit)
    _ = properties.update(with: .propertySupportsHomeKit)
    let unioned = EAWiFiUnconfiguredAccessoryProperties.propertySupportsAirPlay
        .union(.propertySupportsAirPrint)
    precondition(unioned.intersection(.propertySupportsAirPlay) == .propertySupportsAirPlay)
    precondition(unioned.subtracting(.propertySupportsAirPrint) == .propertySupportsAirPlay)
    precondition(unioned.isSuperset(of: .propertySupportsAirPlay))
    precondition(
        EAWiFiUnconfiguredAccessoryProperties.propertySupportsAirPlay.isSubset(of: unioned)
    )
    precondition(
        EAWiFiUnconfiguredAccessoryProperties.propertySupportsAirPlay
            .isDisjoint(with: .propertySupportsAirPrint)
    )
    precondition(
        unioned.symmetricDifference(.propertySupportsAirPlay) == .propertySupportsAirPrint
    )
    var mutable = EAWiFiUnconfiguredAccessoryProperties.propertySupportsAirPlay
    mutable.formUnion(.propertySupportsAirPrint)
    mutable.formIntersection(.propertySupportsAirPrint)
    mutable.formSymmetricDifference(.propertySupportsHomeKit)
    mutable.subtract(.propertySupportsHomeKit)
    _ = EAWiFiUnconfiguredAccessoryProperties([
        .propertySupportsAirPlay, .propertySupportsAirPrint
    ])
    _ = EAWiFiUnconfiguredAccessoryProperties()
    _ = EAWiFiUnconfiguredAccessoryProperties(
        arrayLiteral: .propertySupportsAirPlay, .propertySupportsHomeKit
    )
    precondition(
        EAWiFiUnconfiguredAccessoryProperties.propertySupportsAirPlay
            .isStrictSubset(of: [.propertySupportsAirPlay, .propertySupportsAirPrint])
    )
    precondition(
        EAWiFiUnconfiguredAccessoryProperties([
            .propertySupportsAirPlay, .propertySupportsAirPrint
        ]).isStrictSuperset(of: .propertySupportsAirPlay)
    )
    precondition(EAWiFiUnconfiguredAccessoryProperties().isEmpty)
    precondition(!EAWiFiUnconfiguredAccessoryProperties.propertySupportsAirPlay.isEmpty)
}
