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
