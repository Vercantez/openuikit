import Foundation

open class NFCTagCommandConfiguration: NSObject {
    public var maximumRetries: Int
    public var retryInterval: TimeInterval

    public override init() {
        self.maximumRetries = 0
        self.retryInterval = 0
        super.init()
    }

    public init(maximumRetries: Int, retryInterval: TimeInterval) {
        self.maximumRetries = maximumRetries
        self.retryInterval = retryInterval
        super.init()
    }
}

open class NFCISO15693CustomCommandConfiguration: NFCTagCommandConfiguration {
    public var manufacturerCode: Int
    public var customCommandCode: Int
    public var requestParameters: Data

    public init(manufacturerCode: Int, customCommandCode: Int, requestParameters: Data?) {
        self.manufacturerCode = manufacturerCode
        self.customCommandCode = customCommandCode
        self.requestParameters = requestParameters ?? Data()
        super.init()
    }

    public init(
        manufacturerCode: Int,
        customCommandCode: Int,
        requestParameters: Data?,
        maximumRetries: Int,
        retryInterval: TimeInterval
    ) {
        self.manufacturerCode = manufacturerCode
        self.customCommandCode = customCommandCode
        self.requestParameters = requestParameters ?? Data()
        super.init(maximumRetries: maximumRetries, retryInterval: retryInterval)
    }
}

open class NFCISO15693ReadMultipleBlocksConfiguration: NFCTagCommandConfiguration {
    public var range: NSRange
    public var chunkSize: Int

    public init(range: NSRange, chunkSize: Int) {
        self.range = range
        self.chunkSize = chunkSize
        super.init()
    }

    public init(
        range: NSRange,
        chunkSize: Int,
        maximumRetries: Int,
        retryInterval: TimeInterval
    ) {
        self.range = range
        self.chunkSize = chunkSize
        super.init(maximumRetries: maximumRetries, retryInterval: retryInterval)
    }
}

public protocol NFCNDEFTag: NSObjectProtocol {
    var isAvailable: Bool { get }
    func queryNDEFStatus(
        completionHandler: @escaping (NFCNDEFStatus, Int, (any Error)?) -> Void
    )
    func readNDEF(completionHandler: @escaping (NFCNDEFMessage?, (any Error)?) -> Void)
    func writeLock(completionHandler: @escaping ((any Error)?) -> Void)
    func writeNDEF(_ ndefMessage: NFCNDEFMessage) async throws
}

extension NFCNDEFTag {
    public var isAvailable: Bool { false }

    public func queryNDEFStatus(
        completionHandler: @escaping (NFCNDEFStatus, Int, (any Error)?) -> Void
    ) {
        completionHandler(.notSupported, 0, _nfcUnsupportedError())
    }

    public func readNDEF(
        completionHandler: @escaping (NFCNDEFMessage?, (any Error)?) -> Void
    ) {
        completionHandler(nil, _nfcUnsupportedError())
    }

    public func writeLock(completionHandler: @escaping ((any Error)?) -> Void) {
        _nfcCompleteUnsupported(completionHandler)
    }

    public func writeNDEF(_ ndefMessage: NFCNDEFMessage) async throws {
        _ = ndefMessage
        try _nfcThrowUnsupported()
    }
}

