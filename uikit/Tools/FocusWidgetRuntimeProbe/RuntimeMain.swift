// Runtime harness for the exact, unchanged Focus Widget SwiftUI sources.
//
// This file is build-only proof plumbing.  The proof script copies it beside
// the pinned Focus Assets.swift and SearchWidgetView.swift files in a fresh
// SwiftPM executable target.  SwiftPM, not this harness, generates the
// Bundle.module accessor used by the app source.

import Foundation
import OpenUIKit
import SwiftUI

private struct ProbeFailure: Error, CustomStringConvertible {
    let description: String
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else { throw ProbeFailure(description: message) }
}

private func rgba8(_ color: UIColor) -> [Int] {
    let value = color.resolvedCGColor(with: .current)
    return [value.red, value.green, value.blue, value.alpha].map {
        Int(($0 * 255).rounded())
    }
}

private func pixel(_ bytes: [UInt8], width: Int, x: Int, y: Int) -> [UInt8] {
    let offset = (y * width + x) * 4
    return Array(bytes[offset..<(offset + 4)])
}

private func lightPixelCount(in rect: CGRect, pixels: [UInt8], width: Int, height: Int) -> Int {
    let minX = max(0, Int(rect.minX.rounded(.down)))
    let minY = max(0, Int(rect.minY.rounded(.down)))
    let maxX = min(width, Int(rect.maxX.rounded(.up)))
    let maxY = min(height, Int(rect.maxY.rounded(.up)))
    guard minX < maxX, minY < maxY else { return 0 }
    var count = 0
    for y in minY..<maxY {
        for x in minX..<maxX {
            let offset = (y * width + x) * 4
            if pixels[offset] >= 220,
               pixels[offset + 1] >= 220,
               pixels[offset + 2] >= 220,
               pixels[offset + 3] > 0 {
                count += 1
            }
        }
    }
    return count
}

private func fnv1a64(_ bytes: [UInt8]) -> String {
    var value: UInt64 = 0xcbf29ce484222325
    for byte in bytes {
        value ^= UInt64(byte)
        value &*= 0x100000001b3
    }
    let raw = String(value, radix: 16)
    return String(repeating: "0", count: 16 - raw.count) + raw
}

