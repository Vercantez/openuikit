import Foundation
import VideoSubscriberAccount

func testAccountAccessStatusRawValues() {
    precondition(VSAccountAccessStatus.notDetermined.rawValue == 0)
    precondition(VSAccountAccessStatus.restricted.rawValue == 1)
    precondition(VSAccountAccessStatus.denied.rawValue == 2)
    precondition(VSAccountAccessStatus.granted.rawValue == 3)
    precondition(VSAccountAccessStatus(rawValue: 0) == VSAccountAccessStatus.notDetermined)
    precondition(VSAccountAccessStatus(rawValue: 1) == .restricted)
    precondition(VSAccountAccessStatus(rawValue: 2) == .denied)
    precondition(VSAccountAccessStatus(rawValue: 3) == .granted)
    precondition(VSAccountAccessStatus(rawValue: 4) == nil)
    precondition(VSAccountAccessStatus.notDetermined != .granted)
    precondition(
        VSAccountAccessStatus.denied.hashValue == VSAccountAccessStatus.denied.hashValue
    )
    var hasher = Hasher()
    VSAccountAccessStatus.granted.hash(into: &hasher)
    _ = hasher.finalize()
}

func testSubscriptionAccessLevelRawValues() {
    precondition(VSSubscriptionAccessLevel.unknown.rawValue == 0)
    precondition(VSSubscriptionAccessLevel.freeWithAccount.rawValue == 1)
    precondition(VSSubscriptionAccessLevel.paid.rawValue == 2)
    precondition(VSSubscriptionAccessLevel(rawValue: 0) == VSSubscriptionAccessLevel.unknown)
    precondition(VSSubscriptionAccessLevel(rawValue: 1) == .freeWithAccount)
    precondition(VSSubscriptionAccessLevel(rawValue: 2) == .paid)
    precondition(VSSubscriptionAccessLevel(rawValue: 3) == nil)
    precondition(VSSubscriptionAccessLevel.unknown != .paid)
    precondition(
        VSSubscriptionAccessLevel.paid.hashValue == VSSubscriptionAccessLevel.paid.hashValue
    )
    var hasher = Hasher()
    VSSubscriptionAccessLevel.freeWithAccount.hash(into: &hasher)
    _ = hasher.finalize()
}

func testUserAccountAccountTypeRawValues() {
    precondition(VSUserAccount.AccountType.free.rawValue == 0)
    precondition(VSUserAccount.AccountType.paid.rawValue == 1)
    precondition(VSUserAccount.AccountType.RawValue.self == Int.self)
    precondition(VSUserAccount.AccountType(rawValue: 0) == VSUserAccount.AccountType.free)
    precondition(VSUserAccount.AccountType(rawValue: 1) == .paid)
    precondition(VSUserAccount.AccountType(rawValue: 2) == nil)
    precondition(VSUserAccount.AccountType.free != .paid)
    precondition(
        VSUserAccount.AccountType.paid.hashValue == VSUserAccount.AccountType.paid.hashValue
    )
    var hasher = Hasher()
    VSUserAccount.AccountType.free.hash(into: &hasher)
    _ = hasher.finalize()
}

func testOriginatingDeviceCategoryRawValues() {
    precondition(VSUserAccount.OriginatingDeviceCategory.mobile.rawValue == 0)
    precondition(VSUserAccount.OriginatingDeviceCategory.other.rawValue == 1)
    precondition(VSUserAccount.OriginatingDeviceCategory.RawValue.self == Int.self)
    precondition(
        VSUserAccount.OriginatingDeviceCategory(rawValue: 0)
            == VSUserAccount.OriginatingDeviceCategory.mobile
    )
    precondition(VSUserAccount.OriginatingDeviceCategory(rawValue: 1) == .other)
    precondition(VSUserAccount.OriginatingDeviceCategory(rawValue: 2) == nil)
    precondition(VSUserAccount.OriginatingDeviceCategory.mobile != .other)
    precondition(
        VSUserAccount.OriginatingDeviceCategory.other.hashValue
            == VSUserAccount.OriginatingDeviceCategory.other.hashValue
    )
    var hasher = Hasher()
    VSUserAccount.OriginatingDeviceCategory.mobile.hash(into: &hasher)
    _ = hasher.finalize()
}

func testAutoSignInAuthorizationCases() {
    precondition(VSUserAccountManager.AutoSignInAuthorization.notDetermined.rawValue == 0)
    precondition(VSUserAccountManager.AutoSignInAuthorization.granted.rawValue == 1)
    precondition(VSUserAccountManager.AutoSignInAuthorization.denied.rawValue == 2)
    precondition(
        VSUserAccountManager.AutoSignInAuthorization.notDetermined
            == VSUserAccountManager.AutoSignInAuthorization.notDetermined
    )
    precondition(
        VSUserAccountManager.AutoSignInAuthorization.granted
            != VSUserAccountManager.AutoSignInAuthorization.denied
    )
    precondition(
        VSUserAccountManager.AutoSignInAuthorization.granted.hashValue
            == VSUserAccountManager.AutoSignInAuthorization.granted.hashValue
    )
    var hasher = Hasher()
    VSUserAccountManager.AutoSignInAuthorization.denied.hash(into: &hasher)
    _ = hasher.finalize()
}
