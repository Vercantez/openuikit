@_spi(OpenUIKitHost) import NearbyInteraction
import Foundation

func testNINearbyPeerConfiguration() {
    let token = NIDiscoveryToken.hostToken()
    let config = NINearbyPeerConfiguration(peerToken: token)
    precondition(config.peerDiscoveryToken.isEqual(token))
    precondition(config.isCameraAssistanceEnabled == false)
    precondition(config.isExtendedDistanceMeasurementEnabled == false)

    config.isCameraAssistanceEnabled = true
    config.isExtendedDistanceMeasurementEnabled = true
    precondition(config.isCameraAssistanceEnabled)
    precondition(config.isExtendedDistanceMeasurementEnabled)

    let copy = config.copy() as! NINearbyPeerConfiguration
    precondition(copy !== config)
    precondition(copy.peerDiscoveryToken.isEqual(token))
    precondition(copy.isCameraAssistanceEnabled)
    precondition(copy.isExtendedDistanceMeasurementEnabled)
}

func testNIDLTDOAConfiguration() {
    let config = NIDLTDOAConfiguration(networkIdentifier: 42)
    precondition(config.networkIdentifier == 42)
    config.networkIdentifier = 99
    precondition(config.networkIdentifier == 99)

    let copy = config.copy() as! NIDLTDOAConfiguration
    precondition(copy !== config)
    precondition(copy.networkIdentifier == 99)
}

func testNINearbyAccessoryConfigurationRejectsData() {
    do {
        _ = try NINearbyAccessoryConfiguration(data: Data([0x00]))
        preconditionFailure("init(data:) must fail closed")
    } catch let error as NIError {
        precondition(error.code == .invalidConfiguration)
    } catch {
        preconditionFailure("expected NIError, got \(error)")
    }

    do {
        _ = try NINearbyAccessoryConfiguration(
            accessoryData: Data([0x01]),
            bluetoothPeerIdentifier: UUID()
        )
        preconditionFailure("init(accessoryData:bluetoothPeerIdentifier:) must fail closed")
    } catch let error as NIError {
        precondition(error.code == .invalidConfiguration)
    } catch {
        preconditionFailure("expected NIError, got \(error)")
    }
}

func testNINearbyAccessoryConfigurationHostCopy() {
    let token = NIDiscoveryToken.hostToken()
    let bluetooth = UUID()
    let config = NINearbyAccessoryConfiguration.hostConfiguration(
        token: token,
        bluetoothPeerIdentifier: bluetooth
    )
    precondition(config.accessoryDiscoveryToken.isEqual(token))
    precondition(config.isCameraAssistanceEnabled == false)
    config.isCameraAssistanceEnabled = true
    precondition(config.isCameraAssistanceEnabled)

    let copy = config.copy() as! NINearbyAccessoryConfiguration
    precondition(copy !== config)
    precondition(copy.accessoryDiscoveryToken.isEqual(token))
    precondition(copy.isCameraAssistanceEnabled)
}

func testNIDiscoveryTokenCapabilities() {
    let token = NIDiscoveryToken.hostToken()
    let capabilities = token.deviceCapabilities
    precondition(capabilities.supportsPreciseDistanceMeasurement == false)
    precondition(capabilities.supportsDirectionMeasurement == false)
    precondition(capabilities.supportsCameraAssistance == false)
    precondition(capabilities.supportsExtendedDistanceMeasurement == false)
    precondition(capabilities.supportsDLTDOAMeasurement == false)

    let copy = token.copy() as! NIDiscoveryToken
    precondition(copy.isEqual(token))
    precondition(copy !== token)
}

func testNIConfigurationBaseCopy() {
    let base = NIConfiguration()
    let copy = base.copy() as! NIConfiguration
    precondition(copy !== base)
    precondition(NIConfiguration.supportsSecureCoding)
}
