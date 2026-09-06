import Foundation

open class MTRClusterPath: NSObject {
    public let endpoint: NSNumber
    public let cluster: NSNumber

    public init(endpointID: NSNumber, clusterID: NSNumber) {
        self.endpoint = endpointID
        self.cluster = clusterID
        super.init()
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? MTRClusterPath else { return false }
        return endpoint.isEqual(to: other.endpoint) && cluster.isEqual(to: other.cluster)
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(endpoint.uint64Value)
        hasher.combine(cluster.uint64Value)
        return hasher.finalize()
    }
}

open class MTRAttributePath: MTRClusterPath {
    public let attribute: NSNumber

    public init(endpointID: NSNumber, clusterID: NSNumber, attributeID: NSNumber) {
        self.attribute = attributeID
        super.init(endpointID: endpointID, clusterID: clusterID)
    }

    public convenience init(endpointId: NSNumber, clusterId: NSNumber, attributeId: NSNumber) {
        self.init(endpointID: endpointId, clusterID: clusterId, attributeID: attributeId)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? MTRAttributePath else { return false }
        return super.isEqual(other) && attribute.isEqual(to: other.attribute)
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(super.hash)
        hasher.combine(attribute.uint64Value)
        return hasher.finalize()
    }
}

open class MTREventPath: MTRClusterPath {
    public let event: NSNumber

    public init(endpointID: NSNumber, clusterID: NSNumber, eventID: NSNumber) {
        self.event = eventID
        super.init(endpointID: endpointID, clusterID: clusterID)
    }

    public convenience init(endpointId: NSNumber, clusterId: NSNumber, eventId: NSNumber) {
        self.init(endpointID: endpointId, clusterID: clusterId, eventID: eventId)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? MTREventPath else { return false }
        return super.isEqual(other) && event.isEqual(to: other.event)
    }
}

open class MTRCommandPath: MTRClusterPath {
    public let command: NSNumber

    public init(endpointID: NSNumber, clusterID: NSNumber, commandID: NSNumber) {
        self.command = commandID
        super.init(endpointID: endpointID, clusterID: clusterID)
    }

    public convenience init(endpointId: NSNumber, clusterId: NSNumber, commandId: NSNumber) {
        self.init(endpointID: endpointId, clusterID: clusterId, commandID: commandId)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? MTRCommandPath else { return false }
        return super.isEqual(other) && command.isEqual(to: other.command)
    }
}

open class MTRAttributeRequestPath: NSObject {
    public let endpoint: NSNumber?
    public let cluster: NSNumber?
    public let attribute: NSNumber?

    public init(endpointID: NSNumber?, clusterID: NSNumber?, attributeID: NSNumber?) {
        self.endpoint = endpointID
        self.cluster = clusterID
        self.attribute = attributeID
        super.init()
    }
}

open class MTREventRequestPath: NSObject {
    public let endpoint: NSNumber?
    public let cluster: NSNumber?
    public let event: NSNumber?

    public init(endpointID: NSNumber?, clusterID: NSNumber?, eventID: NSNumber?) {
        self.endpoint = endpointID
        self.cluster = clusterID
        self.event = eventID
        super.init()
    }
}

open class MTRAttributeReport: NSObject {
    public let path: MTRAttributePath
    public let value: Any?
    public let error: (any Error)?

    public init(path: MTRAttributePath, value: Any?, error: (any Error)?) {
        self.path = path
        self.value = value
        self.error = error
        super.init()
    }

    public convenience init(responseValue: [String: Any]) throws {
        guard let path = responseValue[MTRAttributePathKey] as? MTRAttributePath else {
            throw MTRMakeError(.schemaMismatch, reason: "missing attribute path")
        }
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            self.init(path: path, value: nil, error: err)
            return
        }
        let data = responseValue[MTRDataKey] as? [String: Any]
        self.init(path: path, value: data?[MTRValueKey], error: nil)
    }
}

