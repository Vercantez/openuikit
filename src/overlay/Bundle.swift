// Bundle.swift -- the first OS-facing class in the guest Foundation overlay.
//
// This intentionally starts with the part an application needs before it can
// even parse its own resources: locate the main executable's .app directory
// and resolve a named resource inside it.  The executable path comes from
// machorun's _NSGetExecutablePath implementation.  Asking /proc/self/exe would
// return the Linux loader, not the mapped Mach-O guest (machorun's `execpath`
// test is the independent oracle for that distinction).
//
// This is a real Foundation implementation compiled into libFoundation.dylib,
// not a host-Foundation call and not a compile-time placeholder.  The surface
// is deliberately narrow; info dictionaries, localisation, arbitrary bundle
// construction and URL-valued APIs remain later milestones.

@_silgen_name("_NSGetExecutablePath")
private func _bundleExecutablePath(
  _ buffer: UnsafeMutablePointer<CChar>?,
  _ bufferSize: UnsafeMutablePointer<UInt32>?
) -> Int32

@_silgen_name("access")
private func _bundleAccess(_ path: UnsafePointer<CChar>, _ mode: Int32) -> Int32

private let _bundleFileExistsMode: Int32 = 0

private func _bundleDeletingLastPathComponent(_ path: String) -> String {
  if path == "/" { return path }
  var end = path.endIndex
  while end > path.startIndex && path[path.index(before: end)] == "/" {
    end = path.index(before: end)
  }
  guard let slash = path[..<end].lastIndex(of: "/") else { return "." }
  return slash == path.startIndex ? "/" : String(path[..<slash])
}

private func _bundleLastPathComponent(_ path: String) -> String {
  if path == "/" { return "/" }
  var end = path.endIndex
  while end > path.startIndex && path[path.index(before: end)] == "/" {
    end = path.index(before: end)
  }
  guard let slash = path[..<end].lastIndex(of: "/") else {
    return String(path[..<end])
  }
  return String(path[path.index(after: slash)..<end])
}

private func _bundleJoin(_ base: String, _ component: String) -> String {
  if base == "/" { return "/" + component }
  return base.hasSuffix("/") ? base + component : base + "/" + component
}

private func _bundlePathExists(_ path: String) -> Bool {
  return path.withCString { _bundleAccess($0, _bundleFileExistsMode) == 0 }
}

private func _bundleMainExecutablePath() -> String? {
  var required: UInt32 = 0
  guard _bundleExecutablePath(nil, &required) != 0, required > 1 else {
    return nil
  }
  var bytes = [CChar](repeating: 0, count: Int(required))
  let result = bytes.withUnsafeMutableBufferPointer { buffer in
    _bundleExecutablePath(buffer.baseAddress, &required)
  }
  guard result == 0 else { return nil }
  return bytes.withUnsafeBufferPointer { buffer in
    guard let base = buffer.baseAddress else { return nil }
    return String(cString: base)
  }
}

public final class Bundle: @unchecked Sendable {
  public static let main: Bundle = {
    guard let executable = _bundleMainExecutablePath() else {
      // This cannot occur under a conforming Darwin process.  Keep the failure
      // contained and observable instead of guessing at the current directory.
      return Bundle(bundlePath: "", resourcePath: "")
    }

    let executableDirectory = _bundleDeletingLastPathComponent(executable)
    if _bundleLastPathComponent(executableDirectory) == "MacOS" {
      let contents = _bundleDeletingLastPathComponent(executableDirectory)
      if _bundleLastPathComponent(contents) == "Contents" {
        let root = _bundleDeletingLastPathComponent(contents)
        return Bundle(
          bundlePath: root,
          resourcePath: _bundleJoin(contents, "Resources")
        )
      }
    }

    // iOS application bundles are flat: the executable and resources both
    // live directly in Foo.app.  A non-bundled command-line executable uses
    // the same directory fallback, matching the useful part of Bundle.main.
    return Bundle(bundlePath: executableDirectory, resourcePath: executableDirectory)
  }()

  public let bundlePath: String
  public let resourcePath: String?

  private init(bundlePath: String, resourcePath: String) {
    self.bundlePath = bundlePath
    self.resourcePath = resourcePath.isEmpty ? nil : resourcePath
  }

  public func path(forResource name: String?, ofType ext: String?) -> String? {
    return path(forResource: name, ofType: ext, inDirectory: nil)
  }

  public func path(
    forResource name: String?,
    ofType ext: String?,
    inDirectory subpath: String?
  ) -> String? {
    guard let root = resourcePath, let name, !name.isEmpty else { return nil }

    // This first slice accepts the simple relative resource grammar Focus's
    // launch path uses. Broader Apple name/enumeration and symlink semantics
    // remain explicit work; do not present this lexical check as containment.
    let pieces = [subpath, name].compactMap { $0 }
    for piece in pieces {
      if piece.hasPrefix("/") || piece.split(separator: "/").contains("..") {
        return nil
      }
    }

    var candidate = root
    if let subpath, !subpath.isEmpty {
      candidate = _bundleJoin(candidate, subpath)
    }
    candidate = _bundleJoin(candidate, name)
    if let ext, !ext.isEmpty {
      candidate += ext.hasPrefix(".") ? ext : "." + ext
    }
    return _bundlePathExists(candidate) ? candidate : nil
  }
}
