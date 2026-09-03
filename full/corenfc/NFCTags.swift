import Foundation

public protocol NFCNDEFTag: NSObjectProtocol {
    var isAvailable: Bool { get }
    func queryNDEFStatus(completionHandler: @escaping (NFCNDEFStatus, Int, (any Error)?) -> Void)
    func readNDEF(completionHandler: @escaping (NFCNDEFMessage?, (any Error)?) -> Void)
    func writeLock(completionHandler: @escaping ((any Error)?) -> Void)
    func writeNDEF(_ ndefMessage: NFCNDEFMessage) async throws
}

extension NFCNDEFTag {
    public func queryNDEFStatus(
        completionHandler: @escaping (NFCNDEFStatus, Int, (any Error)?) -> Void
    ) {
        coreNFCSessionQueue.async {
            completionHandler(.notSupported, 0, coreNFCUnsupportedNSError())
        }
    }

    public func readNDEF(
        completionHandler: @escaping (NFCNDEFMessage?, (any Error)?) -> Void
    ) {
        coreNFCSessionQueue.async {
            completionHandler(nil, coreNFCUnsupportedNSError(.ndefReaderSessionErrorZeroLengthMessage))
        }
    }

    public func writeLock(completionHandler: @escaping ((any Error)?) -> Void) {
        coreNFCSessionQueue.async {
            completionHandler(coreNFCUnsupportedNSError(.ndefReaderSessionErrorTagNotWritable))
        }
    }

    public func writeNDEF(_ ndefMessage: NFCNDEFMessage) async throws {
        _ = ndefMessage
        throw coreNFCUnsupportedError(.ndefReaderSessionErrorTagNotWritable)
    }
}

public protocol NFCFeliCaTag: NFCNDEFTag {
    var currentIDm: Data { get }
    var currentSystemCode: Data { get }
    func polling(systemCode: Data, requestCode: NFCFeliCaPollingRequestCode, timeSlot: NFCFeliCaPollingTimeSlot) async throws -> (Data, Data)
    func readWithoutEncryption(serviceCodeList: [Data], blockList: [Data]) async throws -> (Int, Int, [Data])
    func requestResponse(completionHandler: @escaping (Int, (any Error)?) -> Void)
    func requestServiceV2(nodeCodeList: [Data]) async throws -> (Int, Int, NFCFeliCaEncryptionId, [Data], [Data])
    func requestService(nodeCodeList: [Data]) async throws -> [Data]
    func requestSpecificationVersion(completionHandler: @escaping (Int, Int, Data, Data, (any Error)?) -> Void)
    func requestSystemCode(completionHandler: @escaping ([Data], (any Error)?) -> Void)
    func resetMode(completionHandler: @escaping (Int, Int, (any Error)?) -> Void)
    func sendFeliCaCommand(commandPacket: Data) async throws -> Data
    func writeWithoutEncryption(serviceCodeList: [Data], blockList: [Data], blockData: [Data]) async throws -> (Int, Int)
}

extension NFCFeliCaTag {
    public func polling(
        systemCode: Data,
        requestCode: NFCFeliCaPollingRequestCode,
        timeSlot: NFCFeliCaPollingTimeSlot
    ) async throws -> (Data, Data) {
        _ = (systemCode, requestCode, timeSlot)
        throw coreNFCUnsupportedError()
    }

    public func readWithoutEncryption(
        serviceCodeList: [Data],
        blockList: [Data]
    ) async throws -> (Int, Int, [Data]) {
        _ = (serviceCodeList, blockList)
        throw coreNFCUnsupportedError()
    }

    public func requestResponse(completionHandler: @escaping (Int, (any Error)?) -> Void) {
        coreNFCSessionQueue.async {
            completionHandler(0, coreNFCUnsupportedNSError())
        }
    }

    public func requestServiceV2(
        nodeCodeList: [Data]
    ) async throws -> (Int, Int, NFCFeliCaEncryptionId, [Data], [Data]) {
        _ = nodeCodeList
        throw coreNFCUnsupportedError()
    }

