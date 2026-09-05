import Foundation
@_spi(OpenUIKitHost) import SensorKit

func testAcousticSettingsEnums() {
    skExpect(SRAcousticSettings.SampleLifetime.eightDays.rawValue == 1, "eightDays")
    skExpect(SRAcousticSettings.SampleLifetime.untilUserDeletes.rawValue == 2, "untilUserDeletes")
    skExpect(SRAcousticSettings.SampleLifetime(rawValue: 1) == .eightDays, "round-trip")
    skExpect(SRAcousticSettings.SampleLifetime.eightDays != .untilUserDeletes, "!=")
    _ = SRAcousticSettings.SampleLifetime.eightDays.hashValue
    var hasher = Hasher()
    SRAcousticSettings.SampleLifetime.untilUserDeletes.hash(into: &hasher)
    _ = hasher.finalize()

    let names: [(SRAcousticSettings.Accessibility.BackgroundSounds.Name, Int)] = [
        (.balancedNoise, 1), (.brightNoise, 2), (.darkNoise, 3), (.ocean, 4),
        (.rain, 5), (.stream, 6), (.night, 7), (.fire, 8), (.babble, 9),
        (.steam, 10), (.airplane, 11), (.boat, 12), (.bus, 13), (.train, 14),
        (.rainOnRoof, 15), (.quietNight, 16),
    ]
    for (name, raw) in names {
        skExpect(name.rawValue == raw, "sound \(raw)")
        skExpect(SRAcousticSettings.Accessibility.BackgroundSounds.Name(rawValue: raw) == name, "rt")
        skExpect(name != .ocean || raw == 4, "!=")
        _ = name.hashValue
        var hasher = Hasher()
        name.hash(into: &hasher)
        _ = hasher.finalize()
    }

    let apps: [(SRAcousticSettings.Accessibility.HeadphoneAccommodations.MediaEnhanceApplication, Int)] = [
        (.none, 1), (.phone, 2), (.media, 3), (.phoneAndMedia, 4),
    ]
    for (value, raw) in apps {
        skExpect(value.rawValue == raw, "app \(raw)")
        skExpect(type(of: value).init(rawValue: raw) == value, "rt")
        skExpect(value != .media || raw == 3, "!=")
        _ = value.hashValue
        var h = Hasher()
        value.hash(into: &h)
        _ = h.finalize()
    }

    let boosts: [(SRAcousticSettings.Accessibility.HeadphoneAccommodations.MediaEnhanceBoosting, Int)] = [
        (.slight, 1), (.moderate, 2), (.strong, 3),
    ]
    for (value, raw) in boosts {
        skExpect(value.rawValue == raw, "boost \(raw)")
        skExpect(type(of: value).init(rawValue: raw) == value, "rt")
        skExpect(value != .strong || raw == 3, "!=")
        _ = value.hashValue
        var h = Hasher()
        value.hash(into: &h)
        _ = h.finalize()
    }

    let tunings: [(SRAcousticSettings.Accessibility.HeadphoneAccommodations.MediaEnhanceTuning, Int)] = [
        (.balancedTone, 1), (.vocalRange, 2), (.brightness, 3),
    ]
    for (value, raw) in tunings {
        skExpect(value.rawValue == raw, "tuning \(raw)")
        skExpect(type(of: value).init(rawValue: raw) == value, "rt")
        skExpect(value != .brightness || raw == 3, "!=")
        _ = value.hashValue
        var h = Hasher()
        value.hash(into: &h)
        _ = h.finalize()
    }
}

func testAcousticSettingsGetters() {
    let sounds = SRAcousticSettings.Accessibility.BackgroundSounds(
        isEnabled: true,
        isPlayWithMediaEnabled: true,
        isStopOnLockEnabled: true,
        relativeVolume: 0.4,
        relativeVolumeWithMedia: 0.2,
        soundName: .rain
    )
    skExpect(sounds.isEnabled, "enabled")
    skExpect(sounds.isPlayWithMediaEnabled, "playWithMedia")
    skExpect(sounds.isStopOnLockEnabled, "stopOnLock")
    skExpect(sounds.relativeVolume == 0.4, "volume")
    skExpect(sounds.relativeVolumeWithMedia == 0.2, "volumeMedia")
    skExpect(sounds.soundName == .rain, "name")

    let headphones = SRAcousticSettings.Accessibility.HeadphoneAccommodations(
        isEnabled: true,
        mediaEnhanceApplication: .phoneAndMedia,
        mediaEnhanceBoosting: .moderate,
        mediaEnhanceTuning: .vocalRange
    )
    skExpect(headphones.isEnabled, "hp enabled")
    skExpect(headphones.mediaEnhanceApplication == .phoneAndMedia, "app")
    skExpect(headphones.mediaEnhanceBoosting == .moderate, "boost")
    skExpect(headphones.mediaEnhanceTuning == .vocalRange, "tune")

    let accessibility = SRAcousticSettings.Accessibility(
        backgroundSounds: sounds,
        headphoneAccommodations: headphones,
        leftRightBalance: 0.1,
        isMonoAudioEnabled: true
    )
    skExpect(accessibility.leftRightBalance == 0.1, "balance")
    skExpect(accessibility.isMonoAudioEnabled, "mono")
    skExpect(accessibility.backgroundSounds.soundName == .rain, "nested sounds")
    skExpect(accessibility.headphoneAccommodations.isEnabled, "nested hp")

    let eq = SRAcousticSettings.MusicEQ(isLateNightModeEnabled: true, isSoundCheckEnabled: true)
    skExpect(eq.isLateNightModeEnabled, "late night")
    skExpect(eq.isSoundCheckEnabled, "sound check")

    let settings = SRAcousticSettings(
        accessibilitySettings: accessibility,
        audioExposureSampleLifetime: .untilUserDeletes,
        isEnvironmentalSoundMeasurementsEnabled: true,
        musicEQSettings: eq,
        headphoneSafetyAudioLevel: 0.5
    )
    skExpect(settings.audioExposureSampleLifetime == .untilUserDeletes, "lifetime")
    skExpect(settings.isEnvironmentalSoundMeasurementsEnabled, "env")
    skExpect(settings.headphoneSafetyAudioLevel == 0.5, "safety")
    skExpect(settings.musicEQSettings.isSoundCheckEnabled, "eq")
    skExpect(settings.accessibilitySettings.isMonoAudioEnabled, "acc")
}
