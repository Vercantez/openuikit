import Foundation
@_spi(OpenUIKitHost) import MediaPlayer

func testVolumeSettingsAlert() {
    precondition(!MPVolumeSettingsAlertIsVisible())
    MPVolumeSettingsAlertShow()
    precondition(!MPVolumeSettingsAlertIsVisible())
    MPVolumeSettingsAlertHide()
    precondition(!MPVolumeSettingsAlertIsVisible())
}

func testVolumeViewFailClosed() {
    let sem = DispatchSemaphore(value: 0)
    var failed = false
    Task { @MainActor in
        let vol = MPVolumeView()
        precondition(vol.frame == .zero)
        precondition(!vol.showsRouteButton)
        precondition(vol.showsVolumeSlider)
        precondition(!vol.isWirelessRouteActive)
        precondition(!vol.areWirelessRoutesAvailable)
        precondition(vol.volumeSliderRect(forBounds: CGRect(x: 0, y: 0, width: 200, height: 44)) == .zero)
        precondition(vol.routeButtonRect(forBounds: CGRect(x: 0, y: 0, width: 200, height: 44)) == .zero)
        precondition(vol.volumeThumbRect(forBounds: .zero, volumeSliderRect: .zero, value: 0) == .zero)
        precondition(vol.maximumVolumeSliderImage(for: .normal) == nil)
        precondition(vol.minimumVolumeSliderImage(for: .normal) == nil)
        precondition(vol.routeButtonImage(for: .normal) == nil)
        precondition(vol.volumeThumbImage(for: .normal) == nil)
        vol.setMaximumVolumeSliderImage(nil, for: .normal)
        vol.setMinimumVolumeSliderImage(nil, for: .normal)
        vol.setRouteButtonImage(nil, for: .highlighted)
        vol.setVolumeThumbImage(nil, for: .selected)
        vol.volumeWarningSliderImage = nil
        let sized = MPVolumeView(frame: CGRect(x: 10, y: 20, width: 300, height: 40))
        precondition(sized.frame.width == 300)
        failed = false
        sem.signal()
    }
    precondition(sem.wait(timeout: .now() + .seconds(5)) == .success)
    _ = failed
}
