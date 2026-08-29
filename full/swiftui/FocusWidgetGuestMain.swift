// Linux/machorun execution harness for Focus's unchanged SearchWidgetView.
// This file is proof tooling, not Focus application source.

import CPortableIO
import FocusWidget
import SwiftUI

@main
@MainActor
struct FocusWidgetGuestMain {
    private static func fail(_ message: String) -> Never {
        ("FAIL: " + message).withCString { cpio_log_stderr($0) }
        cpio_exit(1)
        fatalError(message)
    }

    private static func require(_ condition: @autoclosure () -> Bool, _ message: String) {
        if !condition() { fail(message) }
    }

    private static func identifiedView<T: UIView>(
        _ type: T.Type,
        id: String,
        in root: UIView
    ) -> T? {
        if root.accessibilityIdentifier == id, let typed = root as? T { return typed }
        for child in root.subviews {
            if let found = identifiedView(type, id: id, in: child) { return found }
        }
        return nil
    }

    private static func fnv1a64(_ bytes: [UInt8]) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in bytes {
            hash ^= UInt64(byte)
            hash &*= 0x100000001b3
        }
        return hash
    }

    private static func rgba(_ bitmap: Bitmap, x: Int, y: Int) -> [UInt8] {
        require(x >= 0 && x < bitmap.width && y >= 0 && y < bitmap.height,
                "pixel probe is outside the bitmap")
        let offset = (y * bitmap.width + x) * 4
        return Array(bitmap.pixels[offset..<(offset + 4)])
    }

    private static func whitePixelCount(_ bitmap: Bitmap, in rect: CGRect) -> Int {
        let minX = max(0, Int(rect.minX.rounded(.down)))
        let minY = max(0, Int(rect.minY.rounded(.down)))
        let maxX = min(bitmap.width, Int(rect.maxX.rounded(.up)))
        let maxY = min(bitmap.height, Int(rect.maxY.rounded(.up)))
        var count = 0
        for y in minY..<maxY {
            for x in minX..<maxX {
                let p = (y * bitmap.width + x) * 4
                if bitmap.pixels[p] >= 235,
                   bitmap.pixels[p + 1] >= 235,
                   bitmap.pixels[p + 2] >= 235,
                   bitmap.pixels[p + 3] > 0 {
                    count += 1
                }
            }
        }
        return count
    }

    private static func scaled(_ rect: CGRect, by scale: CGFloat) -> CGRect {
        CGRect(
            x: rect.origin.x * scale,
            y: rect.origin.y * scale,
            width: rect.size.width * scale,
            height: rect.size.height * scale
        )
    }

    private static func pixelDifference(
        _ lhs: Bitmap,
        _ rhs: Bitmap,
        in rect: CGRect
    ) -> (count: Int, maxChannelDelta: Int) {
        require(lhs.width == rhs.width && lhs.height == rhs.height,
                "cannot compare differently sized bitmaps")
        let minX = max(0, Int(rect.minX.rounded(.down)))
        let minY = max(0, Int(rect.minY.rounded(.down)))
        let maxX = min(lhs.width, Int(rect.maxX.rounded(.up)))
        let maxY = min(lhs.height, Int(rect.maxY.rounded(.up)))
        var count = 0
        var maxChannelDelta = 0
        for y in minY..<maxY {
            for x in minX..<maxX {
                let p = (y * lhs.width + x) * 4
                var changed = false
                for channel in 0..<4 {
                    let delta = abs(Int(lhs.pixels[p + channel]) - Int(rhs.pixels[p + channel]))
                    if delta > 0 { changed = true }
                    maxChannelDelta = max(maxChannelDelta, delta)
                }
                if changed { count += 1 }
            }
        }
        return (count, maxChannelDelta)
    }

    static func main() {
        let args = CommandLine.arguments
        require(args.count == 3,
                "usage: focus_widget_guest <Focus_Widget.bundle> <output.png>")
        let resourceBundle = args[1]
        let output = args[2]

        // Bundle.module remains the exact spelling in Assets.swift.  This is
        // the Foundation-hidden host's explicit filesystem side of that API.
        OpenUIKitRuntime.imageSearchPaths = [resourceBundle]
        OpenUIKitRuntime.resourceRoot = "/uikit/Sources/OpenUIKit/Resources"
        let renderScale: CGFloat = 2
        OpenUIKitRuntime.imageScreenScale = renderScale
        OpenUIKitRuntime.renderBackend = .swift
        OpenUIKitRuntime.compositor = .renderPass
        // The Noble image carries these open DejaVu fonts. OpenUIKit keeps
        // Focus's SF-based metrics for layout while using these outlines as a
        // deterministic, redistributable missing-glyph fallback. The build
        // stages them under /w because that path is guest-visible to machorun.
        OpenUIKitRuntime.fontPaths["system"] =
            "/w/build/swiftui-guest/fonts/DejaVuSans.ttf"
        OpenUIKitRuntime.fontPaths["medium"] =
            "/w/build/swiftui-guest/fonts/DejaVuSans-Bold.ttf"
        require(ResourceIO.readFile(OpenUIKitRuntime.fontPaths["system"]!)?.count == 759_720,
                "guest cannot read staged DejaVu Sans")
        require(ResourceIO.readFile(OpenUIKitRuntime.fontPaths["medium"]!)?.count == 708_920,
                "guest cannot read staged DejaVu Sans Bold")
        UIImage.clearNamedCache()

        // These are the exact modifiers in SearchWidgetView_Previews. They are
        // harness-owned invocation syntax around the unchanged production view.
        let widget = SearchWidgetView(
            title: "Search in Focus",
            padding: true,
            background: true
        )
            .previewLayout(.sizeThatFits)
            .frame(width: 135, height: 135)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        let controller = UIHostingController(
            rootView: widget
        )
        guard let host = controller.view else { fail("UIHostingController did not load a view") }
        host.frame = CGRect(x: 0, y: 0, width: 135, height: 135)
        host.layoutIfNeeded()

        guard let gradient = identifiedView(
            UIGradientView.self,
            id: "SwiftUI.LinearGradient",
            in: host
        ) else { fail("exact view did not mount its LinearGradient") }
        guard let label = identifiedView(
            UILabel.self,
            id: "SwiftUI.Text",
            in: host
        ) else { fail("exact view did not mount its Text") }
        guard let search = identifiedView(
            UIView.self,
            id: "SwiftUI.Image.systemName.magnifyingglass",
            in: host
        ) else { fail("exact view did not mount the magnifying-glass symbol") }
        guard let logo = identifiedView(
            UIImageView.self,
            id: "SwiftUI.Image.named.icon_logo",
            in: host
        ) else { fail("exact view did not mount its named logo") }

        require(gradient.frame == CGRect(x: 0, y: 0, width: 135, height: 135),
                "gradient does not cover the 135x135 widget")
        require(host.clipsToBounds, "preview RoundedRectangle did not enable clipping")
        require(host.layer.cornerRadius == 20,
                "preview RoundedRectangle corner radius is not 20 points")
        require(gradient.colors.count == 2,
                "normalized GradientFirst/GradientSecond colors did not resolve")
        require(label.text == "Search in Focus", "title text changed during mounting")
        require(label.font.weight == .medium, "Focus .fontWeight(.medium) was not applied")
        require(label.minimumScaleFactor == 0.8,
                "Focus .minimumScaleFactor(0.8) was not applied")
        require(label.textColor == .white, "Focus foreground color was not applied")
        require(search.frame.height == 18, "magnifying-glass height is not 18 points")
        require(logo.frame.height == 22, "logo height is not 22 points")
        require(logo.image != nil, "normalized icon_logo PNG was not decoded")
        guard let glyphFont = GlyphRasterizer.font(for: label.font) else {
            fail("staged DejaVu font bytes did not initialize as a glyph font")
        }
        let searchGlyph = glyphFont.glyphIndex(of: "S")
        require(searchGlyph != 0, "staged DejaVu font has no title glyphs")
        require(glyphFont.rasterize(glyph: searchGlyph, pixelSize: 17, shiftX: 0) != nil,
                "staged DejaVu title glyph did not rasterize")

        let first = UIRenderer.render(host, scale: renderScale)
        let second = UIRenderer.render(host, scale: renderScale)
        require(first.width == 270 && first.height == 270,
                "renderer did not emit a 270x270 @2x bitmap")
        require(first.pixels == second.pixels,
                "two renders of the unchanged hierarchy produced different pixels")
        label.isHidden = true
        let titleHidden = UIRenderer.render(host, scale: renderScale)
        label.isHidden = false
        let titleFrame = scaled(label.frame, by: renderScale)
        let titleDifference = pixelDifference(first, titleHidden, in: titleFrame)
        require(titleDifference.count >= 30 && titleDifference.maxChannelDelta >= 8,
                "visible and hidden title renders do not differ inside the label frame")
        let opaquePixels = stride(from: 3, to: first.pixels.count, by: 4)
            .reduce(0) { $0 + (first.pixels[$1] == 0 ? 0 : 1) }
        require(opaquePixels >= 70_000,
                "normalized named colors did not paint the widget background")

        require(rgba(first, x: 0, y: 0)[3] == 0,
                "rounded preview clip did not clear the top-left corner")
        require(rgba(first, x: 269, y: 269)[3] == 0,
                "rounded preview clip did not clear the bottom-right corner")
        require(rgba(first, x: 135, y: 135)[3] == 255,
                "rounded preview clip unexpectedly cleared the interior")
        let gradientLeft = rgba(first, x: 40, y: 150)
        let gradientRight = rgba(first, x: 220, y: 150)
        require(gradientLeft != gradientRight,
                "normalized GradientFirst/GradientSecond rendered a flat fill")

        let titlePixels = whitePixelCount(first, in: titleFrame)
        let searchPixels = whitePixelCount(first, in: scaled(search.frame, by: renderScale))
        let logoPixels = whitePixelCount(first, in: scaled(logo.frame, by: renderScale))
        require(titlePixels >= 120,
                "title has no visible light glyph coverage inside its label frame")
        require(searchPixels >= 40,
                "magnifying glass has no visible light coverage inside its frame")
        require(logoPixels >= 80,
                "logo has no visible light coverage inside its image frame")

        let png = first.pngData()
        let repeatedPNG = second.pngData()
        require(png == repeatedPNG,
                "two renders of the unchanged hierarchy produced different PNG bytes")
        require(png.count > 8, "PNG encoder returned an empty artifact")
        require(Array(png.prefix(8)) == [137, 80, 78, 71, 13, 10, 26, 10],
                "render artifact is not PNG")
        let wrote = png.withUnsafeBufferPointer { bytes in
            cpio_write_file(output, bytes.baseAddress, bytes.count) != 0
        }
        require(wrote, "could not write output PNG")

        print("PASS: exact unchanged Focus SearchWidgetView ran under machorun")
        print("widget_points=135x135 png_pixels=270x270 scale=2 opaque_pixels=\(opaquePixels)")
        print("visible_white_pixels title=\(titlePixels) search=\(searchPixels) logo=\(logoPixels)")
        print("title_hidden_difference pixels=\(titleDifference.count) max_channel_delta=\(titleDifference.maxChannelDelta)")
        print("gradient_probes left=\(gradientLeft) right=\(gradientRight)")
        print("png_bytes=\(png.count) png_fnv1a64=\(String(fnv1a64(png), radix: 16))")
        print("resource_bundle=\(resourceBundle)")
        print("output=\(output)")
        cpio_exit(0)
    }
}
