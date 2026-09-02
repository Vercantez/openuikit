import Foundation

@_silgen_name("open")
private func guestOpen(_ path: UnsafePointer<CChar>, _ flags: Int32, _ mode: Int32) -> Int32
@_silgen_name("read")
private func guestRead(_ fd: Int32, _ buffer: UnsafeMutableRawPointer?, _ count: Int) -> Int
@_silgen_name("close")
private func guestClose(_ fd: Int32) -> Int32
@_silgen_name("exit")
private func guestExit(_ status: Int32) -> Never

private let expected = "focus-bundle-oracle-v1\n"

private func lastPathComponent(_ path: String) -> String {
  guard let slash = path.lastIndex(of: "/") else { return path }
  return String(path[path.index(after: slash)...])
}

private func readFile(_ path: String) -> String? {
  let fd = path.withCString { guestOpen($0, 0, 0) }
  guard fd >= 0 else { return nil }
  defer { _ = guestClose(fd) }

  var bytes = [UInt8](repeating: 0, count: 128)
  let count = bytes.withUnsafeMutableBytes {
    guestRead(fd, $0.baseAddress, $0.count)
  }
  guard count >= 0 else { return nil }
  return String(decoding: bytes.prefix(count), as: UTF8.self)
}

guard Bundle.main.bundlePath.hasSuffix("FocusBundleProbe.app") else {
  print("ORACLE_FAIL bundle=\(Bundle.main.bundlePath)")
  guestExit(73)
}
guard let path = Bundle.main.path(forResource: "launch_probe", ofType: "txt") else {
  print("ORACLE_FAIL resource=nil")
  guestExit(73)
}
guard let content = readFile(path) else {
  print("ORACLE_FAIL unreadable")
  guestExit(73)
}
guard content == expected else {
  print("ORACLE_FAIL content=\(content)")
  guestExit(73)
}

print("bundle=FocusBundleProbe.app")
print("resource=\(lastPathComponent(path))")
print("bytes=\(content.utf8.count)")
print("content=focus-bundle-oracle-v1")
let missing = Bundle.main.path(forResource: "does-not-exist", ofType: "txt")
print("missing=\(missing == nil ? "nil" : "FOUND")")
print("PASS")
