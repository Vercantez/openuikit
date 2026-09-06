import DeviceActivity
import Foundation

func testDeviceActivityDeviceModelRawValues() {
    let expected: [(DeviceActivityData.Device.Model, Int)] = [
        (.iPhone, 0),
        (.iPod, 1),
        (.iPad, 2),
        (.mac, 3),
    ]
    for (model, raw) in expected {
        deviceActivityRequire(model.rawValue == raw, "raw \(raw)")
        deviceActivityRequire(
            DeviceActivityData.Device.Model(rawValue: raw) == model,
            "init \(raw)"
        )
    }
    deviceActivityRequire(DeviceActivityData.Device.Model(rawValue: 99) == nil, "unknown")
    deviceActivityRequire(
        DeviceActivityData.Device.Model.iPhone != .mac,
        "models unequal"
    )
}

func testDeviceActivityFamilyRoleRawValues() {
    deviceActivityRequire(
        DeviceActivityData.User.FamilyRole.individual.rawValue == 0,
        "individual"
    )
    deviceActivityRequire(
        DeviceActivityData.User.FamilyRole.child.rawValue == 1,
        "child"
    )
    deviceActivityRequire(
        DeviceActivityData.User.FamilyRole(rawValue: 0) == .individual,
        "init individual"
    )
    deviceActivityRequire(
        DeviceActivityData.User.FamilyRole(rawValue: 1) == .child,
        "init child"
    )
    deviceActivityRequire(
        DeviceActivityData.User.FamilyRole(rawValue: 2) == nil,
        "unknown"
    )
    deviceActivityRequire(
        DeviceActivityData.User.FamilyRole.individual != .child,
        "roles unequal"
    )
}

func testDeviceActivityDataDeviceAndUser() {
    let device = DeviceActivityData.Device(name: "office", model: .mac)
    deviceActivityRequire(device.name == "office", "name")
    deviceActivityRequire(device.model == .mac, "model")
    var hasher = Hasher()
    device.hash(into: &hasher)
    deviceActivityRequire(device.hashValue == device.hashValue, "device hash")

    var components = PersonNameComponents()
    components.givenName = "Ada"
    let user = DeviceActivityData.User(
        nameComponents: components,
        role: .individual,
        appleID: "ada@example.com"
    )
    deviceActivityRequire(user.role == .individual, "role")
    deviceActivityRequire(user.appleID == "ada@example.com", "appleID")
    deviceActivityRequire(user.nameComponents?.givenName == "Ada", "name")
    deviceActivityRequire(
        user != DeviceActivityData.User(role: .child),
        "users unequal"
    )
    var userHasher = Hasher()
    user.hash(into: &userHasher)
    deviceActivityRequire(user.hashValue == user.hashValue, "user hash")
}

func testDeviceActivityApplicationActivity() {
    let application = DeviceActivityData.ApplicationActivity(
        totalActivityDuration: 12,
        numberOfPickups: 3,
        numberOfNotifications: 4,
        bundleIdentifier: "app"
    )
    deviceActivityRequire(application.totalActivityDuration == 12, "duration")
    deviceActivityRequire(application.numberOfPickups == 3, "pickups")
    deviceActivityRequire(application.numberOfNotifications == 4, "notifications")
    let same = DeviceActivityData.ApplicationActivity(
        totalActivityDuration: 12,
        numberOfPickups: 3,
        numberOfNotifications: 4,
        bundleIdentifier: "app"
    )
    deviceActivityRequire(application == same, "equal")
    deviceActivityRequire(
        application != DeviceActivityData.ApplicationActivity(totalActivityDuration: 1),
        "unequal"
    )
    var hasher = Hasher()
    application.hash(into: &hasher)
    deviceActivityRequire(application.hashValue == same.hashValue, "hashValue")
}

func testDeviceActivityWebDomainActivity() {
    let web = DeviceActivityData.WebDomainActivity(
        totalActivityDuration: 8,
        domain: "example.com"
    )
    deviceActivityRequire(web.totalActivityDuration == 8, "duration")
    let same = DeviceActivityData.WebDomainActivity(
        totalActivityDuration: 8,
        domain: "example.com"
    )
    deviceActivityRequire(web == same, "equal")
    deviceActivityRequire(
        web != DeviceActivityData.WebDomainActivity(totalActivityDuration: 1),
        "unequal"
    )
    var hasher = Hasher()
    web.hash(into: &hasher)
    deviceActivityRequire(web.hashValue == same.hashValue, "hashValue")
}

