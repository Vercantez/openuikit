import Foundation
import UIKit
import ClockKit

/// Future clean EC2 probe. Build real guest Foundation and UIKit first, then
/// ClockKit with their -I/-L paths. This file is not part of the isolated
/// host gate. It does not claim integrated Linux success by itself.
let _: Foundation.URL.Type = URL.self
let _: Foundation.NSError.Type = NSError.self
let _: Foundation.NSObject.Type = NSObject.self
let _: ClockKit.CLKWatchFaceLibrary.Type = CLKWatchFaceLibrary.self
let _: ClockKit.CLKWatchFaceLibrary.ErrorCode.Type = CLKWatchFaceLibrary.ErrorCode.self

precondition(CLKWatchFaceLibrary.ErrorDomain == "CLKWatchFaceLibraryErrorDomain")
for raw in 1...5 {
    precondition(CLKWatchFaceLibrary.ErrorCode(rawValue: raw)?.rawValue == raw)
}

private final class IdentityOverride: CLKWatchFaceLibrary {
    var hits = 0
    override func addWatchFace(
        at fileURL: URL,
        completionHandler handler: @escaping (Error?) -> Void
    ) {
        hits += 1
        super.addWatchFace(at: fileURL, completionHandler: handler)
    }
}

private let library = IdentityOverride()
private let url = URL(string: "https://example.invalid/face.watchface")!
precondition(!url.isFileURL)

private let semaphore = DispatchSemaphore(value: 0)
private var seen = 0
library.addWatchFace(at: url) { error in
    precondition(!Thread.isMainThread)
    seen += 1
    let ns = error as NSError
    precondition(ns.domain == CLKWatchFaceLibrary.ErrorDomain)
    precondition(ns.domain == "CLKWatchFaceLibraryErrorDomain")
    precondition(ns.code == 1)
    semaphore.signal()
}
if semaphore.wait(timeout: .now() + .seconds(5)) == .timedOut {
    fatalError("identity probe timed out")
}
precondition(seen == 1)
precondition(library.hits == 1)

private let asyncSemaphore = DispatchSemaphore(value: 0)
Task {
    do {
        try await (library as CLKWatchFaceLibrary).addWatchFace(at: url)
        fatalError("identity async path must not succeed")
    } catch {
        let ns = error as NSError
        precondition(ns.domain == "CLKWatchFaceLibraryErrorDomain")
        precondition(ns.code == 1)
    }
    asyncSemaphore.signal()
}
if asyncSemaphore.wait(timeout: .now() + .seconds(5)) == .timedOut {
    fatalError("identity async probe timed out")
}
precondition(library.hits == 2)

print("CLOCKKIT_DEPENDENCY_IDENTITY_OK")
