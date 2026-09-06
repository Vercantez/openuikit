import Foundation

open class MTRCluster: NSObject {
    public var device: MTRBaseDevice?
    public var endpoint: NSNumber = 0
}

open class MTRGenericBaseCluster: MTRCluster {}
open class MTRGenericCluster: MTRCluster {}

open class MTRBaseDevice: NSObject {
    public var sessionTransportType: MTRTransportType { .undefined }

    public func openCommissioningWindow(
        withSetupPasscode setupPasscode: NSNumber,
        discriminator: NSNumber,
        duration: NSNumber
    ) throws -> MTRSetupPayload {
        _ = (setupPasscode, discriminator, duration)
        throw MTRFailClosed()
    }

    public func readAttribute(
        withEndpointID endpoint: NSNumber,
        clusterID: NSNumber,
        attributeID: NSNumber,
        params: MTRReadParams?
    ) throws -> [Any] {
        _ = (endpoint, clusterID, attributeID, params)
        throw MTRFailClosed(.invalidState)
    }

    public func invokeCommand(
        withEndpointID endpoint: NSNumber,
        clusterID: NSNumber,
        commandID: NSNumber,
        commandFields: [String: Any]?,
        timedInvokeTimeout: NSNumber?
    ) throws -> [Any] {
        _ = (endpoint, clusterID, commandID, commandFields, timedInvokeTimeout)
        throw MTRFailClosed(.invalidState)
    }
}

open class MTRDevice: MTRBaseDevice {
    public var nodeID: NSNumber = 0
    public var state: MTRDeviceState { .unknown }
    public var estimatedStartTime: Date?
    public var estimatedSubscriptionLatency: NSNumber?
    public var deviceController: MTRDeviceController?

    public class func device(withNodeID nodeID: NSNumber, controller: MTRDeviceController) -> MTRDevice {
        let device = MTRDevice()
        device.nodeID = nodeID
        device.deviceController = controller
        return device
    }
}

open class MTRDeviceController: NSObject {
    public var running: Bool { false }
    public var uniqueIdentifier: UUID = UUID()
    public var controllerNodeID: NSNumber?
    public var compressedFabricID: NSNumber?

    public func setupCommissioningSession(with payload: MTRSetupPayload, newNodeID: NSNumber) throws {
        _ = (payload, newNodeID)
        throw MTRFailClosed(.invalidState)
    }

    public func setupCommissioningSession(
        withDiscoveredDevice discoveredDevice: MTRCommissionableBrowserResult,
        payload: MTRSetupPayload,
        newNodeID: NSNumber
    ) throws {
        _ = (discoveredDevice, payload, newNodeID)
        throw MTRFailClosed(.invalidState)
    }

    public func commissionNode(withID nodeID: NSNumber, commissioningParams: MTRCommissioningParameters) throws {
        _ = (nodeID, commissioningParams)
        throw MTRFailClosed()
    }

    public func cancelCommissioning(forNodeID nodeID: NSNumber) throws {
        _ = nodeID
        throw MTRFailClosed(.cancelled)
    }

    public func shutdown() {}

    public func devices() -> [MTRDevice] { [] }

    public func getDeviceBeingCommissioned(_ deviceId: NSNumber) throws -> MTRBaseDevice {
        _ = deviceId
        throw MTRFailClosed(.notFound)
    }
}

open class MTRDeviceControllerAbstractParameters: NSObject {}

open class MTRDeviceControllerParameters: MTRDeviceControllerAbstractParameters {
    public var uniqueIdentifier: UUID = UUID()
}

open class MTRDeviceControllerExternalCertificateParameters: MTRDeviceControllerParameters {}

open class MTRXPCDeviceControllerParameters: MTRDeviceControllerAbstractParameters {}

open class MTRDeviceControllerFactoryParams: NSObject {
    public var storage: (any MTRStorage)?
    public var otaProviderDelegate: (any MTROTAProviderDelegate)?
    public var productAttestationAuthorityCertificates: [Data]?
    public var certificationDeclarationCertificates: [Data]?
    public var port: NSNumber?
    public var shouldStartServer: Bool = false
}

