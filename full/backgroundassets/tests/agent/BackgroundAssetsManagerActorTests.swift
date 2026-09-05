@_spi(OpenUIKitHost) import BackgroundAssets
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

func testAssetPackManagerSharedAndExecutor() {
    precondition(AssetPackManager.shared === AssetPackManager.shared)
    _ = AssetPackManager.shared.unownedExecutor
    _ = AssetPackManager.shared.statusUpdates
    _ = AssetPackManager.shared.statusUpdates(forAssetPackWithID: "missing")
}

func testAssetPackManagerFileAccessFailsClosed() {
    let path = FilePath("Textures/Hero.png")
    do {
        _ = try AssetPackManager.shared.contents(at: path)
        preconditionFailure("contents must fail closed")
    } catch let error as ManagedBackgroundAssetsError {
        switch error {
        case .fileNotFound(let found):
            precondition(found == path)
        default:
            preconditionFailure("expected fileNotFound")
        }
    } catch {
        preconditionFailure("unexpected \(error)")
    }

    do {
        _ = try AssetPackManager.shared.descriptor(for: path, searchingInAssetPackWithID: "pack")
        preconditionFailure("descriptor must fail closed")
    } catch let error as ManagedBackgroundAssetsError {
        switch error {
        case .fileNotFound(let found):
            precondition(found.string == "Textures/Hero.png")
        default:
            preconditionFailure("expected fileNotFound")
        }
    } catch {
        preconditionFailure("unexpected \(error)")
    }

    do {
        _ = try AssetPackManager.shared.url(for: path)
        preconditionFailure("url must fail closed")
    } catch let error as ManagedBackgroundAssetsError {
        switch error {
        case .fileNotFound:
            break
        default:
            preconditionFailure("expected fileNotFound")
        }
    } catch {
        preconditionFailure("unexpected \(error)")
    }
}

func testDownloadStatusUpdateCases() {
    let pack = AssetPack(id: "u", downloadSize: 1, version: 1)
    let began = AssetPackManager.DownloadStatusUpdate.began(pack)
    let paused = AssetPackManager.DownloadStatusUpdate.paused(pack)
    let downloading = AssetPackManager.DownloadStatusUpdate.downloading(
        pack,
        Progress(totalUnitCount: 10)
    )
    let finished = AssetPackManager.DownloadStatusUpdate.finished(pack)
    let failed = AssetPackManager.DownloadStatusUpdate.failed(pack, BAErrorCode.downloadFailedToStart)
    precondition(began.description.contains("began"))
    precondition(paused.description.contains("paused"))
    precondition(downloading.description.contains("downloading"))
    precondition(finished.description.contains("finished"))
    precondition(failed.description.contains("failed"))
    precondition(FilePath("a").description == "a")
    precondition(FileDescriptor(rawValue: 3).rawValue == 3)
}

struct EmptyDownloader: BADownloaderExtension {}

struct EmptyManagedDownloader: ManagedDownloaderExtension {}

func testDownloaderExtensionDefaults() {
    let extensionInfo = BAAppExtensionInfo()
    let downloader = EmptyDownloader()
    let downloads = downloader.downloads(
        for: .periodic,
        manifestURL: URL(string: "https://cdn.example/manifest.json")!,
        extensionInfo: extensionInfo
    )
    precondition(downloads.isEmpty)
    downloader.extensionWillTerminate()
    downloader.backgroundDownload(
        BAURLDownload(
            identifier: "x",
            request: URLRequest(url: URL(string: "https://cdn.example/x")!),
            applicationGroupIdentifier: "group.x"
        ),
        failedWithError: BAErrorCode.downloadAlreadyFailed
    )
    downloader.backgroundDownload(
        BAURLDownload(
            identifier: "y",
            request: URLRequest(url: URL(string: "https://cdn.example/y")!),
            applicationGroupIdentifier: "group.y"
        ),
        finishedWithFileURL: URL(fileURLWithPath: "/tmp/y")
    )
    _ = downloader.configuration
}

func testManagedDownloaderExtensionDefaults() {
    let managed = EmptyManagedDownloader()
    let pack = AssetPack(id: "auto", downloadSize: 1, version: 1)
    precondition(managed.shouldDownload(pack))
    let downloads = managed.downloads(
        for: .install,
        manifestURL: URL(string: "https://cdn.example/m.json")!,
        extensionInfo: BAAppExtensionInfo()
    )
    precondition(downloads.isEmpty)
    _ = managed.configuration
    managed.backgroundDownload(
        BAURLDownload(
            identifier: "z",
            request: URLRequest(url: URL(string: "https://cdn.example/z")!),
            applicationGroupIdentifier: "group.z"
        ),
        failedWithError: BAErrorCode.downloadAlreadyFailed
    )
    managed.backgroundDownload(
        BAURLDownload(
            identifier: "w",
            request: URLRequest(url: URL(string: "https://cdn.example/w")!),
            applicationGroupIdentifier: "group.w"
        ),
        finishedWithFileURL: URL(fileURLWithPath: "/tmp/w")
    )
}
