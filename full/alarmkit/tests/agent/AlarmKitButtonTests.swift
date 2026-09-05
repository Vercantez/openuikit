import Foundation
import AlarmKit

func testAlarmButtonInitAndProperties() {
    let stop = alarmKitStopButton()
    alarmKitExpectEqual(stop.text.key, "Stop", "stop text")
    alarmKitExpectEqual(stop.systemImageName, "stop.circle", "stop image")
    alarmKitExpectEqual(stop.textColor.red, 1, "stop red")
    let listen = alarmKitListenButton()
    alarmKitExpectEqual(listen.systemImageName, "play.fill", "listen image")
    alarmKitExpectEqual(listen.text.key, "RADIO_ALARM_LISTEN", "listen text")
}

func testAlarmButtonCodable() {
    let decoded = alarmKitRoundTrip(alarmKitStopButton())
    alarmKitExpectEqual(decoded.systemImageName, "stop.circle", "button round-trip")
    alarmKitExpectEqual(decoded.text.key, "Stop", "button text round-trip")
}
