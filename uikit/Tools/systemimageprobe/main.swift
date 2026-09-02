// Native UIKit 26.1 semantic oracle for OpenUIKit's bounded system-image
// subset. This probe intentionally validates public contracts and alignment
// bounds, not Apple's proprietary SF Symbols outlines.
import Foundation
import UIKit

func require(_ condition: @autoclosure () -> Bool, _ label: String) {
    precondition(condition(), "system-image oracle failed: \(label)")
}

let weights: [UIImage.SymbolWeight] = [
    .unspecified, .ultraLight, .thin, .light, .regular,
    .medium, .semibold, .bold, .heavy, .black,
]
require(weights.map(\.rawValue) == Array(0...9), "symbol weight raw values")
print("weights\t" + weights.map { String($0.rawValue) }.joined(separator: ","))

let sizes: [(String, CGSize)] = [
    ("calendar", CGSize(width: 21, height: 17.5)),
    ("clock", CGSize(width: 20, height: 19)),
    ("multiply", CGSize(width: 15.5, height: 13.5)),
    ("plus.circle.fill", CGSize(width: 20, height: 19)),
    ("circlebadge", CGSize(width: 16, height: 15)),
    ("checkmark.circle.fill", CGSize(width: 20, height: 19)),
]
for (name, expected) in sizes {
    let image = UIImage(systemName: name)
    require(image != nil, "\(name) availability")
    require(image?.size == expected, "\(name) size")
    require(image?.renderingMode.rawValue == 0, "\(name) automatic mode")
    require(image?.isSymbolImage == true, "\(name) marker")
    print("\(name)\t\(expected.width)x\(expected.height)\tautomatic\tsymbol")
}

let configuration = UIImage.SymbolConfiguration(pointSize: 56, weight: .regular)
let configured = UIImage(systemName: "plus.circle.fill",
                         withConfiguration: configuration)
require(configured?.size == CGSize(width: 66, height: 64),
        "configured plus size")
require(configured?.renderingMode.rawValue == 0, "configured plus mode")
require(configured?.isSymbolImage == true, "configured plus marker")
print("plus.circle.fill@56.regular\t66.0x64.0\tautomatic\tsymbol")

let copy = configuration.copy() as! UIImage.SymbolConfiguration
require(copy !== configuration, "configuration copy identity")
require(copy.isEqual(configuration), "configuration copy equality")
let archive = try NSKeyedArchiver.archivedData(withRootObject: configuration,
                                                requiringSecureCoding: true)
let decoded = try NSKeyedUnarchiver.unarchivedObject(
    ofClass: UIImage.SymbolConfiguration.self,
    from: archive
)
require(decoded != nil, "configuration secure decode")
require(decoded !== configuration, "configuration archive identity")
require(decoded?.isEqual(configuration) == true, "configuration archive equality")
print("configuration\tdistinct-copy-equal\tdistinct-secure-archive-equal")

final class NativeSymbolSubclass: UIImage.SymbolConfiguration,
                                  @unchecked Sendable {
    nonisolated(unsafe) static var coderCalls = 0
    let marker: Int

    override class var supportsSecureCoding: Bool { true }

    required init?(coder: NSCoder) {
        Self.coderCalls += 1
        marker = coder.decodeInteger(forKey: "Native.marker")
        super.init(coder: coder)
    }
}
NativeSymbolSubclass.coderCalls = 0
let nativeSubclass = NativeSymbolSubclass(pointSize: 12, weight: .regular)
require(NativeSymbolSubclass.coderCalls == 0,
        "native factory bypasses subclass coder")
require(nativeSubclass.marker == 0, "native factory zeroes subclass storage")
let nativeSubclassCopy = nativeSubclass.copy() as! UIImage.SymbolConfiguration
require(nativeSubclassCopy !== nativeSubclass, "subclass copy identity")
require(nativeSubclassCopy.isEqual(nativeSubclass), "subclass copy equality")
require(nativeSubclassCopy is NativeSymbolSubclass,
        "subclass copy preserves dynamic type")
require(NativeSymbolSubclass.coderCalls == 0,
        "native copy bypasses subclass coder")
require((nativeSubclassCopy as! NativeSymbolSubclass).marker == 0,
        "native copy keeps zeroed subclass storage")
let subclassArchive = try NSKeyedArchiver.archivedData(
    withRootObject: nativeSubclass,
    requiringSecureCoding: true
)
let subclassDecoded = try NSKeyedUnarchiver.unarchivedObject(
    ofClass: NativeSymbolSubclass.self,
    from: subclassArchive
)
require(NativeSymbolSubclass.coderCalls == 1,
        "native archive uses subclass coder exactly once")
require(subclassDecoded != nil && subclassDecoded !== nativeSubclass,
        "native subclass archive identity")
require(subclassDecoded?.isEqual(nativeSubclass) == true,
        "native subclass archive equality")