public protocol NFCFeliCaTag: NFCNDEFTag {
    var currentIDm: Data { get }
    var currentSystemCode: Data { get }
    func polling(
        systemCode: Data,
        requestCode: NFCFeliCaPollingRequestCode,
        timeSlot: NFCFeliCaPollingTimeSlot
    ) async throws -> (Data, Data)
    func readWithoutEncryption(
        serviceCodeList: [Data],
        blockList: [Data]
    ) async throws -> (Int, Int, [Data])
    func requestResponse(completionHandler: @escaping (Int, (any Error)?) -> Void)
    func requestServiceV2(nodeCodeList: [Data]) async throws -> (
        Int, Int, NFCFeliCaEncryptionId, [Data], [Data]
    )
    func requestService(nodeCodeList: [Data]) async throws -> [Data]
    func requestSpecificationVersion(
        completionHandler: @escaping (Int, Int, Data, Data, (any Error)?) -> Void
    )
    func requestSystemCode(completionHandler: @escaping ([Data], (any Error)?) -> Void)
    func resetMode(completionHandler: @escaping (Int, Int, (any Error)?) -> Void)
    func sendFeliCaCommand(commandPacket: Data) async throws -> Data
    func writeWithoutEncryption(
        serviceCodeList: [Data],
        blockList: [Data],
        blockData: [Data]
    ) async throws -> (Int, Int)
}

extension NFCFeliCaTag {
    public var currentIDm: Data { Data() }
    public var currentSystemCode: Data { Data() }

    public func polling(
        systemCode: Data,
        requestCode: NFCFeliCaPollingRequestCode,
        timeSlot: NFCFeliCaPollingTimeSlot
    ) async throws -> (Data, Data) {
        _ = (systemCode, requestCode, timeSlot)
        try _nfcThrowUnsupported()
    }

    public func readWithoutEncryption(
        serviceCodeList: [Data],
        blockList: [Data]
    ) async throws -> (Int, Int, [Data]) {
        _ = (serviceCodeList, blockList)
        try _nfcThrowUnsupported()
    }

    public func requestResponse(completionHandler: @escaping (Int, (any Error)?) -> Void) {
        completionHandler(0, _nfcUnsupportedError())
    }

    public func requestServiceV2(nodeCodeList: [Data]) async throws -> (
        Int, Int, NFCFeliCaEncryptionId, [Data], [Data]
    ) {
        _ = nodeCodeList
        try _nfcThrowUnsupported()
    }

    public func requestService(nodeCodeList: [Data]) async throws -> [Data] {
        _ = nodeCodeList
        try _nfcThrowUnsupported()
    }

    public func requestSpecificationVersion(
        completionHandler: @escaping (Int, Int, Data, Data, (any Error)?) -> Void
    ) {
        completionHandler(0, 0, Data(), Data(), _nfcUnsupportedError())
    }

    public func requestSystemCode(completionHandler: @escaping ([Data], (any Error)?) -> Void) {
        completionHandler([], _nfcUnsupportedError())
    }

    public func resetMode(completionHandler: @escaping (Int, Int, (any Error)?) -> Void) {
        completionHandler(0, 0, _nfcUnsupportedError())
    }

    public func sendFeliCaCommand(commandPacket: Data) async throws -> Data {
        _ = commandPacket
        try _nfcThrowUnsupported()
    }

    public func writeWithoutEncryption(
        serviceCodeList: [Data],
        blockList: [Data],
        blockData: [Data]
    ) async throws -> (Int, Int) {
        _ = (serviceCodeList, blockList, blockData)
        try _nfcThrowUnsupported()
    }

    public func sendFeliCaCommand(
        commandPacket: Data,
        resultHandler: @escaping (Result<Data, any Error>) -> Void
    ) {
        resultHandler(.failure(_nfcUnsupportedError()))
        _ = commandPacket
    }

    public func requestService(
        nodeCodeList: [Data],
        resultHandler: @escaping (Result<[Data], any Error>) -> Void
    ) {
        _ = nodeCodeList
        resultHandler(.failure(_nfcUnsupportedError()))
    }

    public func requestResponse(resultHandler: @escaping (Result<Int, any Error>) -> Void) {
        resultHandler(.failure(_nfcUnsupportedError()))
    }

    public func requestServiceV2(
        nodeCodeList: [Data],
        resultHandler: @escaping (Result<NFCFeliCaRequsetServiceV2Response, any Error>) -> Void
    ) {
        _ = nodeCodeList
        resultHandler(.failure(_nfcUnsupportedError()))
    }

