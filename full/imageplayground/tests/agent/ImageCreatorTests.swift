import Dispatch
import Foundation
@_spi(OpenUIKitHost) import ImagePlayground

func waitFor(_ body: @escaping () async -> Void) {
    let lock = DispatchSemaphore(value: 0)
    Task {
        await body()
        lock.signal()
    }
    precondition(lock.wait(timeout: .now() + 10) == .success, "async probe timed out")
}

func testImageCreatorInitUnavailable() {
    waitFor {
        do {
            _ = try await ImageCreator()
            preconditionFailure("ImageCreator.init must not succeed on this Linux host")
        } catch let error as ImageCreator.Error {
            precondition(error == .unavailable)
        } catch {
            preconditionFailure("ImageCreator.init threw unexpected \(error)")
        }
    }
}

func testImageCreatorAvailableStyles() {
    let hostCreator = ImagePlaygroundHostControl.makeImageCreator()
    precondition(hostCreator.availableStyles.map(\.id) == ImagePlaygroundStyle.all.map(\.id))
}
