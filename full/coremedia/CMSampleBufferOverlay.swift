import CoreFoundation
import Foundation

extension CMSampleBuffer {
    public enum ContentType: Equatable, Hashable, Sendable {
        case dataBuffer
        case pixelBuffer
        case markerOnly
        case taggedBuffers
        case sampleReference
    }

    public enum DataReadiness: Equatable, Hashable, Sendable {
        case ready
        case notReady
        case failed(OSStatus)
    }

    public enum SizePerSample: Equatable, ExpressibleByArrayLiteral {
        public typealias ArrayLiteralElement = Int
        case uniform(Int)
        case distinct([Int])

        public init(arrayLiteral elements: Int...) {
            if elements.count == 1 {
                self = .uniform(elements[0])
            } else {
                self = .distinct(elements)
            }
        }
    }

    public enum TimingPerSample: Equatable, ExpressibleByArrayLiteral {
        public typealias ArrayLiteralElement = CMSampleTimingInfo
        case sequential(startingAt: CMSampleTimingInfo)
        case distinct([CMSampleTimingInfo])

        public init(arrayLiteral elements: CMSampleTimingInfo...) {
            if elements.count == 1 {
                self = .sequential(startingAt: elements[0])
            } else {
                self = .distinct(elements)
            }
        }

        public static func sequential(
            presentationTimeOfFirstSample: CMTime,
            uniformDuration: CMTime,
            decodeTimeOfFirstSample: CMTime = .invalid
        ) -> TimingPerSample {
            .sequential(
                startingAt: CMSampleTimingInfo(
                    duration: uniformDuration,
                    presentationTimeStamp: presentationTimeOfFirstSample,
                    decodeTimeStamp: decodeTimeOfFirstSample
                )
            )
        }
    }

    public struct HEVCTemporalInfo: Equatable, Sendable {
        public var temporalLayerID: Int
        public var profileSpace: Int
        public var tierFlag: Int
        public var profileIndex: Int
        public var profileCompatibilityFlags: Data?
        public var constraintIndicatorFlags: Data?
        public var levelIndex: Int

        public init(
            temporalLayerID: Int,
            profileSpace: Int,
            tierFlag: Int,
            profileIndex: Int,
            profileCompatibilityFlags: Data?,
            constraintIndicatorFlags: Data?,
            levelIndex: Int
        ) {
            self.temporalLayerID = temporalLayerID
            self.profileSpace = profileSpace
            self.tierFlag = tierFlag
            self.profileIndex = profileIndex
            self.profileCompatibilityFlags = profileCompatibilityFlags
            self.constraintIndicatorFlags = constraintIndicatorFlags
            self.levelIndex = levelIndex
        }
    }

    public struct SampleAttachments: Equatable {
        public var dictionaryRepresentation: [String: any Sendable]

        public init(_ dictionaryRepresentation: [String: any Sendable] = [:]) {
            self.dictionaryRepresentation = dictionaryRepresentation
        }

        public subscript(rawAttachment key: String) -> (any Sendable)? {
            get { dictionaryRepresentation[key] }
            set { dictionaryRepresentation[key] = newValue }
        }

        public subscript(_ key: String) -> (any Sendable)? {
            get { dictionaryRepresentation[key] }
            set { dictionaryRepresentation[key] = newValue }
        }

        public var doNotDisplay: Bool {
            get { bool(for: kCMSampleAttachmentKey_DoNotDisplay) ?? false }
            set { setBool(newValue, for: kCMSampleAttachmentKey_DoNotDisplay) }
        }

        public var displayImmediately: Bool {
            get { bool(for: kCMSampleAttachmentKey_DisplayImmediately) ?? false }
            set { setBool(newValue, for: kCMSampleAttachmentKey_DisplayImmediately) }
        }

        public var isNotSync: Bool {
            get { bool(for: kCMSampleAttachmentKey_NotSync) ?? false }
            set { setBool(newValue, for: kCMSampleAttachmentKey_NotSync) }
        }

        public var isPartialSync: Bool {
            get { bool(for: kCMSampleAttachmentKey_PartialSync) ?? false }
            set { setBool(newValue, for: kCMSampleAttachmentKey_PartialSync) }
        }