    public func requestService(nodeCodeList: [Data]) async throws -> [Data] {
        _ = nodeCodeList
        throw coreNFCUnsupportedError()
    }

    public func requestSpecificationVersion(
        completionHandler: @escaping (Int, Int, Data, Data, (any Error)?) -> Void
    ) {
        coreNFCSessionQueue.async {
            completionHandler(0, 0, Data(), Data(), coreNFCUnsupportedNSError())
        }
    }

    public func requestSystemCode(completionHandler: @escaping ([Data], (any Error)?) -> Void) {
        coreNFCSessionQueue.async {
            completionHandler([], coreNFCUnsupportedNSError())
        }
    }

    public func resetMode(completionHandler: @escaping (Int, Int, (any Error)?) -> Void) {
        coreNFCSessionQueue.async {
            completionHandler(0, 0, coreNFCUnsupportedNSError())
        }
    }

    public func sendFeliCaCommand(commandPacket: Data) async throws -> Data {
        _ = commandPacket
        throw coreNFCUnsupportedError()
    }

    public func writeWithoutEncryption(
        serviceCodeList: [Data],
        blockList: [Data],
        blockData: [Data]
    ) async throws -> (Int, Int) {
        _ = (serviceCodeList, blockList, blockData)
        throw coreNFCUnsupportedError()
    }

    public func sendFeliCaCommand(
        commandPacket: Data,
        resultHandler: @escaping (Result<Data, any Error>) -> Void
    ) {
        coreNFCSessionQueue.async {
            resultHandler(.failure(coreNFCUnsupportedError()))
        }
        _ = commandPacket
    }

    public func requestService(
        nodeCodeList: [Data],
        resultHandler: @escaping (Result<[Data], any Error>) -> Void
    ) {
        coreNFCSessionQueue.async {
            resultHandler(.failure(coreNFCUnsupportedError()))
        }
        _ = nodeCodeList
    }

    public func requestResponse(resultHandler: @escaping (Result<Int, any Error>) -> Void) {
        coreNFCSessionQueue.async {
            resultHandler(.failure(coreNFCUnsupportedError()))
        }
    }

    public func requestServiceV2(
        nodeCodeList: [Data],
        resultHandler: @escaping (Result<NFCFeliCaRequsetServiceV2Response, any Error>) -> Void
    ) {
        coreNFCSessionQueue.async {
            resultHandler(.failure(coreNFCUnsupportedError()))
        }
        _ = nodeCodeList
    }

    public func requestSystemCode(resultHandler: @escaping (Result<[Data], any Error>) -> Void) {
        coreNFCSessionQueue.async {
            resultHandler(.failure(coreNFCUnsupportedError()))
        }
    }

    public func readWithoutEncryption(
        serviceCodeList: [Data],
        blockList: [Data],
        resultHandler: @escaping (Result<(NFCFeliCaStatusFlag, [Data]), any Error>) -> Void
    ) {
        coreNFCSessionQueue.async {
            resultHandler(.failure(coreNFCUnsupportedError()))
        }
        _ = (serviceCodeList, blockList)
    }

    public func writeWithoutEncryption(
        serviceCodeList: [Data],
        blockList: [Data],
        blockData: [Data],
        resultHandler: @escaping (Result<NFCFeliCaStatusFlag, any Error>) -> Void
    ) {
        coreNFCSessionQueue.async {
            resultHandler(.failure(coreNFCUnsupportedError()))
        }
        _ = (serviceCodeList, blockList, blockData)
    }

    public func requestSpecificationVersion(
        resultHandler: @escaping (Result<NFCFeliCaRequestSpecificationVersionResponse, any Error>) -> Void
    ) {
        coreNFCSessionQueue.async {
            resultHandler(.failure(coreNFCUnsupportedError()))
        }
    }

    public func polling(
        systemCode: Data,
        requestCode: NFCFeliCaPollingRequestCode,
        timeSlot: NFCFeliCaPollingTimeSlot,
        resultHandler: @escaping (Result<NFCFeliCaPollingResponse, any Error>) -> Void
    ) {
        coreNFCSessionQueue.async {
            resultHandler(.failure(coreNFCUnsupportedError()))
        }
        _ = (systemCode, requestCode, timeSlot)
    }

