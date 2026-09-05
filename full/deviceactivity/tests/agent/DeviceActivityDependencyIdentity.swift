import DeviceActivity
import Foundation

/// Isolated host compile does not run this probe as a program. The clean
/// EC2 integration build imports real Foundation and passes genuine values
/// through DeviceActivity APIs.
func deviceActivityDependencyIdentityProbe() {
    let start = DateComponents(hour: 9, minute: 0)
    let end = DateComponents(hour: 10, minute: 0)
    let schedule = DeviceActivitySchedule(
        intervalStart: start,
        intervalEnd: end,
        repeats: true
    )
    let assignedStart: DateComponents = schedule.intervalStart
    let assignedEnd: DateComponents = schedule.intervalEnd
    precondition(assignedStart.hour == 9)
    precondition(assignedEnd.hour == 10)

    let data = Data([0x44, 0x41])
    _ = data.count
    _ = UUID()
    _ = Date()
}