        public var dependsOnOthers: Bool? {
            get { bool(for: kCMSampleAttachmentKey_DependsOnOthers) }
            set { setOptionalBool(newValue, for: kCMSampleAttachmentKey_DependsOnOthers) }
        }

        public var isDependedOnByOthers: Bool? {
            get { bool(for: kCMSampleAttachmentKey_IsDependedOnByOthers) }
            set { setOptionalBool(newValue, for: kCMSampleAttachmentKey_IsDependedOnByOthers) }
        }

        public var hasRedundantCoding: Bool? {
            get { bool(for: kCMSampleAttachmentKey_HasRedundantCoding) }
            set { setOptionalBool(newValue, for: kCMSampleAttachmentKey_HasRedundantCoding) }
        }

        public var earlierDisplayTimesAllowed: Bool? {
            get { bool(for: kCMSampleAttachmentKey_EarlierDisplayTimesAllowed) }
            set { setOptionalBool(newValue, for: kCMSampleAttachmentKey_EarlierDisplayTimesAllowed) }
        }

        public var hevcTemporalSubLayerAccess: Bool {
            get { bool(for: kCMSampleAttachmentKey_HEVCTemporalSubLayerAccess) ?? false }
            set { setBool(newValue, for: kCMSampleAttachmentKey_HEVCTemporalSubLayerAccess) }
        }

        public var hevcStepwiseTemporalSubLayerAccess: Bool {
            get { bool(for: kCMSampleAttachmentKey_HEVCStepwiseTemporalSubLayerAccess) ?? false }
            set { setBool(newValue, for: kCMSampleAttachmentKey_HEVCStepwiseTemporalSubLayerAccess) }
        }

        public var hevcSyncSampleNALUnitType: Int? {
            get { dictionaryRepresentation[cmSampleKeyName(kCMSampleAttachmentKey_HEVCSyncSampleNALUnitType)] as? Int }
            set { dictionaryRepresentation[cmSampleKeyName(kCMSampleAttachmentKey_HEVCSyncSampleNALUnitType)] = newValue }
        }

        public var audioIndependentSampleDecoderRefreshCount: Int? {
            get { dictionaryRepresentation[cmSampleKeyName(kCMSampleAttachmentKey_AudioIndependentSampleDecoderRefreshCount)] as? Int }
            set { dictionaryRepresentation[cmSampleKeyName(kCMSampleAttachmentKey_AudioIndependentSampleDecoderRefreshCount)] = newValue }
        }

        public var hdr10PlusPerFrameData: Data? {
            get { dictionaryRepresentation[cmSampleKeyName(kCMSampleAttachmentKey_HDR10PlusPerFrameData)] as? Data }
            set { dictionaryRepresentation[cmSampleKeyName(kCMSampleAttachmentKey_HDR10PlusPerFrameData)] = newValue }
        }

        public var cryptorSubsampleAuxiliaryData: Data? {
            get { dictionaryRepresentation[cmSampleKeyName(kCMSampleAttachmentKey_CryptorSubsampleAuxiliaryData)] as? Data }
            set { dictionaryRepresentation[cmSampleKeyName(kCMSampleAttachmentKey_CryptorSubsampleAuxiliaryData)] = newValue }
        }

        public var hevcTemporalInfo: HEVCTemporalInfo? {
            get { dictionaryRepresentation["HEVCTemporalInfo"] as? HEVCTemporalInfo }
            set { dictionaryRepresentation["HEVCTemporalInfo"] = newValue }
        }

        public static func == (a: SampleAttachments, b: SampleAttachments) -> Bool {
            a.dictionaryRepresentation.keys.sorted() == b.dictionaryRepresentation.keys.sorted()
        }

        private func bool(for key: CFString) -> Bool? {
            dictionaryRepresentation[cmSampleKeyName(key)] as? Bool
        }

        private mutating func setBool(_ value: Bool, for key: CFString) {
            dictionaryRepresentation[cmSampleKeyName(key)] = value
        }

        private mutating func setOptionalBool(_ value: Bool?, for key: CFString) {
            dictionaryRepresentation[cmSampleKeyName(key)] = value
        }
    }