    public func requestSystemCode(
        resultHandler: @escaping (Result<[Data], any Error>) -> Void
    ) {
        resultHandler(.failure(_nfcUnsupportedError()))
    }

    public func readWithoutEncryption(
        serviceCodeList: [Data],
        blockList: [Data],
        resultHandler: @escaping (Result<(NFCFeliCaStatusFlag, [Data]), any Error>) -> Void
    ) {
        _ = (serviceCodeList, blockList)
        resultHandler(.failure(_nfcUnsupportedError()))
    }

    public func writeWithoutEncryption(
        serviceCodeList: [Data],
        blockList: [Data],
        blockData: [Data],
        resultHandler: @escaping (Result<NFCFeliCaStatusFlag, any Error>) -> Void
    ) {
        _ = (serviceCodeList, blockList, blockData)
        resultHandler(.failure(_nfcUnsupportedError()))
    }

    public func requestSpecificationVersion(
        resultHandler: @escaping (
            Result<NFCFeliCaRequestSpecificationVersionResponse, any Error>
        ) -> Void
    ) {
        resultHandler(.failure(_nfcUnsupportedError()))
    }

    public func polling(
        systemCode: Data,
        requestCode: NFCFeliCaPollingRequestCode,
        timeSlot: NFCFeliCaPollingTimeSlot,
        resultHandler: @escaping (Result<NFCFeliCaPollingResponse, any Error>) -> Void
    ) {
        _ = (systemCode, requestCode, timeSlot)
        resultHandler(.failure(_nfcUnsupportedError()))
    }

    public func resetMode(
        resultHandler: @escaping (Result<NFCFeliCaStatusFlag, any Error>) -> Void
    ) {
        resultHandler(.failure(_nfcUnsupportedError()))
    }
}

public protocol NFCISO15693Tag: NFCNDEFTag {
    var icManufacturerCode: Int { get }
    var icSerialNumber: Data { get }
    var identifier: Data { get }
    func customCommand(
        requestFlags flags: NFCISO15693RequestFlag,
        customCommandCode: Int,
        customRequestParameters: Data
    ) async throws -> Data
    func extendedLockBlock(requestFlags flags: NFCISO15693RequestFlag, blockNumber: Int) async throws
    func extendedReadMultipleBlocks(
        requestFlags flags: NFCISO15693RequestFlag,
        blockRange: NSRange
    ) async throws -> [Data]
    func extendedReadSingleBlock(
        requestFlags flags: NFCISO15693RequestFlag,
        blockNumber: Int
    ) async throws -> Data
    func extendedWriteSingleBlock(
        requestFlags flags: NFCISO15693RequestFlag,
        blockNumber: Int,
        dataBlock: Data
    ) async throws
    func getMultipleBlockSecurityStatus(
        requestFlags flags: NFCISO15693RequestFlag,
        blockRange: NSRange
    ) async throws -> [NSNumber]
    func getSystemInfo(
        requestFlags flags: NFCISO15693RequestFlag,
        completionHandler: @escaping (Int, Int, Int, Int, Int, (any Error)?) -> Void
    )
    func lockAFI(requestFlags flags: NFCISO15693RequestFlag) async throws
    func lockBlock(requestFlags flags: NFCISO15693RequestFlag, blockNumber: UInt8) async throws
    func lockDFSID(
        requestFlags flags: NFCISO15693RequestFlag,
        completionHandler: @escaping ((any Error)?) -> Void
    )
    func lockDSFID(requestFlags flags: NFCISO15693RequestFlag) async throws
    func readMultipleBlock(
        readConfiguration: NFCISO15693ReadMultipleBlocksConfiguration,
        completionHandler: @escaping (Data, (any Error)?) -> Void
    )
    func readMultipleBlocks(
        requestFlags flags: NFCISO15693RequestFlag,
        blockRange: NSRange
    ) async throws -> [Data]
    func readSingleBlock(
        requestFlags flags: NFCISO15693RequestFlag,
        blockNumber: UInt8
    ) async throws -> Data
    func resetToReady(requestFlags flags: NFCISO15693RequestFlag) async throws
    func select(requestFlags flags: NFCISO15693RequestFlag) async throws
    func sendCustomCommand(
        commandConfiguration: NFCISO15693CustomCommandConfiguration,
        completionHandler: @escaping (Data, (any Error)?) -> Void
    )
    func stayQuiet(completionHandler: @escaping ((any Error)?) -> Void)
    func writeAFI(requestFlags flags: NFCISO15693RequestFlag, afi: UInt8) async throws
    func writeDSFID(requestFlags flags: NFCISO15693RequestFlag, dsfid: UInt8) async throws
    func writeMultipleBlocks(
        requestFlags flags: NFCISO15693RequestFlag,
        blockRange: NSRange,
        dataBlocks: [Data]
    ) async throws
    func writeSingleBlock(
        requestFlags flags: NFCISO15693RequestFlag,
        blockNumber: UInt8,
        dataBlock: Data
    ) async throws
}

