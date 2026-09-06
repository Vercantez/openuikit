import Foundation
@_spi(OpenUIKitHost) import DeviceDiscoveryUI

private struct HostBrowser: BrowserProvider {
    typealias Endpoint = String
}

private struct MarkerView: View {
    let token: String
    var body: EmptyView { EmptyView() }
}

func testDevicePickerType() {
    let view = DevicePicker(HostBrowser(), onSelect: { (_: String) in }) {
        MarkerView(token: "label")
    } fallback: {
        MarkerView(token: "fallback")
    }
    precondition(type(of: view) == DevicePicker<MarkerView, MarkerView>.self)
}

func testDevicePickerInit() {
    var selected: [String] = []
    var parametersCalled = 0
    let view = DevicePicker(
        HostBrowser(),
        access: .permanent,
        onSelect: { endpoint in selected.append(endpoint) },
        label: { MarkerView(token: "label") },
        fallback: { MarkerView(token: "fallback") },
        parameters: {
            parametersCalled += 1
            return NWParameters()
        }
    )
    precondition(DeviceDiscoveryUIHostControl.pickerAccess(view) == .permanent)
    precondition(DeviceDiscoveryUIHostControl.pickerLabel(view).token == "label")
    precondition(DeviceDiscoveryUIHostControl.pickerFallback(view).token == "fallback")
    precondition(DeviceDiscoveryUIHostControl.pickerHasParametersClosure(view))
    precondition(DeviceDiscoveryUIHostControl.pickerOnSelectCount(view) == 0)
    precondition(selected.isEmpty)
    precondition(parametersCalled == 0)

    let defaulted = DevicePicker(HostBrowser(), onSelect: { (_: String) in }) {
        MarkerView(token: "l")
    } fallback: {
        MarkerView(token: "f")
    }
    precondition(DeviceDiscoveryUIHostControl.pickerAccess(defaulted) == .default)
    precondition(!DeviceDiscoveryUIHostControl.pickerHasParametersClosure(defaulted))
    precondition(DeviceDiscoveryUIHostControl.pickerOnSelectCount(defaulted) == 0)

    DeviceDiscoveryUIHostControl.invokeStoredOnSelect(view, endpoint: "peer.local")
    precondition(selected == ["peer.local"])
    precondition(DeviceDiscoveryUIHostControl.pickerOnSelectCount(view) == 1)
}

func testDevicePickerBody() {
    let view = DevicePicker(HostBrowser(), onSelect: { (_: String) in }) {
        MarkerView(token: "label")
    } fallback: {
        MarkerView(token: "fallback")
    }
    let body: DevicePicker<MarkerView, MarkerView>.Body = view.body
    precondition(body.token == "fallback")
    precondition(view.body.token == "fallback")
    precondition(DeviceDiscoveryUIHostControl.pickerOnSelectCount(view) == 0)
}