    public struct SampleProperties: Equatable {
        public var size: Int?
        public var timing: CMSampleTimingInfo
        public var attachments: SampleAttachments

        public init(
            size: Int? = nil,
            timing: CMSampleTimingInfo,
            attachments: SampleAttachments = .init()
        ) {
            self.size = size
            self.timing = timing
            self.attachments = attachments
        }
    }

    public struct SamplePropertiesCollection: Equatable, RandomAccessCollection, ExpressibleByArrayLiteral {
        public typealias Index = Int
        public typealias Element = SampleProperties
        public typealias Indices = Range<Int>
        public typealias Iterator = IndexingIterator<SamplePropertiesCollection>
        public typealias SubSequence = Slice<SamplePropertiesCollection>
        public typealias ArrayLiteralElement = SampleProperties

        public var sampleCount: Int
        public var sizes: SizePerSample?
        public var timings: TimingPerSample?
        public var attachments: [SampleAttachments]?
        private var items: [SampleProperties]

        public var startIndex: Int { 0 }
        public var endIndex: Int { items.count }
        public var count: Int { items.count }

        public init() {
            self.sampleCount = 0
            self.sizes = nil
            self.timings = nil
            self.attachments = nil
            self.items = []
        }

        public init(
            sampleCount: Int,
            sizes: SizePerSample?,
            timings: TimingPerSample?,
            attachments: [SampleAttachments]? = nil
        ) {
            self.sampleCount = sampleCount
            self.sizes = sizes
            self.timings = timings
            self.attachments = attachments
            self.items = (0..<Swift.max(0, sampleCount)).map { index in
                let size: Int? = {
                    switch sizes {
                    case .uniform(let value): return value
                    case .distinct(let values): return index < values.count ? values[index] : nil
                    case nil: return nil
                    }
                }()
                let timing: CMSampleTimingInfo = {
                    switch timings {
                    case .sequential(let start): return start
                    case .distinct(let values): return index < values.count ? values[index] : .invalid
                    case nil: return .invalid
                    }
                }()
                let attachment = attachments.flatMap { index < $0.count ? $0[index] : nil } ?? .init()
                return SampleProperties(size: size, timing: timing, attachments: attachment)
            }
        }

        public init(_ elements: some Collection<SampleProperties>) {
            self.items = Array(elements)
            self.sampleCount = items.count
            self.sizes = .distinct(items.map { $0.size ?? 0 })
            self.timings = .distinct(items.map(\.timing))
            self.attachments = items.map(\.attachments)
        }

        public init(arrayLiteral elements: SampleProperties...) {
            self.init(elements)
        }

        public subscript(position: Int) -> SampleProperties {
            get { items[position] }
            set { items[position] = newValue }
        }
    }

    public struct PerSampleAttachmentsDictionary: Sequence {
        public typealias Element = (key: Key, value: Any)

        public struct Key: RawRepresentable, Hashable {
            public typealias RawValue = CFString
            public var rawValue: CFString
            public init(rawValue: CFString) { self.rawValue = rawValue }

            public static func == (lhs: Key, rhs: Key) -> Bool {
                CFEqual(lhs.rawValue, rhs.rawValue)
            }

            public func hash(into hasher: inout Hasher) {
                hasher.combine(cmSampleKeyName(rawValue))
            }