    public func resetMode(resultHandler: @escaping (Result<NFCFeliCaStatusFlag, any Error>) -> Void) {
        coreNFCSessionQueue.async {
            resultHandler(.failure(coreNFCUnsupportedError()))
        }
    }
}

public protocol NFCISO15693Tag: NFCNDEFTag {
    var icManufacturerCode: Int { get }
    var icSerialNumber: Data { get }
    var identifier: Data { get }
    func customCommand(requestFlags flags: NFCISO15693RequestFlag, customCommandCode: Int, customRequestParameters: Data) async throws -> Data
    func extendedLockBlock(requestFlags flags: NFCISO15693RequestFlag, blockNumber: Int) async throws
    func extendedReadMultipleBlocks(requestFlags flags: NFCISO15693RequestFlag, blockRange: NSRange) async throws -> [Data]
    func extendedReadSingleBlock(requestFlags flags: NFCISO15693RequestFlag, blockNumber: Int) async throws -> Data
    func extendedWriteSingleBlock(requestFlags flags: NFCISO15693RequestFlag, blockNumber: Int, dataBlock: Data) async throws
    func getMultipleBlockSecurityStatus(requestFlags flags: NFCISO15693RequestFlag, blockRange: NSRange) async throws -> [NSNumber]
    func getSystemInfo(requestFlags flags: NFCISO15693RequestFlag, completionHandler: @escaping (Int, Int, Int, Int, Int, (any Error)?) -> Void)
    func lockAFI(requestFlags flags: NFCISO15693RequestFlag) async throws
    func lockBlock(requestFlags flags: NFCISO15693RequestFlag, blockNumber: UInt8) async throws
    func lockDFSID(requestFlags flags: NFCISO15693RequestFlag, completionHandler: @escaping ((any Error)?) -> Void)
    func lockDSFID(requestFlags flags: NFCISO15693RequestFlag) async throws
    func readMultipleBlock(readConfiguration: NFCISO15693ReadMultipleBlocksConfiguration, completionHandler: @escaping (Data, (any Error)?) -> Void)
    func readMultipleBlocks(requestFlags flags: NFCISO15693RequestFlag, blockRange: NSRange) async throws -> [Data]
    func readSingleBlock(requestFlags flags: NFCISO15693RequestFlag, blockNumber: UInt8) async throws -> Data
    func resetToReady(requestFlags flags: NFCISO15693RequestFlag) async throws
    func select(requestFlags flags: NFCISO15693RequestFlag) async throws
    func sendCustomCommand(commandConfiguration: NFCISO15693CustomCommandConfiguration, completionHandler: @escaping (Data, (any Error)?) -> Void)
    func stayQuiet(completionHandler: @escaping ((any Error)?) -> Void)
    func writeAFI(requestFlags flags: NFCISO15693RequestFlag, afi: UInt8) async throws
    func writeDSFID(requestFlags flags: NFCISO15693RequestFlag, dsfid: UInt8) async throws
    func writeMultipleBlocks(requestFlags flags: NFCISO15693RequestFlag, blockRange: NSRange, dataBlocks: [Data]) async throws
    func writeSingleBlock(requestFlags flags: NFCISO15693RequestFlag, blockNumber: UInt8, dataBlock: Data) async throws
}

extension NFCISO15693Tag {
    public func customCommand(
        requestFlags flags: NFCISO15693RequestFlag,
        customCommandCode: Int,
        customRequestParameters: Data
    ) async throws -> Data {
        _ = (flags, customCommandCode, customRequestParameters)
        throw coreNFCUnsupportedError()
    }

    public func extendedLockBlock(requestFlags flags: NFCISO15693RequestFlag, blockNumber: Int) async throws {
        _ = (flags, blockNumber)
        throw coreNFCUnsupportedError()
    }

    public func extendedReadMultipleBlocks(
        requestFlags flags: NFCISO15693RequestFlag,
        blockRange: NSRange
    ) async throws -> [Data] {
        _ = (flags, blockRange)
        throw coreNFCUnsupportedError()
    }

