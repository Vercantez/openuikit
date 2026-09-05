import Foundation
import CoreGraphics

/// Fail-closed volume chrome. MEASURED /tmp/mp_oracle.json, iPhone SE 2x /
/// iOS 26.1: `MPVolumeView()` frame is `.zero`, `showsRouteButton` is
/// `false`, `showsVolumeSlider` is `true`, wireless flags are `false`,
/// `volumeSliderRect(forBounds: 200×44)` is `.zero`. Route-button layout
/// for other sizes is unobserved (one 200×44 sample is in the report).
@MainActor
open class MPVolumeView: UIView {
    public var showsRouteButton: Bool = false
    public var showsVolumeSlider: Bool = true
    public var volumeWarningSliderImage: UIImage?
    public var isWirelessRouteActive: Bool { false }
    public var areWirelessRoutesAvailable: Bool { false }

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public func maximumVolumeSliderImage(for state: UIControl.State) -> UIImage? {
        _ = state
        return nil
    }

    public func minimumVolumeSliderImage(for state: UIControl.State) -> UIImage? {
        _ = state
        return nil
    }

    public func routeButtonImage(for state: UIControl.State) -> UIImage? {
        _ = state
        return nil
    }

    public func volumeThumbImage(for state: UIControl.State) -> UIImage? {
        _ = state
        return nil
    }

    public func setMaximumVolumeSliderImage(_ image: UIImage?, for state: UIControl.State) {
        _ = image
        _ = state
    }

    public func setMinimumVolumeSliderImage(_ image: UIImage?, for state: UIControl.State) {
        _ = image
        _ = state
    }

    public func setRouteButtonImage(_ image: UIImage?, for state: UIControl.State) {
        _ = image
        _ = state
    }

    public func setVolumeThumbImage(_ image: UIImage?, for state: UIControl.State) {
        _ = image
        _ = state
    }

    public func routeButtonRect(forBounds bounds: CGRect) -> CGRect {
        _ = bounds
        return .zero
    }

    public func volumeSliderRect(forBounds bounds: CGRect) -> CGRect {
        _ = bounds
        return .zero
    }

    public func volumeThumbRect(
        forBounds bounds: CGRect,
        volumeSliderRect rect: CGRect,
        value: Float
    ) -> CGRect {
        _ = bounds
        _ = rect
        _ = value
        return .zero
    }
}
