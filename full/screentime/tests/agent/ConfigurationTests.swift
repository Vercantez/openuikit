import Foundation
@_spi(OpenUIKitHost) import ScreenTime

func testScreenTimeConfigurationType() {
    let configuration = ScreenTimeHostControl.failClosedConfiguration()
    precondition(type(of: configuration) == STScreenTimeConfiguration.self)
    let object: NSObject = configuration
    precondition(object === configuration)
}

func testEnforcesChildRestrictionsFailClosed() {
    let configuration = ScreenTimeHostControl.failClosedConfiguration()
    precondition(configuration.enforcesChildRestrictions == false)
    precondition(configuration.enforcesChildRestrictions != true)
}
