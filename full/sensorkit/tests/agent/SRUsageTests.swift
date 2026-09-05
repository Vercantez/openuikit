import Foundation
@_spi(OpenUIKitHost) import SensorKit

func testDeviceUsageReport() {
    let app = SRDeviceUsageReport.ApplicationUsage(
        bundleIdentifier: "com.example.app",
        relativeStartTime: 1.5,
        reportApplicationIdentifier: "rpt",
        supplementalCategories: [SRSupplementalCategory(identifier: "cat")],
        textInputSessions: [SRTextInputSession(duration: 1, sessionIdentifier: "t", sessionType: .keyboard)],
        usageTime: 12
    )
    skExpect(app.bundleIdentifier == "com.example.app", "bundle")
    skExpect(app.relativeStartTime == 1.5, "rel")
    skExpect(app.reportApplicationIdentifier == "rpt", "rpt")
    skExpect(app.supplementalCategories.count == 1, "supp")
    skExpect(app.textInputSessions.count == 1, "text")
    skExpect(app.usageTime == 12, "usage")

    let note = SRDeviceUsageReport.NotificationUsage(bundleIdentifier: "com.notify", event: .received)
    skExpect(note.bundleIdentifier == "com.notify", "note bundle")
    skExpect(note.event == .received, "event")

    let web = SRDeviceUsageReport.WebUsage(totalUsageTime: 8)
    skExpect(web.totalUsageTime == 8, "web")

    let report = SRDeviceUsageReport(
        applicationUsageByCategory: [.games: [app]],
        duration: 100,
        notificationUsageByCategory: [.socialNetworking: [note]],
        totalScreenWakes: 4,
        totalUnlockDuration: 50,
        totalUnlocks: 3,
        version: "v1",
        webUsageByCategory: [.news: [web]]
    )
    skExpect(report.applicationUsageByCategory[.games]?.first?.usageTime == 12, "app cat")
    skExpect(report.duration == 100, "dur")
    skExpect(report.notificationUsageByCategory[.socialNetworking]?.first?.event == .received, "note cat")
    skExpect(report.totalScreenWakes == 4, "wakes")
    skExpect(report.totalUnlockDuration == 50, "unlock dur")
    skExpect(report.totalUnlocks == 3, "unlocks")
    skExpect(report.version == "v1", "ver")
    skExpect(report.webUsageByCategory[.news]?.first?.totalUsageTime == 8, "web cat")
}

func testMessagesPhoneMediaVisit() {
    let messages = SRMessagesUsageReport(
        duration: 10,
        totalIncomingMessages: 2,
        totalOutgoingMessages: 3,
        totalUniqueContacts: 4
    )
    skExpect(messages.duration == 10, "dur")
    skExpect(messages.totalIncomingMessages == 2, "in")
    skExpect(messages.totalOutgoingMessages == 3, "out")
    skExpect(messages.totalUniqueContacts == 4, "uniq")

    let phone = SRPhoneUsageReport(
        duration: 20,
        totalIncomingCalls: 1,
        totalOutgoingCalls: 2,
        totalPhoneCallDuration: 30,
        totalUniqueContacts: 5
    )
    skExpect(phone.duration == 20, "pdur")
    skExpect(phone.totalIncomingCalls == 1, "pin")
    skExpect(phone.totalOutgoingCalls == 2, "pout")
    skExpect(phone.totalPhoneCallDuration == 30, "calldur")
    skExpect(phone.totalUniqueContacts == 5, "puni")

    let media = SRMediaEvent(eventType: .onScreen, mediaIdentifier: "m1")
    skExpect(media.eventType == .onScreen, "type")
    skExpect(media.mediaIdentifier == "m1", "id")

    let arrival = DateInterval(start: Date(timeIntervalSinceReferenceDate: 0), duration: 10)
    let departure = DateInterval(start: Date(timeIntervalSinceReferenceDate: 20), duration: 5)
    let visit = SRVisit(
        arrivalDateInterval: arrival,
        departureDateInterval: departure,
        distanceFromHome: 1500,
        identifier: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        locationCategory: .home
    )
    skExpect(visit.arrivalDateInterval.duration == 10, "arr")
    skExpect(visit.departureDateInterval.duration == 5, "dep")
    skExpect(visit.distanceFromHome == 1500, "dist")
    skExpect(visit.identifier.uuidString == "00000000-0000-0000-0000-000000000001", "uuid")
    skExpect(visit.locationCategory == .home, "cat")
}

func testSpeechAndFaceMetrics() {
    let level = SRAudioLevel(loudness: -12)
    skExpect(level.loudness == -12, "loud")

    let expression = SRSpeechExpression(
        activation: 0.1,
        confidence: 0.2,
        dominance: 0.3,
        mood: 0.4,
        valence: 0.5,
        version: "1"
    )
    skExpect(expression.activation == 0.1, "act")
    skExpect(expression.confidence == 0.2, "conf")
    skExpect(expression.dominance == 0.3, "dom")
    skExpect(expression.mood == 0.4, "mood")
    skExpect(expression.valence == 0.5, "val")
    skExpect(expression.version == "1", "ver")

    let metrics = SRSpeechMetrics(
        audioLevel: level,
        sessionFlags: .bypassVoiceProcessing,
        sessionIdentifier: "sid",
        speechExpression: expression,
        timeSinceAudioStart: 1.25,
        timestamp: Date(timeIntervalSinceReferenceDate: 8)
    )
    skExpect(metrics.audioLevel?.loudness == -12, "al")
    skExpect(metrics.sessionFlags.contains(.bypassVoiceProcessing), "flags")
    skExpect(metrics.sessionIdentifier == "sid", "sid")
    skExpect(metrics.speechExpression?.mood == 0.4, "expr")
    skExpect(metrics.timeSinceAudioStart == 1.25, "since")
    skExpect(metrics.timestamp.timeIntervalSinceReferenceDate == 8, "ts")

    let faceExpr = SRFaceMetricsExpression(identifier: "smile", value: 0.9)
    skExpect(faceExpr.identifier == "smile", "fid")
    skExpect(faceExpr.value == 0.9, "fv")

    let face = SRFaceMetrics(
        context: [.deviceUnlock],
        partialFaceExpressions: [faceExpr],
        sessionIdentifier: "face",
        version: "2",
        wholeFaceExpressions: [faceExpr]
    )
    skExpect(face.context.contains(.deviceUnlock), "ctx")
    skExpect(face.partialFaceExpressions.count == 1, "partial")
    skExpect(face.sessionIdentifier == "face", "sid")
    skExpect(face.version == "2", "ver")
    skExpect(face.wholeFaceExpressions.first?.identifier == "smile", "whole")
}