extension NFCISO15693Tag {
    public var icManufacturerCode: Int { 0 }
    public var icSerialNumber: Data { Data() }
    public var identifier: Data { Data() }

    public func customCommand(
        requestFlags flags: NFCISO15693RequestFlag,
        customCommandCode: Int,
        customRequestParameters: Data
    ) async throws -> Data {
        _ = (flags, customCommandCode, customRequestParameters)
        try _nfcThrowUnsupported()
    }

    public func extendedLockBlock(
        requestFlags flags: NFCISO15693RequestFlag,
        blockNumber: Int
    ) async throws {
        _ = (flags, blockNumber)
        try _nfcThrowUnsupported()
    }

    public func extendedReadMultipleBlocks(
        requestFlags flags: NFCISO15693RequestFlag,
        blockRange: NSRange
    ) async throws -> [Data] {
        _ = (flags, blockRange)
        try _nfcThrowUnsupported()
    }

    public func extendedReadSingleBlock(
        requestFlags flags: NFCISO15693RequestFlag,
        blockNumber: Int
    ) async throws -> Data {
        _ = (flags, blockNumber)
        try _nfcThrowUnsupported()
    }

    public func extendedWriteSingleBlock(
        requestFlags flags: NFCISO15693RequestFlag,
        blockNumber: Int,
        dataBlock: Data
    ) async throws {
        _ = (flags, blockNumber, dataBlock)
        try _nfcThrowUnsupported()
    }

    public func getMultipleBlockSecurityStatus(
        requestFlags flags: NFCISO15693RequestFlag,
        blockRange: NSRange
    ) async throws -> [NSNumber] {
        _ = (flags, blockRange)
        try _nfcThrowUnsupported()
    }

    public func getSystemInfo(
        requestFlags flags: NFCISO15693RequestFlag,
        completionHandler: @escaping (Int, Int, Int, Int, Int, (any Error)?) -> Void
    ) {
        _ = flags
        completionHandler(0, 0, 0, 0, 0, _nfcUnsupportedError())
    }

    public func lockAFI(requestFlags flags: NFCISO15693RequestFlag) async throws {
        _ = flags
        try _nfcThrowUnsupported()
    }

    public func lockBlock(
        requestFlags flags: NFCISO15693RequestFlag,
        blockNumber: UInt8
    ) async throws {
        _ = (flags, blockNumber)
        try _nfcThrowUnsupported()
    }

    public func lockDFSID(
        requestFlags flags: NFCISO15693RequestFlag,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = flags
        _nfcCompleteUnsupported(completionHandler)
    }

    public func lockDSFID(requestFlags flags: NFCISO15693RequestFlag) async throws {
        _ = flags
        try _nfcThrowUnsupported()
    }

    public func readMultipleBlock(
        readConfiguration: NFCISO15693ReadMultipleBlocksConfiguration,
        completionHandler: @escaping (Data, (any Error)?) -> Void
    ) {
        _ = readConfiguration
        completionHandler(Data(), _nfcUnsupportedError())
    }

