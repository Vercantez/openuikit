import Foundation

public struct NFCFeliCaStatusFlag: Equatable, Sendable {
    public var statusFlag1: Int
    public var statusFlag2: Int

    public init(statusFlag1: Int, statusFlag2: Int) {
        self.statusFlag1 = statusFlag1
        self.statusFlag2 = statusFlag2
    }
}

public struct NFCISO15693SystemInfo: Equatable, Sendable {
    public var uniqueIdentifier: Data
    public var dataStorageFormatIdentifier: Int
    public var applicationFamilyIdentifier: Int
    public var blockSize: Int
    public var totalBlocks: Int
    public var icReference: Int

    public init(
        uniqueIdentifier: Data,
        dataStorageFormatIdentifier: Int,
        applicationFamilyIdentifier: Int,
        blockSize: Int,
        totalBlocks: Int,
        icReference: Int
    ) {
        self.uniqueIdentifier = uniqueIdentifier
        self.dataStorageFormatIdentifier = dataStorageFormatIdentifier
        self.applicationFamilyIdentifier = applicationFamilyIdentifier
        self.blockSize = blockSize
        self.totalBlocks = totalBlocks
        self.icReference = icReference
    }
}

public struct NFCFeliCaPollingResponse: Equatable, Sendable {
    public var manufactureParameter: Data
    public var requestData: Data?

    public init(manufactureParameter: Data, requestData: Data?) {
        self.manufactureParameter = manufactureParameter
        self.requestData = requestData
    }
}

public struct NFCFeliCaRequsetServiceV2Response: Equatable, Sendable {
    public var statusFlag1: Int
    public var statusFlag2: Int
    public var encryptionIdentifier: NFCFeliCaEncryptionId
    public var nodeKeyVersionListAES: [Data]?
    public var nodeKeyVersionListDES: [Data]?

    public init(
        statusFlag1: Int,
        statusFlag2: Int,
        encryptionIdentifier: NFCFeliCaEncryptionId,
        nodeKeyVersionListAES: [Data]?,
        nodeKeyVersionListDES: [Data]?
    ) {
        self.statusFlag1 = statusFlag1
        self.statusFlag2 = statusFlag2
        self.encryptionIdentifier = encryptionIdentifier
        self.nodeKeyVersionListAES = nodeKeyVersionListAES
        self.nodeKeyVersionListDES = nodeKeyVersionListDES
    }
}

public struct NFCISO15693MultipleBlockSecurityStatus: Equatable, Sendable {
    public var blockSecurityStatus: [Int]

    public init(blockSecurityStatus: [Int]) {
        self.blockSecurityStatus = blockSecurityStatus
    }
}

public struct NFCFeliCaRequestSpecificationVersionResponse: Equatable, Sendable {
    public var statusFlag1: Int
    public var statusFlag2: Int
    public var basicVersion: Data?
    public var optionVersion: Data?

    public init(
        statusFlag1: Int,
        statusFlag2: Int,
        basicVersion: Data?,
        optionVersion: Data?
    ) {
        self.statusFlag1 = statusFlag1
        self.statusFlag2 = statusFlag2
        self.basicVersion = basicVersion
        self.optionVersion = optionVersion
    }
}
