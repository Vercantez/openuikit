import Foundation

public enum NFCFeliCaEncryptionId: Int, Hashable, Sendable {
    case AES = 0x4F
    case AES_DES = 0x41

    public static var aes: NFCFeliCaEncryptionId { .AES }
    public static var aes_des: NFCFeliCaEncryptionId { .AES_DES }
}

public enum NFCFeliCaPollingRequestCode: Int, Hashable, Sendable {
    case noRequest = 0
    case systemCode = 1
    case communicationPerformance = 2

    public static var PollingRequestCodeNoRequest: NFCFeliCaPollingRequestCode { .noRequest }
    public static var PollingRequestCodeSystemCode: NFCFeliCaPollingRequestCode { .systemCode }
    public static var PollingRequestCodeCommunicationPerformance: NFCFeliCaPollingRequestCode {
        .communicationPerformance
    }
}

public enum NFCFeliCaPollingTimeSlot: Int, Hashable, Sendable {
    case max1 = 0x00
    case max2 = 0x01
    case max4 = 0x03
    case max8 = 0x07
    case max16 = 0x0F

    public static var PollingTimeSlotMax1: NFCFeliCaPollingTimeSlot { .max1 }
    public static var PollingTimeSlotMax2: NFCFeliCaPollingTimeSlot { .max2 }
    public static var PollingTimeSlotMax4: NFCFeliCaPollingTimeSlot { .max4 }
    public static var PollingTimeSlotMax8: NFCFeliCaPollingTimeSlot { .max8 }
    public static var PollingTimeSlotMax16: NFCFeliCaPollingTimeSlot { .max16 }
}

public enum NFCMiFareFamily: UInt, Hashable, Sendable {
    case unknown = 1
    case ultralight = 2
    case plus = 3
    case desfire = 4
}

public struct NFCISO15693RequestFlag: OptionSet, Hashable, Sendable {
    public let rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public static let dualSubCarriers = NFCISO15693RequestFlag(rawValue: 1 << 0)
    public static let highDataRate = NFCISO15693RequestFlag(rawValue: 1 << 1)
    public static let protocolExtension = NFCISO15693RequestFlag(rawValue: 1 << 3)
    public static let select = NFCISO15693RequestFlag(rawValue: 1 << 4)
    public static let address = NFCISO15693RequestFlag(rawValue: 1 << 5)
    public static let option = NFCISO15693RequestFlag(rawValue: 1 << 6)
    public static let commandSpecificBit8 = NFCISO15693RequestFlag(rawValue: 1 << 7)

    public static var RequestFlagDualSubCarriers: NFCISO15693RequestFlag { .dualSubCarriers }
    public static var RequestFlagHighDataRate: NFCISO15693RequestFlag { .highDataRate }
    public static var RequestFlagProtocolExtension: NFCISO15693RequestFlag { .protocolExtension }
    public static var RequestFlagSelect: NFCISO15693RequestFlag { .select }
    public static var RequestFlagAddress: NFCISO15693RequestFlag { .address }
    public static var RequestFlagOption: NFCISO15693RequestFlag { .option }
}

public struct NFCISO15693ResponseFlag: OptionSet, Hashable, Sendable {
    public let rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public static let error = NFCISO15693ResponseFlag(rawValue: 1 << 0)
    public static let responseBufferValid = NFCISO15693ResponseFlag(rawValue: 1 << 1)
    public static let finalResponse = NFCISO15693ResponseFlag(rawValue: 1 << 2)
    public static let protocolExtension = NFCISO15693ResponseFlag(rawValue: 1 << 3)
    public static let blockSecurityStatusBit5 = NFCISO15693ResponseFlag(rawValue: 1 << 4)
    public static let waitTimeExtension = NFCISO15693ResponseFlag(rawValue: 1 << 5)
    public static let blockSecurityStatusBit6 = NFCISO15693ResponseFlag(rawValue: 1 << 6)
}

public struct NFCFeliCaStatusFlag: Hashable, Sendable {
    public var statusFlag1: Int
    public var statusFlag2: Int

    public init(statusFlag1: Int, statusFlag2: Int) {
        self.statusFlag1 = statusFlag1
        self.statusFlag2 = statusFlag2
    }
}

public struct NFCFeliCaPollingResponse: Hashable, Sendable {
    public var manufactureParameter: Data
    public var requestData: Data?

    public init(manufactureParameter: Data, requestData: Data?) {
        self.manufactureParameter = manufactureParameter
        self.requestData = requestData
    }
}

public struct NFCFeliCaRequsetServiceV2Response: Hashable, Sendable {
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

public struct NFCFeliCaRequestSpecificationVersionResponse: Hashable, Sendable {
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

public struct NFCISO15693SystemInfo: Hashable, Sendable {
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

public struct NFCISO15693MultipleBlockSecurityStatus: Hashable, Sendable {
    public var blockSecurityStatus: [Int]

    public init(blockSecurityStatus: [Int]) {
        self.blockSecurityStatus = blockSecurityStatus
    }
}