    public func extendedReadSingleBlock(
        requestFlags flags: NFCISO15693RequestFlag,
        blockNumber: Int
    ) async throws -> Data {
        _ = (flags, blockNumber)
        throw coreNFCUnsupportedError()
    }

    public func extendedWriteSingleBlock(
        requestFlags flags: NFCISO15693RequestFlag,
        blockNumber: Int,
        dataBlock: Data
    ) async throws {
        _ = (flags, blockNumber, dataBlock)
        throw coreNFCUnsupportedError()
    }

    public func getMultipleBlockSecurityStatus(
        requestFlags flags: NFCISO15693RequestFlag,
        blockRange: NSRange
    ) async throws -> [NSNumber] {
        _ = (flags, blockRange)
        throw coreNFCUnsupportedError()
    }

    public func getSystemInfo(
        requestFlags flags: NFCISO15693RequestFlag,
        completionHandler: @escaping (Int, Int, Int, Int, Int, (any Error)?) -> Void
    ) {
        coreNFCSessionQueue.async {
            completionHandler(0, 0, 0, 0, 0, coreNFCUnsupportedNSError())
        }
        _ = flags
    }

    public func lockAFI(requestFlags flags: NFCISO15693RequestFlag) async throws {
        _ = flags
        throw coreNFCUnsupportedError()
    }

    public func lockBlock(requestFlags flags: NFCISO15693RequestFlag, blockNumber: UInt8) async throws {
        _ = (flags, blockNumber)
        throw coreNFCUnsupportedError()
    }

    public func lockDFSID(
        requestFlags flags: NFCISO15693RequestFlag,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        coreNFCSessionQueue.async {
            completionHandler(coreNFCUnsupportedNSError())
        }
        _ = flags
    }

    public func lockDSFID(requestFlags flags: NFCISO15693RequestFlag) async throws {
        _ = flags
        throw coreNFCUnsupportedError()
    }

    public func readMultipleBlock(
        readConfiguration: NFCISO15693ReadMultipleBlocksConfiguration,
        completionHandler: @escaping (Data, (any Error)?) -> Void
    ) {
        coreNFCSessionQueue.async {
            completionHandler(Data(), coreNFCUnsupportedNSError())
        }
        _ = readConfiguration
    }

    public func readMultipleBlocks(
        requestFlags flags: NFCISO15693RequestFlag,
        blockRange: NSRange
    ) async throws -> [Data] {
        _ = (flags, blockRange)
        throw coreNFCUnsupportedError()
    }

    public func readSingleBlock(
        requestFlags flags: NFCISO15693RequestFlag,
        blockNumber: UInt8
    ) async throws -> Data {
        _ = (flags, blockNumber)
        throw coreNFCUnsupportedError()
    }

    public func resetToReady(requestFlags flags: NFCISO15693RequestFlag) async throws {
        _ = flags
        throw coreNFCUnsupportedError()
    }

    public func select(requestFlags flags: NFCISO15693RequestFlag) async throws {
        _ = flags
        throw coreNFCUnsupportedError()
    }

    public func sendCustomCommand(
        commandConfiguration: NFCISO15693CustomCommandConfiguration,
        completionHandler: @escaping (Data, (any Error)?) -> Void
    ) {
        coreNFCSessionQueue.async {
            completionHandler(Data(), coreNFCUnsupportedNSError())
        }
        _ = commandConfiguration
    }

    public func stayQuiet(completionHandler: @escaping ((any Error)?) -> Void) {
        coreNFCSessionQueue.async {
            completionHandler(coreNFCUnsupportedNSError())
        }
    }

    public func writeAFI(requestFlags flags: NFCISO15693RequestFlag, afi: UInt8) async throws {
        _ = (flags, afi)
        throw coreNFCUnsupportedError()
    }

    public func writeDSFID(requestFlags flags: NFCISO15693RequestFlag, dsfid: UInt8) async throws {
        _ = (flags, dsfid)
        throw coreNFCUnsupportedError()
    }