    public func readMultipleBlocks(
        requestFlags flags: NFCISO15693RequestFlag,
        blockRange: NSRange
    ) async throws -> [Data] {
        _ = (flags, blockRange)
        try _nfcThrowUnsupported()
    }

    public func readSingleBlock(
        requestFlags flags: NFCISO15693RequestFlag,
        blockNumber: UInt8
    ) async throws -> Data {
        _ = (flags, blockNumber)
        try _nfcThrowUnsupported()
    }

    public func resetToReady(requestFlags flags: NFCISO15693RequestFlag) async throws {
        _ = flags
        try _nfcThrowUnsupported()
    }

    public func select(requestFlags flags: NFCISO15693RequestFlag) async throws {
        _ = flags
        try _nfcThrowUnsupported()
    }

    public func sendCustomCommand(
        commandConfiguration: NFCISO15693CustomCommandConfiguration,
        completionHandler: @escaping (Data, (any Error)?) -> Void
    ) {
        _ = commandConfiguration
        completionHandler(Data(), _nfcUnsupportedError())
    }

    public func stayQuiet(completionHandler: @escaping ((any Error)?) -> Void) {
        _nfcCompleteUnsupported(completionHandler)
    }

    public func writeAFI(requestFlags flags: NFCISO15693RequestFlag, afi: UInt8) async throws {
        _ = (flags, afi)
        try _nfcThrowUnsupported()
    }

    public func writeDSFID(requestFlags flags: NFCISO15693RequestFlag, dsfid: UInt8) async throws {
        _ = (flags, dsfid)
        try _nfcThrowUnsupported()
    }

    public func writeMultipleBlocks(
        requestFlags flags: NFCISO15693RequestFlag,
        blockRange: NSRange,
        dataBlocks: [Data]
    ) async throws {
        _ = (flags, blockRange, dataBlocks)
        try _nfcThrowUnsupported()
    }

    public func writeSingleBlock(
        requestFlags flags: NFCISO15693RequestFlag,
        blockNumber: UInt8,
        dataBlock: Data
    ) async throws {
        _ = (flags, blockNumber, dataBlock)
        try _nfcThrowUnsupported()
    }

    public func readBuffer(
        requestFlags flags: NFCISO15693RequestFlag,
        resultHandler: @escaping (Result<(NFCISO15693ResponseFlag, Data), any Error>) -> Void
    ) {
        _ = flags
        resultHandler(.failure(_nfcUnsupportedError()))
    }

    public func readBuffer(
        requestFlags flags: NFCISO15693RequestFlag
    ) async throws -> (NFCISO15693ResponseFlag, Data) {
        _ = flags
        try _nfcThrowUnsupported()
    }

    public func systemInfo(
        requestFlags flags: NFCISO15693RequestFlag
    ) async throws -> NFCISO15693SystemInfo {
        _ = flags
        try _nfcThrowUnsupported()
    }

    public func sendRequest(
        requestFlags flags: Int,
        commandCode: Int,
        data: Data?,
        resultHandler: @escaping (Result<(NFCISO15693ResponseFlag, Data?), any Error>) -> Void
    ) {
        _ = (flags, commandCode, data)
        resultHandler(.failure(_nfcUnsupportedError()))
    }

    public func sendRequest(
        requestFlags flags: Int,
        commandCode: Int,
        data: Data?
    ) async throws -> (NFCISO15693ResponseFlag, Data?) {
        _ = (flags, commandCode, data)
        try _nfcThrowUnsupported()
    }

    public func authenticate(
        requestFlags flags: NFCISO15693RequestFlag,
        cryptoSuiteIdentifier: Int,
        message: Data,
        resultHandler: @escaping (Result<(NFCISO15693ResponseFlag, Data), any Error>) -> Void
    ) {
        _ = (flags, cryptoSuiteIdentifier, message)
        resultHandler(.failure(_nfcUnsupportedError()))
    }

