import Foundation

public class SRKeyboardMetrics: NSObject {
    public enum SentimentCategory: Int, Hashable, Sendable {
        case absolutist = 0
        case down = 1
        case death = 2
        case anxiety = 3
        case anger = 4
        case health = 5
        case positive = 6
        case sad = 7
        case lowEnergy = 8
        case confused = 9
    }

    public class ProbabilityMetric<UnitType: Unit>: NSObject {
        public private(set) var distributionSampleValues: [Measurement<UnitType>]

        @_spi(OpenUIKitHost)
        public init(distributionSampleValues: [Measurement<UnitType>] = []) {
            self.distributionSampleValues = distributionSampleValues
            super.init()
        }
    }

    public private(set) var duration: TimeInterval
    public private(set) var height: Measurement<UnitLength>
    public private(set) var inputModes: [String]
    public private(set) var keyboardIdentifier: String
    public private(set) var sessionIdentifiers: [String]
    public private(set) var version: String
    public private(set) var width: Measurement<UnitLength>

    public private(set) var totalAlteredWords: Int
    public private(set) var totalAutoCorrections: Int
    public private(set) var totalDeletes: Int
    public private(set) var totalDrags: Int
    public private(set) var totalEmojis: Int
    public private(set) var totalHitTestCorrections: Int
    public private(set) var totalInsertKeyCorrections: Int
    public private(set) var totalNearKeyCorrections: Int
    public private(set) var totalPathLength: Measurement<UnitLength>
    public private(set) var totalPathPauses: Int
    public private(set) var totalPathTime: TimeInterval
    public private(set) var totalPaths: Int
    public private(set) var totalPauses: Int
    public private(set) var totalRetroCorrections: Int
    public private(set) var totalSkipTouchCorrections: Int
    public private(set) var totalSpaceCorrections: Int
    public private(set) var totalSubstitutionCorrections: Int
    public private(set) var totalTaps: Int
    public private(set) var totalTranspositionCorrections: Int
    public private(set) var totalTypingDuration: TimeInterval
    public private(set) var totalTypingEpisodes: Int
    public private(set) var totalWords: Int
    public private(set) var pathTypingSpeed: Double
    public private(set) var typingSpeed: Double
    public private(set) var pathErrorDistanceRatio: [NSNumber]

