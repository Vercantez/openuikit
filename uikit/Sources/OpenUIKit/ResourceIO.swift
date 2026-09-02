// File loading via the CPortableIO libc shim. Owner: runtime-util.
import CPortableIO

public enum ResourceIO {
    /// Read an entire file; nil if unreadable.
    public static func readFile(_ path: String) -> [UInt8]? {
        var size: Int = 0
        guard let buf = cpio_read_file(path, &size) else { return nil }
        defer { cpio_free(buf) }
        return Array(UnsafeBufferPointer(start: buf, count: size))
    }

    /// Load + parse a JSON resource from OpenUIKitRuntime.resourceRoot.
    public static func loadJSONResource(_ name: String) -> JSONValue? {
        guard let bytes = readFile(OpenUIKitRuntime.resourceRoot + "/" + name) else { return nil }
        return JSONValue.parse(bytes)
    }
}

public extension OpenUIKitRuntime {
    /// Bind OpenUIKit to the resources in a relocatable application bundle.
    ///
    /// This is part of the framework rather than a generated executable
    /// helper because SwiftUI's default `App.main()` is the executable entry
    /// point: it has to establish the same fail-closed resource contract
    /// before constructing the user's App value or delegate adaptor.
    @MainActor
    static func configureApplicationBundleResources(at bundleResourceRoot: String) {
        let openUIKit = bundleResourceRoot + "/OpenUIKit"
        for relativePath in [
            "system_colors.json",
            "font_metrics.json",
            "fonts/DejaVuSans.ttf",
            "fonts/DejaVuSans-Bold.ttf",
        ] {
            let path = openUIKit + "/" + relativePath
            guard let bytes = ResourceIO.readFile(path), !bytes.isEmpty else {
                preconditionFailure(
                    "required portable application resource is missing: \(path)"
                )
            }
        }

        resourceRoot = openUIKit
        imageSearchPaths = [bundleResourceRoot]
        imageScreenScale = 2

        // FontEngine's tables are process-wide and initialized once. Probe
        // after installing resourceRoot so a late/missing metrics table can
        // never be hidden by the rasterizer fallback configured below.
        let metricsProbe = FontEngine.advance(
            of: "M",
            font: UIFont.systemFont(ofSize: 17)
        )
        precondition(
            metricsProbe > 0,
            "packaged OpenUIKit font metrics were unavailable before application launch"
        )

        let regular = openUIKit + "/fonts/DejaVuSans.ttf"
        let bold = openUIKit + "/fonts/DejaVuSans-Bold.ttf"
        fontPaths = [
            "system": regular,
            "medium": bold,
            "semibold": bold,
            "bold": bold,
            "heavy": bold,
            "black": bold,
        ]
        UIImage.clearNamedCache()
    }
}