    public func writeMultipleBlocks(
        requestFlags flags: NFCISO15693RequestFlag,
        blockRange: NSRange,
        dataBlocks: [Data]
    ) async throws {
        _ = (flags, blockRange, dataBlocks)
        throw coreNFCUnsupportedError()
    }

    public func writeSingleBlock(
        requestFlags flags: NFCISO15693RequestFlag,
        blockNumber: UInt8,
        dataBlock: Data
    ) async throws {
        _ = (flags, blockNumber, dataBlock)
        throw coreNFCUnsupportedError()
    }

    public func readBuffer(
        requestFlags flags: NFCISO15693RequestFlag,
        resultHandler: @escaping (Result<(NFCISO15693ResponseFlag, Data), any Error>) -> Void
    ) {
        coreNFCSessionQueue.async {
            resultHandler(.failure(coreNFCUnsupportedError()))
        }
        _ = flags
    }

    public func readBuffer(
        requestFlags flags: NFCISO15693RequestFlag
    ) async throws -> (NFCISO15693ResponseFlag, Data) {
        _ = flags
        throw coreNFCUnsupportedError()
    }

    public func systemInfo(requestFlags flags: NFCISO15693RequestFlag) async throws -> NFCISO15693SystemInfo {
        _ = flags
        throw coreNFCUnsupportedError()
    }

    public func sendRequest(
        requestFlags flags: Int,
        commandCode: Int,
        data: Data?,
        resultHandler: @escaping (Result<(NFCISO15693ResponseFlag, Data?), any Error>) -> Void
    ) {
        coreNFCSessionQueue.async {
            resultHandler(.failure(coreNFCUnsupportedError()))
        }
        _ = (flags, commandCode, data)
    }

    public func sendRequest(
        requestFlags flags: Int,
        commandCode: Int,
        data: Data?
    ) async throws -> (NFCISO15693ResponseFlag, Data?) {
        _ = (flags, commandCode, data)
        throw coreNFCUnsupportedError()
    }

    public func authenticate(
        requestFlags flags: NFCISO15693RequestFlag,
        cryptoSuiteIdentifier: Int,
        message: Data,
        resultHandler: @escaping (Result<(NFCISO15693ResponseFlag, Data), any Error>) -> Void
    ) {
        coreNFCSessionQueue.async {
            resultHandler(.failure(coreNFCUnsupportedError()))
        }
        _ = (flags, cryptoSuiteIdentifier, message)
    }

    public func authenticate(
        requestFlags flags: NFCISO15693RequestFlag,
        cryptoSuiteIdentifier: Int,
        message: Data
    ) async throws -> (NFCISO15693ResponseFlag, Data) {
        _ = (flags, cryptoSuiteIdentifier, message)
        throw coreNFCUnsupportedError()
    }

    public func customCommand(
        requestFlags flags: NFCISO15693RequestFlag,
        customCommandCode: Int,
        customRequestParameters: Data,
        resultHandler: @escaping (Result<Data, any Error>) -> Void
    ) {
        coreNFCSessionQueue.async {
            resultHandler(.failure(coreNFCUnsupportedError()))
        }
        _ = (flags, customCommandCode, customRequestParameters)
    }

    public func getSystemInfo(
        requestFlags flags: NFCISO15693RequestFlag,
        resultHandler: @escaping (Result<NFCISO15693SystemInfo, any Error>) -> Void
    ) {
        coreNFCSessionQueue.async {
            resultHandler(.failure(coreNFCUnsupportedError()))
        }
        _ = flags
    }

    public func readSingleBlock(
        requestFlags flags: NFCISO15693RequestFlag,
        blockNumber: UInt8,
        resultHandler: @escaping (Result<Data, any Error>) -> Void
    ) {
        coreNFCSessionQueue.async {
            resultHandler(.failure(coreNFCUnsupportedError()))
        }
        _ = (flags, blockNumber)
    }

    public func readMultipleBlocks(
        requestFlags flags: NFCISO15693RequestFlag,
        blockRange: NSRange,
        resultHandler: @escaping (Result<[Data], any Error>) -> Void
    ) {
        coreNFCSessionQueue.async {
            resultHandler(.failure(coreNFCUnsupportedError()))
        }
        _ = (flags, blockRange)
    }