    public func authenticate(
        requestFlags flags: NFCISO15693RequestFlag,
        cryptoSuiteIdentifier: Int,
        message: Data
    ) async throws -> (NFCISO15693ResponseFlag, Data) {
        _ = (flags, cryptoSuiteIdentifier, message)
        try _nfcThrowUnsupported()
    }

    public func customCommand(
        requestFlags flags: NFCISO15693RequestFlag,
        customCommandCode: Int,
        customRequestParameters: Data,
        resultHandler: @escaping (Result<Data, any Error>) -> Void
    ) {
        _ = (flags, customCommandCode, customRequestParameters)
        resultHandler(.failure(_nfcUnsupportedError()))
    }

    public func getSystemInfo(
        requestFlags flags: NFCISO15693RequestFlag,
        resultHandler: @escaping (Result<NFCISO15693SystemInfo, any Error>) -> Void
    ) {
        _ = flags
        resultHandler(.failure(_nfcUnsupportedError()))
    }

    public func readSingleBlock(
        requestFlags flags: NFCISO15693RequestFlag,
        blockNumber: UInt8,
        resultHandler: @escaping (Result<Data, any Error>) -> Void
    ) {
        _ = (flags, blockNumber)
        resultHandler(.failure(_nfcUnsupportedError()))
    }

    public func readMultipleBlocks(
        requestFlags flags: NFCISO15693RequestFlag,
        blockRange: NSRange,
        resultHandler: @escaping (Result<[Data], any Error>) -> Void
    ) {
        _ = (flags, blockRange)
        resultHandler(.failure(_nfcUnsupportedError()))
    }

    public func fastReadMultipleBlocks(
        requestFlags flags: NFCISO15693RequestFlag,
        blockRange: NSRange,
        resultHandler: @escaping (Result<[Data], any Error>) -> Void
    ) {
        _ = (flags, blockRange)
        resultHandler(.failure(_nfcUnsupportedError()))
    }

    public func fastReadMultipleBlocks(
        requestFlags flags: NFCISO15693RequestFlag,
        blockRange: NSRange
    ) async throws -> [Data] {
        _ = (flags, blockRange)
        try _nfcThrowUnsupported()
    }

    public func extendedReadSingleBlock(
        requestFlags flags: NFCISO15693RequestFlag,
        blockNumber: Int,
        resultHandler: @escaping (Result<Data, any Error>) -> Void
    ) {
        _ = (flags, blockNumber)
        resultHandler(.failure(_nfcUnsupportedError()))
    }

    public func extendedWriteMultipleBlocks(
        requestFlags flags: NFCISO15693RequestFlag,
        blockRange: NSRange,
        dataBlocks: [Data],
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = (flags, blockRange, dataBlocks)
        _nfcCompleteUnsupported(completionHandler)
    }

    public func extendedWriteMultipleBlocks(
        requestFlags flags: NFCISO15693RequestFlag,
        blockRange: NSRange,
        dataBlocks: [Data]
    ) async throws {
        _ = (flags, blockRange, dataBlocks)
        try _nfcThrowUnsupported()
    }

    public func extendedFastReadMultipleBlocks(
        requestFlags flags: NFCISO15693RequestFlag,
        blockRange: NSRange,
        resultHandler: @escaping (Result<[Data], any Error>) -> Void
    ) {
        _ = (flags, blockRange)
        resultHandler(.failure(_nfcUnsupportedError()))
    }

    public func extendedFastReadMultipleBlocks(
        requestFlags flags: NFCISO15693RequestFlag,
        blockRange: NSRange
    ) async throws -> [Data] {
        _ = (flags, blockRange)
        try _nfcThrowUnsupported()
    }

