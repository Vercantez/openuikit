import Foundation
import CoreNFC

func testNFCFeliCaStatusFlag() {
    let flags = NFCFeliCaStatusFlag(statusFlag1: 0, statusFlag2: 1)
    precondition(flags.statusFlag1 == 0)
    precondition(flags.statusFlag2 == 1)
    precondition(flags == NFCFeliCaStatusFlag(statusFlag1: 0, statusFlag2: 1))
    precondition(flags != NFCFeliCaStatusFlag(statusFlag1: 1, statusFlag2: 1))
}

func testNFCISO15693SystemInfo() {
    let info = NFCISO15693SystemInfo(
        uniqueIdentifier: Data([0x01, 0x02]),
        dataStorageFormatIdentifier: 3,
        applicationFamilyIdentifier: 4,
        blockSize: 4,
        totalBlocks: 16,
        icReference: 9
    )
    precondition(info.uniqueIdentifier == Data([0x01, 0x02]))
    precondition(info.dataStorageFormatIdentifier == 3)
    precondition(info.applicationFamilyIdentifier == 4)
    precondition(info.blockSize == 4)
    precondition(info.totalBlocks == 16)
    precondition(info.icReference == 9)
    precondition(
        info == NFCISO15693SystemInfo(
            uniqueIdentifier: Data([0x01, 0x02]),
            dataStorageFormatIdentifier: 3,
            applicationFamilyIdentifier: 4,
            blockSize: 4,
            totalBlocks: 16,
            icReference: 9
        )
    )
}

func testNFCFeliCaPollingResponse() {
    let polling = NFCFeliCaPollingResponse(manufactureParameter: Data([0x01]), requestData: nil)
    precondition(polling.manufactureParameter == Data([0x01]))
    precondition(polling.requestData == nil)
    let withRequest = NFCFeliCaPollingResponse(
        manufactureParameter: Data([0x01]),
        requestData: Data([0xAA])
    )
    precondition(withRequest.requestData == Data([0xAA]))
    precondition(polling != withRequest)
}

func testNFCFeliCaRequsetServiceV2Response() {
    let response = NFCFeliCaRequsetServiceV2Response(
        statusFlag1: 0,
        statusFlag2: 1,
        encryptionIdentifier: .AES,
        nodeKeyVersionListAES: [Data([0x01])],
        nodeKeyVersionListDES: nil
    )
    precondition(response.statusFlag1 == 0)
    precondition(response.statusFlag2 == 1)
    precondition(response.encryptionIdentifier == .AES)
    precondition(response.nodeKeyVersionListAES == [Data([0x01])])
    precondition(response.nodeKeyVersionListDES == nil)
}

func testNFCISO15693MultipleBlockSecurityStatus() {
    let status = NFCISO15693MultipleBlockSecurityStatus(blockSecurityStatus: [0, 1, 0])
    precondition(status.blockSecurityStatus == [0, 1, 0])
    precondition(
        status != NFCISO15693MultipleBlockSecurityStatus(blockSecurityStatus: [1])
    )
}

func testNFCFeliCaRequestSpecificationVersionResponse() {
    let response = NFCFeliCaRequestSpecificationVersionResponse(
        statusFlag1: 0,
        statusFlag2: 0,
        basicVersion: Data([0x10]),
        optionVersion: nil
    )
    precondition(response.statusFlag1 == 0)
    precondition(response.statusFlag2 == 0)
    precondition(response.basicVersion == Data([0x10]))
    precondition(response.optionVersion == nil)
}