    public private(set) var anyTapToCharKey: ProbabilityMetric<UnitDuration>
    public private(set) var anyTapToPlaneChangeKey: ProbabilityMetric<UnitDuration>
    public private(set) var charKeyToAnyTapKey: ProbabilityMetric<UnitDuration>
    public private(set) var charKeyToDelete: ProbabilityMetric<UnitDuration>
    public private(set) var charKeyToPlaneChangeKey: ProbabilityMetric<UnitDuration>
    public private(set) var charKeyToPrediction: ProbabilityMetric<UnitDuration>
    public private(set) var charKeyToSpaceKey: ProbabilityMetric<UnitDuration>
    public private(set) var deleteDownErrorDistance: ProbabilityMetric<UnitLength>
    public private(set) var deleteToCharKey: ProbabilityMetric<UnitDuration>
    public private(set) var deleteToDelete: ProbabilityMetric<UnitDuration>
    public private(set) var deleteToDeletes: [ProbabilityMetric<UnitDuration>]
    public private(set) var deleteToPath: ProbabilityMetric<UnitDuration>
    public private(set) var deleteToPlaneChangeKey: ProbabilityMetric<UnitDuration>
    public private(set) var deleteToShiftKey: ProbabilityMetric<UnitDuration>
    public private(set) var deleteToSpaceKey: ProbabilityMetric<UnitDuration>
    public private(set) var deleteTouchDownUp: ProbabilityMetric<UnitDuration>
    public private(set) var deleteUpErrorDistance: ProbabilityMetric<UnitLength>
    public private(set) var downErrorDistance: ProbabilityMetric<UnitLength>
    public private(set) var longWordDownErrorDistance: [ProbabilityMetric<UnitLength>]
    public private(set) var longWordTouchDownDown: [ProbabilityMetric<UnitDuration>]
    public private(set) var longWordTouchDownUp: [ProbabilityMetric<UnitDuration>]
    public private(set) var longWordTouchUpDown: [ProbabilityMetric<UnitDuration>]
    public private(set) var longWordUpErrorDistance: [ProbabilityMetric<UnitLength>]
    public private(set) var pathToDelete: ProbabilityMetric<UnitDuration>
    public private(set) var pathToPath: ProbabilityMetric<UnitDuration>
    public private(set) var pathToSpace: ProbabilityMetric<UnitDuration>
    public private(set) var planeChangeKeyToCharKey: ProbabilityMetric<UnitDuration>
    public private(set) var planeChangeToAnyTap: ProbabilityMetric<UnitDuration>
    public private(set) var shortWordCharKeyDownErrorDistance: ProbabilityMetric<UnitLength>
    public private(set) var shortWordCharKeyToCharKey: ProbabilityMetric<UnitDuration>
    public private(set) var shortWordCharKeyTouchDownUp: ProbabilityMetric<UnitDuration>
    public private(set) var shortWordCharKeyUpErrorDistance: ProbabilityMetric<UnitLength>
    public private(set) var spaceDownErrorDistance: ProbabilityMetric<UnitLength>
    public private(set) var spaceToCharKey: ProbabilityMetric<UnitDuration>
    public private(set) var spaceToDeleteKey: ProbabilityMetric<UnitDuration>
    public private(set) var spaceToPath: ProbabilityMetric<UnitDuration>
    public private(set) var spaceToPlaneChangeKey: ProbabilityMetric<UnitDuration>
    public private(set) var spaceToPredictionKey: ProbabilityMetric<UnitDuration>
    public private(set) var spaceToShiftKey: ProbabilityMetric<UnitDuration>
    public private(set) var spaceToSpaceKey: ProbabilityMetric<UnitDuration>
    public private(set) var spaceTouchDownUp: ProbabilityMetric<UnitDuration>
    public private(set) var spaceUpErrorDistance: ProbabilityMetric<UnitLength>
    public private(set) var touchDownDown: ProbabilityMetric<UnitDuration>
    public private(set) var touchDownUp: ProbabilityMetric<UnitDuration>
    public private(set) var touchUpDown: ProbabilityMetric<UnitDuration>
    public private(set) var upErrorDistance: ProbabilityMetric<UnitLength>

    private let wordCounts: [SentimentCategory: Int]
    private let emojiCounts: [SentimentCategory: Int]

    public func emojiCount(for category: SentimentCategory) -> Int {
        emojiCounts[category] ?? 0
    }

    public func wordCount(for category: SentimentCategory) -> Int {
        wordCounts[category] ?? 0
    }

