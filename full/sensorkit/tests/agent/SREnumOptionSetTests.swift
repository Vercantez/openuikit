import Foundation
@_spi(OpenUIKitHost) import SensorKit

func testLocationAndTextInputEnums() {
    let locations: [(SRVisit.LocationCategory, Int)] = [
        (.unknown, 0), (.home, 1), (.work, 2), (.school, 3), (.gym, 4),
    ]
    for (value, raw) in locations {
        skExpect(value.rawValue == raw, "loc \(raw)")
        skExpect(SRVisit.LocationCategory(rawValue: raw) == value, "rt")
        skExpect(value != .gym || raw == 4, "!=")
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }

    let events: [(SRDeviceUsageReport.NotificationUsage.Event, Int)] = [
        (.unknown, 0), (.received, 1), (.defaultAction, 2), (.supplementaryAction, 3),
        (.clear, 4), (.notificationCenterClearAll, 5), (.removed, 6), (.hide, 7),
        (.longLook, 8), (.silence, 9), (.appLaunch, 10), (.expired, 11),
        (.bannerPulldown, 12), (.tapCoalesce, 13), (.deduped, 14),
        (.deviceActivated, 15), (.deviceUnlocked, 16),
    ]
    for (value, raw) in events {
        skExpect(value.rawValue == raw, "event \(raw)")
        skExpect(SRDeviceUsageReport.NotificationUsage.Event(rawValue: raw) == value, "rt")
        skExpect(value != .clear || raw == 4, "!=")
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }

    let sessions: [(SRTextInputSession.SessionType, Int)] = [
        (.keyboard, 1), (.thirdPartyKeyboard, 2), (.pencil, 3), (.dictation, 4),
    ]
    for (value, raw) in sessions {
        skExpect(value.rawValue == raw, "session \(raw)")
        skExpect(SRTextInputSession.SessionType(rawValue: raw) == value, "rt")
        skExpect(value != .pencil || raw == 3, "!=")
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
}

func testKeyboardSentimentCategory() {
    let rows: [(SRKeyboardMetrics.SentimentCategory, Int)] = [
        (.absolutist, 0), (.down, 1), (.death, 2), (.anxiety, 3), (.anger, 4),
        (.health, 5), (.positive, 6), (.sad, 7), (.lowEnergy, 8), (.confused, 9),
    ]
    for (value, raw) in rows {
        skExpect(value.rawValue == raw, "sent \(raw)")
        skExpect(SRKeyboardMetrics.SentimentCategory(rawValue: raw) == value, "rt")
        skExpect(value != .anger || raw == 4, "!=")
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
}

func testFaceMetricsContext() {
    var context: SRFaceMetrics.Context = []
    skExpect(context.isEmpty, "empty")
    skExpect(SRFaceMetrics.Context.deviceUnlock.rawValue == 1, "unlock")
    skExpect(SRFaceMetrics.Context.messagingAppUsage.rawValue == 2, "msg")
    context.insert(.deviceUnlock)
    skExpect(context.contains(.deviceUnlock), "contains")
    context.formUnion(.messagingAppUsage)
    skExpect(context.union(.deviceUnlock).contains(.messagingAppUsage), "union")
    skExpect(context.intersection(.deviceUnlock) == .deviceUnlock, "inter")
    skExpect(context.subtracting(.messagingAppUsage) == .deviceUnlock, "sub")
    var mut = context
    mut.subtract(.deviceUnlock)
    skExpect(mut == .messagingAppUsage, "subtract")
    var form = SRFaceMetrics.Context.deviceUnlock
    form.formIntersection(.deviceUnlock)
    form.formSymmetricDifference(.messagingAppUsage)
    let seq = SRFaceMetrics.Context([.deviceUnlock])
    skExpect(seq.contains(.deviceUnlock), "seq")
    let literal: SRFaceMetrics.Context = [.messagingAppUsage]
    skExpect(literal.contains(.messagingAppUsage), "lit")
    skExpect(SRFaceMetrics.Context().isEmpty, "init")
    skExpect(SRFaceMetrics.Context.deviceUnlock != .messagingAppUsage, "!=")
    skExpect(context.isSuperset(of: .messagingAppUsage), "super")
    skExpect(context.isSubset(of: [.deviceUnlock, .messagingAppUsage]), "subset")
    skExpect(!context.isDisjoint(with: .deviceUnlock), "disjoint")
    skExpect(SRFaceMetrics.Context.deviceUnlock.isStrictSubset(of: context) || context.contains(.deviceUnlock), "strict")
    skExpect(context.isStrictSuperset(of: .deviceUnlock), "strict super")
    _ = context.remove(.deviceUnlock)
    _ = context.update(with: .deviceUnlock)
}

func testSpeechSessionFlags() {
    var flags: SRSpeechMetrics.SessionFlags = []
    skExpect(flags.isEmpty, "empty")
    skExpect(SRSpeechMetrics.SessionFlags.bypassVoiceProcessing.rawValue == 1, "bypass")
    flags.insert(.bypassVoiceProcessing)
    skExpect(flags.contains(.bypassVoiceProcessing), "contains")
    skExpect(flags.union(.bypassVoiceProcessing) == .bypassVoiceProcessing, "union")
    skExpect(flags.intersection(.bypassVoiceProcessing) == .bypassVoiceProcessing, "inter")
    skExpect(flags.symmetricDifference(.bypassVoiceProcessing).isEmpty, "sym")
    skExpect(flags.subtracting(.bypassVoiceProcessing).isEmpty, "sub")
    var mut = flags
    mut.subtract(.bypassVoiceProcessing)
    skExpect(mut.isEmpty, "subtract")
    var form = SRSpeechMetrics.SessionFlags.bypassVoiceProcessing
    form.formIntersection(.bypassVoiceProcessing)
    form.formSymmetricDifference([])
    let seq = SRSpeechMetrics.SessionFlags([.bypassVoiceProcessing])
    skExpect(seq.contains(.bypassVoiceProcessing), "seq")
    let literal: SRSpeechMetrics.SessionFlags = [.bypassVoiceProcessing]
    skExpect(literal.contains(.bypassVoiceProcessing), "lit")
    skExpect(SRSpeechMetrics.SessionFlags().isEmpty, "init")
    skExpect(flags.isSuperset(of: .bypassVoiceProcessing), "super")
    skExpect(flags.isSubset(of: .bypassVoiceProcessing), "subset")
    skExpect(flags.isDisjoint(with: []), "disjoint")
    skExpect(!flags.isStrictSubset(of: .bypassVoiceProcessing), "strict")
    skExpect(!flags.isStrictSuperset(of: .bypassVoiceProcessing), "strict super")
    _ = flags.remove(.bypassVoiceProcessing)
    _ = flags.update(with: .bypassVoiceProcessing)
    skExpect(SRSpeechMetrics.SessionFlags.bypassVoiceProcessing != [], "!=")
}
