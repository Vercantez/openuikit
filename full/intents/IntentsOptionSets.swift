// Generated Intents option-set overlays (NS_OPTIONS) from the public surface.

public struct INCallCapabilityOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let audioCall = INCallCapabilityOptions(rawValue: 1)
    public static let videoCall = INCallCapabilityOptions(rawValue: 2)
}

public struct INCallRecordTypeOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let inProgress = INCallRecordTypeOptions(rawValue: 64)
    public static let latest = INCallRecordTypeOptions(rawValue: 8)
    public static let missed = INCallRecordTypeOptions(rawValue: 2)
    public static let onHold = INCallRecordTypeOptions(rawValue: 128)
    public static let outgoing = INCallRecordTypeOptions(rawValue: 1)
    public static let received = INCallRecordTypeOptions(rawValue: 4)
    public static let ringing = INCallRecordTypeOptions(rawValue: 32)
    public static let voicemail = INCallRecordTypeOptions(rawValue: 16)
}

public struct INCarSignalOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let audible = INCarSignalOptions(rawValue: 1)
    public static let visible = INCarSignalOptions(rawValue: 2)
}

public struct INDayOfWeekOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let friday = INDayOfWeekOptions(rawValue: 4)
    public static let monday = INDayOfWeekOptions(rawValue: 0)
    public static let saturday = INDayOfWeekOptions(rawValue: 5)
    public static let sunday = INDayOfWeekOptions(rawValue: 6)
    public static let thursday = INDayOfWeekOptions(rawValue: 3)
    public static let tuesday = INDayOfWeekOptions(rawValue: 1)
    public static let wednesday = INDayOfWeekOptions(rawValue: 2)
}

public struct INMessageAttributeOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let flagged = INMessageAttributeOptions(rawValue: 4)
    public static let played = INMessageAttributeOptions(rawValue: 9)
    public static let read = INMessageAttributeOptions(rawValue: 1)
    public static let unflagged = INMessageAttributeOptions(rawValue: 8)
    public static let unread = INMessageAttributeOptions(rawValue: 2)
}

public struct INPhotoAttributeOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let bouncePhoto = INPhotoAttributeOptions(rawValue: 8388612)
    public static let burstPhoto = INPhotoAttributeOptions(rawValue: 1024)
    public static let chromeFilter = INPhotoAttributeOptions(rawValue: 131072)
    public static let fadeFilter = INPhotoAttributeOptions(rawValue: 4194304)
    public static let favorite = INPhotoAttributeOptions(rawValue: 64)
    public static let flash = INPhotoAttributeOptions(rawValue: 8)
    public static let frontFacingCamera = INPhotoAttributeOptions(rawValue: 256)
    public static let GIF = INPhotoAttributeOptions(rawValue: 0)
    public static let hdrPhoto = INPhotoAttributeOptions(rawValue: 2048)
    public static let instantFilter = INPhotoAttributeOptions(rawValue: 262144)
    public static let landscapeOrientation = INPhotoAttributeOptions(rawValue: 16)
    public static let livePhoto = INPhotoAttributeOptions(rawValue: 8388610)
    public static let longExposurePhoto = INPhotoAttributeOptions(rawValue: 8388613)
    public static let loopPhoto = INPhotoAttributeOptions(rawValue: 8388611)
    public static let monoFilter = INPhotoAttributeOptions(rawValue: 2097152)
    public static let noirFilter = INPhotoAttributeOptions(rawValue: 65536)
    public static let panoramaPhoto = INPhotoAttributeOptions(rawValue: 8192)
    public static let photo = INPhotoAttributeOptions(rawValue: 1)
    public static let portraitOrientation = INPhotoAttributeOptions(rawValue: 32)
    public static let portraitPhoto = INPhotoAttributeOptions(rawValue: 8388609)
    public static let processFilter = INPhotoAttributeOptions(rawValue: 8388608)
    public static let screenshot = INPhotoAttributeOptions(rawValue: 512)
    public static let selfie = INPhotoAttributeOptions(rawValue: 128)
    public static let slowMotionVideo = INPhotoAttributeOptions(rawValue: 32768)
    public static let squarePhoto = INPhotoAttributeOptions(rawValue: 4096)
    public static let timeLapseVideo = INPhotoAttributeOptions(rawValue: 16384)
    public static let tonalFilter = INPhotoAttributeOptions(rawValue: 524288)
    public static let transferFilter = INPhotoAttributeOptions(rawValue: 1048576)
    public static let video = INPhotoAttributeOptions(rawValue: 2)
}

public struct INRideFeedbackTypeOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let rate = INRideFeedbackTypeOptions(rawValue: 1)
    public static let tip = INRideFeedbackTypeOptions(rawValue: 2)
}

public struct INShortcutAvailabilityOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let sleepJournaling = INShortcutAvailabilityOptions(rawValue: 0)
    public static let sleepMindfulness = INShortcutAvailabilityOptions(rawValue: 0)
    public static let sleepMusic = INShortcutAvailabilityOptions(rawValue: 0)
    public static let sleepPodcasts = INShortcutAvailabilityOptions(rawValue: 0)
    public static let sleepReading = INShortcutAvailabilityOptions(rawValue: 0)
    public static let sleepWrapUpYourDay = INShortcutAvailabilityOptions(rawValue: 0)
    public static let sleepYogaAndStretching = INShortcutAvailabilityOptions(rawValue: 0)
}

public struct INTemporalEventTriggerTypeOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let notScheduled = INTemporalEventTriggerTypeOptions(rawValue: 0)
    public static let scheduledNonRecurring = INTemporalEventTriggerTypeOptions(rawValue: 1)
    public static let scheduledRecurring = INTemporalEventTriggerTypeOptions(rawValue: 2)
}
