import Foundation
import AVKit

private final class RoutePickerMethodProbe: NSObject, AVRoutePickerViewDelegate {
    var events: [String] = []

    func routePickerViewWillBeginPresentingRoutes(_ routePickerView: AVRoutePickerView) {
        _ = routePickerView
        events.append("willBegin")
    }

    func routePickerViewDidEndPresentingRoutes(_ routePickerView: AVRoutePickerView) {
        _ = routePickerView
        events.append("didEnd")
    }
}

func testRoutePickerViewConstructs() {
    avkitOnMain {
        let picker = AVRoutePickerView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        _ = picker
        precondition(picker.prioritizesVideoDevices == false)
    }
}

func testRoutePickerViewActiveTintColor() {
    avkitOnMain {
        let picker = AVRoutePickerView(frame: .zero)
        precondition(picker.activeTintColor != nil)
        picker.activeTintColor = .white
        precondition(picker.activeTintColor != nil)
    }
}

func testRoutePickerViewCustomRoutingController() {
    avkitOnMain {
        let picker = AVRoutePickerView(frame: .zero)
        precondition(picker.customRoutingController == nil)
        picker.customRoutingController = AVCustomRoutingController()
        precondition(picker.customRoutingController != nil)
        picker.customRoutingController = nil
        precondition(picker.customRoutingController == nil)
    }
}

func testRoutePickerViewDelegateStorage() {
    avkitOnMain {
        let picker = AVRoutePickerView(frame: .zero)
        let probe = RoutePickerMethodProbe()
        picker.delegate = probe
        precondition(picker.delegate === probe)
        picker.delegate = nil
        precondition(picker.delegate == nil)
    }
}

func testRoutePickerViewPrioritizesVideoDevices() {
    avkitOnMain {
        let picker = AVRoutePickerView(frame: .zero)
        precondition(picker.prioritizesVideoDevices == false)
        picker.prioritizesVideoDevices = true
        precondition(picker.prioritizesVideoDevices == true)
    }
}

func testRoutePickerViewDelegateProtocolConformance() {
    avkitOnMain {
        let picker = AVRoutePickerView(frame: .zero)
        let probe = RoutePickerMethodProbe()
        picker.delegate = probe
        let typed: (any AVRoutePickerViewDelegate)? = picker.delegate
        precondition(typed === probe)
    }
}

func testRoutePickerViewDidEndPresentingRoutesFailClosed() {
    avkitOnMain {
        let picker = AVRoutePickerView(frame: .zero)
        let probe = RoutePickerMethodProbe()
        picker.delegate = probe
        picker.openUIKitHostAttemptPresentRoutes()
        precondition(probe.events.isEmpty)
        probe.routePickerViewDidEndPresentingRoutes(picker)
        precondition(probe.events == ["didEnd"])
    }
}

func testRoutePickerViewWillBeginPresentingRoutesFailClosed() {
    avkitOnMain {
        let picker = AVRoutePickerView(frame: .zero)
        let probe = RoutePickerMethodProbe()
        picker.delegate = probe
        picker.openUIKitHostAttemptPresentRoutes()
        precondition(probe.events.isEmpty)
        probe.routePickerViewWillBeginPresentingRoutes(picker)
        precondition(probe.events == ["willBegin"])
    }
}