@main
private enum FocusWidgetRuntimeProbe {
    @MainActor
    static func main() throws {
        try require(
            CommandLine.arguments.count == 4,
            "usage: FocusWidgetRuntimeProbe OUTPUT_PNG OPENUIKIT_RESOURCE_ROOT FONT_DIR"
        )
        let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
        let openUIKitResourceRoot = CommandLine.arguments[2]
        let fontDirectory = CommandLine.arguments[3]
        try require(
            FileManager.default.fileExists(atPath: openUIKitResourceRoot),
            "OpenUIKit resource root does not exist"
        )

        OpenUIKitRuntime.resourceRoot = openUIKitResourceRoot
        OpenUIKitRuntime.fontPaths = [
            "system": URL(fileURLWithPath: fontDirectory)
                .appendingPathComponent("SFNS.ttf").path,
            "mono": URL(fileURLWithPath: fontDirectory)
                .appendingPathComponent("SFNSMono.ttf").path,
            "italic": URL(fileURLWithPath: fontDirectory)
                .appendingPathComponent("SFNSItalic.ttf").path,
        ]
        for path in OpenUIKitRuntime.fontPaths.values {
            try require(FileManager.default.fileExists(atPath: path),
                        "required deterministic font is missing: \(path)")
        }
        OpenUIKitRuntime.imageScreenScale = 2
        OpenUIKitRuntime.renderBackend = .swift
        OpenUIKitRuntime.compositor = .renderPass
        UIImage.clearNamedCache()

        let bundle = Bundle.module
        guard let bundleRoot = bundle.resourcePath else {
            throw ProbeFailure(description: "Bundle.module has no resource path")
        }
        let requiredBundlePaths = [
            "Media.xcassets/GradientFirst.colorset/Contents.json",
            "Media.xcassets/GradientSecond.colorset/Contents.json",
            "icon_logo.png",
            "icon_logo@2x.png",
            "icon_logo@3x.png",
            "resource-index.json",
        ]
        for relativePath in requiredBundlePaths {
            try require(
                FileManager.default.fileExists(
                    atPath: URL(fileURLWithPath: bundleRoot)
                        .appendingPathComponent(relativePath).path
                ),
                "Bundle.module is missing \(relativePath)"
            )
        }

        let firstColor = try requireColor(named: "GradientFirst", in: bundle)
        let secondColor = try requireColor(named: "GradientSecond", in: bundle)
        try require(rgba8(firstColor) == [89, 42, 203, 255], "GradientFirst bytes drifted")
        try require(rgba8(secondColor) == [171, 113, 255, 255], "GradientSecond bytes drifted")

        guard let sourceLogo = UIImage(
            named: "icon_logo",
            in: bundle,
            compatibleWith: UITraitCollection(displayScale: 2)
        ) else {
            throw ProbeFailure(description: "OpenUIKit did not load icon_logo from Bundle.module")
        }
        try require(sourceLogo.size.width == 145.5, "2x logo width drifted")
        try require(sourceLogo.size.height == 150, "2x logo height drifted")

        // This is the exact app-defined type from the byte-identical copied
        // SearchWidgetView.swift, not a hand-written facsimile.
        let exactView = SearchWidgetView(
                title: "Search in Focus",
                padding: true,
                background: true
            )
        let controller = UIHostingController(
            rootView: exactView
                .frame(width: 135, height: 135)
                .clipShape(RoundedRectangle(cornerRadius: 20))
        )
        guard let host = controller.view else {
            throw ProbeFailure(description: "UIHostingController did not load its view")
        }
        host.frame = CGRect(x: 0, y: 0, width: 135, height: 135)
        host.layoutIfNeeded()

        let gradient = try requireSubview(
            of: UIGradientView.self,
            identifier: "SwiftUI.LinearGradient",
            in: host
        )
        let label = try requireSubview(
            of: UILabel.self,
            identifier: "SwiftUI.Text",
            in: host
        )
        let search = try requireSubview(
            of: UIView.self,
            identifier: "SwiftUI.Image.systemName.magnifyingglass",
            in: host
        )
        let logo = try requireSubview(
            of: UIImageView.self,
            identifier: "SwiftUI.Image.named.icon_logo",
            in: host
        )

        try require(host.subviews.count == 4, "unexpected rendered hierarchy size")
        try require(host.clipsToBounds, "rounded widget clipping was not enabled")
        try require(host.layer.cornerRadius == 20, "rounded widget radius drifted")
        try require(gradient.frame == CGRect(x: 0, y: 0, width: 135, height: 135),
                    "gradient frame drifted")
        try require(gradient.startPoint == CGPoint(x: 0, y: 0), "gradient start drifted")
        try require(gradient.endPoint == CGPoint(x: 1, y: 1), "gradient end drifted")
        try require(gradient.colors.map(rgba8) == [[89, 42, 203, 255], [171, 113, 255, 255]],
                    "rendered gradient resources drifted")
        try require(label.text == "Search in Focus", "exact view title did not render")
        try require(label.font.weight == .medium, "title font weight drifted")
        try require(label.minimumScaleFactor == 0.8, "title scale factor drifted")
        try require(label.adjustsFontSizeToFitWidth, "title did not enable scaling")
        try require(label.textColor == .white, "title foreground color drifted")
        try require(label.frame.minX >= 10 && label.frame.minY >= 10,
                    "title escaped exact-view padding")
        try require(search.frame.height == 18 && search.frame.width > 0,
                    "system magnifier frame drifted")
        try require(search.frame.maxX <= 125.001, "system magnifier escaped padding")
        try require(logo.frame.height == 22, "named logo frame drifted")
        try require(logo.frame.maxX <= 125.001 && logo.frame.maxY <= 125.001,
                    "named logo escaped padding")
        try require(logo.image != nil, "named logo view has no decoded image")

        let first = UIRenderer.render(host, scale: 1)
        let second = UIRenderer.render(host, scale: 1)
        try require(first.width == 135 && first.height == 135, "render dimensions drifted")
        try require(first.pixels == second.pixels, "repeated renders are not byte-identical")
        try require(first.pngData() == second.pngData(), "repeated PNG encodes are not byte-identical")
        try require(first.pixels.count == 135 * 135 * 4, "RGBA byte count drifted")

        let opaquePixels = stride(from: 3, to: first.pixels.count, by: 4)
            .filter { first.pixels[$0] == 255 }.count
        let whitePixels = stride(from: 0, to: first.pixels.count, by: 4)
            .filter {
                first.pixels[$0] >= 245
                    && first.pixels[$0 + 1] >= 245
                    && first.pixels[$0 + 2] >= 245
                    && first.pixels[$0 + 3] > 0
            }.count
        let distinctPixels = Set(stride(from: 0, to: first.pixels.count, by: 4).map {
            UInt32(first.pixels[$0]) << 24
                | UInt32(first.pixels[$0 + 1]) << 16
                | UInt32(first.pixels[$0 + 2]) << 8
                | UInt32(first.pixels[$0 + 3])
        }).count
        let textPixels = lightPixelCount(
            in: label.frame,
            pixels: first.pixels,
            width: first.width,
            height: first.height
        )
        let systemSymbolPixels = lightPixelCount(
            in: search.frame,
            pixels: first.pixels,
            width: first.width,
            height: first.height
        )
        let logoPixels = lightPixelCount(
            in: logo.frame,
            pixels: first.pixels,
            width: first.width,
            height: first.height
        )
        try require(opaquePixels > 16_000 && opaquePixels < 135 * 135,
                    "rounded gradient coverage drifted")
        try require(whitePixels > 100, "text/symbol/logo foreground pixels are missing")
        try require(textPixels > 60, "title glyphs are not visibly rasterized")
        try require(systemSymbolPixels > 40, "magnifier pixels are not visibly rasterized")
        try require(logoPixels > 200, "logo pixels are not visibly rasterized")
        try require(distinctPixels > 100, "render does not contain a real gradient")

        let topLeft = pixel(first.pixels, width: first.width, x: 0, y: 0)
        let topInset = pixel(first.pixels, width: first.width, x: 20, y: 20)
        let center = pixel(first.pixels, width: first.width, x: 67, y: 67)
        let bottomRight = pixel(first.pixels, width: first.width, x: 134, y: 134)
        let bottomInset = pixel(first.pixels, width: first.width, x: 114, y: 114)
        try require(topLeft[3] == 0 && bottomRight[3] == 0,
                    "rounded clipping did not clear corner pixels")
        try require(center[3] == 255, "widget center is not opaque")
        try require(topInset[0] < bottomInset[0], "gradient red channel did not increase")
        try require(topInset[1] < bottomInset[1], "gradient green channel did not increase")
        try require(topInset[2] < bottomInset[2], "gradient blue channel did not increase")

        let png = first.pngData()
        try require(Array(png.prefix(8)) == [137, 80, 78, 71, 13, 10, 26, 10],
                    "output is not a PNG")
        try Data(png).write(to: outputURL, options: .withoutOverwriting)

        print("PASS: exact Focus SearchWidgetView rendered through OpenUIKit SwiftUI")
        print("bundle_module_root=\(bundleRoot)")
        print("hierarchy_subviews=\(host.subviews.count)")
        print("opaque_pixels=\(opaquePixels)")
        print("white_pixels=\(whitePixels)")
        print("title_pixels=\(textPixels)")
        print("system_symbol_pixels=\(systemSymbolPixels)")
        print("logo_pixels=\(logoPixels)")
        print("distinct_pixels=\(distinctPixels)")
        print("pixel_fnv1a64=\(fnv1a64(first.pixels))")
        print("png_bytes=\(png.count)")
    }

    @MainActor
    private static func requireColor(named name: String, in bundle: Bundle) throws -> UIColor {
        guard let color = UIColor(named: name, in: bundle, compatibleWith: nil) else {
            throw ProbeFailure(description: "OpenUIKit did not load \(name) from Bundle.module")
        }
        return color
    }

    @MainActor
    private static func requireSubview<T: UIView>(
        of type: T.Type,
        identifier: String,
        in host: UIView
    ) throws -> T {
        guard let result = host.subviews.first(where: {
            $0.accessibilityIdentifier == identifier
        }) as? T else {
            throw ProbeFailure(description: "missing rendered subview \(identifier)")
        }
        return result
    }
}
