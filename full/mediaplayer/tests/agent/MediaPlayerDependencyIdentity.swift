import CoreGraphics
import Foundation
import MediaPlayer

/// Future EC2 integrated-client probe. Do not treat an isolated `test_host.sh`
/// run as proof that this file linked guest Foundation + CoreGraphics.
///
/// Expected EC2 sequence (no local Docker):
/// 1. Build guest Foundation and CoreGraphics modules and dylibs.
/// 2. Build MediaPlayer with those `-I`/`-L` paths into `libMediaPlayer.dylib`.
/// 3. Compile this client against all three modules and link `libMediaPlayer.dylib`.
/// 4. Run with `LD_LIBRARY_PATH` pointing at the guest dylibs.
/// 5. Confirm `libMediaPlayer.dylib` is loaded and the identity marker prints.
///
/// Artwork APIs stay unavailable until UIKit is integrated; this client must
/// not invent `UIImage` / `CGSize` / `CGRect` lookalikes inside MediaPlayer.

final class IdentityOverridingDataSource: NSObject, MPPlayableContentDataSource {
    let child = MPContentItem(identifier: "identity-child")
    var beganLoading = false

    func numberOfChildItems(at indexPath: IndexPath) -> Int {
        _ = indexPath
        return 1
    }

    func contentItem(at indexPath: IndexPath) -> MPContentItem? {
        _ = indexPath
        return child
    }

    func beginLoadingChildItems(at indexPath: IndexPath) async throws {
        _ = indexPath
        beganLoading = true
    }

    func childItemsDisplayPlaybackProgress(at indexPath: IndexPath) -> Bool {
        _ = indexPath
        return true
    }

    func contentItem(forIdentifier identifier: String) async throws -> MPContentItem {
        _ = identifier
        return child
    }
}

final class IdentityDefaultDataSource: NSObject, MPPlayableContentDataSource {
    func numberOfChildItems(at indexPath: IndexPath) -> Int {
        _ = indexPath
        return 0
    }

    func contentItem(at indexPath: IndexPath) -> MPContentItem? {
        _ = indexPath
        return nil
    }
}

final class IdentityOverridingDelegate: NSObject, MPPlayableContentDelegate {
    var didUpdate = false

    func playableContentManager(
        _ contentManager: MPPlayableContentManager,
        didUpdate context: MPPlayableContentManagerContext
    ) {
        _ = (contentManager, context)
        didUpdate = true
    }

    func playableContentManager(
        _ contentManager: MPPlayableContentManager,
        initializePlaybackQueueWithCompletionHandler completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = contentManager
        completionHandler(nil)
    }

    func playableContentManager(
        _ contentManager: MPPlayableContentManager,
        initializePlaybackQueueWithContentItems contentItems: [Any]?,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = (contentManager, contentItems)
        completionHandler(nil)
    }

    func playableContentManager(
        _ contentManager: MPPlayableContentManager,
        initiatePlaybackOfContentItemAt indexPath: IndexPath
    ) async throws {
        _ = indexPath
    }
}

final class IdentityDefaultDelegate: NSObject, MPPlayableContentDelegate {}

func identityFail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("MEDIAPLAYER_DEPENDENCY_IDENTITY_FAIL: \(message)\n".utf8))
    exit(1)
}

func identityRunAsync(_ body: @escaping () async throws -> Void) {
    let sema = DispatchSemaphore(value: 0)
    var caught: Error?
    Task {
        do {
            try await body()
        } catch {
            caught = error
        }
        sema.signal()
    }
    if sema.wait(timeout: .now() + 5) != .success {
        identityFail("async timeout")
    }
    if let caught {
        identityFail(String(describing: caught))
    }
}

func identityLoadedMediaPlayerDylib() -> Bool {
    guard let maps = try? String(contentsOfFile: "/proc/self/maps", encoding: .utf8) else {
        return false
    }
    return maps.contains("libMediaPlayer.dylib")
}

// Real guest CoreGraphics value. Not passed into unavailable artwork APIs.
let cgSize = CGSize(width: 44, height: 88)
if cgSize.width != 44 || cgSize.height != 88 {
    identityFail("CoreGraphics CGSize identity")
}

// Real guest Foundation value passed through public MediaPlayer APIs.
let indexPath = IndexPath(indexes: [1, 0])
let source = IdentityOverridingDataSource()
let defaultSource = IdentityDefaultDataSource()
let delegate = IdentityOverridingDelegate()
let defaultDelegate = IdentityDefaultDelegate()

let manager = MPPlayableContentManager()
manager.dataSource = source
manager.delegate = delegate

let sourceWitness: any MPPlayableContentDataSource = manager.dataSource!
let delegateWitness: any MPPlayableContentDelegate = manager.delegate!
let defaultSourceWitness: any MPPlayableContentDataSource = defaultSource
let defaultDelegateWitness: any MPPlayableContentDelegate = defaultDelegate

if sourceWitness.numberOfChildItems(at: indexPath) != 1 {
    identityFail("overriding child count")
}
if sourceWitness.contentItem(at: indexPath) !== source.child {
    identityFail("overriding contentItem(at:)")
}
if !sourceWitness.childItemsDisplayPlaybackProgress(at: indexPath) {
    identityFail("overriding progress witness")
}
if defaultSourceWitness.childItemsDisplayPlaybackProgress(at: indexPath) {
    identityFail("default progress witness")
}

identityRunAsync {
    try await sourceWitness.beginLoadingChildItems(at: indexPath)
    if !source.beganLoading {
        identityFail("beginLoading witness")
    }
    let fetched = try await sourceWitness.contentItem(forIdentifier: "identity-child")
    if fetched !== source.child {
        identityFail("contentItem(forIdentifier:) witness")
    }
    do {
        _ = try await defaultSourceWitness.contentItem(forIdentifier: "missing")
        identityFail("default identifier must fail closed")
    } catch let error as MPError {
        if error.code != .notSupported {
            identityFail("default identifier error")
        }
    }
}

delegateWitness.playableContentManager(manager, didUpdate: manager.context)
if !delegate.didUpdate {
    identityFail("didUpdate witness")
}

var defaultQueueError: (any Error)?
defaultDelegateWitness.playableContentManager(
    manager,
    initializePlaybackQueueWithCompletionHandler: { defaultQueueError = $0 }
)
if (defaultQueueError as? MPError)?.code != .notSupported {
    identityFail("default queue must fail closed")
}

if !identityLoadedMediaPlayerDylib() {
    identityFail("libMediaPlayer.dylib is not loaded")
}

print(
    "MEDIAPLAYER_DEPENDENCY_IDENTITY_OK "
        + "modules=Foundation,CoreGraphics,MediaPlayer "
        + "dylib=libMediaPlayer.dylib existential=1"
)