open class MTREventReport: NSObject {
    public let path: MTREventPath
    public let eventNumber: NSNumber
    public let priority: MTREventPriority
    public let eventTimeType: MTREventTimeType
    public let systemUpTime: TimeInterval
    public let timestampDate: Date?
    public let value: Any?
    public let error: (any Error)?

    public init(
        path: MTREventPath,
        eventNumber: NSNumber,
        priority: MTREventPriority,
        eventTimeType: MTREventTimeType,
        systemUpTime: TimeInterval,
        timestampDate: Date?,
        value: Any?,
        error: (any Error)?
    ) {
        self.path = path
        self.eventNumber = eventNumber
        self.priority = priority
        self.eventTimeType = eventTimeType
        self.systemUpTime = systemUpTime
        self.timestampDate = timestampDate
        self.value = value
        self.error = error
        super.init()
    }

    public convenience init(responseValue: [String: Any]) throws {
        guard let path = responseValue[MTREventPathKey] as? MTREventPath else {
            throw MTRMakeError(.schemaMismatch, reason: "missing event path")
        }
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            self.init(
                path: path, eventNumber: 0, priority: .debug, eventTimeType: .systemUpTime,
                systemUpTime: 0, timestampDate: nil, value: nil, error: err
            )
            return
        }
        let data = responseValue[MTRDataKey] as? [String: Any]
        let number = responseValue[MTREventNumberKey] as? NSNumber ?? 0
        let upTime = responseValue[MTREventSystemUpTimeKey] as? TimeInterval ?? 0
        let date = responseValue[MTREventTimestampDateKey] as? Date
        let timeType: MTREventTimeType = date != nil ? .timestampDate : .systemUpTime
        self.init(
            path: path,
            eventNumber: number,
            priority: .info,
            eventTimeType: timeType,
            systemUpTime: upTime,
            timestampDate: date,
            value: data?[MTRValueKey],
            error: nil
        )
    }
}

open class MTRReadParams: NSObject {
    public var shouldAssumeUnknownAttributesReportable: Bool = true
    public var fabricFiltered: NSNumber?
    public var shouldFilterByFabric: Bool = true
    public var minEventNumber: NSNumber?

    public override init() {
        super.init()
    }
}

open class MTRSubscribeParams: MTRReadParams {
    public var autoResubscribe: NSNumber?
    public var keepPreviousSubscriptions: NSNumber?
    public var maxInterval: NSNumber
    public var minInterval: NSNumber
    public var shouldReplaceExistingSubscriptions: Bool = true
    public var shouldReportEventsUrgently: Bool = false
    public var shouldResubscribeAutomatically: Bool = true

    public init(minInterval: NSNumber, maxInterval: NSNumber) {
        self.minInterval = minInterval
        self.maxInterval = maxInterval
        super.init()
        shouldResubscribeAutomatically = true
        shouldReplaceExistingSubscriptions = true
    }

    public class func `new`() -> MTRSubscribeParams {
        MTRSubscribeParams(minInterval: NSNumber(value: 0), maxInterval: NSNumber(value: 1))
    }
}

open class MTRWriteParams: NSObject {
    public var dataVersion: NSNumber?
    public var timedWriteTimeout: NSNumber?
}

open class MTRDeviceType: NSObject {
    public let id: NSNumber
    public let name: String
    public let isUtility: Bool

    public init?(forID deviceTypeID: NSNumber) {
        guard let known = MTRKnownDeviceType.lookup(deviceTypeID.uint32Value) else { return nil }
        self.id = deviceTypeID
        self.name = known.name
        self.isUtility = known.isUtility
        super.init()
    }
}

open class MTRDeviceTypeRevision: NSObject {
    public let deviceTypeID: NSNumber
    public let revision: NSNumber

    public init?(deviceTypeID: NSNumber, revision: NSNumber) {
        guard revision.intValue > 0 else { return nil }
        self.deviceTypeID = deviceTypeID
        self.revision = revision
        super.init()
    }

    public var deviceType: MTRDeviceType? {
        MTRDeviceType(forID: deviceTypeID)
    }
}

