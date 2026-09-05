import Foundation
import AlarmKit

func testAlarmConfigurationMemberwiseInit() {
    let attributes = AlarmAttributes(
        presentation: alarmKitMakePresentation(),
        metadata: AlarmKitProbeMetadata(label: "probe"),
        tintColor: Color(red: 0, green: 0, blue: 1, opacity: 1)
    )
    let configuration = AlarmManager.AlarmConfiguration(
        countdownDuration: Alarm.CountdownDuration(preAlert: 5, postAlert: nil),
        schedule: .fixed(Date(timeIntervalSince1970: 0)),
        attributes: attributes,
        stopIntent: AlarmKitEmptyIntent(),
        secondaryIntent: AlarmKitEmptyIntent(),
        sound: .default
    )
    alarmKitExpectEqual(configuration.sound.identifier, "default", "default sound")
    alarmKitExpect(configuration.stopIntent != nil, "stop intent stored")
    alarmKitExpect(configuration.secondaryIntent != nil, "secondary intent stored")
    alarmKitExpectEqual(configuration.countdownDuration?.preAlert, 5, "config duration")
}

func testAlarmConfigurationAlarmFactory() {
    let attributes = AlarmAttributes(
        presentation: alarmKitMakePresentation(),
        metadata: AlarmKitProbeMetadata(label: "x"),
        tintColor: .primary
    )
    let alarmConfig = AlarmManager.AlarmConfiguration<AlarmKitProbeMetadata>.alarm(
        schedule: .fixed(Date(timeIntervalSince1970: 1)),
        attributes: attributes,
        sound: AlertConfiguration.AlertSound(named: "radar")
    )
    alarmKitExpectEqual(alarmConfig.sound.identifier, "radar", "named sound")
    alarmKitExpect(alarmConfig.countdownDuration == nil, "alarm factory duration")
    alarmKitExpect(alarmConfig.schedule != nil, "alarm factory schedule")
}

func testAlarmConfigurationTimerFactory() {
    let attributes = AlarmAttributes(
        presentation: alarmKitMakePresentation(),
        metadata: AlarmKitProbeMetadata(label: "x"),
        tintColor: .primary
    )
    let timerConfig = AlarmManager.AlarmConfiguration<AlarmKitProbeMetadata>.timer(
        duration: 90,
        attributes: attributes
    )
    alarmKitExpectEqual(timerConfig.countdownDuration?.preAlert, 90, "timer duration")
    alarmKitExpect(timerConfig.schedule == nil, "timer has no schedule")
}
