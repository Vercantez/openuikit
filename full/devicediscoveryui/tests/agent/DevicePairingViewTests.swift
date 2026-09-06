import Foundation
@_spi(OpenUIKitHost) import DeviceDiscoveryUI

private struct HostListener: ListenerProvider {}

private struct MarkerView: View {
    let token: String
    var body: EmptyView { EmptyView() }
}

func testDevicePairingViewType() {
    let view = DevicePairingView(HostListener(), access: .default) {
        MarkerView(token: "label")
    } fallback: {
        MarkerView(token: "fallback")
    }
    precondition(type(of: view) == DevicePairingView<MarkerView, MarkerView>.self)
}

func testDevicePairingViewInit() {
    let view = DevicePairingView(HostListener()) {
        MarkerView(token: "label-default")
    } fallback: {
        MarkerView(token: "fallback-default")
    }
    precondition(DeviceDiscoveryUIHostControl.pairingViewAccess(view) == .default)
    precondition(DeviceDiscoveryUIHostControl.pairingViewLabel(view).token == "label-default")
    precondition(DeviceDiscoveryUIHostControl.pairingViewFallback(view).token == "fallback-default")

    let permanent = DevicePairingView(HostListener(), access: .permanent) {
        MarkerView(token: "l")
    } fallback: {
        MarkerView(token: "f")
    }
    precondition(DeviceDiscoveryUIHostControl.pairingViewAccess(permanent) == .permanent)
}

func testDevicePairingViewBody() {
    let view = DevicePairingView(HostListener(), access: .permanent) {
        MarkerView(token: "label")
    } fallback: {
        MarkerView(token: "fallback")
    }
    let body: DevicePairingView<MarkerView, MarkerView>.Body = view.body
    precondition(body.token == "fallback")
    precondition(view.body.token == "fallback")
    precondition(view.body.token != "label")
}
