import Dispatch
import Foundation
import ClockKit

private final class AsyncErrorBox: @unchecked Sendable {
    var error: (any Error)?
    var succeeded = false
}

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

private func expectCode(
    _ error: (any Error)?,
    _ expected: CLKWatchFaceLibrary.ErrorCode,
    _ label: String
) {
    guard let error else {
        fatalError("\(label): expected fail-closed error, got success")
    }
    if let code = error as? CLKWatchFaceLibrary.ErrorCode {
        expect(code == expected, "\(label): got \(code) expected \(expected)")
    } else {
        let nsError = error as NSError
        expect(
            nsError.domain == CLKWatchFaceLibrary.ErrorDomain,
            "\(label): domain \(nsError.domain)"
        )
        expect(nsError.code == expected.rawValue, "\(label): code \(nsError.code)")
    }

    let nsError = error as NSError
    expect(nsError.domain == CLKWatchFaceLibrary.ErrorDomain, "\(label): NSError domain")
    expect(nsError.code == expected.rawValue, "\(label): NSError code")
}

private func addWatchFaceSync(_ library: CLKWatchFaceLibrary, at url: URL) -> (any Error)? {
    var captured: (any Error)?
    var calls = 0
    library.addWatchFace(at: url) { error in
        calls += 1
        captured = error
    }
    expect(calls == 1, "completion handler must run exactly once")
    return captured
}

private func addWatchFaceAsync(_ library: CLKWatchFaceLibrary, at url: URL) -> (any Error)? {
    let box = AsyncErrorBox()
    let semaphore = DispatchSemaphore(value: 0)
    Task {
        do {
            try await library.addWatchFace(at: url)
            box.succeeded = true
        } catch {
            box.error = error
        }
        semaphore.signal()
    }
    semaphore.wait()
    if box.succeeded {
        return nil
    }
    return box.error
}

private func exerciseErrorCodeIdentity() {
    let codes: [CLKWatchFaceLibrary.ErrorCode] = [
        .notFileURL,
        .invalidFile,
        .permissionDenied,
        .faceNotAvailable,
        .noURL,
    ]
    let rawValues = [1, 2, 3, 4, 5]
    for (code, rawValue) in zip(codes, rawValues) {
        expect(code.rawValue == rawValue, "raw value for \(code)")
        expect(CLKWatchFaceLibrary.ErrorCode(rawValue: rawValue) == code, "init(rawValue: \(rawValue))")
        let other = codes[(rawValue % codes.count)]
        expect(code != other, "\(code) != \(other)")
    }
    expect(CLKWatchFaceLibrary.ErrorCode(rawValue: 0) == nil, "raw value 0 must be nil")
    expect(CLKWatchFaceLibrary.ErrorCode(rawValue: 6) == nil, "raw value 6 must be nil")
    expect(CLKWatchFaceLibrary.ErrorCode.notFileURL != .invalidFile, "notFileURL != invalidFile")
    expect(CLKWatchFaceLibrary.ErrorCode.faceNotAvailable == .faceNotAvailable, "equality")

    var hasher = Hasher()
    CLKWatchFaceLibrary.ErrorCode.permissionDenied.hash(into: &hasher)
    let hashValue = CLKWatchFaceLibrary.ErrorCode.permissionDenied.hashValue
    expect(hashValue == CLKWatchFaceLibrary.ErrorCode.permissionDenied.hashValue, "hashValue is stable")
    _ = hasher.finalize()

    let unique = Set(codes)
    expect(unique.count == codes.count, "ErrorCode hash/equality must distinguish cases")
}

private func exerciseFailClosedAdds() throws {
    let library = CLKWatchFaceLibrary()
    expect(CLKWatchFaceLibrary.ErrorDomain == CLKWatchFaceLibraryErrorDomain, "ErrorDomain alias")
    expect(
        CLKWatchFaceLibrary.ErrorDomain == "CLKWatchFaceLibraryErrorDomain",
        "ErrorDomain string"
    )
    expect(CLKWatchFaceLibrary.ErrorCode.errorDomain == CLKWatchFaceLibrary.ErrorDomain, "CustomNSError domain")

    let https = URL(string: "https://example.invalid/face.watchface")!
    expectCode(addWatchFaceSync(library, at: https), .notFileURL, "https completion")
    expectCode(addWatchFaceAsync(library, at: https), .notFileURL, "https async")

    let emptyFileURL = URL(string: "file://")!
    expect(emptyFileURL.isFileURL, "file:// is a file URL")
    expect(emptyFileURL.path.isEmpty, "file:// has an empty path")
    expectCode(addWatchFaceSync(library, at: emptyFileURL), .noURL, "empty path completion")
    expectCode(addWatchFaceAsync(library, at: emptyFileURL), .noURL, "empty path async")

    let missing = URL(fileURLWithPath: "/tmp/clockkit-missing-\(UUID().uuidString).watchface")
    expectCode(addWatchFaceSync(library, at: missing), .invalidFile, "missing completion")
    expectCode(addWatchFaceAsync(library, at: missing), .invalidFile, "missing async")

    let directory = URL(fileURLWithPath: FileManager.default.temporaryDirectory.path, isDirectory: true)
    expectCode(addWatchFaceSync(library, at: directory), .invalidFile, "directory completion")

    let readable = FileManager.default.temporaryDirectory
        .appendingPathComponent("clockkit-readable-\(UUID().uuidString).watchface")
    try Data("not-a-watch-face".utf8).write(to: readable)
    defer { try? FileManager.default.removeItem(at: readable) }
    expectCode(addWatchFaceSync(library, at: readable), .faceNotAvailable, "readable completion")
    expectCode(addWatchFaceAsync(library, at: readable), .faceNotAvailable, "readable async")

    let unreadable = FileManager.default.temporaryDirectory
        .appendingPathComponent("clockkit-unreadable-\(UUID().uuidString).watchface")
    try Data("secret".utf8).write(to: unreadable)
    defer { try? FileManager.default.removeItem(at: unreadable) }
    try FileManager.default.setAttributes(
        [.posixPermissions: 0o000],
        ofItemAtPath: unreadable.path
    )
    if FileManager.default.isReadableFile(atPath: unreadable.path) {
        expectCode(
            addWatchFaceSync(library, at: unreadable),
            .faceNotAvailable,
            "still-readable after chmod"
        )
    } else {
        expectCode(addWatchFaceSync(library, at: unreadable), .permissionDenied, "unreadable completion")
        expectCode(addWatchFaceAsync(library, at: unreadable), .permissionDenied, "unreadable async")
    }
}

exerciseErrorCodeIdentity()
do {
    try exerciseFailClosedAdds()
} catch {
    fatalError("runtime fixture failed: \(error)")
}

print("CLOCKKIT_AGENT_RUNTIME_OK")
