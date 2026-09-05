import DeviceActivity
import Foundation

func testDeviceActivityFilterUsers() {
    deviceActivityRequire(
        DeviceActivityFilter.Users.all != DeviceActivityFilter.Users.children,
        "all != children"
    )
    deviceActivityRequire(
        DeviceActivityFilter.Users.all == DeviceActivityFilter.Users.all,
        "all equal"
    )
    var hasher = Hasher()
    DeviceActivityFilter.Users.children.hash(into: &hasher)
    deviceActivityRequire(
        DeviceActivityFilter.Users.children.hashValue
            == DeviceActivityFilter.Users.children.hashValue,
        "hashValue"
    )
}

func testDeviceActivityFilterDevices() {
    let phones = DeviceActivityFilter.Devices([.iPhone])
    let pads = DeviceActivityFilter.Devices([.iPad])
    deviceActivityRequire(phones != pads, "model sets differ")
    deviceActivityRequire(phones != .all, "all != specific")
    deviceActivityRequire(
        DeviceActivityFilter.Devices.all == DeviceActivityFilter.Devices.all,
        "all equal"
    )
    var hasher = Hasher()
    phones.hash(into: &hasher)
    deviceActivityRequire(phones.hashValue == phones.hashValue, "hashValue")
}

func testDeviceActivityFilterSegmentInterval() {
    let day = DateInterval(start: Date(timeIntervalSince1970: 0), duration: 3600)
    let hourly = DeviceActivityFilter.SegmentInterval.hourly(during: day)
    let daily = DeviceActivityFilter.SegmentInterval.daily(during: day)
    let weekly = DeviceActivityFilter.SegmentInterval.weekly(during: day)
    deviceActivityRequire(hourly != daily, "hourly != daily")
    deviceActivityRequire(daily != weekly, "daily != weekly")
    deviceActivityRequire(hourly == .hourly(during: day), "hourly equal")
    var hasher = Hasher()
    hourly.hash(into: &hasher)
    deviceActivityRequire(hourly.hashValue == hourly.hashValue, "hashValue")
}

func testDeviceActivityFilterInitializers() {
    let day = DateInterval(start: Date(timeIntervalSince1970: 1000), duration: 7200)
    let devices = DeviceActivityFilter.Devices([.mac])
    let filter = DeviceActivityFilter(
        segment: .daily(during: day),
        devices: devices
    )
    deviceActivityRequire(filter.users == nil, "users optional nil")
    deviceActivityRequire(filter.devices == devices, "devices")
    deviceActivityRequire(
        filter.segmentInterval == .daily(during: day),
        "segment"
    )
    let withUsers = DeviceActivityFilter(
        segment: .weekly(during: day),
        users: .children,
        devices: .all
    )
    deviceActivityRequire(withUsers.users == .children, "users")
    deviceActivityRequire(withUsers.devices == .all, "devices all")
    deviceActivityRequire(filter != withUsers, "filters differ")
    let defaulted = DeviceActivityFilter()
    deviceActivityRequire(defaulted.users == nil, "default users")
    deviceActivityRequire(defaulted.devices == nil, "default devices")
}