    public func fastReadMultipleBlocks(
        requestFlags flags: NFCISO15693RequestFlag,
        blockRange: NSRange,
        resultHandler: @escaping (Result<[Data], any Error>) -> Void
    ) {
        coreNFCSessionQueue.async {
            resultHandler(.failure(coreNFCUnsupportedError()))
        }
        _ = (flags, blockRange)
    }

    public func fastReadMultipleBlocks(
        requestFlags flags: NFCISO15693RequestFlag,
        blockRange: NSRange
    ) async throws -> [Data] {
        _ = (flags, blockRange)
        throw coreNFCUnsupportedError()
    }

    public func extendedReadSingleBlock(
        requestFlags flags: NFCISO15693RequestFlag,
        blockNumber: Int,
        resultHandler: @escaping (Result<Data, any Error>) -> Void
    ) {
        coreNFCSessionQueue.async {
            resultHandler(.failure(coreNFCUnsupportedError()))
        }
        _ = (flags, blockNumber)
    }

    public func extendedWriteMultipleBlocks(
        requestFlags flags: NFCISO15693RequestFlag,
        blockRange: NSRange,
        dataBlocks: [Data],
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        coreNFCSessionQueue.async {
            completionHandler(coreNFCUnsupportedNSError())
        }
        _ = (flags, blockRange, dataBlocks)
    }

    public func extendedWriteMultipleBlocks(
        requestFlags flags: NFCISO15693RequestFlag,
        blockRange: NSRange,
        dataBlocks: [Data]
    ) async throws {
        _ = (flags, blockRange, dataBlocks)
        throw coreNFCUnsupportedError()
    }

    public func extendedFastReadMultipleBlocks(
        requestFlags flags: NFCISO15693RequestFlag,
        blockRange: NSRange,
        resultHandler: @escaping (Result<[Data], any Error>) -> Void
    ) {
        coreNFCSessionQueue.async {
            resultHandler(.failure(coreNFCUnsupportedError()))
        }
        _ = (flags, blockRange)
    }

    public func extendedFastReadMultipleBlocks(
        requestFlags flags: NFCISO15693RequestFlag,
        blockRange: NSRange
    ) async throws -> [Data] {
        _ = (flags, blockRange)
        throw coreNFCUnsupportedError()
    }

    public func extendedGetMultipleBlockSecurityStatus(
        requestFlags flags: NFCISO15693RequestFlag,
        blockRange: NSRange,
        resultHandler: @escaping (Result<NFCISO15693MultipleBlockSecurityStatus, any Error>) -> Void
    ) {
        coreNFCSessionQueue.async {
            resultHandler(.failure(coreNFCUnsupportedError()))
        }
        _ = (flags, blockRange)
    }

    public func extendedGetMultipleBlockSecurityStatus(
        requestFlags flags: NFCISO15693RequestFlag,
        blockRange: NSRange
    ) async throws -> NFCISO15693MultipleBlockSecurityStatus {
        _ = (flags, blockRange)
        throw coreNFCUnsupportedError()
    }

    public func challenge(
        requestFlags flags: NFCISO15693RequestFlag,
        cryptoSuiteIdentifier: Int,
        message: Data,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        coreNFCSessionQueue.async {
            completionHandler(coreNFCUnsupportedNSError())
        }
        _ = (flags, cryptoSuiteIdentifier, message)
    }

    public func challenge(
        requestFlags flags: NFCISO15693RequestFlag,
        cryptoSuiteIdentifier: Int,
        message: Data
    ) async throws {
        _ = (flags, cryptoSuiteIdentifier, message)
        throw coreNFCUnsupportedError()
    }

    public func keyUpdate(
        requestFlags flags: NFCISO15693RequestFlag,
        keyIdentifier: Int,
        message: Data,
        resultHandler: @escaping (Result<(NFCISO15693ResponseFlag, Data), any Error>) -> Void
    ) {
        coreNFCSessionQueue.async {
            resultHandler(.failure(coreNFCUnsupportedError()))
        }
        _ = (flags, keyIdentifier, message)
    }

