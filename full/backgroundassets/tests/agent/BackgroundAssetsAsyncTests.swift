@_spi(OpenUIKitHost) import BackgroundAssets
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class AgentAsyncChallengeSender: NSObject, URLAuthenticationChallengeSender {
    func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {}
    func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {}
    func cancel(_ challenge: URLAuthenticationChallenge) {}
    func performDefaultHandling(for challenge: URLAuthenticationChallenge) {}
    func rejectProtectionSpaceAndContinue(with challenge: URLAuthenticationChallenge) {}
}

func makeAgentAsyncChallenge() -> URLAuthenticationChallenge {
    let space = URLProtectionSpace(
        host: "cdn.example",
        port: 443,
        protocol: "https",
        realm: nil,
        authenticationMethod: NSURLAuthenticationMethodServerTrust
    )
    return URLAuthenticationChallenge(
        protectionSpace: space,
        proposedCredential: nil,
        previousFailureCount: 0,
        failureResponse: nil,
        error: nil,
        sender: AgentAsyncChallengeSender()
    )
}

struct AgentAsyncDownloader: BADownloaderExtension {}

struct AgentAsyncManagedDownloader: ManagedDownloaderExtension {}

final class AgentAsyncChallengeDelegate: NSObject, BADownloadManagerDelegate {}

func testAssetPackManagerAsyncReads() async {
    do {
        _ = try await AssetPackManager.shared.allAssetPacks
        preconditionFailure("allAssetPacks must fail closed")
    } catch let code as BAErrorCode {
        precondition(code == .callerConnectionInvalid)
    } catch {
        preconditionFailure("unexpected allAssetPacks error \(error)")
    }
    do {
        _ = try await AssetPackManager.shared.assetPack(withID: "missing-pack")
        preconditionFailure("assetPack must fail closed")
    } catch let error as ManagedBackgroundAssetsError {
        switch error {
        case .assetPackNotFound(let id):
            precondition(id == "missing-pack")
        default:
            preconditionFailure("expected assetPackNotFound")
        }
    } catch {
        preconditionFailure("unexpected assetPack error \(error)")
    }
    do {
        _ = try await AssetPackManager.shared.status(ofAssetPackWithID: "missing-pack")
        preconditionFailure("status must fail closed")
    } catch let error as ManagedBackgroundAssetsError {
        switch error {
        case .assetPackNotFound(let id):
            precondition(id == "missing-pack")
        default:
            preconditionFailure("expected assetPackNotFound")
        }
    } catch {
        preconditionFailure("unexpected status error \(error)")
    }
}

func testAssetPackManagerAsyncWrites() async {
    let pack = AssetPack(id: "missing-pack", downloadSize: 1, version: 1)
    do {
        try await AssetPackManager.shared.ensureLocalAvailability(of: pack)
        preconditionFailure("ensureLocalAvailability must fail closed")
    } catch let error as ManagedBackgroundAssetsError {
        switch error {
        case .assetPackNotFound(let id):
            precondition(id == "missing-pack")
        default:
            preconditionFailure("expected assetPackNotFound")
        }
    } catch {
        preconditionFailure("unexpected ensureLocalAvailability error \(error)")
    }
    do {
        _ = try await AssetPackManager.shared.checkForUpdates()
        preconditionFailure("checkForUpdates must fail closed")
    } catch let code as BAErrorCode {
        precondition(code == .callerConnectionInvalid)
    } catch {
        preconditionFailure("unexpected checkForUpdates error \(error)")
    }
    do {
        try await AssetPackManager.shared.remove(assetPackWithID: "missing-pack")
        preconditionFailure("remove must fail closed")
    } catch let error as ManagedBackgroundAssetsError {
        switch error {
        case .assetPackNotFound(let id):
            precondition(id == "missing-pack")
        default:
            preconditionFailure("expected assetPackNotFound")
        }
    } catch {
        preconditionFailure("unexpected remove error \(error)")
    }
}

func testAsyncChallengeDefaults() async {
    let challenge = makeAgentAsyncChallenge()
    let download = BAURLDownload(
        identifier: "async-challenge",
        request: URLRequest(url: URL(string: "https://cdn.example/async.bin")!),
        applicationGroupIdentifier: "group.async"
    )
    let unmanaged = AgentAsyncDownloader()
    let (unmanagedDisposition, unmanagedCredential) = await unmanaged.backgroundDownload(
        download,
        didReceive: challenge
    )
    precondition(unmanagedDisposition == .performDefaultHandling)
    precondition(unmanagedCredential == nil)
    let managed = AgentAsyncManagedDownloader()
    let (managedDisposition, managedCredential) = await managed.backgroundDownload(
        download,
        didReceive: challenge
    )
    precondition(managedDisposition == .performDefaultHandling)
    precondition(managedCredential == nil)
    let delegate = AgentAsyncChallengeDelegate()
    let (delegateDisposition, delegateCredential) = await delegate.download(
        download,
        didReceive: challenge
    )
    precondition(delegateDisposition == .performDefaultHandling)
    precondition(delegateCredential == nil)
}