open class MTRProductIdentity: NSObject {
    public let vendorID: NSNumber
    public let productID: NSNumber

    public init(vendorID: NSNumber, productID: NSNumber) {
        self.vendorID = vendorID
        self.productID = productID
        super.init()
    }
}

open class MTRThreadOperationalDataset: NSObject {
    public private(set) var networkName: String
    public private(set) var extendedPANID: Data
    public private(set) var masterKey: Data
    public var psKc: Data
    public var channel: UInt16
    public private(set) var panID: Data

    public var channelNumber: NSNumber { NSNumber(value: channel) }

    public init?(
        networkName: String,
        extendedPANID: Data,
        masterKey: Data,
        psKc PSKc: Data,
        channel: UInt16,
        panID: Data
    ) {
        guard networkName.utf8.count <= MTRSizeThreadNetworkName,
              extendedPANID.count == MTRSizeThreadExtendedPANID,
              masterKey.count == MTRSizeThreadMasterKey,
              PSKc.count == MTRSizeThreadPSKc,
              panID.count == MTRSizeThreadPANID
        else { return nil }
        self.networkName = networkName
        self.extendedPANID = extendedPANID
        self.masterKey = masterKey
        self.psKc = PSKc
        self.channel = channel
        self.panID = panID
        super.init()
    }

    public convenience init?(
        networkName: String,
        extendedPANID: Data,
        masterKey: Data,
        psKc PSKc: Data,
        channelNumber: NSNumber,
        panID: Data
    ) {
        self.init(
            networkName: networkName,
            extendedPANID: extendedPANID,
            masterKey: masterKey,
            psKc: PSKc,
            channel: channelNumber.uint16Value,
            panID: panID
        )
    }

    public convenience init?(
        networkName: String,
        extendedPANID: Data,
        masterKey: Data,
        PSKc: Data,
        channelNumber: NSNumber,
        panID: Data
    ) {
        self.init(
            networkName: networkName,
            extendedPANID: extendedPANID,
            masterKey: masterKey,
            psKc: PSKc,
            channelNumber: channelNumber,
            panID: panID
        )
    }

    public init?(data: Data) {
        guard let parsed = MTRThreadTLV.parse(data) else { return nil }
        self.networkName = parsed.networkName
        self.extendedPANID = parsed.extendedPANID
        self.masterKey = parsed.masterKey
        self.psKc = parsed.psKc
        self.channel = parsed.channel
        self.panID = parsed.panID
        super.init()
    }

    public func data() -> Data {
        MTRThreadTLV.serialize(self)
    }
}

enum MTRThreadTLV {
    static let channelType: UInt8 = 0
    static let panIDType: UInt8 = 1
    static let extPan: UInt8 = 2
    static let networkNameType: UInt8 = 3
    static let pskcType: UInt8 = 4
    static let masterKeyType: UInt8 = 5

    static func serialize(_ dataset: MTRThreadOperationalDataset) -> Data {
        var out = Data()
        func put(_ type: UInt8, _ payload: Data) {
            out.append(type)
            out.append(UInt8(payload.count))
            out.append(payload)
        }
        let channelBytes = Data([0x00, UInt8((dataset.channel >> 8) & 0xFF), UInt8(dataset.channel & 0xFF)])
        put(channelType, channelBytes)
        put(panIDType, dataset.panID)
        put(extPan, dataset.extendedPANID)
        put(networkNameType, Data(dataset.networkName.utf8))
        put(pskcType, dataset.psKc)
        put(masterKeyType, dataset.masterKey)
        return out
    }