            public static let audioIndependentSampleDecoderRefreshCount = Key(
                rawValue: kCMSampleAttachmentKey_AudioIndependentSampleDecoderRefreshCount
            )
            public static let hevcSyncSampleNALUnitType = Key(
                rawValue: kCMSampleAttachmentKey_HEVCSyncSampleNALUnitType
            )
            public static let partialSync = Key(rawValue: kCMSampleAttachmentKey_PartialSync)
            public static let doNotDisplay = Key(rawValue: kCMSampleAttachmentKey_DoNotDisplay)
            public static let dependsOnOthers = Key(rawValue: kCMSampleAttachmentKey_DependsOnOthers)
            public static let displayImmediately = Key(rawValue: kCMSampleAttachmentKey_DisplayImmediately)
            public static let hasRedundantCoding = Key(rawValue: kCMSampleAttachmentKey_HasRedundantCoding)
            public static let isDependedOnByOthers = Key(rawValue: kCMSampleAttachmentKey_IsDependedOnByOthers)
            public static let hevcTemporalLevelInfo = Key(rawValue: kCMSampleAttachmentKey_HEVCTemporalLevelInfo)
            public static let earlierDisplayTimesAllowed = Key(
                rawValue: kCMSampleAttachmentKey_EarlierDisplayTimesAllowed
            )
            public static let hevcTemporalSubLayerAccess = Key(
                rawValue: kCMSampleAttachmentKey_HEVCTemporalSubLayerAccess
            )
            public static let hevcStepwiseTemporalSubLayerAccess = Key(
                rawValue: kCMSampleAttachmentKey_HEVCStepwiseTemporalSubLayerAccess
            )
            public static let notSync = Key(rawValue: kCMSampleAttachmentKey_NotSync)
        }

        public struct Iterator: IteratorProtocol {
            public typealias Element = (key: Key, value: Any)
            fileprivate var pairs: [(Key, Any)]
            fileprivate var index = 0
            public mutating func next() -> (key: Key, value: Any)? {
                guard index < pairs.count else { return nil }
                let pair = pairs[index]
                index += 1
                return pair
            }
        }

        private var map: [String: Any] = [:]

        public init() {
            self.map = [:]
        }

        public subscript(key: Key) -> Any? {
            get { map[cmSampleKeyName(key.rawValue)] }
            set { map[cmSampleKeyName(key.rawValue)] = newValue }
        }

        public func makeIterator() -> Iterator {
            Iterator(pairs: map.map { (Key(rawValue: cmMakeCFString($0.key)), $0.value) })
        }
    }

    public struct SampleAttachmentsArray: RandomAccessCollection {
        public typealias Index = Int
        public typealias Element = PerSampleAttachmentsDictionary
        public typealias Indices = Range<Int>
        public typealias Iterator = IndexingIterator<SampleAttachmentsArray>
        public typealias SubSequence = Swift.Slice<SampleAttachmentsArray>

        public var startIndex: Int
        public var endIndex: Int
        private var items: [PerSampleAttachmentsDictionary]

        public init(count: Int) {
            self.startIndex = 0
            self.endIndex = count
            self.items = Array(repeating: PerSampleAttachmentsDictionary(), count: Swift.max(0, count))
        }

        public func index(after i: Int) -> Int { i + 1 }
        public func index(before i: Int) -> Int { i - 1 }

        public subscript(sample: Int) -> PerSampleAttachmentsDictionary {
            get { items[sample] }
            set { items[sample] = newValue }
        }
    }

    public struct NotificationKey: RawRepresentable, Hashable {
        public typealias RawValue = CFString
        public var rawValue: CFString
        public init(rawValue: CFString) { self.rawValue = rawValue }
        public static let status = NotificationKey(rawValue: kCMSampleBufferNotificationParameter_OSStatus)

        public static func == (lhs: NotificationKey, rhs: NotificationKey) -> Bool {
            CFEqual(lhs.rawValue, rhs.rawValue)
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(cmSampleKeyName(rawValue))
        }
    }

    public var contentType: ContentType {
        if dataBuffer != nil { return .dataBuffer }
        if numSamples == 0 { return .markerOnly }
        return .dataBuffer
    }

    public var dataReadiness: DataReadiness {
        if let failed = currentDataFailedStatus() { return .failed(failed) }
        return dataIsReady ? .ready : .notReady
    }

    public func setDataReadiness(_ newValue: DataReadiness) throws {
        switch newValue {
        case .ready:
            try makeDataReady()
        case .notReady:
            forceNotReady()
        case .failed(let status):
            applyDataFailed(status)
        }
    }

    public func trackDataReadiness(_ sampleBufferToTrack: CMSampleBuffer) throws {
        let status = CMSampleBufferTrackDataReadiness(self, sampleBufferToTrack: sampleBufferToTrack)
        if status != 0 { throw cmNSError(code: Int(status)) }
    }
}

internal func cmSampleKeyName(_ key: CFString) -> String {
    unsafeBitCast(key, to: NSString.self) as String
}