    public func keyUpdate(
        requestFlags flags: NFCISO15693RequestFlag,
        keyIdentifier: Int,
        message: Data
    ) async throws -> (NFCISO15693ResponseFlag, Data) {
        _ = (flags, keyIdentifier, message)
        throw coreNFCUnsupportedError()
    }
}

public protocol NFCISO7816Tag: NFCNDEFTag {
    var applicationData: Data? { get }
    var historicalBytes: Data? { get }
    var identifier: Data { get }
    var initialSelectedAID: String { get }
    var proprietaryApplicationDataCoding: Bool { get }
    func sendCommand(apdu: NFCISO7816APDU) async throws -> (Data, UInt8, UInt8)
}

extension NFCISO7816Tag {
    public func sendCommand(apdu: NFCISO7816APDU) async throws -> (Data, UInt8, UInt8) {
        _ = apdu
        throw coreNFCUnsupportedError()
    }

    public func sendCommand(
        apdu: NFCISO7816APDU,
        resultHandler: @escaping (Result<NFCISO7816ResponseAPDU, any Error>) -> Void
    ) {
        coreNFCSessionQueue.async {
            resultHandler(.failure(coreNFCUnsupportedError()))
        }
        _ = apdu
    }
}

public protocol NFCMiFareTag: NFCNDEFTag {
    var historicalBytes: Data? { get }
    var identifier: Data { get }
    var mifareFamily: NFCMiFareFamily { get }
    func sendMiFareCommand(commandPacket command: Data) async throws -> Data
    func sendMiFareISO7816Command(_ apdu: NFCISO7816APDU) async throws -> (Data, UInt8, UInt8)
}

extension NFCMiFareTag {
    public func sendMiFareCommand(commandPacket command: Data) async throws -> Data {
        _ = command
        throw coreNFCUnsupportedError()
    }

    public func sendMiFareISO7816Command(_ apdu: NFCISO7816APDU) async throws -> (Data, UInt8, UInt8) {
        _ = apdu
        throw coreNFCUnsupportedError()
    }

    public func sendMiFareISO7816Command(
        _ apdu: NFCISO7816APDU,
        resultHandler: @escaping (Result<NFCISO7816ResponseAPDU, any Error>) -> Void
    ) {
        coreNFCSessionQueue.async {
            resultHandler(.failure(coreNFCUnsupportedError()))
        }
        _ = apdu
    }

    public func sendMiFareCommand(
        commandPacket command: Data,
        resultHandler: @escaping (Result<Data, any Error>) -> Void
    ) {
        coreNFCSessionQueue.async {
            resultHandler(.failure(coreNFCUnsupportedError()))
        }
        _ = command
    }
}

public enum NFCTag {
    case feliCa(any NFCFeliCaTag)
    case miFare(any NFCMiFareTag)
    case iso7816(any NFCISO7816Tag)
    case iso15693(any NFCISO15693Tag)

    public var isAvailable: Bool {
        switch self {
        case .feliCa(let tag):
            return tag.isAvailable
        case .miFare(let tag):
            return tag.isAvailable
        case .iso7816(let tag):
            return tag.isAvailable
        case .iso15693(let tag):
            return tag.isAvailable
        }
    }
}

/// Host-only stand-in so `NFCTag` cases can be constructed without a radio.
@_spi(OpenUIKitHost)
public final class CoreNFCHostNDEFTag: NSObject, NFCNDEFTag, NFCFeliCaTag, NFCISO15693Tag, NFCISO7816Tag, NFCMiFareTag {
    public var isAvailable: Bool { false }
    public var currentIDm: Data { Data() }
    public var currentSystemCode: Data { Data() }
    public var icManufacturerCode: Int { 0 }
    public var icSerialNumber: Data { Data() }
    public var identifier: Data { Data() }
    public var applicationData: Data? { nil }
    public var historicalBytes: Data? { nil }
    public var initialSelectedAID: String { "" }
    public var proprietaryApplicationDataCoding: Bool { false }
    public var mifareFamily: NFCMiFareFamily { .unknown }

    public override init() {
        super.init()
    }
}