    static func parse(_ data: Data) -> MTRThreadOperationalDataset? {
        var i = 0
        let bytes = [UInt8](data)
        var networkName: String?
        var ext: Data?
        var master: Data?
        var pskc: Data?
        var channel: UInt16?
        var pan: Data?
        while i + 2 <= bytes.count {
            let type = bytes[i]
            let len = Int(bytes[i + 1])
            i += 2
            guard i + len <= bytes.count else { return nil }
            let payload = Data(bytes[i..<(i + len)])
            i += len
            switch type {
            case channelType:
                if payload.count == 3 {
                    channel = (UInt16(payload[1]) << 8) | UInt16(payload[2])
                } else if payload.count == 2 {
                    channel = (UInt16(payload[0]) << 8) | UInt16(payload[1])
                }
            case panIDType: pan = payload
            case extPan: ext = payload
            case networkNameType: networkName = String(data: payload, encoding: .utf8)
            case pskcType: pskc = payload
            case masterKeyType: master = payload
            default: break
            }
        }
        guard let networkName, let ext, let master, let pskc, let channel, let pan else { return nil }
        return MTRThreadOperationalDataset(
            networkName: networkName,
            extendedPANID: ext,
            masterKey: master,
            psKc: pskc,
            channel: channel,
            panID: pan
        )
    }
}

struct MTRKnownDeviceType {
    let name: String
    let isUtility: Bool

    static func lookup(_ id: UInt32) -> MTRKnownDeviceType? {
        switch id {
        case 0x0016: return MTRKnownDeviceType(name: "Root Node", isUtility: true)
        case 0x0011: return MTRKnownDeviceType(name: "Power Source", isUtility: true)
        case 0x0012: return MTRKnownDeviceType(name: "OTA Requestor", isUtility: true)
        case 0x0014: return MTRKnownDeviceType(name: "OTA Provider", isUtility: true)
        case 0x000E: return MTRKnownDeviceType(name: "Aggregator", isUtility: true)
        case 0x0013: return MTRKnownDeviceType(name: "Bridged Node", isUtility: true)
        case 0x0100: return MTRKnownDeviceType(name: "On/Off Light", isUtility: false)
        case 0x0101: return MTRKnownDeviceType(name: "Dimmable Light", isUtility: false)
        case 0x010C: return MTRKnownDeviceType(name: "On/Off Plug-in Unit", isUtility: false)
        case 0x010A: return MTRKnownDeviceType(name: "On/Off Light Switch", isUtility: false)
        case 0x0103: return MTRKnownDeviceType(name: "On/Off Sensor", isUtility: false)
        case 0x0301: return MTRKnownDeviceType(name: "Thermostat", isUtility: false)
        case 0x000A: return MTRKnownDeviceType(name: "Door Lock", isUtility: false)
        default: return nil
        }
    }
}

open class MTRCommissioningParameters: NSObject {
    public var csrNonce: Data?
    public var attestationNonce: Data?
    public var wifiSSID: Data?
    public var wifiCredentials: Data?
    public var threadOperationalDataset: Data?
    public var countryCode: String?
    public var skipCommissioningComplete: Bool = false
    public var extraReadTimeout: NSNumber?
}

open class MTRAccessGrant: NSObject {
    public let subjectID: NSNumber?
    public let grantedPrivilege: MTRAccessControlEntryPrivilege
    public let authenticationMode: MTRAccessControlEntryAuthMode

    public init(
        subjectID: NSNumber?,
        grantedPrivilege: MTRAccessControlEntryPrivilege,
        authenticationMode: MTRAccessControlEntryAuthMode
    ) {
        self.subjectID = subjectID
        self.grantedPrivilege = grantedPrivilege
        self.authenticationMode = authenticationMode
        super.init()
    }
}

open class MTRFabricInfo: NSObject {
    public var fabricIndex: NSNumber = 0
    public var fabricID: NSNumber = 0
    public var nodeID: NSNumber = 0
    public var vendorID: NSNumber = 0
    public var rootPublicKey: Data = Data()
    public var vendorName: String?
    public var fabricLabel: String?
}

open class MTREndpointInfo: NSObject {
    public var endpointID: NSNumber = 0
    public var deviceTypes: [MTRDeviceTypeRevision] = []
    public var partsList: [NSNumber] = []
}

open class CSRInfo: NSObject {
    public var nonce: Data
    public var elements: Data
    public var elementsSignature: Data
    public var csr: Data

