import Foundation
import AlarmKit

func testAlarmMetadataConformance() {
    let metadata = AlarmKitProbeMetadata(label: "probe")
    alarmKitExpectEqual(metadata.label, "probe", "metadata label")
    alarmKitExpect(metadata == AlarmKitProbeMetadata(label: "probe"), "metadata ==")
    alarmKitExpect(metadata != AlarmKitProbeMetadata(label: "other"), "metadata !=")
    _ = metadata.hashValue
}

func testAlarmAttributesInitAndContentState() {
    let presentation = alarmKitMakePresentation()
    let metadata = AlarmKitProbeMetadata(label: "probe")
    let attributes = AlarmAttributes(
        presentation: presentation,
        metadata: metadata,
        tintColor: Color(red: 0, green: 0, blue: 1, opacity: 1)
    )
    alarmKitExpectEqual(attributes.metadata?.label, "probe", "metadata")
    alarmKitExpectEqual(attributes.tintColor.blue, 1, "tint")
    alarmKitExpectEqual(attributes.presentation.alert.title.key, "Wake", "presentation")
    let _: AlarmAttributes<AlarmKitProbeMetadata>.ContentState.Type =
        AlarmPresentationState.self
}

func testAlarmAttributesCodable() {
    let attributes = AlarmAttributes(
        presentation: alarmKitMakePresentation(),
        metadata: AlarmKitProbeMetadata(label: "probe"),
        tintColor: Color(red: 0, green: 0, blue: 1, opacity: 1)
    )
    let decoded = alarmKitRoundTrip(attributes)
    alarmKitExpectEqual(decoded.metadata?.label, "probe", "attributes round-trip")
    alarmKitExpectEqual(decoded.tintColor.blue, 1, "tint round-trip")
}
