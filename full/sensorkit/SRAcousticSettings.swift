import Foundation

public class SRAcousticSettings: NSObject {
    public enum SampleLifetime: Int, Hashable, Sendable {
        case eightDays = 1
        case untilUserDeletes = 2
    }

    public class Accessibility: NSObject {
        public class BackgroundSounds: NSObject {
            public enum Name: Int, Hashable, Sendable {
                case balancedNoise = 1
                case brightNoise = 2
                case darkNoise = 3
                case ocean = 4
                case rain = 5
                case stream = 6
                case night = 7
                case fire = 8
                case babble = 9
                case steam = 10
                case airplane = 11
                case boat = 12
                case bus = 13
                case train = 14
                case rainOnRoof = 15
                case quietNight = 16
            }

            public private(set) var isEnabled: Bool
            public private(set) var isPlayWithMediaEnabled: Bool
            public private(set) var isStopOnLockEnabled: Bool
            public private(set) var relativeVolume: Double
            public private(set) var relativeVolumeWithMedia: Double
            public private(set) var soundName: Name

            @_spi(OpenUIKitHost)
            public init(
                isEnabled: Bool = false,
                isPlayWithMediaEnabled: Bool = false,
                isStopOnLockEnabled: Bool = false,
                relativeVolume: Double = 0,
                relativeVolumeWithMedia: Double = 0,
                soundName: Name = .balancedNoise
            ) {
                self.isEnabled = isEnabled
                self.isPlayWithMediaEnabled = isPlayWithMediaEnabled
                self.isStopOnLockEnabled = isStopOnLockEnabled
                self.relativeVolume = relativeVolume
                self.relativeVolumeWithMedia = relativeVolumeWithMedia
                self.soundName = soundName
                super.init()
            }
        }

        public class HeadphoneAccommodations: NSObject {
            public enum MediaEnhanceApplication: Int, Hashable, Sendable {
                case none = 1
                case phone = 2
                case media = 3
                case phoneAndMedia = 4
            }

            public enum MediaEnhanceBoosting: Int, Hashable, Sendable {
                case slight = 1
                case moderate = 2
                case strong = 3
            }

            public enum MediaEnhanceTuning: Int, Hashable, Sendable {
                case balancedTone = 1
                case vocalRange = 2
                case brightness = 3
            }

            public private(set) var isEnabled: Bool
            public private(set) var mediaEnhanceApplication: MediaEnhanceApplication
            public private(set) var mediaEnhanceBoosting: MediaEnhanceBoosting
            public private(set) var mediaEnhanceTuning: MediaEnhanceTuning

            @_spi(OpenUIKitHost)
            public init(
                isEnabled: Bool = false,
                mediaEnhanceApplication: MediaEnhanceApplication = .none,
                mediaEnhanceBoosting: MediaEnhanceBoosting = .slight,
                mediaEnhanceTuning: MediaEnhanceTuning = .balancedTone
            ) {
                self.isEnabled = isEnabled
                self.mediaEnhanceApplication = mediaEnhanceApplication
                self.mediaEnhanceBoosting = mediaEnhanceBoosting
                self.mediaEnhanceTuning = mediaEnhanceTuning
                super.init()
            }
        }

        public private(set) var backgroundSounds: BackgroundSounds
        public private(set) var headphoneAccommodations: HeadphoneAccommodations
        public private(set) var leftRightBalance: Double
        public private(set) var isMonoAudioEnabled: Bool

        @_spi(OpenUIKitHost)
        public init(
            backgroundSounds: BackgroundSounds = BackgroundSounds(),
            headphoneAccommodations: HeadphoneAccommodations = HeadphoneAccommodations(),
            leftRightBalance: Double = 0,
            isMonoAudioEnabled: Bool = false
        ) {
            self.backgroundSounds = backgroundSounds
            self.headphoneAccommodations = headphoneAccommodations
            self.leftRightBalance = leftRightBalance
            self.isMonoAudioEnabled = isMonoAudioEnabled
            super.init()
        }
    }

    public class MusicEQ: NSObject {
        public private(set) var isLateNightModeEnabled: Bool
        public private(set) var isSoundCheckEnabled: Bool

        @_spi(OpenUIKitHost)
        public init(isLateNightModeEnabled: Bool = false, isSoundCheckEnabled: Bool = false) {
            self.isLateNightModeEnabled = isLateNightModeEnabled
            self.isSoundCheckEnabled = isSoundCheckEnabled
            super.init()
        }
    }

    public private(set) var accessibilitySettings: Accessibility
    public private(set) var audioExposureSampleLifetime: SampleLifetime
    public private(set) var isEnvironmentalSoundMeasurementsEnabled: Bool
    public private(set) var musicEQSettings: MusicEQ
    public private(set) var headphoneSafetyAudioLevel: Double?

    @_spi(OpenUIKitHost)
    public init(
        accessibilitySettings: Accessibility = Accessibility(),
        audioExposureSampleLifetime: SampleLifetime = .eightDays,
        isEnvironmentalSoundMeasurementsEnabled: Bool = false,
        musicEQSettings: MusicEQ = MusicEQ(),
        headphoneSafetyAudioLevel: Double? = nil
    ) {
        self.accessibilitySettings = accessibilitySettings
        self.audioExposureSampleLifetime = audioExposureSampleLifetime
        self.isEnvironmentalSoundMeasurementsEnabled = isEnvironmentalSoundMeasurementsEnabled
        self.musicEQSettings = musicEQSettings
        self.headphoneSafetyAudioLevel = headphoneSafetyAudioLevel
        super.init()
    }
}