    public init(nonce: Data, elements: Data, elementsSignature: Data, csr: Data) {
        self.nonce = nonce
        self.elements = elements
        self.elementsSignature = elementsSignature
        self.csr = csr
        super.init()
    }
}

open class AttestationInfo: NSObject {
    public var challenge: Data
    public var nonce: Data
    public var elements: Data
    public var elementsSignature: Data
    public var dac: Data
    public var pai: Data
    public var certificationDeclaration: Data
    public var firmwareInfo: Data?

    public init(
        challenge: Data,
        nonce: Data,
        elements: Data,
        elementsSignature: Data,
        dac: Data,
        pai: Data,
        certificationDeclaration: Data,
        firmwareInfo: Data?
    ) {
        self.challenge = challenge
        self.nonce = nonce
        self.elements = elements
        self.elementsSignature = elementsSignature
        self.dac = dac
        self.pai = pai
        self.certificationDeclaration = certificationDeclaration
        self.firmwareInfo = firmwareInfo
        super.init()
    }
}

open class MTRDeviceAttestationDeviceInfo: NSObject {
    public var vendorID: NSNumber?
    public var productID: NSNumber?
    public var dacVendorID: NSNumber?
    public var dacProductID: NSNumber?
}

open class MTRDeviceAttestationInfo: NSObject {
    public var challenge: Data = Data()
    public var nonce: Data = Data()
    public var elements: Data = Data()
    public var elementsSignature: Data = Data()
    public var dac: Data = Data()
    public var pai: Data = Data()
    public var certificationDeclaration: Data = Data()
    public var firmwareInfo: Data?
}

open class MTROperationalCSRInfo: NSObject {
    public var csr: Data = Data()
    public var csrNonce: Data = Data()
}

open class MTROperationalCertificateChain: NSObject {
    public var operationalCertificate: Data = Data()
    public var intermediateCertificate: Data?
    public var rootCertificate: Data = Data()
    public var adminVendorID: NSNumber?
}

open class MTRCommandWithRequiredResponse: NSObject {
    public var path: MTRCommandPath?
    public var commandFields: [String: Any]?
    public var requiredResponse: [NSNumber: [String: Any]]?
}

open class MTRCertificateInfo: NSObject {
    public var issuer: MTRDistinguishedNameInfo?
    public var subject: MTRDistinguishedNameInfo?
    public var notBefore: Date?
    public var notAfter: Date?
}

open class MTRDistinguishedNameInfo: NSObject {
    public var nodeID: NSNumber?
    public var fabricID: NSNumber?
    public var fabricCAID: NSNumber?
    public var matterRCACID: NSNumber?
}

open class MTRMetricData: NSObject {
    public var value: NSNumber?
}

open class MTRMetrics: NSObject {
    public var uniqueIdentifier: UUID = UUID()
    public var allKeys: [String] { [] }
    public func metricData(forKey key: String) -> MTRMetricData? { nil }
}

open class MTRAttributeValueWaiter: NSObject {
    public func cancel() {}
}

open class MTRDeviceStorageBehaviorConfiguration: NSObject {
    public var disableStorageBehaviorOptimization: Bool = false
}

open class MTROTAHeader: NSObject {
    public var vendorID: NSNumber?
    public var productID: NSNumber?
    public var payloadSize: NSNumber?
}

open class MTROTAHeaderParser: NSObject {
    public class func header(fromData data: Data) throws -> MTROTAHeader {
        _ = data
        throw MTRFailClosed(.unknownSchema)
    }
}

open class MTRCommissionableBrowserResult: NSObject {
    public var instanceName: String?
    public var vendorID: NSNumber?
    public var productID: NSNumber?
    public var discriminator: NSNumber?
    public var commissioningMode: Bool = false
}

open class MTRCommissioneeInfo: NSObject {
    public var productIdentity: MTRProductIdentity?
    public var endpointsById: [NSNumber: MTREndpointInfo]?
}

