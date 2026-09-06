// UIColorPickerViewController. A real picker: `selectedColor` plus the
// iOS 15 delegate. Chrome is HSB sliders over the measured page sheet /
// UISlider (control_slider), not the unmeasured iOS 26 colour-well UI
// (OPEN).

#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif

@preconcurrency @MainActor
public protocol UIColorPickerViewControllerDelegate: AnyObject {
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController)
    func colorPickerViewController(_ viewController: UIColorPickerViewController,
                                   didSelect color: UIColor,
                                   continuously: Bool)
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController)
}

extension UIColorPickerViewControllerDelegate {
    public func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {}
    public func colorPickerViewController(_ viewController: UIColorPickerViewController,
                                         didSelect color: UIColor,
                                         continuously: Bool) {}
    public func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {}
}

@preconcurrency @MainActor
open class UIColorPickerViewController: UIViewController {
    public weak var delegate: UIColorPickerViewControllerDelegate?
    public var selectedColor: UIColor = .white {
        didSet {
            guard selectedColor != oldValue else { return }
            applyColorToSliders()
            preview?.backgroundColor = selectedColor
        }
    }
    public var supportsAlpha: Bool = true {
        didSet { alphaSlider?.isHidden = !supportsAlpha }
    }
    public var supportsEyedropper: Bool = true
    public var maximumLinearExposure: CGFloat = 1

    private var hueSlider: UISlider?
    private var satSlider: UISlider?
    private var briSlider: UISlider?
    private var alphaSlider: UISlider?
    private var preview: UIView?
    private var doneButton: UIButton?
    private var updatingFromSliders = false

    public override init() {
        super.init()
        modalPresentationStyle = .pageSheet
    }

    open override func loadView() {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        v.backgroundColor = .systemGroupedBackground

        let done = UIButton(type: .system)
        done.setTitle("Done", for: .normal)
        done.addTarget(for: .touchUpInside) { [weak self] _, _ in
            self?.finish()
        }
        v.addSubview(done)
        doneButton = done

        let previewBox = UIView()
        previewBox.layer.cornerRadius = 10
        previewBox.clipsToBounds = true
        v.addSubview(previewBox)
        preview = previewBox

        hueSlider = makeSlider(in: v)
        satSlider = makeSlider(in: v)
        briSlider = makeSlider(in: v)
        alphaSlider = makeSlider(in: v)
        applyColorToSliders()
        previewBox.backgroundColor = selectedColor
        view = v
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let w = view.bounds.width
        let sa = view.safeAreaInsets
        doneButton?.frame = CGRect(x: w - 80, y: sa.top + 8, width: 64, height: 44)
        preview?.frame = CGRect(x: 24, y: sa.top + 60, width: w - 48, height: 72)
        let sliderY0 = sa.top + 148
        let sliders = [hueSlider, satSlider, briSlider, alphaSlider]
        for (i, slider) in sliders.enumerated() {
            slider?.frame = CGRect(x: 24, y: sliderY0 + CGFloat(i) * 44, width: w - 48, height: 34)
        }
        alphaSlider?.isHidden = !supportsAlpha
    }

    private func makeSlider(in parent: UIView) -> UISlider {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.addTarget(for: .valueChanged) { [weak self] control, _ in
            self?.sliderChanged(control, continuously: true)
        }
        slider.addTarget(for: .touchUpInside) { [weak self] control, _ in
            self?.sliderChanged(control, continuously: false)
        }
        parent.addSubview(slider)
        return slider
    }

    private func applyColorToSliders() {
        guard !updatingFromSliders else { return }
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        _ = selectedColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        hueSlider?.value = Float(h)
        satSlider?.value = Float(s)
        briSlider?.value = Float(b)
        alphaSlider?.value = Float(a)
    }

    private func sliderChanged(_ control: UIControl, continuously: Bool) {
        let h = CGFloat(hueSlider?.value ?? 0)
        let s = CGFloat(satSlider?.value ?? 0)
        let b = CGFloat(briSlider?.value ?? 0)
        let a = supportsAlpha ? CGFloat(alphaSlider?.value ?? 1) : 1
        updatingFromSliders = true
        selectedColor = UIColor(hue: h, saturation: s, brightness: b, alpha: a)
        updatingFromSliders = false
        preview?.backgroundColor = selectedColor
        delegate?.colorPickerViewControllerDidSelectColor(self)
        delegate?.colorPickerViewController(self, didSelect: selectedColor, continuously: continuously)
    }

    private func finish() {
        delegate?.colorPickerViewControllerDidFinish(self)
        dismiss(animated: true)
    }

    @_spi(OpenUIKitHost)
    public func _hostFinish() { finish() }
}