    @_spi(OpenUIKitHost)
    public init(
        keyboardIdentifier: String = "linux",
        version: String = "0",
        duration: TimeInterval = 0,
        width: Measurement<UnitLength> = Measurement(value: 0, unit: .meters),
        height: Measurement<UnitLength> = Measurement(value: 0, unit: .meters),
        inputModes: [String] = [],
        sessionIdentifiers: [String] = [],
        totalWords: Int = 0,
        totalAlteredWords: Int = 0,
        totalTaps: Int = 0,
        totalDrags: Int = 0,
        totalDeletes: Int = 0,
        totalEmojis: Int = 0,
        totalPaths: Int = 0,
        totalPathTime: TimeInterval = 0,
        totalPathLength: Measurement<UnitLength> = Measurement(value: 0, unit: .meters),
        totalAutoCorrections: Int = 0,
        totalSpaceCorrections: Int = 0,
        totalRetroCorrections: Int = 0,
        totalTranspositionCorrections: Int = 0,
        totalInsertKeyCorrections: Int = 0,
        totalSkipTouchCorrections: Int = 0,
        totalNearKeyCorrections: Int = 0,
        totalHitTestCorrections: Int = 0,
        totalSubstitutionCorrections: Int = 0,
        totalTypingDuration: TimeInterval = 0,
        totalTypingEpisodes: Int = 0,
        totalPauses: Int = 0,
        totalPathPauses: Int = 0,
        pathTypingSpeed: Double = 0,
        typingSpeed: Double = 0,
        pathErrorDistanceRatio: [NSNumber] = [],
        durationSamples: [Measurement<UnitDuration>] = [],
        lengthSamples: [Measurement<UnitLength>] = [],
        wordCounts: [SentimentCategory: Int] = [:],
        emojiCounts: [SentimentCategory: Int] = [:]
    ) {
        self.keyboardIdentifier = keyboardIdentifier
        self.version = version
        self.duration = duration
        self.width = width
        self.height = height
        self.inputModes = inputModes
        self.sessionIdentifiers = sessionIdentifiers
        self.totalWords = totalWords
        self.totalAlteredWords = totalAlteredWords
        self.totalTaps = totalTaps
        self.totalDrags = totalDrags
        self.totalDeletes = totalDeletes
        self.totalEmojis = totalEmojis
        self.totalPaths = totalPaths
        self.totalPathTime = totalPathTime
        self.totalPathLength = totalPathLength
        self.totalAutoCorrections = totalAutoCorrections
        self.totalSpaceCorrections = totalSpaceCorrections
        self.totalRetroCorrections = totalRetroCorrections
        self.totalTranspositionCorrections = totalTranspositionCorrections
        self.totalInsertKeyCorrections = totalInsertKeyCorrections
        self.totalSkipTouchCorrections = totalSkipTouchCorrections
        self.totalNearKeyCorrections = totalNearKeyCorrections
        self.totalHitTestCorrections = totalHitTestCorrections
        self.totalSubstitutionCorrections = totalSubstitutionCorrections
        self.totalTypingDuration = totalTypingDuration
        self.totalTypingEpisodes = totalTypingEpisodes
        self.totalPauses = totalPauses
        self.totalPathPauses = totalPathPauses
        self.pathTypingSpeed = pathTypingSpeed
        self.typingSpeed = typingSpeed
        self.pathErrorDistanceRatio = pathErrorDistanceRatio
        self.wordCounts = wordCounts
        self.emojiCounts = emojiCounts

        let durationMetric = ProbabilityMetric<UnitDuration>(distributionSampleValues: durationSamples)
        let lengthMetric = ProbabilityMetric<UnitLength>(distributionSampleValues: lengthSamples)
        self.anyTapToCharKey = durationMetric
        self.anyTapToPlaneChangeKey = durationMetric
        self.charKeyToAnyTapKey = durationMetric
        self.charKeyToDelete = durationMetric
        self.charKeyToPlaneChangeKey = durationMetric
        self.charKeyToPrediction = durationMetric
        self.charKeyToSpaceKey = durationMetric
        self.deleteDownErrorDistance = lengthMetric
        self.deleteToCharKey = durationMetric
        self.deleteToDelete = durationMetric
        self.deleteToDeletes = [durationMetric]
        self.deleteToPath = durationMetric
        self.deleteToPlaneChangeKey = durationMetric
        self.deleteToShiftKey = durationMetric
        self.deleteToSpaceKey = durationMetric
        self.deleteTouchDownUp = durationMetric
        self.deleteUpErrorDistance = lengthMetric
        self.downErrorDistance = lengthMetric
        self.longWordDownErrorDistance = [lengthMetric]
        self.longWordTouchDownDown = [durationMetric]
        self.longWordTouchDownUp = [durationMetric]
        self.longWordTouchUpDown = [durationMetric]
        self.longWordUpErrorDistance = [lengthMetric]
        self.pathToDelete = durationMetric
        self.pathToPath = durationMetric
        self.pathToSpace = durationMetric
        self.planeChangeKeyToCharKey = durationMetric
        self.planeChangeToAnyTap = durationMetric
        self.shortWordCharKeyDownErrorDistance = lengthMetric
        self.shortWordCharKeyToCharKey = durationMetric
        self.shortWordCharKeyTouchDownUp = durationMetric
        self.shortWordCharKeyUpErrorDistance = lengthMetric
        self.spaceDownErrorDistance = lengthMetric
        self.spaceToCharKey = durationMetric
        self.spaceToDeleteKey = durationMetric
        self.spaceToPath = durationMetric
        self.spaceToPlaneChangeKey = durationMetric
        self.spaceToPredictionKey = durationMetric
        self.spaceToShiftKey = durationMetric
        self.spaceToSpaceKey = durationMetric
        self.spaceTouchDownUp = durationMetric
        self.spaceUpErrorDistance = lengthMetric
        self.touchDownDown = durationMetric
        self.touchDownUp = durationMetric
        self.touchUpDown = durationMetric
        self.upErrorDistance = lengthMetric
        super.init()
    }
}