open class MTRControllerFactoryParams: MTRDeviceControllerFactoryParams {}

open class MTRDeviceControllerFactory: NSObject {
    public var running: Bool { false }

    public class func sharedInstance() -> MTRDeviceControllerFactory {
        MTRDeviceControllerFactory.shared
    }

    public static let shared = MTRDeviceControllerFactory()

    public func start(_ startupParams: MTRDeviceControllerFactoryParams) throws {
        _ = startupParams
        throw MTRFailClosed()
    }

    public func stop() {}

    public func createController(onExistingFabric startupParams: MTRDeviceControllerParameters) throws -> MTRDeviceController {
        _ = startupParams
        throw MTRFailClosed()
    }

    public func createController(onNewFabric startupParams: MTRDeviceControllerParameters) throws -> MTRDeviceController {
        _ = startupParams
        throw MTRFailClosed()
    }
}

open class MTRControllerFactory: MTRDeviceControllerFactory {
    public static let sharedFactory = MTRControllerFactory()
}

open class MTRCertificates: NSObject {
    public class func isCertificate(_ certificate1: Data, equalTo certificate2: Data) -> Bool {
        certificate1 == certificate2
    }

    public class func keypair(_ keypair: any MTRKeypair, matchesCertificate certificate: Data) -> Bool {
        _ = (keypair, certificate)
        return false
    }

    public class func convertMatterCertificate(_ matterCertificate: Data) -> Data? {
        _ = matterCertificate
        return nil
    }

    public class func convertX509Certificate(_ x509Certificate: Data) -> Data? {
        _ = x509Certificate
        return nil
    }

    public class func createCertificateSigningRequest(_ keypair: any MTRKeypair) throws -> Data {
        _ = keypair
        throw MTRFailClosed(.invalidState)
    }

    public class func generateCertificateSigningRequest(_ keypair: any MTRKeypair) throws -> Data {
        try createCertificateSigningRequest(keypair)
    }

    public class func createRootCertificate(
        _ keypair: any MTRKeypair,
        issuerID: NSNumber?,
        fabricID: NSNumber?
    ) throws -> Data {
        _ = (keypair, issuerID, fabricID)
        throw MTRFailClosed(.invalidState)
    }

    public class func generateRootCertificate(
        _ keypair: any MTRKeypair,
        issuerId: NSNumber?,
        fabricId: NSNumber?
    ) throws -> Data {
        try createRootCertificate(keypair, issuerID: issuerId, fabricID: fabricId)
    }

    public class func publicKey(fromCSR csr: Data) throws -> Data {
        _ = csr
        throw MTRFailClosed(.tlvDecodeFailed)
    }
}

open class MTRAttributeCacheContainer: NSObject {}
open class MTRClusterStateCacheContainer: NSObject {}

open class MTRAsyncCallbackQueueWorkItem: NSObject {
    public var readyHandler: MTRAsyncCallbackReadyHandler?
    public var cancelHandler: (() -> Void)?
    public var enqueued = false
    public var ended = false
    public var retryCount = 0

    public func endWork() { ended = true }
    public func retryWork() { retryCount += 1 }
}

open class MTRAsyncCallbackWorkQueue: NSObject {
    private var items: [MTRAsyncCallbackQueueWorkItem] = []

    public func enqueue(_ item: MTRAsyncCallbackQueueWorkItem) {
        item.enqueued = true
        items.append(item)
        item.readyHandler?(item, item.retryCount)
    }

    public func invalidate() {
        items.removeAll()
    }
}

open class MTRServerAttribute: NSObject {
    public var attributeID: NSNumber = 0
    public var value: Any?
}

open class MTRServerCluster: NSObject {
    public var clusterID: NSNumber = 0
    public var attributes: [MTRServerAttribute] = []
}

open class MTRServerEndpoint: NSObject {
    public var endpointID: NSNumber = 0
    public var clusters: [MTRServerCluster] = []
    public var deviceTypes: [MTRDeviceTypeRevision] = []
}
