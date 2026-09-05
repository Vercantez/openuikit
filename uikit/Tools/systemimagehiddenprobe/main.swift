// Foundation-hidden ARM64 Mach-O runtime closure for the bounded provider.
// Build this against the literal UIKit shim plus all OpenUIKit sources; it
// deliberately uses no Foundation spelling or app-side source adaptation.
import UIKit

#if canImport(Foundation)
#error("systemimagehiddenprobe must compile with the Foundation umbrella hidden")
#endif

@main
struct SystemImageHiddenProbe {
    @MainActor
    static func main() {
        OpenUIKitRuntime.renderBackend = .swift
        OpenUIKitRuntime.compositor = .renderPass
        OpenUIKitRuntime.imageScreenScale = 2

        let expected: [String: UInt64] = [
            "calendar": 17_688_738_542_957_584_656,
            "clock": 11_422_362_519_469_204_408,
            "multiply": 930_275_962_113_226_808,
            "plus.circle.fill": 5_248_006_694_040_004_741,
            "circlebadge": 1_384_709_250_049_653_253,
            "checkmark.circle.fill": 9_384_873_863_741_001_018,
        ]
        for name in expected.keys.sorted() {
            guard let image = UIImage(systemName: name) else {
                fatalError("missing bounded symbol \(name)")
            }
            precondition(image.isSymbolImage)
            precondition(fnv1a(image.bitmap.pixels) == expected[name])
        }

        let configuration = UIImage.SymbolConfiguration(pointSize: 56,
                                                          weight: .regular)
        guard let plus = UIImage(systemName: "plus.circle.fill",
                                 withConfiguration: configuration) else {
            fatalError("missing configured plus")
        }
        precondition(plus.size == CGSize(width: 66, height: 64))
        precondition(fnv1a(plus.bitmap.pixels) == 4_184_632_315_002_413_221)
        precondition(UIImage(systemName: "magnifyingglass") == nil)

        // Automatic symbol intent survives an immutable tint copy: the view's
        // blue tint wins over the baked red pixels.
        let view = UIImageView(image: plus.withTintColor(.red))
        view.tintColor = .blue
        let output = Bitmap(width: plus.bitmap.width, height: plus.bitmap.height)
        view.drawContent(in: Canvas(bitmap: output, scale: plus.scale),
                         bounds: view.bounds)
        precondition(hasBlueInk(output))

        // The root validator rejects finite product-bypass scale before any
        // child shadow conversion can trap.
        let tiny = CGFloat.leastNormalMagnitude
        let root = UIView(frame: CGRect(x: 0, y: 0, width: tiny, height: tiny))
        let shadowed = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        shadowed.layer.shadowOpacity = 1
        shadowed.layer.shadowOffset = CGSize(width: 1, height: 1)
        shadowed.layer.shadowRadius = 1
        root.addSubview(shadowed)
        let rejected = UIRenderer.render(
            root,
            scale: CGFloat.greatestFiniteMagnitude
        )
        precondition(rejected.width == 0 && rejected.height == 0)

        print("SYSTEM_IMAGE_FOUNDATION_HIDDEN_RUNTIME_OK symbols=6")
    }

    static func fnv1a(_ bytes: [UInt8]) -> UInt64 {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in bytes {
            hash ^= UInt64(byte)
            hash = hash &* 1_099_511_628_211
        }
        return hash
    }

    static func hasBlueInk(_ bitmap: Bitmap) -> Bool {
        for index in stride(from: 0, to: bitmap.pixels.count, by: 4) {
            guard bitmap.pixels[index + 3] > 200 else { continue }
            let red = Int(bitmap.pixels[index])
            let green = Int(bitmap.pixels[index + 1])
            let blue = Int(bitmap.pixels[index + 2])
            if blue > red + 50 && blue > green + 50 { return true }
        }
        return false
    }
}