func testDeviceActivityCategoryActivity() {
    let application = DeviceActivityData.ApplicationActivity(
        totalActivityDuration: 12,
        numberOfPickups: 3,
        numberOfNotifications: 4,
        bundleIdentifier: "app"
    )
    let web = DeviceActivityData.WebDomainActivity(
        totalActivityDuration: 8,
        domain: "example.com"
    )
    let category = DeviceActivityData.CategoryActivity(
        totalActivityDuration: 20,
        applications: [application],
        webDomains: [web]
    )
    deviceActivityRequire(category.totalActivityDuration == 20, "duration")
    let appIterator = category.applications.makeAsyncIterator()
    deviceActivityRequire(appIterator.nextSynchronously() == application, "apps")
    deviceActivityRequire(appIterator.nextSynchronously() == nil, "apps exhausted")
    let webIterator = category.webDomains.makeAsyncIterator()
    deviceActivityRequire(webIterator.nextSynchronously() == web, "web")
    let same = DeviceActivityData.CategoryActivity(
        totalActivityDuration: 20,
        applications: [application],
        webDomains: [web]
    )
    deviceActivityRequire(category == same, "equal")
    var hasher = Hasher()
    category.hash(into: &hasher)
    deviceActivityRequire(category.hashValue == same.hashValue, "hashValue")
}

func testDeviceActivityActivitySegment() {
    let interval = DateInterval(start: Date(timeIntervalSince1970: 0), duration: 3600)
    let application = DeviceActivityData.ApplicationActivity(
        totalActivityDuration: 12,
        numberOfPickups: 3,
        numberOfNotifications: 4,
        bundleIdentifier: "app"
    )
    let web = DeviceActivityData.WebDomainActivity(
        totalActivityDuration: 8,
        domain: "example.com"
    )
    let category = DeviceActivityData.CategoryActivity(
        totalActivityDuration: 20,
        applications: [application],
        webDomains: [web]
    )
    let segment = DeviceActivityData.ActivitySegment(
        dateInterval: interval,
        totalActivityDuration: 20,
        totalPickupsWithoutApplicationActivity: 1,
        longestActivity: interval,
        firstPickup: Date(timeIntervalSince1970: 10),
        categories: [category]
    )
    deviceActivityRequire(segment.dateInterval == interval, "interval")
    deviceActivityRequire(segment.totalActivityDuration == 20, "duration")
    deviceActivityRequire(segment.totalPickupsWithoutApplicationActivity == 1, "pickups")
    deviceActivityRequire(segment.longestActivity == interval, "longest")
    deviceActivityRequire(segment.firstPickup == Date(timeIntervalSince1970: 10), "first")
    let catIterator = segment.categories.makeAsyncIterator()
    deviceActivityRequire(catIterator.nextSynchronously() == category, "categories")
    let same = DeviceActivityData.ActivitySegment(
        dateInterval: interval,
        totalActivityDuration: 20,
        totalPickupsWithoutApplicationActivity: 1,
        longestActivity: interval,
        firstPickup: Date(timeIntervalSince1970: 10),
        categories: [category]
    )
    deviceActivityRequire(segment == same, "equal")
    var hasher = Hasher()
    segment.hash(into: &hasher)
    deviceActivityRequire(segment.hashValue == same.hashValue, "hashValue")
}

func testDeviceActivityDataRecord() {
    let interval = DateInterval(start: Date(timeIntervalSince1970: 0), duration: 3600)
    let application = DeviceActivityData.ApplicationActivity(
        totalActivityDuration: 12,
        numberOfPickups: 3,
        numberOfNotifications: 4,
        bundleIdentifier: "app"
    )
    let web = DeviceActivityData.WebDomainActivity(
        totalActivityDuration: 8,
        domain: "example.com"
    )
    let category = DeviceActivityData.CategoryActivity(
        totalActivityDuration: 20,
        applications: [application],
        webDomains: [web]
    )
    let segment = DeviceActivityData.ActivitySegment(
        dateInterval: interval,
        totalActivityDuration: 20,
        totalPickupsWithoutApplicationActivity: 1,
        longestActivity: interval,
        firstPickup: Date(timeIntervalSince1970: 10),
        categories: [category]
    )
    let device = DeviceActivityData.Device(name: "office", model: .mac)
    let data = DeviceActivityData(
        lastUpdatedDate: Date(timeIntervalSince1970: 50),
        segmentInterval: .daily(during: interval),
        user: DeviceActivityData.User(role: .child),
        device: device,
        activitySegments: [segment]
    )
    deviceActivityRequire(data.lastUpdatedDate.timeIntervalSince1970 == 50, "updated")
    deviceActivityRequire(data.segmentInterval == .daily(during: interval), "segment")
    deviceActivityRequire(data.user.role == .child, "user")
    deviceActivityRequire(data.device.model == .mac, "device")
    let segIterator = data.activitySegments.makeAsyncIterator()
    deviceActivityRequire(segIterator.nextSynchronously() == segment, "segments")
    let same = DeviceActivityData(
        lastUpdatedDate: Date(timeIntervalSince1970: 50),
        segmentInterval: .daily(during: interval),
        user: DeviceActivityData.User(role: .child),
        device: device,
        activitySegments: [segment]
    )
    deviceActivityRequire(data == same, "equal")
    var hasher = Hasher()
    data.hash(into: &hasher)
    deviceActivityRequire(data.hashValue == same.hashValue, "hashValue")
}