    public func extendedGetMultipleBlockSecurityStatus(
        requestFlags flags: NFCISO15693RequestFlag,
        blockRange: NSRange,
        resultHandler: @escaping (
            Result<NFCISO15693MultipleBlockSecurityStatus, any Error>
        ) -> Void
    ) {
        _ = (flags, blockRange)
        resultHandler(.failure(_nfcUnsupportedError()))
    }

    public func extendedGetMultipleBlockSecurityStatus(
        requestFlags flags: NFCISO15693RequestFlag,
        blockRange: NSRange
    ) async throws -> NFCISO15693MultipleBlockSecurityStatus {
        _ = (flags, blockRange)
        try _nfcThrowUnsupported()
    }

    public func challenge(
        requestFlags flags: NFCISO15693RequestFlag,
        cryptoSuiteIdentifier: Int,
        message: Data,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = (flags, cryptoSuiteIdentifier, message)
        _nfcCompleteUnsupported(completionHandler)
    }

    public func challenge(
        requestFlags flags: NFCISO15693RequestFlag,
        cryptoSuiteIdentifier: Int,
        message: Data
    ) async throws {
        _ = (flags, cryptoSuiteIdentifier, message)
        try _nfcThrowUnsupported()
    }

    public func keyUpdate(
        requestFlags flags: NFCISO15693RequestFlag,
        keyIdentifier: Int,
        message: Data,
        resultHandler: @escaping (Result<(NFCISO15693ResponseFlag, Data), any Error>) -> Void
    ) {
        _ = (flags, keyIdentifier, message)
        resultHandler(.failure(_nfcUnsupportedError()))
    }

    public func keyUpdate(
        requestFlags flags: NFCISO15693RequestFlag,
        keyIdentifier: Int,
        message: Data
    ) async throws -> (NFCISO15693ResponseFlag, Data) {
        _ = (flags, keyIdentifier, message)
        try _nfcThrowUnsupported()
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
    public var applicationData: Data? { nil }
    public var historicalBytes: Data? { nil }
    public var identifier: Data { Data() }
    public var initialSelectedAID: String { "" }
    public var proprietaryApplicationDataCoding: Bool { false }

    public func sendCommand(apdu: NFCISO7816APDU) async throws -> (Data, UInt8, UInt8) {
        _ = apdu
        try _nfcThrowUnsupported()
    }

    public func sendCommand(apdu: NFCISO7816APDU) async throws -> NFCISO7816ResponseAPDU {
        _ = apdu
        try _nfcThrowUnsupported()
    }

    public func sendCommand(
        apdu: NFCISO7816APDU,
        resultHandler: @escaping (Result<NFCISO7816ResponseAPDU, any Error>) -> Void
    ) {
        _ = apdu
        resultHandler(.failure(_nfcUnsupportedError()))
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
    public var historicalBytes: Data? { nil }
    public var identifier: Data { Data() }
    public var mifareFamily: NFCMiFareFamily { .unknown }

    public func sendMiFareCommand(commandPacket command: Data) async throws -> Data {
        _ = command
        try _nfcThrowUnsupported()
    }

    public func sendMiFareISO7816Command(
        _ apdu: NFCISO7816APDU
    ) async throws -> (Data, UInt8, UInt8) {
        _ = apdu
        try _nfcThrowUnsupported()
    }

    public func sendMiFareISO7816Command(
        _ apdu: NFCISO7816APDU
    ) async throws -> NFCISO7816ResponseAPDU {
        _ = apdu
        try _nfcThrowUnsupported()
    }

    public func sendMiFareISO7816Command(
        _ apdu: NFCISO7816APDU,
        resultHandler: @escaping (Result<NFCISO7816ResponseAPDU, any Error>) -> Void
    ) {
        _ = apdu
        resultHandler(.failure(_nfcUnsupportedError()))
    }

    public func sendMiFareCommand(
        commandPacket command: Data,
        resultHandler: @escaping (Result<Data, any Error>) -> Void
    ) {
        _ = command
        resultHandler(.failure(_nfcUnsupportedError()))
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