print("subclass\tfactory-coder=0\tcopy-coder=0\tarchive-coder=1")

let tinted = configured!.withTintColor(.red)
require(tinted.renderingMode.rawValue == configured!.renderingMode.rawValue,
        "one-argument tint preserves automatic mode")
require(tinted.isSymbolImage, "tinted marker")
require(configured!.withRenderingMode(.alwaysOriginal).isSymbolImage,
        "rendering-mode copy marker")
let rasterTint = UIImage().withTintColor(.red)
require(rasterTint.renderingMode.rawValue == 0, "ordinary raster tint mode")
require(!rasterTint.isSymbolImage, "ordinary raster marker")
print("copies\tautomatic-tint\tsymbol-marker-preserved\traster-not-symbol")

// Public visual oracle: automatic symbol tint is resolved by UIImageView,
// even after withTintColor has colored the image. Ordinary automatic rasters
// are original pixels, including a raster explicitly tinted beforehand.
func dominantInk(_ image: UIImage, viewTint: UIColor) -> (Int, Int, Int, Int) {
    let view = UIImageView(image: image)
    view.tintColor = viewTint
    view.frame = CGRect(origin: .zero, size: CGSize(width: 80, height: 80))
    view.contentMode = .center
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    format.opaque = false
    let rendered = UIGraphicsImageRenderer(size: view.bounds.size,
                                            format: format).image { context in
        view.layer.render(in: context.cgContext)
    }
    guard let cg = rendered.cgImage,
          let provider = cg.dataProvider,
          let data = provider.data,
          let pointer = CFDataGetBytePtr(data) else { return (-1, -1, -1, -1) }
    var best = (0, 0, 0, 0)
    for y in 0..<cg.height {
        for x in 0..<cg.width {
            let index = y * cg.bytesPerRow + x * 4
            let pixel = (Int(pointer[index + 2]), Int(pointer[index + 1]),
                         Int(pointer[index]), Int(pointer[index + 3]))
            if pixel.3 > best.3 { best = pixel }
        }
    }
    return best
}

let ordinary = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10)).image {
    context in
    UIColor.black.setFill()
    context.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
}
let ordinaryTemplateTint = ordinary.withRenderingMode(.alwaysTemplate)
    .withTintColor(.red)
let systemOriginalTint = configured!.withRenderingMode(.alwaysOriginal)
    .withTintColor(.red)
let ordinaryExplicitThenAutomatic = ordinary
    .withTintColor(.red, renderingMode: .alwaysTemplate)
    .withRenderingMode(.automatic)
let systemExplicitThenAutomatic = configured!
    .withTintColor(.red, renderingMode: .alwaysTemplate)
    .withRenderingMode(.automatic)
require(ordinaryTemplateTint.renderingMode.rawValue == 2,
        "ordinary template tint preserves mode")
require(systemOriginalTint.renderingMode.rawValue == 1,
        "system original tint preserves mode")
require(ordinaryExplicitThenAutomatic.renderingMode.rawValue == 0,
        "ordinary explicit-then-automatic mode")
require(systemExplicitThenAutomatic.renderingMode.rawValue == 0,
        "system explicit-then-automatic mode")
print("copy-chains\ttemplate=2\toriginal=1\treset=0,0")
let visuals: [(String, UIImage, (Int, Int, Int, Int))] = [
    ("system-auto", configured!, (0, 0, 255, 255)),
    ("system-tinted-auto", configured!.withTintColor(.red), (0, 0, 255, 255)),
    ("system-tinted-template",
     configured!.withTintColor(.red).withRenderingMode(.alwaysTemplate),
     (0, 0, 255, 255)),
    ("raster-auto", ordinary, (0, 0, 0, 255)),
    ("raster-tinted-auto", ordinary.withTintColor(.red), (255, 0, 0, 255)),
    ("raster-template-tinted", ordinaryTemplateTint, (0, 0, 255, 255)),
    ("system-original-tinted", systemOriginalTint, (255, 0, 0, 255)),
    ("raster-explicit-then-auto", ordinaryExplicitThenAutomatic,
     (255, 0, 0, 255)),
    ("system-explicit-then-auto", systemExplicitThenAutomatic,
     (0, 0, 255, 255)),
]
for (label, image, expected) in visuals {
    let actual = dominantInk(image, viewTint: .blue)
    require(actual == expected, "\(label) visual tint")
    print("visual.\(label)\t\(actual.0),\(actual.1),\(actual.2),\(actual.3)")
}

// These are malformed/noncanonical native lookups. Provider scope is a
// separate OpenUIKit-only gate: magnifyingglass is a valid native SF Symbol
// but intentionally outside the portable six-name provider.
for name in ["", "Calendar", " calendar", "calendar ", "../calendar"] {
    require(UIImage(systemName: name) == nil, "unknown \(name.debugDescription)")
}
print("unknowns\tnil")
print("SYSTEM_IMAGE_NATIVE_ORACLE_OK")
