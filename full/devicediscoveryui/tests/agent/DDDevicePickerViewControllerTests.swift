import Foundation
@_spi(OpenUIKitHost) import DeviceDiscoveryUI

func testPickerViewControllerType() {
    precondition(
        String(describing: DDDevicePickerViewController.self)
            == "DDDevicePickerViewController"
    )
    let metatype: DDDevicePickerViewController.Type = DDDevicePickerViewController.self
    precondition(metatype.isSupported(.bonjour(type: "_http._tcp", domain: nil)) == false)
}

func testPickerViewControllerIsSupported() {
    let bonjour = NWBrowser.Descriptor.bonjour(type: "_dd._tcp", domain: "local.")
    let txt = NWBrowser.Descriptor.bonjourWithTXTRecord(type: "_dd._tcp", domain: nil)
    let app = NWBrowser.Descriptor.applicationService(name: "example")
    precondition(DDDevicePickerViewController.isSupported(bonjour) == false)
    precondition(DDDevicePickerViewController.isSupported(txt, using: nil) == false)
    let parameters = NWParameters()
    precondition(DDDevicePickerViewController.isSupported(app, using: parameters) == false)
}

func testPickerInit() {
    let descriptor = NWBrowser.Descriptor.bonjour(type: "_http._tcp", domain: nil)
    let missing = DDDevicePickerViewController(browseDescriptor: descriptor)
    precondition(missing == nil)
    let withParameters = DDDevicePickerViewController(
        browseDescriptor: descriptor,
        parameters: NWParameters()
    )
    precondition(withParameters == nil)
}

func testPickerInitWithAccess() {
    let descriptor = NWBrowser.Descriptor.applicationService(name: "picker")
    let defaulted = DDDevicePickerViewController(
        browseDescriptor: descriptor,
        parameters: nil,
        access: .default
    )
    precondition(defaulted == nil)
    let permanent = DDDevicePickerViewController(
        browseDescriptor: descriptor,
        parameters: NWParameters(),
        access: .permanent
    )
    precondition(permanent == nil)
}
