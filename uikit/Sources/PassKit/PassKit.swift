// Fail-closed PassKit for Blockzilla/Modules/WebView/WebViewController.swift
// PKPass(data:) / PKPassLibrary (focus-e2e.md: 1 PKPass). No Wallet: init
// throws, the library reports no passes.

import Foundation

public struct PKPassError: Error {
    public init() {}
}

public final class PKPass {
    public var passURL: URL?
    public init(data: Data) throws {
        _ = data
        throw PKPassError()
    }
}

public final class PKPassLibrary {
    public init() {}
    public func containsPass(_ pass: PKPass) -> Bool {
        _ = pass
        return false
    }
    public func addPasses(_ passes: [PKPass], withCompletionHandler completion: ((PKPassLibraryAddPassesResult) -> Void)? = nil) {
        _ = passes
        completion?(.shouldReviewPasses)
    }
}

public enum PKPassLibraryAddPassesResult: Int, Sendable {
    case didAddPasses = 0
    case shouldReviewPasses = 1
    case didCancelAddPasses = 2
}

import OpenUIKit

@preconcurrency @MainActor
open class PKAddPassesViewController: UIViewController {
    public init?(pass: PKPass) {
        super.init(nibName: nil, bundle: nil)
        _ = pass
        return nil
    }
}
