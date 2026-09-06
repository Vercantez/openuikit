import Foundation
@_spi(OpenUIKitHost) import ScreenTime

func testScreenTimeConfigurationType() {
    let configuration = ScreenTimeHostControl.failClosedConfiguration()
    precondition(type(of: configuration) == STScreenTimeConfiguration.self)
    precondition(configuration is NSObject)
}

func testEnforcesChildRestrictionsFailClosed() {
    let configuration = ScreenTimeHostControl.failClosedConfiguration()
    precondition(configuration.enforcesChildRestrictions == false)
    precondition(configuration.enforcesChildRestrictions != true)
}
